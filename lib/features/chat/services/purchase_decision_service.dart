/// Purchase-decision engine for Azdal.
///
/// Pure Dart per DEC-024 — all financial math is Dart-computed, no
/// Edge Functions, no LLM arithmetic.  Evaluates whether a user can
/// afford a purchase given income, commitments, current-month spending,
/// and active goals.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

final class PurchaseDecisionService {
  PurchaseDecisionService(this._client);
  final SupabaseClient _client;

  /// Evaluate whether [item] can be purchased for [amount] SAR.
  ///
  /// Returns a map with:
  /// - `verdict`: 'yes' | 'wait' | 'no' | 'need_info'
  /// - `disposable`: double — remaining disposable after purchase
  /// - `dti`: double — debt-to-income ratio
  /// - `goalImpact`: String? — active goal impact description
  /// - `reply`: String — verdict explanation
  Future<Map<String, dynamic>> evaluate(String item, double amount) async {
    final userId = _client.auth.currentUser!.id;

    // 1. Fetch financial profile
    final profileRows = await _client
        .from('financial_profile')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .limit(1);

    final income = (profileRows as List).isEmpty
        ? 0.0
        : ((profileRows.first as Map)['monthly_income'] as num?)
            ?.toDouble() ??
            0;

    if (income <= 0) {
      return {
        'verdict': 'need_info',
        'reply': 'عشان أقدر أساعدك — كم دخلك الشهري التقريبي؟',
        'disposable': 0.0,
        'dti': 0.0,
        'goalImpact': null,
      };
    }

    // Cold Start's rough estimate (DEC-033) — the user is walked through
    // itemizing it into real commitments one at a time, but until that's
    // fully done the un-itemized remainder is still real committed money.
    final commitmentsEstimate = profileRows.isEmpty
        ? 0.0
        : ((profileRows.first as Map)['monthly_commitments_estimate'] as num?)
                ?.toDouble() ??
            0;

    // 2. Fetch active commitments (DEC-026: DTI check)
    final commitmentsRows = await _client
        .from('commitments')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .eq('status', 'active');

    final itemizedCommitments = (commitmentsRows as List).fold<double>(
      0,
      (sum, c) =>
          sum + ((c['monthly_amount'] as num?)?.toDouble() ?? 0),
    );
    // Never let itemizing a partial commitment (e.g. rent alone) LOWER the
    // known total below the Cold Start estimate — take whichever is higher.
    final totalCommitments =
        itemizedCommitments > commitmentsEstimate
            ? itemizedCommitments
            : commitmentsEstimate;

    // 3. DTI check (DEC-026: 33% cap)
    final dti = income > 0 ? totalCommitments / income : 0;
    if (dti > 0.33) {
      final dtiPercent = (dti * 100).round();
      return {
        'verdict': 'no',
        'dti': dti,
        'disposable': 0.0,
        'goalImpact': null,
        'reply':
            'نسبة التزاماتك ${dtiPercent}% من دخلك — أعلى من الحد الآمن (33%). '
            'خفّف الالتزامات أول.',
      };
    }

    // 4. Current-month spending (expenses only — DEC-026 filter)
    final now = DateTime.now();
    final monthStart =
        DateTime(now.year, now.month, 1).toIso8601String();
    final spendRows = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .eq('is_deleted', false)
        .gte('created_at', monthStart);

    final monthlySpend = (spendRows as List).fold<double>(
      0,
      (sum, r) => sum + ((r['amount'] as num?)?.toDouble() ?? 0),
    );

    // 5. Active goals impact
    final goalsRows = await _client
        .from('goals')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .eq('status', 'active');

    final totalGoalMonthly = (goalsRows as List).fold<double>(
      0,
      (sum, g) =>
          sum + ((g['monthly_contribution'] as num?)?.toDouble() ?? 0),
    );

    // 6. Disposable calculation
    final disposable =
        income - totalCommitments - monthlySpend - totalGoalMonthly - amount;

    if (disposable >= 0) {
      return {
        'verdict': 'yes',
        'disposable': disposable,
        'dti': dti,
        'goalImpact': null,
        'reply': 'تقدر! باقي لك ${disposable.round()} ريال.',
      };
    } else if (totalGoalMonthly > 0) {
      return {
        'verdict': 'wait',
        'disposable': disposable,
        'dti': dti,
        'goalImpact': 'عندك أهداف ادخار نشطة — الشراء الآن يأخر تحقيقها.',
        'reply': 'عندك أهداف ادخار نشطة. '
            'إذا اشتريت الآن — راح يتأخر هدفك.',
      };
    } else {
      return {
        'verdict': 'no',
        'disposable': disposable,
        'dti': dti,
        'goalImpact': null,
        'reply':
            'ما يكفي. المصروف الحالي (${monthlySpend.round()}) '
            '+ الالتزامات (${totalCommitments.round()}) أعلى من المتبقي.',
      };
    }
  }

  /// Calculate how much disposable budget is left for the current month.
  ///
  /// Same deterministic factors as [evaluate] (income, active commitments,
  /// current-month expense total, active goal contributions) but with no
  /// specific purchase amount — this answers "كم باقي من ميزانيتي؟" rather
  /// than "can I afford X". Returns `{'hasProfile': false}` if no income is
  /// on file yet (caller should ask for it, same as [evaluate]'s need_info).
  Future<Map<String, dynamic>> calculateRemainingBudget() async {
    final userId = _client.auth.currentUser!.id;

    final profileRows = await _client
        .from('financial_profile')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .limit(1);

    final income = (profileRows as List).isEmpty
        ? 0.0
        : ((profileRows.first as Map)['monthly_income'] as num?)
            ?.toDouble() ??
            0;

    if (income <= 0) {
      return {'hasProfile': false};
    }

    // Cold Start's rough estimate (DEC-033) — see [evaluate] for why the
    // un-itemized remainder still counts.
    final commitmentsEstimate = profileRows.isEmpty
        ? 0.0
        : ((profileRows.first as Map)['monthly_commitments_estimate'] as num?)
                ?.toDouble() ??
            0;

    final commitmentsRows = await _client
        .from('commitments')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .eq('status', 'active');

    final itemizedCommitments = (commitmentsRows as List).fold<double>(
      0,
      (sum, c) => sum + ((c['monthly_amount'] as num?)?.toDouble() ?? 0),
    );
    final totalCommitments =
        itemizedCommitments > commitmentsEstimate
            ? itemizedCommitments
            : commitmentsEstimate;

    final now = DateTime.now();
    final monthStart =
        DateTime(now.year, now.month, 1).toIso8601String();
    final spendRows = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .eq('is_deleted', false)
        .gte('created_at', monthStart);

    final monthlySpend = (spendRows as List).fold<double>(
      0,
      (sum, r) => sum + ((r['amount'] as num?)?.toDouble() ?? 0),
    );

    final goalsRows = await _client
        .from('goals')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .eq('status', 'active');

    final totalGoalMonthly = (goalsRows as List).fold<double>(
      0,
      (sum, g) =>
          sum + ((g['monthly_contribution'] as num?)?.toDouble() ?? 0),
    );

    final remaining = income - totalCommitments - monthlySpend - totalGoalMonthly;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day + 1;

    return {
      'hasProfile': true,
      'income': income,
      'commitments': totalCommitments,
      'monthlySpend': monthlySpend,
      'goalMonthly': totalGoalMonthly,
      'remaining': remaining,
      'daysLeft': daysLeft,
    };
  }
}
