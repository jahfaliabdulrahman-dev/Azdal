/// Concrete [RouterTool] implementations wrapping Azdal's existing
/// pure-Dart services.
///
/// Each tool is self-contained: it declares its own FunctionDeclaration,
/// parses args with Arabic-Indic digit normalization, and delegates to
/// the existing service through [ToolContext].
///
/// WRITE tools return [StagedProposal] — they NEVER write to the database
/// inside `run()`. The existing tiered-approval machinery (confirm/undo)
/// commits only after the user taps confirm (DEC-020/021).
library;

import 'package:googleai_dart/googleai_dart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/arabic_numerals.dart';
import '../chat/services/commitment_service.dart';
import '../chat/services/goal_service.dart';
import '../chat/services/integrity_score_service.dart';
import '../chat/services/purchase_decision_service.dart';
import 'tool_types.dart';

// ─────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────

/// Parse a numeric arg that could be int, double, or String.
double? _parseAmount(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  if (raw is String) {
    final cleaned = normalizeArabicNumerals(raw);
    return double.tryParse(cleaned);
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────────
// evaluate_purchase — READ tool (tier: none)
// ─────────────────────────────────────────────────────────────────────

final class EvaluatePurchaseTool extends RouterTool<Map<String, dynamic>> {
  EvaluatePurchaseTool(this._purchaseService);

  final PurchaseDecisionService _purchaseService;

  @override
  String get name => 'evaluate_purchase';

  @override
  WriteTier get tier => WriteTier.none;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'evaluate_purchase',
        description: 'تقييم القدرة على شراء شيء معين — يرجع قرار (نعم/انتظر/لا) مع تفاصيل مالية',
        parameters: Schema(
          type: SchemaType.object,
          properties: {
            'item': Schema(
              type: SchemaType.string,
              description: 'اسم الشيء اللي يبي يشتريه (مثلاً: جوال، لابتوب، سيارة)',
            ),
            'amount': Schema(
              type: SchemaType.number,
              description: 'سعر الشيء بالريال السعودي',
            ),
          },
          required: ['item', 'amount'],
        ),
      );

  @override
  Map<String, dynamic> parseArgs(Map<String, Object?> raw) {
    final item = raw['item'] as String?;
    if (item == null || item.trim().isEmpty) {
      throw const ToolArgsError('item is required for evaluate_purchase');
    }
    final amount = _parseAmount(raw['amount']);
    if (amount == null || amount <= 0) {
      throw const ToolArgsError('amount must be a positive number');
    }
    return {'item': item.trim(), 'amount': amount};
  }

  @override
  Future<ToolOutcome> run(Map<String, dynamic> args, ToolContext ctx) async {
    final result = await _purchaseService.evaluate(
      args['item'] as String,
      args['amount'] as double,
    );
    final verdict = result['verdict'] as String;
    final reply = result['reply'] as String;
    final disposable = result['disposable'] as double;
    final goalImpact = result['goalImpact'] as String?;

    if (verdict == 'need_info') {
      return ClarifyOutcome(question: reply);
    }

    return RenderOutcome(
      widget: ChatWidgetSpec(
        widget: 'summary_card',
        title: 'نتيجة التحليل — شراء ${args['item']}',
        tone: verdict == 'yes'
            ? 'success'
            : verdict == 'wait'
                ? 'warning'
                : 'error',
        rows: [
          {'label': 'المبلغ المطلوب', 'value': '${(args['amount'] as double).round()} ريال', 'tone': 'neutral'},
          if (verdict == 'yes')
            {'label': 'الفائض المتاح', 'value': '${disposable.round()} ريال', 'tone': 'success'},
          if (goalImpact != null)
            {'label': 'تأثير الشراء', 'value': goalImpact, 'tone': 'warning'},
        ],
      ),
    );
    // Note: the confirm_purchase button is handled by the route() function,
    // not inside the tool — it's a separate user action.
  }
}

// ─────────────────────────────────────────────────────────────────────
// get_remaining_budget — READ tool (tier: none)
// ─────────────────────────────────────────────────────────────────────

final class GetRemainingBudgetTool extends RouterTool<void> {
  GetRemainingBudgetTool(this._purchaseService);

  final PurchaseDecisionService _purchaseService;

  @override
  String get name => 'get_remaining_budget';

  @override
  WriteTier get tier => WriteTier.none;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'get_remaining_budget',
        description: 'يعرض الميزانية المتبقية للمستخدم هذا الشهر — كم باقي له بعد الالتزامات والمصاريف',
        parameters: Schema(type: SchemaType.object, properties: {}),
      );

  @override
  void parseArgs(Map<String, Object?> raw) {
    // No args needed
  }

  @override
  Future<ToolOutcome> run(void args, ToolContext ctx) async {
    final result = await _purchaseService.calculateRemainingBudget();
    if (result['hasProfile'] != true) {
      return const ClarifyOutcome(
        question: 'عشان أحسب ميزانيتك — كم دخلك الشهري التقريبي؟',
      );
    }

    final remaining = result['remaining'] as double;
    final daysLeft = result['daysLeft'] as int;
    final income = result['income'] as double;
    final commitments = result['commitments'] as double;
    final monthlySpend = result['monthlySpend'] as double;
    final goalMonthly = result['goalMonthly'] as double;

    return RenderOutcome(
      widget: ChatWidgetSpec(
        widget: 'summary_card',
        title: 'الميزانية المتبقية',
        tone: remaining >= 0 ? 'success' : 'error',
        rows: [
          {'label': 'الدخل الشهري', 'value': '${income.round()} ريال', 'tone': 'neutral'},
          {'label': 'الالتزامات', 'value': '${commitments.round()} ريال', 'tone': 'neutral'},
          {'label': 'المصروف هذا الشهر', 'value': '${monthlySpend.round()} ريال', 'tone': 'neutral'},
          {'label': 'الأهداف', 'value': '${goalMonthly.round()} ريال', 'tone': 'neutral'},
          {'label': 'المتبقي', 'value': '${remaining.round()} ريال', 'tone': remaining >= 0 ? 'success' : 'error'},
          {'label': 'الأيام المتبقية', 'value': '$daysLeft يوم', 'tone': 'neutral'},
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// get_integrity_score — READ tool (tier: none)
// ─────────────────────────────────────────────────────────────────────

final class GetIntegrityScoreTool extends RouterTool<void> {
  GetIntegrityScoreTool(this._integrityService);

  final IntegrityScoreService _integrityService;

  @override
  String get name => 'get_integrity_score';

  @override
  WriteTier get tier => WriteTier.none;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'get_integrity_score',
        description: 'يعرض درجة النزاهة المالية للمستخدم (0-100) مع تفصيل العوامل',
        parameters: Schema(type: SchemaType.object, properties: {}),
      );

  @override
  void parseArgs(Map<String, Object?> raw) {}

  @override
  Future<ToolOutcome> run(void args, ToolContext ctx) async {
    final result = await _integrityService.calculate();
    final score = result['score'] as int;

    return RenderOutcome(
      widget: ChatWidgetSpec(
        widget: 'summary_card',
        title: 'درجة النزاهة',
        tone: score >= 70 ? 'success' : score >= 40 ? 'warning' : 'error',
        rows: [
          {'label': 'الدرجة', 'value': '$score/100', 'tone': score >= 70 ? 'success' : 'warning'},
          {'label': 'انتظام التسجيل', 'value': '${result['logging_consistency']}%', 'tone': 'neutral'},
          {'label': 'رفع الإيصالات', 'value': '${result['receipt_upload_rate']}%', 'tone': 'neutral'},
          {'label': 'عدم الحذف', 'value': '${result['no_deletion_rate']}%', 'tone': 'neutral'},
          {'label': 'دقة البيانات', 'value': 'قادم مع الربط البنكي', 'tone': 'neutral'},
          {'label': 'سرعة التفاعل', 'value': 'قادم مع الربط البنكي', 'tone': 'neutral'},
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// view_commitments — READ tool (tier: none)
// ─────────────────────────────────────────────────────────────────────

final class ViewCommitmentsTool extends RouterTool<String?> {
  ViewCommitmentsTool(this._commitmentService);

  final CommitmentService _commitmentService;

  @override
  String get name => 'view_commitments';

  @override
  WriteTier get tier => WriteTier.none;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'view_commitments',
        description: 'عرض الالتزامات المالية الشهرية الحالية (الأقساط، الإيجار، الاشتراكات...)',
        parameters: Schema(
          type: SchemaType.object,
          properties: {
            'name_hint': Schema(
              type: SchemaType.string,
              description: 'اسم أو مزوّد التزام معين للبحث عنه (اختياري)',
              nullable: true,
            ),
          },
        ),
      );

  @override
  String? parseArgs(Map<String, Object?> raw) {
    return raw['name_hint'] as String?;
  }

  @override
  Future<ToolOutcome> run(String? nameHint, ToolContext ctx) async {
    final commitments = await _commitmentService.listActive();
    if (commitments.isEmpty) {
      return const RenderOutcome(
        widget: ChatWidgetSpec(
          widget: 'summary_card',
          title: 'التزاماتك',
          tone: 'neutral',
          rows: [
            {'label': 'الحالة', 'value': 'ما فيه التزامات مسجلة حالياً ✨', 'tone': 'neutral'},
          ],
        ),
      );
    }

    // Filter by name hint if provided
    var filtered = commitments;
    if (nameHint != null && nameHint.isNotEmpty) {
      filtered = commitments
          .where((c) =>
              (c['name'] as String? ?? '').contains(nameHint) ||
              (c['provider'] as String? ?? '').contains(nameHint))
          .toList();
      if (filtered.isEmpty) {
        filtered = commitments;
      }
    }

    final rows = <Map<String, dynamic>>[];
    for (final c in filtered) {
      final name = c['name'] as String? ?? 'بدون اسم';
      final monthly = c['monthly_amount'] as num? ?? 0;
      final type = c['type'] as String? ?? '';
      final typeLabel = type == 'recurring' ? 'شهرياً' : type == 'bnpl' ? 'تقسيط' : '';
      rows.add({
        'label': name,
        'value': '${monthly.toInt()} ريال $typeLabel',
        'tone': 'neutral',
      });
    }

    return RenderOutcome(
      widget: ChatWidgetSpec(
        widget: 'summary_card',
        title: 'التزاماتك (${filtered.length})',
        tone: 'neutral',
        rows: rows,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// view_goals — READ tool (tier: none)
// ─────────────────────────────────────────────────────────────────────

final class ViewGoalsTool extends RouterTool<String?> {
  ViewGoalsTool(this._goalService);

  final GoalService _goalService;

  @override
  String get name => 'view_goals';

  @override
  WriteTier get tier => WriteTier.none;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'view_goals',
        description: 'عرض أهداف الادخار الحالية وتقدّمها',
        parameters: Schema(
          type: SchemaType.object,
          properties: {
            'name_hint': Schema(
              type: SchemaType.string,
              description: 'اسم هدف معين للبحث عنه (اختياري)',
              nullable: true,
            ),
          },
        ),
      );

  @override
  String? parseArgs(Map<String, Object?> raw) {
    return raw['name_hint'] as String?;
  }

  @override
  Future<ToolOutcome> run(String? nameHint, ToolContext ctx) async {
    final goals = await _goalService.listActive();
    if (goals.isEmpty) {
      return const RenderOutcome(
        widget: ChatWidgetSpec(
          widget: 'summary_card',
          title: 'أهدافك',
          tone: 'neutral',
          rows: [
            {'label': 'الحالة', 'value': 'ما فيه أهداف مسجلة حالياً 🎯', 'tone': 'neutral'},
          ],
        ),
      );
    }

    var filtered = goals;
    if (nameHint != null && nameHint.isNotEmpty) {
      filtered = goals
          .where((g) => (g['name'] as String? ?? '').contains(nameHint))
          .toList();
      if (filtered.isEmpty) filtered = goals;
    }

    final rows = <Map<String, dynamic>>[];
    for (final g in filtered) {
      final name = g['name'] as String? ?? 'بدون اسم';
      final target = g['target_amount'] as num? ?? 0;
      final current = g['current_amount'] as num? ?? 0;
      final monthly = g['monthly_contribution'] as num? ?? 0;
      rows.add({
        'label': name,
        'value': '${current.toInt()}/${target.toInt()} ريال (${monthly.toInt()} شهرياً)',
        'tone': 'neutral',
      });
    }

    return RenderOutcome(
      widget: ChatWidgetSpec(
        widget: 'summary_card',
        title: 'أهدافك (${filtered.length})',
        tone: 'neutral',
        rows: rows,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// log_expense — WRITE tool (tier: autoSaveWithUndo)
// ─────────────────────────────────────────────────────────────────────

final class LogExpenseTool extends RouterTool<Map<String, dynamic>> {
  LogExpenseTool();

  @override
  String get name => 'log_expense';

  @override
  WriteTier get tier => WriteTier.autoSaveWithUndo;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'log_expense',
        description: 'تسجيل عملية صرف واحدة (مبلغ + الفئة) — تتسجل تلقائياً مع إمكانية التراجع',
        parameters: Schema(
          type: SchemaType.object,
          properties: {
            'amount': Schema(type: SchemaType.number, description: 'المبلغ بالريال السعودي'),
            'category': Schema(type: SchemaType.string, description: 'الفئة (مثلاً: أكل، مواصلات، ترفيه، فواتير)'),
            'tone': Schema(
              type: SchemaType.string,
              enumValues: ['green', 'gray', 'red'],
              description: 'لون المؤشر: green لمصروف بسيط، gray عادي، red كبير',
              nullable: true,
            ),
          },
          required: ['amount'],
        ),
      );

  @override
  Map<String, dynamic> parseArgs(Map<String, Object?> raw) {
    final amount = _parseAmount(raw['amount']);
    if (amount == null || amount <= 0) {
      throw const ToolArgsError('amount must be a positive number');
    }
    return {
      'amount': amount,
      'category': raw['category'] as String? ?? 'متنوع',
      'tone': raw['tone'] as String? ?? 'gray',
    };
  }

  @override
  Future<ToolOutcome> run(Map<String, dynamic> args, ToolContext ctx) async {
    // DEC-020: autoSaveWithUndo — save immediately, show undo button.
    // This returns a StagedProposal so the route() function can execute
    // the save and show the undo button.
    return StagedProposal(
      toolName: name,
      draft: args,
      previewText: 'تم تسجيل ${(args['amount'] as double).round()} ريال — ${args['category']}',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// log_compound_expense — WRITE tool (tier: confirmCard)
// ─────────────────────────────────────────────────────────────────────

final class LogCompoundExpenseTool extends RouterTool<Map<String, dynamic>> {
  LogCompoundExpenseTool();

  @override
  String get name => 'log_compound_expense';

  @override
  WriteTier get tier => WriteTier.confirmCard;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'log_compound_expense',
        description: 'تسجيل مجموعة مصاريف في رسالة واحدة — كل بند له فئة ومبلغ',
        parameters: Schema(
          type: SchemaType.object,
          properties: {
            'splits': Schema(
              type: SchemaType.array,
              items: Schema(
                type: SchemaType.object,
                properties: {
                  'category': Schema(type: SchemaType.string, description: 'الفئة'),
                  'amount': Schema(type: SchemaType.number, description: 'المبلغ بالريال'),
                },
                required: ['category', 'amount'],
              ),
              description: 'قائمة المصاريف',
            ),
          },
          required: ['splits'],
        ),
      );

  @override
  Map<String, dynamic> parseArgs(Map<String, Object?> raw) {
    final splitsRaw = raw['splits'];
    if (splitsRaw == null || splitsRaw is! List || splitsRaw.isEmpty) {
      throw const ToolArgsError('splits must be a non-empty list');
    }
    final splits = splitsRaw.map((s) {
      if (s is! Map) throw const ToolArgsError('each split must be an object');
      final amount = _parseAmount(s['amount']);
      if (amount == null || amount <= 0) {
        throw const ToolArgsError('each split must have a positive amount');
      }
      return {
        'category': s['category'] as String? ?? 'متنوع',
        'amount': amount,
      };
    }).toList();
    return {'splits': splits};
  }

  @override
  Future<ToolOutcome> run(Map<String, dynamic> args, ToolContext ctx) async {
    final splits = args['splits'] as List<Map<String, dynamic>>;
    return StagedProposal(
      toolName: name,
      draft: {'splits': splits},
      previewText: 'قسمت مصروفك إلى ${splits.length} بنود — راجع وأكد 👇',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// add_commitment — WRITE tool (tier: confirmCard)
// ─────────────────────────────────────────────────────────────────────

final class AddCommitmentTool extends RouterTool<Map<String, dynamic>> {
  AddCommitmentTool();

  @override
  String get name => 'add_commitment';

  @override
  WriteTier get tier => WriteTier.confirmCard;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'add_commitment',
        description: 'إضافة التزام مالي شهري جديد (قسط، إيجار، اشتراك...)',
        parameters: Schema(
          type: SchemaType.object,
          properties: {
            'name': Schema(type: SchemaType.string, description: 'اسم الالتزام (مثلاً: قسط سيارة، إيجار الشقة)'),
            'provider': Schema(
              type: SchemaType.string,
              description: 'اسم الجهة (تمارا، تابي، البنك...)',
              nullable: true,
            ),
            'amount_monthly': Schema(type: SchemaType.number, description: 'المبلغ الشهري بالريال', nullable: true),
            'amount_total': Schema(type: SchemaType.number, description: 'المبلغ الإجمالي بالريال', nullable: true),
            'type': Schema(
              type: SchemaType.string,
              enumValues: ['recurring', 'bnpl', 'loan', 'subscription'],
              description: 'نوع الالتزام',
              nullable: true,
            ),
          },
          required: ['name'],
        ),
      );

  @override
  Map<String, dynamic> parseArgs(Map<String, Object?> raw) {
    final name = raw['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      throw const ToolArgsError('name is required');
    }
    return {
      'name': name.trim(),
      'provider': raw['provider'] as String?,
      'amount_monthly': _parseAmount(raw['amount_monthly']),
      'amount_total': _parseAmount(raw['amount_total']),
      'type': raw['type'] as String? ?? 'recurring',
    };
  }

  @override
  Future<ToolOutcome> run(Map<String, dynamic> args, ToolContext ctx) async {
    return StagedProposal(
      toolName: name,
      draft: args,
      previewText: 'تمام، فهمت — ${args['name']}. راجع التفاصيل قبل الحفظ 👇',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// add_goal — WRITE tool (tier: confirmCard)
// ─────────────────────────────────────────────────────────────────────

final class AddGoalTool extends RouterTool<Map<String, dynamic>> {
  AddGoalTool();

  @override
  String get name => 'add_goal';

  @override
  WriteTier get tier => WriteTier.confirmCard;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'add_goal',
        description: 'إضافة هدف ادخار جديد',
        parameters: Schema(
          type: SchemaType.object,
          properties: {
            'name': Schema(type: SchemaType.string, description: 'اسم الهدف (مثلاً: سيارة، زواج، طوارئ)'),
            'amount_total': Schema(type: SchemaType.number, description: 'المبلغ الإجمالي المطلوب بالريال', nullable: true),
            'amount_monthly': Schema(type: SchemaType.number, description: 'مبلغ التوفير الشهري بالريال', nullable: true),
          },
          required: ['name'],
        ),
      );

  @override
  Map<String, dynamic> parseArgs(Map<String, Object?> raw) {
    final name = raw['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      throw const ToolArgsError('name is required');
    }
    return {
      'name': name.trim(),
      'amount_total': _parseAmount(raw['amount_total']),
      'amount_monthly': _parseAmount(raw['amount_monthly']),
    };
  }

  @override
  Future<ToolOutcome> run(Map<String, dynamic> args, ToolContext ctx) async {
    return StagedProposal(
      toolName: name,
      draft: args,
      previewText: 'حلو! هدف ${args['name']}. راجع وأكد 👇',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// general_chat — STRUCTURAL tool (tier: none, always registered)
// ─────────────────────────────────────────────────────────────────────

final class GeneralChatTool extends RouterTool<String> {
  @override
  String get name => 'general_chat';

  @override
  WriteTier get tier => WriteTier.none;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'general_chat',
        description: 'لأي رسالة عامة: سلام، شكر، سؤال عام، نصيحة، دردشة، أو أي شيء ما ينطبق على الأدوات الثانية',
        parameters: Schema(type: SchemaType.object, properties: {}),
      );

  @override
  String parseArgs(Map<String, Object?> raw) {
    return raw['message'] as String? ?? '';
  }

  @override
  Future<ToolOutcome> run(String message, ToolContext ctx) async {
    // This tool is handled specially in route() — the LLM call to the coach
    // prompt happens OUTSIDE the tool because the tool doesn't have access
    // to the RouterLlm. The route() function checks for `general_chat` and
    // delegates to the coach chat path.
    return const RenderOutcome(
      widget: ChatWidgetSpec(widget: '_delegate_to_coach'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// ask_clarification — STRUCTURAL tool (tier: none, always registered)
// ─────────────────────────────────────────────────────────────────────

final class AskClarificationTool extends RouterTool<Map<String, dynamic>> {
  @override
  String get name => 'ask_clarification';

  @override
  WriteTier get tier => WriteTier.none;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'ask_clarification',
        description: 'إذا كان قصد المستخدم غير واضح أو ناقص معلومات — استخدم هذه الأداة لطلب توضيح',
        parameters: Schema(
          type: SchemaType.object,
          properties: {
            'missing': Schema(
              type: SchemaType.array,
              items: Schema(type: SchemaType.string),
              description: 'المعلومات الناقصة (مثلاً: [\"المبلغ\", \"اسم الشيء\"])',
            ),
            'question': Schema(
              type: SchemaType.string,
              description: 'سؤال توضيحي باللهجة السعودية',
            ),
          },
          required: ['missing', 'question'],
        ),
      );

  @override
  Map<String, dynamic> parseArgs(Map<String, Object?> raw) {
    return {
      'missing': (raw['missing'] as List<dynamic>?)?.cast<String>() ?? [],
      'question': raw['question'] as String? ?? 'وش تقصد بالضبط؟',
    };
  }

  @override
  Future<ToolOutcome> run(Map<String, dynamic> args, ToolContext ctx) async {
    return ClarifyOutcome(question: args['question'] as String);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Convenience factory — build all tools wired to Supabase
// ─────────────────────────────────────────────────────────────────────

/// Build the complete tool set wired to a Supabase client.
List<RouterTool<Object?>> createAllTools(SupabaseClient client) {
  final purchaseService = PurchaseDecisionService(client);
  final integrityService = IntegrityScoreService(client);
  final commitmentService = CommitmentService(client);
  final goalService = GoalService(client);

  return [
    // READ tools
    EvaluatePurchaseTool(purchaseService) as RouterTool<Object?>,
    GetRemainingBudgetTool(purchaseService) as RouterTool<Object?>,
    GetIntegrityScoreTool(integrityService) as RouterTool<Object?>,
    ViewCommitmentsTool(commitmentService) as RouterTool<Object?>,
    ViewGoalsTool(goalService) as RouterTool<Object?>,
    // WRITE tools — no services injected; they return StagedProposal
    LogExpenseTool() as RouterTool<Object?>,
    LogCompoundExpenseTool() as RouterTool<Object?>,
    AddCommitmentTool() as RouterTool<Object?>,
    AddGoalTool() as RouterTool<Object?>,
    // STRUCTURAL tools
    GeneralChatTool() as RouterTool<Object?>,
    AskClarificationTool() as RouterTool<Object?>,
  ];
}
