/// Widget catalog renderers for Azdal.
///
/// Renders the 6 JSON-defined widget types inline inside bot message bubbles.
/// AI sends a JSON map with a "widget" type key → Flutter renders from this catalog.
/// NO eval(). NO code injection. Only pre-defined widgets.
library;

import 'package:flutter/material.dart';

import 'ocr_widgets.dart';

// ─────────────────────────────────────────────────────────────────────
// Design token constants
// ─────────────────────────────────────────────────────────────────────

const _navy = Color(0xFF001F5E);
const _cyan = Color(0xFF32C2FF);
const _success = Color(0xFF2E7D32);
const _warning = Color(0xFFB7791F);
const _danger = Color(0xFFD32F2F);
const _cardBg = Color(0xFF161B22);
const _cardBorder = Color(0xFF30363D);
const _muted = Color(0xFF6B7280);
const _white = Colors.white;
const _answeredOpacity = 0.85;

// ─────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────

/// Renders a widget from the catalog based on [widgetJson].
///
/// [widgetJson] must have a `"widget"` key with one of:
///   summary_card, bar_chart, action_buttons, quick_input_form,
///   goal_progress_card, compound_split_card.
///
/// [onAction] is called when the user taps an action button or submits a form.
/// It receives a Map<String, dynamic> with the action payload.
Widget renderCatalogWidget(
  Map<String, dynamic> widgetJson, {
  void Function(Map<String, dynamic>)? onAction,
}) {
  final type = widgetJson['widget'] as String?;
  if (type == null) return const SizedBox.shrink();

  return switch (type) {
    'summary_card' => _SummaryCardWidget(json: widgetJson),
    'bar_chart' => _BarChartWidget(json: widgetJson),
    'action_buttons' => _ActionButtonsWidget(
        json: widgetJson,
        onAction: onAction,
      ),
    'quick_input_form' => _QuickInputFormWidget(
        json: widgetJson,
        onAction: onAction,
      ),
    'goal_progress_card' => _GoalProgressCardWidget(json: widgetJson),
    'compound_split_card' => _CompoundSplitCardWidget(
        json: widgetJson,
        onAction: onAction,
      ),
    'ocr_processing' => const OcrProcessingOverlay(),
    'ocr_failure' => _OcrFailureWidgetAdapter(
        json: widgetJson,
        onAction: onAction,
      ),
    'ocr_partial' => _OcrPartialExtractionAdapter(
        json: widgetJson,
        onAction: onAction,
      ),
    _ => const SizedBox.shrink(),
  };
}

// ─────────────────────────────────────────────────────────────────────
// 1. summary_card
// ─────────────────────────────────────────────────────────────────────

class _SummaryCardWidget extends StatelessWidget {
  const _SummaryCardWidget({required this.json});
  final Map<String, dynamic> json;

  Color _toneColor(String? tone) => switch (tone) {
        'success' => _success,
        'warning' => _warning,
        'danger' => _danger,
        _ => _muted,
      };

  @override
  Widget build(BuildContext context) {
    final title = json['title'] as String? ?? '';
    final rows = (json['rows'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: const TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ...rows.map((row) {
            final tone = row['tone'] as String?;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: _toneColor(tone), width: 3),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      row['label'] as String? ?? '',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      row['value'] as String? ?? '',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: _toneColor(tone),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// 2. bar_chart
// ─────────────────────────────────────────────────────────────────────

class _BarChartWidget extends StatelessWidget {
  const _BarChartWidget({required this.json});
  final Map<String, dynamic> json;

  @override
  Widget build(BuildContext context) {
    final title = json['title'] as String? ?? '';
    final bars = (json['bars'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: const TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ...bars.map((bar) {
            final label = bar['label'] as String? ?? '';
            final value = (bar['value'] as num?)?.toDouble() ?? 0;
            final max = (bar['max'] as num?)?.toDouble() ?? 1;
            final ratio = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        '${value.toInt()} ريال',
                        style: const TextStyle(
                          color: _white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    builder: (context, val, _) {
                      return Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _cardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: val,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _cyan,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// 3. action_buttons
// ─────────────────────────────────────────────────────────────────────

class _ActionButtonsWidget extends StatelessWidget {
  const _ActionButtonsWidget({required this.json, this.onAction});
  final Map<String, dynamic> json;
  final void Function(Map<String, dynamic>)? onAction;

  @override
  Widget build(BuildContext context) {
    final question = json['question'] as String? ?? '';
    final buttons = (json['buttons'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final answered = json['_answered'] == true;
    final selectedValue = json['_selectedValue'] as String?;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Opacity(
        opacity: answered ? _answeredOpacity : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (question.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  question,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 14,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: buttons.map((btn) {
                final type = btn['type'] as String? ?? 'primary';
                final isPrimary = type == 'primary';
                final value = btn['value'] as String?;
                final isSelected = answered && value == selectedValue;
                return SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? _cyan
                          : (isPrimary ? _cyan : Colors.transparent),
                      foregroundColor: isSelected
                          ? _navy
                          : (isPrimary ? _navy : _cyan),
                      disabledBackgroundColor: isSelected
                          ? _cyan
                          : (isPrimary ? _cyan : Colors.transparent),
                      disabledForegroundColor: isSelected
                          ? _navy
                          : (isPrimary ? _navy : _cyan),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: isPrimary && !isSelected
                            ? BorderSide.none
                            : const BorderSide(color: _cyan),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: answered
                        ? null
                        : () => onAction?.call({
                            ...json,
                            'action': 'button_tap',
                            'widget': 'action_buttons',
                            'value': value,
                            'label': btn['label'],
                          }),
                    child: Text(
                      btn['label'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// 4. quick_input_form
// ─────────────────────────────────────────────────────────────────────

class _QuickInputFormWidget extends StatefulWidget {
  const _QuickInputFormWidget({required this.json, this.onAction});
  final Map<String, dynamic> json;
  final void Function(Map<String, dynamic>)? onAction;

  @override
  State<_QuickInputFormWidget> createState() => _QuickInputFormWidgetState();
}

class _QuickInputFormWidgetState extends State<_QuickInputFormWidget> {
  final _values = <String, String>{};
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _controllerFor(String key, String initial) {
    return _controllers.putIfAbsent(key, () {
      _values[key] = initial;
      return TextEditingController(text: initial);
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.json['title'] as String? ?? '';
    final fields = (widget.json['fields'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final submitLabel = widget.json['submit_label'] as String? ?? 'إرسال';
    final answered = widget.json['_answered'] == true;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Opacity(
        opacity: answered ? _answeredOpacity : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                title,
                style: const TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ...fields.map((field) {
            final key = field['key'] as String? ?? '';
            final label = field['label'] as String? ?? '';
            final placeholder = field['placeholder'] as String? ?? '';
            final prefill = field['prefill'] as String? ?? '';
            final isNumeric = field['type'] == 'number';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  TextField(
                    enabled: !answered,
                    controller: _controllerFor(key, prefill),
                    keyboardType:
                        isNumeric ? TextInputType.number : TextInputType.text,
                    onChanged: (v) => _values[key] = v,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 14,
                      fontFamily: 'Cairo',
                    ),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: const TextStyle(
                        color: _muted,
                        fontFamily: 'Cairo',
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0D1117),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _cyan),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: _navy,
                disabledBackgroundColor: _cyan,
                disabledForegroundColor: _navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: answered
                  ? null
                  : () => widget.onAction?.call({
                      ...widget.json,
                      'action': 'form_submit',
                      'widget': 'quick_input_form',
                      'values': Map<String, String>.from(_values),
                    }),
              child: Text(
                submitLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ],
      ),
      ), // Opacity
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// 5. goal_progress_card
// ─────────────────────────────────────────────────────────────────────

class _GoalProgressCardWidget extends StatelessWidget {
  const _GoalProgressCardWidget({required this.json});
  final Map<String, dynamic> json;

  @override
  Widget build(BuildContext context) {
    final goalName = json['goal_name'] as String? ?? '';
    final current = (json['current'] as num?)?.toDouble() ?? 0;
    final target = (json['target'] as num?)?.toDouble() ?? 1;
    final monthlySaving = (json['monthly_saving'] as num?)?.toDouble() ?? 0;
    final monthsRemaining = (json['months_remaining'] as num?)?.toInt() ?? 0;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goalName,
            style: const TextStyle(
              color: _white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            builder: (context, val, _) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${current.toInt()} / ${target.toInt()} ريال',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: _success,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: val,
                      minHeight: 8,
                      backgroundColor: _cardBorder,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_success),
                    ),
                  ),
                ],
              );
            },
          ),
          if (monthlySaving > 0 || monthsRemaining > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (monthlySaving > 0)
                  Text(
                    'ادخار شهري: ${monthlySaving.toInt()} ريال',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                  ),
                if (monthsRemaining > 0)
                  Text(
                    'متبقي: $monthsRemaining شهر',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// 6. compound_split_card
// ─────────────────────────────────────────────────────────────────────

class _CompoundSplitCardWidget extends StatefulWidget {
  const _CompoundSplitCardWidget({required this.json, this.onAction});
  final Map<String, dynamic> json;
  final void Function(Map<String, dynamic>)? onAction;

  @override
  State<_CompoundSplitCardWidget> createState() =>
      _CompoundSplitCardWidgetState();
}

class _CompoundSplitCardWidgetState extends State<_CompoundSplitCardWidget> {
  late List<Map<String, dynamic>> _splits;

  @override
  void initState() {
    super.initState();
    _splits = ((widget.json['splits'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        []);
  }

  void _adjust(int index, int delta) {
    setState(() {
      final current = (_splits[index]['amount'] as num).toInt();
      final max = (_splits[index]['max'] as num?)?.toInt() ?? 999999;
      final newVal = (current + delta).clamp(0, max);
      _splits[index]['amount'] = newVal;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Compute total locally from _splits — never trust LLM math (DEC-003).
    // This recalculates on every build, so it stays correct when the user
    // adjusts amounts via the +/- buttons.
    final total = _splits.fold<int>(
      0,
      (sum, s) => sum + ((s['amount'] as num?)?.toInt() ?? 0),
    );

    final answered = widget.json['_answered'] == true;
    final selectedValue = widget.json['_selectedValue'] as String?;
    final isConfirmed = answered && selectedValue == 'compound_split_confirm';

    return Opacity(
      opacity: answered ? _answeredOpacity : 1.0,
      child: Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تقسيم المصروف',
                style: TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'الإجمالي: $total ريال',
                style: const TextStyle(
                  color: _cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._splits.asMap().entries.map((entry) {
            final idx = entry.key;
            final split = entry.value;
            final category = split['category'] as String? ?? '';
            final amount = (split['amount'] as num).toInt();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  _AdjustButton(
                    icon: Icons.remove,
                    onTap: () => _adjust(idx, -5),
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text(
                      '$amount',
                      style: const TextStyle(
                        color: _cyan,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  _AdjustButton(
                    icon: Icons.add,
                    onTap: () => _adjust(idx, 5),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              // Cancel button
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _muted,
                      side: const BorderSide(color: _cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: answered
                        ? null
                        : () => widget.onAction?.call({
                            'action': 'compound_split_cancel',
                            'widget': 'compound_split_card',
                          }),
                    child: const Text(
                      '❌ إلغاء',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Confirm button
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConfirmed ? _success : _cyan,
                      foregroundColor: _navy,
                      disabledBackgroundColor: isConfirmed ? _success : _cyan,
                      disabledForegroundColor: _navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: answered
                        ? null
                        : () => widget.onAction?.call({
                            'action': 'compound_split_confirm',
                            'widget': 'compound_split_card',
                            'total': total,
                            'splits': _splits,
                          }),
                    child: const Text(
                      '✅ تأكيد',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ), // Opacity
    );
  }
}

class _AdjustButton extends StatelessWidget {
  const _AdjustButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _cyan.withAlpha(80)),
        ),
        child: Icon(icon, color: _cyan, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// OCR Widget Adapters (bridge ocr_widgets.dart → widget catalog)
// ─────────────────────────────────────────────────────────────────────

/// Adapter for OcrPartialExtractionWidget — extracts data from JSON
/// and routes button taps through the catalog's [onAction] callback.
class _OcrPartialExtractionAdapter extends StatelessWidget {
  const _OcrPartialExtractionAdapter({
    required this.json,
    this.onAction,
  });
  final Map<String, dynamic> json;
  final void Function(Map<String, dynamic>)? onAction;

  @override
  Widget build(BuildContext context) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final uncertainCount = (json['uncertain_count'] as num?)?.toInt() ?? 0;
    final total = (json['total'] as num?)?.toInt() ?? 0;

    return OcrPartialExtractionWidget(
      confirmedItems: items,
      uncertainCount: uncertainCount,
      confirmedTotal: total,
      onConfirmAll: () => onAction?.call({
        'action': 'ocr_partial_confirm',
        'widget': 'ocr_partial',
        'items': items,
        'total': total,
      }),
    );
  }
}

/// Adapter for OcrFailureWidget — extracts form action through catalog.
class _OcrFailureWidgetAdapter extends StatelessWidget {
  const _OcrFailureWidgetAdapter({
    required this.json,
    this.onAction,
  });
  final Map<String, dynamic> json;
  final void Function(Map<String, dynamic>)? onAction;

  @override
  Widget build(BuildContext context) {
    return OcrFailureWidget(
      onSubmit: (values) => onAction?.call({
        'action': 'ocr_failure_submit',
        'widget': 'ocr_failure',
        'amount': values['amount'],
        'category': values['category'],
      }),
      onRetake: () => onAction?.call({
        'action': 'ocr_retake',
        'widget': 'ocr_failure',
      }),
    );
  }
}
