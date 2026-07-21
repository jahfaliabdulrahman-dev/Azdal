/// Chat screen — the sole UI screen of Azdal.
///
/// Implements the full chat experience:
/// - Scrollable message list with user/bot bubbles
/// - Widget catalog rendering (6 types) via Gemini JSON responses
/// - Voice input via speech_to_text (CHAT-04)
/// - Transaction logging to Supabase (CHAT-05)
/// - Compound transaction splitting (CHAT-06)
/// - Cold Start Intelligence (CHAT-07)
/// - Commitment & Goal setup flow (Stage 4)
/// - Offline detection with connectivity_plus
/// - Error bubble with retry
/// - Typing indicator
library;

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../core/utils/arabic_numerals.dart';
import '../../main.dart';
import 'models/chat_message.dart';
import 'providers/chat_provider.dart';
import 'widgets/chat_widgets.dart';
import 'widgets/widget_catalog.dart';
import '../router/router.dart';

// ─────────────────────────────────────────────────────────────────────
// Design token constants (from 04_ui_design_system.md)
// ─────────────────────────────────────────────────────────────────────

const _navy = Color(0xFF001F5E);
const _cyan = Color(0xFF32C2FF);
const _userBubbleBg = Color(0xFFE3E8F5);
const _muted = Color(0xFF6B7280);
const _white = Colors.white;

// ─────────────────────────────────────────────────────────────────────
// ChatScreen
// ─────────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _coldStartDone = false;
  bool _isUndoing = false;
  final Map<String, Map<String, dynamic>> _storedClassifications = {};
  RouterState _routerState = const RouterState();

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _initVoice();
    _checkColdStart();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingSharedImage();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ── Connectivity ──

  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateOnlineStatus(result);
      _connectivitySub = Connectivity().onConnectivityChanged.listen(_updateOnlineStatus);
    } catch (e) {
      print('=== AZDAL DEBUG: Connectivity init error — $e');
    }
  }

  void _updateOnlineStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      setState(() => _isOnline = online);
      print('=== AZDAL DEBUG: Connectivity changed — online=$online');
    }
  }

  // ── Voice ──

  Future<void> _initVoice() async {
    final voiceService = ref.read(voiceServiceProvider);
    final available = await voiceService.initialize();
    print('=== AZDAL DEBUG: Voice init — available=$available');
  }

  Future<void> _toggleVoice() async {
    final voiceService = ref.read(voiceServiceProvider);
    final voiceListening = ref.read(voiceListeningProvider);
    if (voiceListening.isListening) {
      final text = await voiceService.stopListening();
      if (text.isNotEmpty && mounted) {
        _textController.text = text;
        _textController.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
      }
    } else {
      final started = await voiceService.startListening(
        onResult: (text, _) {
          if (mounted) {
            _textController.text = text;
            _textController.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
          }
        },
      );
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تشغيل الميكروفون. تأكد من الصلاحيات.')),
        );
      }
    }
  }

  // ── Cold Start ──

  Future<void> _checkColdStart() async {
    if (_coldStartDone) return;
    final chatState = ref.read(chatProvider);
    if (chatState.messages.isNotEmpty) return;
    try {
      final txService = ref.read(transactionServiceProvider);
      final hasTransactions = await txService.hasExistingTransactions();
      if (!hasTransactions && mounted) {
        _coldStartDone = true;
        _triggerColdStart();
      }
    } catch (e) {
      print('=== AZDAL DEBUG: Cold start check FAILED — $e');
    }
  }

  void _triggerColdStart() {
    final chatNotifier = ref.read(chatProvider.notifier);
    chatNotifier.addBotMessage(
      'صباح الخير! عشان أقدر أساعدك — ٣ أسئلة بس:',
      widget: {
        'widget': 'quick_input_form',
        'title': 'معلوماتك المالية',
        'fields': [
          {'label': 'الدخل الشهري التقريبي', 'placeholder': 'مثلاً: 10,000 ريال', 'key': 'monthly_income', 'type': 'number'},
          {'label': 'الالتزامات الشهرية — إيجار، أقساط، فواتير', 'placeholder': 'مثلاً: 4,000 ريال', 'key': 'monthly_commitments', 'type': 'number'},
          {'label': 'كم تصرف تقريباً بالأسبوع؟', 'placeholder': 'مثلاً: 1,500 ريال', 'key': 'weekly_spend', 'type': 'number'},
        ],
        'submit_label': 'إرسال',
      },
    );
  }

  Future<void> _handleColdStartSubmit(Map<String, dynamic> values) async {
    final chatNotifier = ref.read(chatProvider.notifier);
    final income = values['monthly_income'] ?? '0';
    final commitments = values['monthly_commitments'] ?? '0';
    final weeklySpend = values['weekly_spend'] ?? '0';

    final monthlyIncome = double.tryParse(normalizeArabicNumerals(income.toString())) ?? 0;
    final monthlyCommitments = double.tryParse(normalizeArabicNumerals(commitments.toString())) ?? 0;
    final monthlySpend = (double.tryParse(normalizeArabicNumerals(weeklySpend.toString())) ?? 0) * 4;

    final disposableAfterCommitments = monthlyIncome - monthlyCommitments;
    final spendRatio = disposableAfterCommitments > 0
        ? (monthlySpend / disposableAfterCommitments * 100).round()
        : 100;

    // DEC-023: persist Cold Start estimates to financial_profile
    try {
      final profileService = ref.read(financialProfileServiceProvider);
      await profileService.upsert(
        monthlyIncome: monthlyIncome,
        monthlyCommitmentsEstimate: monthlyCommitments,
        weeklySpendEstimate: (double.tryParse(normalizeArabicNumerals(weeklySpend.toString())) ?? 0),
      );
    } catch (e) {
      print('=== AZDAL DEBUG: financial_profile upsert FAILED — $e');
    }

    // DEC-022 (BRP): use LLM for personalized reaction, with hardcoded fallback
    final geminiService = ref.read(geminiServiceProvider);
    String insight;
    try {
      final reaction = await geminiService.reactToColdStart(
        spendRatio: spendRatio,
        disposableAfterCommitments: disposableAfterCommitments,
      );
      insight = (reaction.error == null && reaction.text.trim().isNotEmpty)
          ? reaction.text.trim()
          : _coldStartFallback(spendRatio);
    } catch (e) {
      print('=== AZDAL DEBUG: Cold start reaction FAILED — $e');
      insight = _coldStartFallback(spendRatio);
    }

    chatNotifier.addBotMessage(
      '$insight\n\nوأي وقت تبي، قول لي مثلاً "عندي قسط..." أو "عندي هدف..." وأسجله لك.',
    );

    if (monthlyIncome > 0) {
      try {
        final txService = ref.read(transactionServiceProvider);
        await txService.saveTransaction(
          amount: monthlyIncome, category: 'دخل', subcategory: 'دخل شهري',
          description: 'الدخل الشهري التقريبي (Cold Start)', type: 'income', tone: 'green',
        );
      } catch (e) {
        print('=== AZDAL DEBUG: Cold start income save FAILED — $e');
      }
    }
  }

  String _coldStartFallback(int spendRatio) {
    if (spendRatio >= 70) {
      return 'تصرف $spendRatio% من دخلك قبل منتصف الشهر. خليني أساعدك — سجل أول عملية بالصوت أو الكتابة.';
    }
    return 'وضعك المالي معقول حالياً. تبي نبدأ نسجل أول عملية؟ اكتب أو استخدم الصوت 🎤';
  }

  // ── Message send (tool-calling router — DEC-050, Phase 0.5) ──

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (!_isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أنت غير متصل. حاول مرة أخرى عند عودة الاتصال.')),
        );
      }
      return;
    }
    _textController.clear();
    _focusNode.unfocus();

    final chatNotifier = ref.read(chatProvider.notifier);
    final routerLlm = ref.read(routerLlmProvider);
    final registry = ref.read(toolRegistryProvider);
    final tracer = ref.read(toolCallTraceServiceProvider);
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id ?? '';

    final userMsgId = chatNotifier.addUserMessage(text);
    _storedClassifications[userMsgId] = <String, dynamic>{};

    try {
      final result = await route(
        routerLlm: routerLlm,
        registry: registry,
        userText: text,
        userId: userId,
        tracer: tracer,
        state: _routerState,
      );

      if (!mounted) return;

      if (result.isError) {
        chatNotifier.setError(result.errorText!);
        _storedClassifications.remove(userMsgId);
        return;
      }

      if (result.isGeneralChat) {
        // Delegate to the coach LLM (existing GeminiService.sendMessage)
        final geminiService = ref.read(geminiServiceProvider);
        final allMessages = ref.read(chatProvider).messages;
        // Filter: exclude widget-bearing bot replies from coach history
        final filteredHistory = allMessages.where((m) {
          if (!m.isUser) return !m.hasWidget;
          if (m.id == userMsgId) return true;
          return !_storedClassifications.containsKey(m.id);
        }).toList();

        final response = await geminiService.sendMessage(text, history: filteredHistory);
        if (!mounted) return;
        if (response.hasError) {
          chatNotifier.setError(response.error!);
          _storedClassifications.remove(userMsgId);
          return;
        }
        chatNotifier.addBotMessage(response.text, widget: response.widget);
        _storedClassifications.remove(userMsgId);
        return;
      }

      final outcome = result.outcome!;
      switch (outcome) {
        case RenderOutcome(:final widget):
          final widgetJson = widget.toJson();
          // Purchase decision needs follow-up confirm button
          if (widget.widget == 'summary_card' &&
              widget.title?.startsWith('نتيجة التحليل') == true) {
            chatNotifier.addBotMessage('', widget: widgetJson);
            // The confirm/defer buttons are handled by the purchase flow
          } else {
            chatNotifier.addBotMessage('', widget: widgetJson);
          }
          _storedClassifications.remove(userMsgId);
          // Reset router state
          _routerState = const RouterState();
          break;

        case ClarifyOutcome(:final question):
          chatNotifier.addBotMessage(question);
          _storedClassifications.remove(userMsgId);
          _routerState = const RouterState();
          break;

        case StagedProposal(:final toolName, :final draft, :final previewText):
          await _handleStagedProposal(
            chatNotifier, toolName, draft, previewText, userMsgId,
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      chatNotifier.setError(e.toString());
      _storedClassifications.remove(userMsgId);
    }
  }

  /// Handle a [StagedProposal] from the router — execute the write
  /// (auto-save or confirm-card) per the tool's [WriteTier].
  Future<void> _handleStagedProposal(
    ChatProvider chatNotifier,
    String toolName,
    Map<String, dynamic> draft,
    String previewText,
    String userMsgId,
  ) async {
    switch (toolName) {
      case 'log_expense':
        // DEC-020: autoSaveWithUndo — save immediately, show undo button
        try {
          final txService = ref.read(transactionServiceProvider);
          final saved = await txService.saveTransaction(
            amount: (draft['amount'] as num).toDouble(),
            category: draft['category'] as String,
            tone: draft['tone'] as String? ?? 'gray',
          );
          final txId = saved['id'] as String;
          chatNotifier.addBotMessage('', widget: {
            'widget': 'action_buttons',
            'question': previewText,
            'buttons': [
              {'label': '↩️ تراجع', 'value': 'undo_transaction', 'type': 'secondary'},
            ],
            'tx_id': txId,
            'tx_type': 'simple',
          });
        } catch (e) {
          if (mounted) chatNotifier.setError('فشل حفظ المعاملة: $e');
        }
        _storedClassifications.remove(userMsgId);
        break;

      case 'log_compound_expense':
        // DEC-020: confirmCard — show confirm/edit card
        final splits = (draft['splits'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        chatNotifier.addBotMessage(
          previewText,
          widget: {
            'widget': 'compound_split_card',
            'splits': splits,
          },
        );
        _storedClassifications.remove(userMsgId);
        break;

      case 'add_commitment':
        // DEC-020: confirmCard — show quick_input_form for review
        chatNotifier.addBotMessage(
          previewText,
          widget: {
            'widget': 'quick_input_form',
            'title': 'إضافة التزام — ${draft['name']}',
            'fields': [
              {
                'label': 'اسم الالتزام',
                'key': 'name',
                'type': 'text',
                'value': draft['name'] ?? '',
              },
              {
                'label': 'الجهة',
                'key': 'provider',
                'type': 'text',
                'value': draft['provider'] ?? '',
              },
              {
                'label': 'المبلغ الشهري',
                'key': 'amount_monthly',
                'type': 'number',
                'value': draft['amount_monthly']?.toString() ?? '',
              },
              {
                'label': 'المبلغ الإجمالي',
                'key': 'amount_total',
                'type': 'number',
                'value': draft['amount_total']?.toString() ?? '',
              },
            ],
            'submit_label': 'حفظ الالتزام',
            '_form_kind': 'commitment_add',
          },
        );
        _storedClassifications.remove(userMsgId);
        break;

      case 'add_goal':
        // DEC-020: confirmCard — show quick_input_form for review
        chatNotifier.addBotMessage(
          previewText,
          widget: {
            'widget': 'quick_input_form',
            'title': 'إضافة هدف — ${draft['name']}',
            'fields': [
              {
                'label': 'اسم الهدف',
                'key': 'name',
                'type': 'text',
                'value': draft['name'] ?? '',
              },
              {
                'label': 'المبلغ الإجمالي',
                'key': 'amount_total',
                'type': 'number',
                'value': draft['amount_total']?.toString() ?? '',
              },
              {
                'label': 'التوفير الشهري',
                'key': 'amount_monthly',
                'type': 'number',
                'value': draft['amount_monthly']?.toString() ?? '',
              },
            ],
            'submit_label': 'حفظ الهدف',
            '_form_kind': 'goal_add',
          },
        );
        _storedClassifications.remove(userMsgId);
        break;

      default:
        chatNotifier.addBotMessage(previewText);
        _storedClassifications.remove(userMsgId);
    }

    // Reset router state after staged proposal
    _routerState = const RouterState();
  }

  Future<void> _runPurchaseDecision(
    String item,
    double? amount,
    ChatProvider chatNotifier,
  ) async {
    if (item.isEmpty) {
      chatNotifier.addBotMessage('وش الشيء اللي تبي تشتريه؟');
      return;
    }
    if (amount == null || amount <= 0) {
      chatNotifier.addBotMessage('كم سعره؟ عشان أقدر أحلل وضعك.');
      return;
    }

    try {
      final purchaseService = ref.read(purchaseDecisionServiceProvider);
      final result = await purchaseService.evaluate(item, amount);
      final verdict = result['verdict'] as String;
      final reply = result['reply'] as String;
      final disposable = result['disposable'] as double;
      final dti = result['dti'] as double;

      switch (verdict) {
        case 'yes':
          chatNotifier.addBotMessage(reply, widget: {
            'widget': 'summary_card',
            'title': 'نتيجة التحليل — شراء $item',
            'tone': 'success',
            'rows': [
              {'label': 'المبلغ المطلوب', 'value': '${amount.round()} ريال', 'tone': 'neutral'},
              {'label': 'الفائض المتاح', 'value': '${disposable.round()} ريال', 'tone': 'success'},
            ],
          });
          chatNotifier.addBotMessage('', widget: {
            'widget': 'action_buttons',
            'question': 'تقدر تشتري! تبي نسجل العملية؟',
            'buttons': [
              {'label': 'تسجيل العملية ✓', 'value': 'confirm_purchase', 'type': 'primary'},
            ],
            'purchase_item': item,
            'purchase_amount': amount.round(),
            'purchase_reply': reply,
            'purchase_disposable': disposable,
          });
          break;
        case 'wait':
          final goalImpact = result['goalImpact'] as String?;
          chatNotifier.addBotMessage(reply, widget: {
            'widget': 'summary_card',
            'title': 'انتبه — أولوياتك المالية',
            'tone': 'warning',
            'rows': [
              {'label': 'الفائض هذا الشهر', 'value': '${(disposable + amount).round()} ريال', 'tone': 'neutral'},
              if (goalImpact != null)
                {'label': 'تأثير الشراء', 'value': goalImpact, 'tone': 'warning'},
            ],
          });
          chatNotifier.addBotMessage('', widget: {
            'widget': 'action_buttons',
            'question': 'وش تبي تسوي؟',
            'buttons': [
              {'label': 'تأجيل', 'value': 'defer_purchase', 'type': 'secondary'},
              {'label': 'شراء الآن', 'value': 'confirm_purchase', 'type': 'primary'},
            ],
            'purchase_item': item,
            'purchase_amount': amount.round(),
            'purchase_reply': reply,
            'purchase_disposable': disposable,
          });
          break;
        case 'no':
          final dtiPercent = (dti * 100).round();
          chatNotifier.addBotMessage(reply, widget: {
            'widget': 'summary_card',
            'title': 'الأفضل ما تشتري الآن',
            'tone': 'danger',
            'rows': [
              {'label': 'نسبة الالتزامات', 'value': '$dtiPercent% من الدخل', 'tone': 'danger'},
              {'label': 'الحد الآمن', 'value': '33% من الدخل', 'tone': 'neutral'},
              {'label': 'التوصية', 'value': 'انتظر حتى تنخفض التزاماتك', 'tone': 'danger'},
            ],
          });
          break;
        case 'need_info':
          chatNotifier.addBotMessage(reply, widget: {
            'widget': 'quick_input_form',
            'title': 'معلومة ناقصة',
            '_form_kind': 'buy_verdict_clarification',
            'fields': [
              {'label': 'الدخل الشهري التقريبي', 'placeholder': 'مثلاً: 8,000', 'key': 'income', 'type': 'number', 'required': true},
            ],
            'submit_label': 'احسب →',
            '_pending_item': item,
            '_pending_amount': amount,
          });
          break;
      }
    } catch (e) {
      chatNotifier.setError('فشل تحليل الشراء: $e');
    }
  }

  // ── Commitment flow (DEC-033) ──

  Future<void> _showCommitmentAddForm(Map<String, dynamic>? draft, String? reply, ChatProvider chatNotifier) async {
    final commitmentService = ref.read(commitmentServiceProvider);
    final hasAny = await commitmentService.hasAnyCommitments();
    double? seedMonthly;
    if (!hasAny) {
      final profileService = ref.read(financialProfileServiceProvider);
      final profile = await profileService.getProfile();
      final estimate = profile?['monthly_commitments_estimate'] as num?;
      if (estimate != null && estimate > 0) seedMonthly = estimate.toDouble();
    }
    final introText = seedMonthly != null
        ? 'قدرت التزاماتك الشهرية بـ ${seedMonthly.toInt()} ريال وقت البداية السريعة. خلنا نفصّلها لالتزامات حقيقية — ابدأ بأول واحد، وعدّل الرقم إذا كان يخص التزام واحد بس:'
        : (reply != null && reply.trim().isNotEmpty ? reply.trim() : 'سجّلت مسودة التزام — راجع التفاصيل وأكد:');
    chatNotifier.addBotMessage(introText, widget: {
      'widget': 'quick_input_form', 'title': 'إضافة التزام',
      'fields': [
        {'label': 'اسم الالتزام', 'placeholder': 'مثلاً: تمارا، إيجار', 'key': 'name', 'prefill': draft?['name'] as String? ?? ''},
        {'label': 'المبلغ الإجمالي', 'placeholder': 'مثلاً: 1000 ريال', 'key': 'total_amount', 'type': 'number', 'prefill': (draft?['amount_total'])?.toString() ?? ''},
        {'label': 'القسط الشهري', 'placeholder': 'مثلاً: 200 ريال', 'key': 'monthly_amount', 'type': 'number', 'prefill': (draft?['amount_monthly'] ?? seedMonthly)?.toString() ?? ''},
      ],
      'submit_label': 'حفظ الالتزام', '_form_kind': 'commitment_add',
    });
  }

  Future<void> _submitCommitmentAdd(Map<String, dynamic> values, ChatProvider chatNotifier) async {
    final name = (values['name'] as String?)?.trim();
    final monthly = double.tryParse(normalizeArabicNumerals(values['monthly_amount'] as String? ?? ''));
    if (name == null || name.isEmpty || monthly == null || monthly <= 0) {
      chatNotifier.addBotMessage('محتاج اسم الالتزام والقسط الشهري على الأقل عشان أسجله.');
      return;
    }
    final total = double.tryParse(normalizeArabicNumerals(values['total_amount'] as String? ?? '')) ?? monthly;
    try {
      final commitmentService = ref.read(commitmentServiceProvider);
      final saved = await commitmentService.addCommitment(name: name, totalAmount: total, remaining: total, monthlyAmount: monthly, type: _inferCommitmentType(name));
      final id = saved['id'] as String;
      chatNotifier.addBotMessage('تم حفظ التزام "$name" — $monthly ريال شهرياً ✅', widget: {
        'widget': 'action_buttons', 'question': 'في التزامات ثانية تبي تضيفها؟',
        'buttons': [{'label': 'نعم، ضيف واحد ثاني', 'value': 'commitment_add_another', 'type': 'secondary'}, {'label': 'لا، خلاص كذا', 'value': 'commitment_add_done', 'type': 'primary'}],
        'commitment_id': id,
      });
    } catch (e) { chatNotifier.setError('فشل حفظ الالتزام: $e'); }
  }

  String _inferCommitmentType(String name) {
    if (RegExp('تمارا|تابي|تابى|سلة').hasMatch(name)) return 'bnpl';
    if (RegExp('إيجار|ايجار').hasMatch(name)) return 'rent';
    if (RegExp('قرض|تمويل').hasMatch(name)) return 'loan';
    if (RegExp('اشتراك|نتفلكس|شاهد').hasMatch(name)) return 'subscription';
    return 'bnpl';
  }

  Future<void> _showCommitmentCompletePrompt(Map<String, dynamic> c, ChatProvider chatNotifier) async {
    chatNotifier.addBotMessage('', widget: {
      'widget': 'action_buttons', 'question': 'هل خلصت التزام "${c['name']}" بالكامل؟',
      'buttons': [{'label': '✅ خلصته بالكامل', 'value': 'commitment_edit_complete', 'type': 'primary'}, {'label': '✏️ عدّل المتبقي', 'value': 'commitment_edit_adjust', 'type': 'secondary'}],
      'commitment_id': c['id'],
    });
  }

  Future<void> _showCommitmentCompletePromptById(String id, ChatProvider chatNotifier) async {
    final commitments = await ref.read(commitmentServiceProvider).listActive();
    final match = commitments.where((c) => c['id'] == id);
    if (match.isEmpty) { chatNotifier.addBotMessage('ما لقيت هذا الالتزام.'); return; }
    await _showCommitmentCompletePrompt(match.first, chatNotifier);
  }

  Future<void> _completeCommitment(String id, ChatProvider chatNotifier) async {
    try {
      final commitmentService = ref.read(commitmentServiceProvider);
      await commitmentService.markCompleted(id);
      chatNotifier.addBotMessage('مبروك! خلصت الالتزام بالكامل 🎉');
    } catch (e) { chatNotifier.setError('فشل تحديث الالتزام: $e'); }
  }

  Future<void> _showCommitmentAdjustForm(String id, ChatProvider chatNotifier) async {
    chatNotifier.addBotMessage('كم المبلغ المتبقي؟', widget: {
      'widget': 'quick_input_form', 'title': 'تعديل المبلغ المتبقي',
      'fields': [{'label': 'المبلغ المتبقي', 'placeholder': 'مثلاً: 500 ريال', 'key': 'remaining', 'type': 'number'}],
      'submit_label': 'حفظ', '_form_kind': 'commitment_edit_amount', 'commitment_id': id,
    });
  }

  Future<void> _submitCommitmentAdjust(Map<String, dynamic> action, Map<String, dynamic> values, ChatProvider chatNotifier) async {
    final remaining = double.tryParse(normalizeArabicNumerals(values['remaining'] as String? ?? ''));
    final id = action['commitment_id'] as String?;
    if (remaining == null || id == null) {
      chatNotifier.addBotMessage('محتاج رقم صحيح للمبلغ المتبقي.');
      return;
    }
    try {
      final commitmentService = ref.read(commitmentServiceProvider);
      if (remaining <= 0) {
        await commitmentService.markCompleted(id);
        chatNotifier.addBotMessage('مبروك! خلصت الالتزام بالكامل 🎉');
      } else {
        await commitmentService.updateRemaining(id, remaining);
        chatNotifier.addBotMessage('تم تحديث المبلغ المتبقي ✅');
      }
    } catch (e) { chatNotifier.setError('فشل التحديث: $e'); }
  }

  // ── Goal flow (DEC-033) ──

  Future<void> _showGoalAddForm(Map<String, dynamic>? draft, String? reply, ChatProvider chatNotifier) async {
    final introText = (reply != null && reply.trim().isNotEmpty) ? reply.trim() : 'سجّلت مسودة هدف — راجع التفاصيل وأكد:';
    chatNotifier.addBotMessage(introText, widget: {
      'widget': 'quick_input_form', 'title': 'إضافة هدف ادخار',
      'fields': [
        {'label': 'اسم الهدف', 'placeholder': 'مثلاً: صندوق الطوارئ', 'key': 'name', 'prefill': draft?['name'] as String? ?? ''},
        {'label': 'المبلغ المستهدف', 'placeholder': 'مثلاً: 5000 ريال', 'key': 'target_amount', 'type': 'number', 'prefill': (draft?['amount_total'])?.toString() ?? ''},
        {'label': 'الادخار الشهري', 'placeholder': 'مثلاً: 500 ريال', 'key': 'monthly_contribution', 'type': 'number', 'prefill': (draft?['amount_monthly'])?.toString() ?? ''},
      ],
      'submit_label': 'حفظ الهدف', '_form_kind': 'goal_add',
    });
  }

  Future<void> _submitGoalAdd(Map<String, dynamic> values, ChatProvider chatNotifier) async {
    final name = (values['name'] as String?)?.trim();
    final target = double.tryParse(normalizeArabicNumerals(values['target_amount'] as String? ?? ''));
    final monthly = double.tryParse(normalizeArabicNumerals(values['monthly_contribution'] as String? ?? ''));
    if (name == null || name.isEmpty || target == null || target <= 0) {
      chatNotifier.addBotMessage('محتاج اسم الهدف والمبلغ المستهدف على الأقل عشان أسجله.');
      return;
    }
    try {
      final goalService = ref.read(goalServiceProvider);
      final saved = await goalService.addGoal(name: name, targetAmount: target, monthlyContribution: monthly ?? 0);
      final id = saved['id'] as String;
      chatNotifier.addBotMessage('تم حفظ هدف "$name" — ${target.toInt()} ريال ✅', widget: {
        'widget': 'action_buttons', 'question': 'في أهداف ثانية تبي تضيفها؟',
        'buttons': [{'label': 'نعم، ضيف هدف ثاني', 'value': 'goal_add_another', 'type': 'secondary'}, {'label': 'لا، خلاص كذا', 'value': 'goal_add_done', 'type': 'primary'}],
        'goal_id': id,
      });
    } catch (e) { chatNotifier.setError('فشل حفظ الهدف: $e'); }
  }

  Future<void> _showGoalAchievedPrompt(Map<String, dynamic> g, ChatProvider chatNotifier) async {
    chatNotifier.addBotMessage('', widget: {
      'widget': 'action_buttons', 'question': 'هل حققت هدف "${g['name']}" بالكامل؟',
      'buttons': [{'label': '✅ حققته', 'value': 'goal_edit_complete', 'type': 'primary'}, {'label': '✏️ عدّل المبلغ', 'value': 'goal_edit_adjust', 'type': 'secondary'}],
      'goal_id': g['id'],
    });
  }

  Future<void> _showGoalCompletePromptById(String id, ChatProvider chatNotifier) async {
    final goals = await ref.read(goalServiceProvider).listActive();
    final match = goals.where((g) => g['id'] == id);
    if (match.isEmpty) { chatNotifier.addBotMessage('ما لقيت هذا الهدف.'); return; }
    await _showGoalAchievedPrompt(match.first, chatNotifier);
  }

  Future<void> _completeGoal(String id, ChatProvider chatNotifier) async {
    try { await ref.read(goalServiceProvider).markAchieved(id); chatNotifier.addBotMessage('مبروك! حققت الهدف 🎉'); }
    catch (e) { chatNotifier.setError('فشل تحديث الهدف: $e'); }
  }

  Future<void> _showGoalAdjustForm(String id, ChatProvider chatNotifier) async {
    chatNotifier.addBotMessage('كم المبلغ الحالي المدخر؟', widget: {
      'widget': 'quick_input_form', 'title': 'تحديث المبلغ المدخر',
      'fields': [{'label': 'المبلغ المدخر الحالي', 'placeholder': 'مثلاً: 500 ريال', 'key': 'current_amount', 'type': 'number'}],
      'submit_label': 'حفظ', '_form_kind': 'goal_edit_amount', 'goal_id': id,
    });
  }

  Future<void> _submitGoalAdjust(Map<String, dynamic> action, Map<String, dynamic> values, ChatProvider chatNotifier) async {
    final amount = double.tryParse(normalizeArabicNumerals(values['current_amount'] as String? ?? ''));
    final id = action['goal_id'] as String?;
    if (amount == null || id == null) {
      chatNotifier.addBotMessage('محتاج رقم صحيح للمبلغ المدخر.');
      return;
    }
    try {
      final goalService = ref.read(goalServiceProvider);
      await goalService.updateCurrentAmount(id, amount);
      final goals = await goalService.listActive();
      final match = goals.where((g) => g['id'] == id);
      final target = match.isEmpty ? null : (match.first['target_amount'] as num?)?.toDouble();
      if (target != null && amount >= target) {
        await goalService.markAchieved(id);
        chatNotifier.addBotMessage('مبروك! حققت الهدف 🎉');
      } else {
        chatNotifier.addBotMessage('تم تحديث المبلغ المدخر ✅');
      }
    } catch (e) { chatNotifier.setError('فشل التحديث: $e'); }
  }

  // ── Widget action handler ──

  Future<void> _handleWidgetAction(Map<String, dynamic> action) async {
    final chatNotifier = ref.read(chatProvider.notifier);
    final actionType = action['action'] as String?;
    final widgetType = action['widget'] as String?;
    print('=== AZDAL DEBUG: Widget action — $actionType on $widgetType');

    switch (widgetType) {
      case 'action_buttons':
        final value = action['value'] as String?;
        final msgId = action['message_id'] as String?;
        if (value == null || msgId == null) break;
        if (value == 'undo_transaction') {
          await _undoTransaction(action, chatNotifier);
        } else if (value == 'commitment_add_another') {
          chatNotifier.markWidgetAnswered(msgId, value);
          await _showCommitmentAddForm(null, null, chatNotifier);
        } else if (value == 'goal_add_another') {
          chatNotifier.markWidgetAnswered(msgId, value);
          await _showGoalAddForm(null, null, chatNotifier);
        } else if (value == 'commitment_add_done' || value == 'goal_add_done') {
          chatNotifier.markWidgetAnswered(msgId, value);
          chatNotifier.addBotMessage('تمام 👍 تقدر تسألني عنها أي وقت.');
        } else if (value == 'commitment_edit_complete') {
          chatNotifier.markWidgetAnswered(msgId, value);
          await _completeCommitment(action['commitment_id'] as String, chatNotifier);
        } else if (value == 'commitment_edit_adjust') {
          chatNotifier.markWidgetAnswered(msgId, value);
          await _showCommitmentAdjustForm(action['commitment_id'] as String, chatNotifier);
        } else if (value.startsWith('commitment_edit_pick_')) {
          chatNotifier.markWidgetAnswered(msgId, value);
          await _showCommitmentCompletePromptById(value.substring('commitment_edit_pick_'.length), chatNotifier);
        } else if (value == 'goal_edit_complete') {
          chatNotifier.markWidgetAnswered(msgId, value);
          await _completeGoal(action['goal_id'] as String, chatNotifier);
        } else if (value == 'goal_edit_adjust') {
          chatNotifier.markWidgetAnswered(msgId, value);
          await _showGoalAdjustForm(action['goal_id'] as String, chatNotifier);
        } else if (value.startsWith('goal_edit_pick_')) {
          chatNotifier.markWidgetAnswered(msgId, value);
          await _showGoalCompletePromptById(value.substring('goal_edit_pick_'.length), chatNotifier);
        } else if (value == 'confirm_purchase') {
          chatNotifier.markWidgetAnswered(msgId, value);
          final item = action['purchase_item'] as String? ?? '';
          final amt = action['purchase_amount'] as int? ?? 0;
          final reply = action['purchase_reply'] as String? ?? '';
          final disposable = (action['purchase_disposable'] as num?)?.toDouble() ?? 0;
          await _confirmPurchase(item, amt, reply, disposable, chatNotifier);
        } else if (value == 'defer_purchase') {
          chatNotifier.markWidgetAnswered(msgId, value);
          chatNotifier.addBotMessage('تمام، أجلناه. خلنا نركز على أولوياتك الحالية 👍');
        }
        break;

      case 'quick_input_form':
        final values = action['values'] as Map<String, dynamic>?;
        final formKind = action['_form_kind'] as String?;
        final msgId = action['message_id'] as String?;
        if (values == null) break;
        if (msgId != null) chatNotifier.markWidgetAnswered(msgId, 'form_submitted');
        switch (formKind) {
          case 'commitment_add': await _submitCommitmentAdd(values, chatNotifier); break;
          case 'goal_add': await _submitGoalAdd(values, chatNotifier); break;
          case 'commitment_edit_amount': await _submitCommitmentAdjust(action, values, chatNotifier); break;
          case 'goal_edit_amount': await _submitGoalAdjust(action, values, chatNotifier); break;
          case 'buy_verdict_clarification':
            final income = double.tryParse(normalizeArabicNumerals(values['income'] as String? ?? ''));
            if (income != null && income > 0) {
              final profileService = ref.read(financialProfileServiceProvider);
              final existing = await profileService.getProfile();
              await profileService.upsert(
                monthlyIncome: income,
                monthlyCommitmentsEstimate:
                    (existing?['monthly_commitments_estimate'] as num?)?.toDouble() ?? 0,
                weeklySpendEstimate:
                    (existing?['weekly_spend_estimate'] as num?)?.toDouble() ?? 0,
              );
              final pendingItem = action['_pending_item'] as String?;
              final pendingAmount = (action['_pending_amount'] as num?)?.toDouble();
              if (pendingItem != null && pendingItem.isNotEmpty && pendingAmount != null) {
                chatNotifier.addBotMessage('تمام، سجلت دخلك — خلني أحسبها لك 🔍');
                await _runPurchaseDecision(pendingItem, pendingAmount, chatNotifier);
              } else {
                chatNotifier.addBotMessage(
                  'تمام، سجلت دخلك — خلنا نرجع نحلل. اكتب "أبي أشتري..." بالشيء والمبلغ.',
                );
              }
            } else {
              chatNotifier.addBotMessage('محتاج رقم صحيح للدخل الشهري.');
            }
            break;
          case 'budget_query_clarification':
            final budgetIncome = double.tryParse(normalizeArabicNumerals(values['income'] as String? ?? ''));
            if (budgetIncome != null && budgetIncome > 0) {
              final profileService = ref.read(financialProfileServiceProvider);
              final existing = await profileService.getProfile();
              await profileService.upsert(
                monthlyIncome: budgetIncome,
                monthlyCommitmentsEstimate:
                    (existing?['monthly_commitments_estimate'] as num?)?.toDouble() ?? 0,
                weeklySpendEstimate:
                    (existing?['weekly_spend_estimate'] as num?)?.toDouble() ?? 0,
              );
              await _showRemainingBudget(chatNotifier);
            } else {
              chatNotifier.addBotMessage('محتاج رقم صحيح للدخل الشهري.');
            }
            break;
          default:
            if (values.containsKey('monthly_income')) await _handleColdStartSubmit(values);
            chatNotifier.addBotMessage('تم استلام المعلومات. شكراً لك! 🙏');
        }
        break;

      case 'compound_split_card':
        final msgId2 = action['message_id'] as String?;
        if (msgId2 == null) break;
        if (actionType == 'compound_split_cancel') { chatNotifier.markWidgetAnswered(msgId2, 'compound_split_cancel'); chatNotifier.addBotMessage('تم الإلغاء.'); break; }
        chatNotifier.markWidgetAnswered(msgId2, 'compound_split_confirm');
        String? receiptUrl;
        if (_capturedReceiptPath != null) {
          receiptUrl = await _uploadReceiptToStorage(_capturedReceiptPath!);
          _capturedReceiptPath = null;
        }
        await _handleCompoundSplit(action, chatNotifier, receiptUrl: receiptUrl);
        break;

      case 'ocr_failure':
        final ocrAction = action['action'] as String?;
        if (ocrAction == 'ocr_failure_submit') { await _handleOcrFailureSubmit(action, chatNotifier); }
        else if (ocrAction == 'ocr_retake') { print('=== AZDAL DEBUG: OCR retake requested'); unawaited(_pickReceiptImage()); }
        break;
    }
  }

  // ── Purchase confirmation (Stage 4) ──

  Future<void> _confirmPurchase(
    String item,
    int amount,
    String reply,
    double disposable,
    ChatProvider chatNotifier,
  ) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Audit log — matches the REAL purchase_decisions schema.
      await client.from('purchase_decisions').insert({
        'user_id': userId,
        'query': '$item بـ $amount ريال',
        'verdict': 'yes',
        'disposable_income': disposable,
        'explanation': reply,
      });

      // Actually track it as a real expense (DEC-024: Dart writes, never LLM) —
      // reuses the same save path as every other transaction, so it correctly
      // feeds future spend totals / Integrity Score / next "Can I Buy?" call.
      final txService = ref.read(transactionServiceProvider);
      final saved = await txService.saveTransaction(
        amount: amount.toDouble(),
        category: item,
        tone: 'gray',
        description: 'شراء عبر تحليل "هل أقدر أشتري؟"',
      );
      final txId = saved['id'] as String;

      // Reuses the existing, already-verified undo_transaction path — no new
      // handler needed. Do NOT introduce a separate 'undo_purchase' value.
      chatNotifier.addBotMessage(
        '',
        widget: {
          'widget': 'action_buttons',
          'question': 'تم تسجيل عملية شراء $item بـ $amount ريال ✅',
          'buttons': [
            {'label': '↩️ تراجع', 'value': 'undo_transaction', 'type': 'secondary'},
          ],
          'tx_id': txId,
          'tx_type': 'simple',
        },
      );
    } catch (e) {
      chatNotifier.setError('فشل تسجيل الشراء: $e');
    }
  }

  // ── Remaining-budget query — deterministic, no LLM (DEC-003) ──

  Future<void> _showRemainingBudget(ChatProvider chatNotifier) async {
    try {
      final purchaseService = ref.read(purchaseDecisionServiceProvider);
      final result = await purchaseService.calculateRemainingBudget();
      if (result['hasProfile'] != true) {
        chatNotifier.addBotMessage('عشان أقدر أحسبها — كم دخلك الشهري التقريبي؟', widget: {
          'widget': 'quick_input_form',
          'title': 'معلومة ناقصة',
          '_form_kind': 'budget_query_clarification',
          'fields': [
            {'label': 'الدخل الشهري التقريبي', 'placeholder': 'مثلاً: 8,000', 'key': 'income', 'type': 'number', 'required': true},
          ],
          'submit_label': 'احسب →',
        });
        return;
      }
      final income = result['income'] as double;
      final commitments = result['commitments'] as double;
      final monthlySpend = result['monthlySpend'] as double;
      final goalMonthly = result['goalMonthly'] as double;
      final remaining = result['remaining'] as double;
      final daysLeft = result['daysLeft'] as int;
      final isPositive = remaining >= 0;

      chatNotifier.addBotMessage(
        isPositive
            ? 'باقي لك ${remaining.round()} ريال هالشهر، وقدامك $daysLeft يوم 📊'
            : 'مصاريفك والتزاماتك تجاوزت دخلك بـ ${(-remaining).round()} ريال هالشهر — خل بالك من أي مصروف إضافي ⚠️',
        widget: {
          'widget': 'summary_card',
          'title': 'ميزانيتك المتبقية',
          'tone': isPositive ? 'success' : 'danger',
          'rows': [
            {'label': 'الدخل الشهري', 'value': '${income.round()} ريال', 'tone': 'neutral'},
            {'label': 'الالتزامات', 'value': '${commitments.round()} ريال', 'tone': 'neutral'},
            {'label': 'مصروفك هالشهر', 'value': '${monthlySpend.round()} ريال', 'tone': 'neutral'},
            if (goalMonthly > 0)
              {'label': 'مساهمة الأهداف', 'value': '${goalMonthly.round()} ريال', 'tone': 'neutral'},
            {'label': 'المتبقي', 'value': '${remaining.round()} ريال', 'tone': isPositive ? 'success' : 'danger'},
          ],
        },
      );
    } catch (e) {
      chatNotifier.setError('فشل حساب الميزانية المتبقية: $e');
    }
  }

  // ── Undo (DEC-020) ──

  Future<void> _undoTransaction(Map<String, dynamic> action, ChatProvider chatNotifier) async {
    if (_isUndoing) return;
    _isUndoing = true;
    try {
      final txId = action['tx_id'] as String?;
      final txType = action['tx_type'] as String?;
      if (txId == null) return;
      final txService = ref.read(transactionServiceProvider);
      if (txType == 'group') { await txService.softDeleteTransactionGroup(txId); }
      else { await txService.softDeleteTransaction(txId); }
      final messages = ref.read(chatProvider).messages;
      for (final msg in messages.reversed) { if (msg.hasWidget && msg.widget!['tx_id'] == txId) { chatNotifier.removeMessage(msg.id); break; } }
      chatNotifier.addBotMessage('تم التراجع ✅');
    } catch (e) { chatNotifier.setError('فشل التراجع: $e'); }
    finally { _isUndoing = false; }
  }

  // ── Compound split (unchanged from DEC-020) ──

  Future<void> _handleCompoundSplit(Map<String, dynamic> action, ChatProvider chatNotifier, {String? receiptUrl}) async {
    final splits = action['splits'] as List<dynamic>?;
    if (splits == null || splits.isEmpty) return;
    try {
      final txService = ref.read(transactionServiceProvider);
      final splitData = splits.map((s) { final split = s as Map<String, dynamic>; return {'amount': (split['amount'] as num).toDouble(), 'category': split['category'] as String? ?? 'متنوع', 'type': 'expense', 'tone': 'gray'}; }).toList();
      final results = await txService.saveCompoundSplits(splits: splitData, receiptUrl: receiptUrl);
      final groupId = results.first['id'] as String;
      chatNotifier.addBotMessage('', widget: {'widget': 'action_buttons', 'question': 'تم تسجيل ${splits.length} معاملات بنجاح ✅', 'buttons': [{'label': '↩️ تراجع', 'value': 'undo_transaction', 'type': 'secondary'}], 'tx_id': groupId, 'tx_type': 'group'});
    } catch (e) { chatNotifier.setError(e.toString()); }
  }

  // ── OCR failure manual entry ──

  Future<void> _handleOcrFailureSubmit(Map<String, dynamic> action, ChatProvider chatNotifier) async {
    final amountStr = action['amount'] as String?;
    final category = action['category'] as String? ?? 'متنوع';
    if (amountStr == null || amountStr.isEmpty) return;
    final amount = double.tryParse(normalizeArabicNumerals(amountStr)) ?? 0;
    if (amount <= 0) return;
    try {
      final txService = ref.read(transactionServiceProvider);
      String? receiptUrl;
      if (_capturedReceiptPath != null) { receiptUrl = await _uploadReceiptToStorage(_capturedReceiptPath!); _capturedReceiptPath = null; }
      final saved = await txService.saveTransaction(amount: amount, category: category, description: 'إدخال يدوي (فشل OCR)', receiptUrl: receiptUrl);
      final txId = saved['id'] as String;
      chatNotifier.addBotMessage('', widget: {'widget': 'action_buttons', 'question': 'تم تسجيل $amount ريال — $category ✅', 'buttons': [{'label': '↩️ تراجع', 'value': 'undo_transaction', 'type': 'secondary'}], 'tx_id': txId, 'tx_type': 'simple'});
    } catch (e) { chatNotifier.setError('فشل حفظ المعاملة: $e'); }
  }

  // ── OCR camera/gallery ──

  String? _capturedReceiptPath;

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(context: context, builder: (ctx) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.camera_alt, color: _navy), title: const Text('تصوير الإيصال', style: TextStyle(fontFamily: 'Cairo')), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
      ListTile(leading: const Icon(Icons.photo_library, color: _navy), title: const Text('اختيار من المعرض', style: TextStyle(fontFamily: 'Cairo')), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
    ])));
    if (source == null) return;
    try {
      final xFile = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1920);
      if (xFile != null && mounted) { print('=== AZDAL DEBUG: Receipt image picked — path=${xFile.path}'); await _processReceiptImage(xFile.path); }
    } catch (e) { print('=== AZDAL DEBUG: Image pick FAILED — $e'); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر التقاط الصورة. تأكد من الصلاحيات.'))); } }
  }

  Future<void> _processReceiptImage(String imagePath) async {
    final chatNotifier = ref.read(chatProvider.notifier);
    chatNotifier.addUserMessage('📷 إيصال', imagePath: imagePath);
    final processingId = chatNotifier.addBotMessage('', widget: const {'widget': 'ocr_processing'});
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) { chatNotifier.setError('الصورة غير موجودة.'); return; }
      final imageBytes = await imageFile.readAsBytes();
      final geminiService = ref.read(geminiServiceProvider);
      final ocrResult = await geminiService.ocrReceipt(imageBytes).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (ocrResult.containsKey('error')) { _showOcrFailure(chatNotifier, ocrResult, processingId); return; }
      final items = ocrResult['items'] as List<dynamic>? ?? [];
      final total = ocrResult['total'];
      final reply = ocrResult['reply'] as String?;
      if (items.isEmpty) { _showOcrFailure(chatNotifier, ocrResult, processingId); return; }
      _showOcrResult(chatNotifier, items, total, reply, imagePath, processingId);
    } on TimeoutException {
      if (!mounted) return; print('=== AZDAL DEBUG: OCR timed out after 10s'); _showOcrFailure(chatNotifier, {'error': 'timeout'}, processingId);
    } catch (e) {
      if (!mounted) return; print('=== AZDAL DEBUG: OCR process FAILED — $e'); _showOcrFailure(chatNotifier, {'error': 'unexpected'}, processingId);
    }
  }

  void _showOcrFailure(ChatProvider chatNotifier, Map<String, dynamic> ocrResult, String processingId) {
    chatNotifier.removeMessage(processingId); chatNotifier.addBotMessage('', widget: const {'widget': 'ocr_failure'});
  }

  void _showOcrResult(ChatProvider chatNotifier, List<dynamic> items, dynamic total, String? reply, String imagePath, String processingId) {
    chatNotifier.removeMessage(processingId);
    final splits = items.map<Map<String, dynamic>>((item) { final map = item as Map<String, dynamic>; return {'category': map['name'] as String? ?? '', 'amount': (map['price'] as num?)?.toInt() ?? 0}; }).toList();
    final totalAmount = (total is num) ? total.toInt() : 0;
    _capturedReceiptPath = imagePath;
    final bubbleText = (reply != null && reply.trim().isNotEmpty) ? reply.trim() : 'تم استخراج ${items.length} بنود من الإيصال:';
    chatNotifier.addBotMessage(bubbleText, widget: {'widget': 'compound_split_card', 'splits': splits, 'total': totalAmount});
  }

  Future<String?> _uploadReceiptToStorage(String localPath) async {
    try {
      final client = Supabase.instance.client; final uid = client.auth.currentUser?.id;
      if (uid == null) { print('=== AZDAL DEBUG: Receipt upload SKIPPED — no user'); return null; }
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final fileName = '${timestamp}_receipt.jpg'; final storagePath = '$uid/$fileName';
      final file = File(localPath); if (!await file.exists()) return null;
      await client.storage.from('receipts').upload(storagePath, file, fileOptions: const FileOptions(contentType: 'image/jpeg'));
      print('=== AZDAL DEBUG: Receipt uploaded — path=$storagePath'); return storagePath;
    } catch (e) { print('=== AZDAL DEBUG: Receipt upload FAILED — $e'); return null; }
  }

  void _checkPendingSharedImage() { final pendingPath = _getPendingSharedImage(); if (pendingPath != null && mounted) { print('=== AZDAL DEBUG: Processing pending shared image — path=$pendingPath'); _processReceiptImage(pendingPath); } }
  static String? _getPendingSharedImage() => consumePendingSharedImage();

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final voiceListeningState = ref.watch(voiceListeningProvider);
    // Chat predates app-level Arabic localization and was built RTL via
    // explicit per-widget textDirection (input bar, TextField, bubble
    // text) under an ambient direction that was actually LTR the whole
    // time (MaterialApp's Localizations always re-derives Directionality
    // below any outer wrapper). Now that the app locale is properly ar
    // (RTL), pin this screen's ambient direction back to the LTR it was
    // always actually rendered under, so this stabilized screen cannot
    // move a single pixel. Remove only in a dedicated chat-RTL pass.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(title: const Text('أزدل'), backgroundColor: _navy, foregroundColor: _white, centerTitle: true),
        body: Column(children: [
          Expanded(child: chatState.messages.isEmpty && !_coldStartDone ? const _EmptyState() : ListView.builder(
            controller: _scrollController, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0) + (chatState.error != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (chatState.error != null && index == chatState.messages.length) return ErrorBubble(message: 'حدث خطأ. حاول مرة أخرى.', onRetry: () => ref.read(chatProvider.notifier).clearError());
              final typingOffset = chatState.error != null ? 1 : 0;
              if (chatState.isLoading && index == chatState.messages.length - typingOffset) return const TypingIndicator();
              final adjustedIndex = chatState.isLoading && index >= chatState.messages.length ? chatState.messages.length - 1 : index.clamp(0, chatState.messages.length - 1);
              if (adjustedIndex >= chatState.messages.length) return const SizedBox.shrink();
              final message = chatState.messages[adjustedIndex];
              return _MessageBubble(message: message, onWidgetAction: _handleWidgetAction);
            },
          )),
          if (!_isOnline) const OfflineBanner(),
          _InputBar(controller: _textController, focusNode: _focusNode, isOnline: _isOnline, isListening: voiceListeningState.isListening, onSend: _sendMessage, onMic: _toggleVoice, onCamera: _pickReceiptImage),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.shield_outlined, size: 64, color: _navy.withAlpha(100)), const SizedBox(height: 16),
      const Text('أهلاً بك في أزدل', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _navy)),
      const SizedBox(height: 8),
      const Text('مساعدك المالي الذكي. بدون تعب. بدون إدخال بيانات.', style: TextStyle(fontSize: 14, color: _muted, fontFamily: 'Cairo'), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Text('اكتب أول مصروف... أو استخدم الصوت 🎤', style: TextStyle(fontSize: 14, color: _navy.withAlpha(150), fontFamily: 'Cairo')),
    ])));
  }
}

// ─────────────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onWidgetAction});
  final ChatMessage message;
  final void Function(Map<String, dynamic>)? onWidgetAction;
  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start,
      children: [Flexible(child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: EdgeInsets.only(left: isUser ? 16 : 40, right: isUser ? 40 : 16),
        child: Column(crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
          if (message.isUser && message.hasImage) Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _userBubbleBg),
            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(message.imagePath!), fit: BoxFit.cover, width: double.infinity, height: 180, errorBuilder: (context, error, stackTrace) => Container(height: 120, color: _userBubbleBg, child: const Center(child: Icon(Icons.broken_image, color: _muted, size: 32))))),
          ),
          if (message.content.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: isUser ? _userBubbleBg : _navy, borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: isUser ? const Radius.circular(4) : const Radius.circular(16), bottomLeft: const Radius.circular(16), bottomRight: isUser ? const Radius.circular(16) : const Radius.circular(4))),
            child: Text(message.content, style: TextStyle(color: isUser ? _navy : _white, fontSize: 14, fontFamily: 'Cairo'), textDirection: TextDirection.rtl),
          ),
          if (message.hasWidget) renderCatalogWidget(message.widget!, onAction: onWidgetAction != null ? (action) => onWidgetAction!({...action, 'message_id': message.id}) : null),
          Padding(padding: const EdgeInsets.only(top: 2), child: Text(_formatTime(message.timestamp), style: const TextStyle(color: _muted, fontSize: 10, fontFamily: 'Cairo'))),
        ]),
      ))]),
    );
  }
  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────
// Input Bar
// ─────────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  const _InputBar({required this.controller, required this.focusNode, required this.isOnline, required this.isListening, required this.onSend, required this.onMic, required this.onCamera});
  final TextEditingController controller; final FocusNode focusNode; final bool isOnline; final bool isListening; final VoidCallback onSend; final VoidCallback onMic; final VoidCallback onCamera;
  @override State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;
  @override void initState() { super.initState(); _hasText = widget.controller.text.trim().isNotEmpty; widget.controller.addListener(_onTextChanged); }
  @override void dispose() { widget.controller.removeListener(_onTextChanged); super.dispose(); }
  void _onTextChanged() { final hasText = widget.controller.text.trim().isNotEmpty; if (hasText != _hasText) setState(() => _hasText = hasText); }
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: const BoxDecoration(color: Color(0xFFF1F3F5), border: Border(top: BorderSide(color: Color(0xFFE1E4E8)))),
      child: SafeArea(child: Row(textDirection: TextDirection.rtl, children: [
        _SendButton(isOnline: widget.isOnline, hasText: _hasText, onSend: widget.onSend), const SizedBox(width: 8),
        Expanded(child: TextField(controller: widget.controller, focusNode: widget.focusNode, textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14, fontFamily: 'Cairo', color: Color(0xFF1B1B1F)),
          decoration: InputDecoration(hintText: 'اكتب مصروف... أو اسأل سؤال', hintStyle: const TextStyle(color: _muted, fontFamily: 'Cairo'), filled: true, fillColor: _white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _cyan, width: 1.5))),
          maxLines: 3, minLines: 1, textInputAction: TextInputAction.send, onSubmitted: (_) => widget.onSend(),
        )), const SizedBox(width: 8),
        _IconButton(icon: Icons.mic, isActive: widget.isListening, activeColor: _cyan, onTap: widget.onMic), const SizedBox(width: 4),
        _IconButton(icon: Icons.camera_alt_outlined, isActive: false, activeColor: _cyan, onTap: widget.onCamera),
      ])),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isOnline, required this.hasText, required this.onSend});
  final bool isOnline; final bool hasText; final VoidCallback onSend;
  @override Widget build(BuildContext context) => GestureDetector(onTap: (isOnline && hasText) ? onSend : null, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: (isOnline && hasText) ? _cyan : _muted), child: const Icon(Icons.arrow_upward, color: _white, size: 20)));
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.isActive, required this.activeColor, required this.onTap});
  final IconData icon; final bool isActive; final Color activeColor; final VoidCallback onTap;
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? activeColor.withAlpha(30) : Colors.transparent, border: Border.all(color: isActive ? activeColor : _muted, width: isActive ? 2 : 1)), child: Icon(icon, color: isActive ? activeColor : _muted, size: 20)));
}
