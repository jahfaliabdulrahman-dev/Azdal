/// OCR receipt scanning widgets for Azdal (Stage 3).
///
/// Implements the 3 OCR states defined in 03_user_flows_navigation.md:
///   1. Uploading/Processing overlay
///   2. Low-confidence partial extraction with editable fields
///   3. "Couldn't Read" failure fallback with manual entry
library;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────
// Design token constants (match chat design tokens)
// ─────────────────────────────────────────────────────────────────────

const _navy = Color(0xFF001F5E);
const _cyan = Color(0xFF32C2FF);
const _danger = Color(0xFFD32F2F);
const _warning = Color(0xFFB7791F);
const _success = Color(0xFF2E7D32);
const _cardBg = Color(0xFF161B22);
const _cardBorder = Color(0xFF30363D);
const _muted = Color(0xFF6B7280);
const _white = Colors.white;

// ─────────────────────────────────────────────────────────────────────
// OCR State 1 — Uploading/Processing Overlay
// ─────────────────────────────────────────────────────────────────────

/// Overlay shown on the user's receipt image while OCR is processing.
///
/// Per spec:
/// - Navy overlay at 70% opacity covering bottom 30% of image
/// - 3 animated cyan dots (pulse 800ms stagger)
/// - "جاري تحليل الإيصال…" in white
class OcrProcessingOverlay extends StatefulWidget {
  const OcrProcessingOverlay({super.key});

  @override
  State<OcrProcessingOverlay> createState() => _OcrProcessingOverlayState();
}

class _OcrProcessingOverlayState extends State<OcrProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: _navy.withAlpha(179), // ~70% opacity
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final delay = i * 0.27; // 800ms stagger
                  final t = (_controller.value - delay).clamp(0.0, 1.0);
                  final opacity = (t < 0.5 ? t * 2 : 2 - t * 2).clamp(0.2, 1.0);
                  final scale = 0.6 + (opacity * 0.4);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: _cyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'جاري تحليل الإيصال…',
            style: TextStyle(
              color: _white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// OCR State 3 — "Couldn't Read" Failure Fallback
// ─────────────────────────────────────────────────────────────────────

/// Error bubble + inline quick_input_form for manual entry when OCR fails.
///
/// Per spec:
/// - Navy BG, ⚠️ Danger Red icon
/// - "لم أستطع قراءة الإيصال"
/// - "الصورة مش واضحة أو مو فاتورة"
/// - Inline quick_input_form: amount (required, number pad) + category (optional)
/// - "سجل العملية ✓" button → saves as normal transaction
class OcrFailureWidget extends StatefulWidget {
  const OcrFailureWidget({
    super.key,
    required this.onSubmit,
    this.onRetake,
  });

  /// Called when user taps the save button with {amount, category}.
  final void Function(Map<String, dynamic> values) onSubmit;

  /// Called when user wants to retake the photo.
  final VoidCallback? onRetake;

  @override
  State<OcrFailureWidget> createState() => _OcrFailureWidgetState();
}

class _OcrFailureWidgetState extends State<OcrFailureWidget> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _danger, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _danger, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'لم أستطع قراءة الإيصال',
                  style: TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'الصورة مش واضحة أو مو فاتورة',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontFamily: 'Cairo',
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 14),

          // Amount field (required, number pad)
          const Text(
            'المبلغ (مطلوب)',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: _white,
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
            decoration: InputDecoration(
              hintText: 'مثلاً: 350',
              hintStyle: const TextStyle(color: _muted, fontFamily: 'Cairo'),
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
          const SizedBox(height: 10),

          // Category field (optional)
          const Text(
            'الفئة (اختياري)',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _categoryController,
            style: const TextStyle(
              color: _white,
              fontSize: 14,
              fontFamily: 'Cairo',
            ),
            decoration: InputDecoration(
              hintText: 'مثلاً: مقاضي',
              hintStyle: const TextStyle(color: _muted, fontFamily: 'Cairo'),
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
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              if (widget.onRetake != null) ...[
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _cyan,
                        side: const BorderSide(color: _cyan),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: widget.onRetake,
                      child: const Text(
                        '📷 إعادة التصوير',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cyan,
                      foregroundColor: _navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      final amountText =
                          _amountController.text.trim();
                      if (amountText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الرجاء إدخال المبلغ'),
                          ),
                        );
                        return;
                      }
                      widget.onSubmit({
                        'amount': amountText,
                        'category':
                            _categoryController.text.trim().isEmpty
                                ? 'متنوع'
                                : _categoryController.text.trim(),
                      });
                    },
                    child: const Text(
                      'سجل العملية ✓',
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// OCR State 2 — Low-Confidence Partial Extraction
// ─────────────────────────────────────────────────────────────────────

/// Hybrid widget: confirmed items (green checkmark, editable) +
/// uncertain items (amber left border, ⚠️ icon, manual fields).
///
/// Per spec:
/// - Confirmed items: green ✓, tap to edit
/// - Uncertain items: amber left border #B7791F, ⚠️ icon, manual entry
/// - Partial total: "المجموع: 350 + ?? ريال"
/// - "تأكيد الكل ✓" disabled until all uncertain fields filled
class OcrPartialExtractionWidget extends StatefulWidget {
  const OcrPartialExtractionWidget({
    super.key,
    required this.confirmedItems,
    required this.uncertainCount,
    required this.confirmedTotal,
    this.onEditConfirmed,
    required this.onConfirmAll,
  });

  /// Confirmed line items from OCR: [{name, price}].
  final List<Map<String, dynamic>> confirmedItems;

  /// How many uncertain items couldn't be extracted.
  final int uncertainCount;

  /// Sum of confirmed item prices.
  final int confirmedTotal;

  /// Called when user taps a confirmed item to edit it.
  final void Function(int index)? onEditConfirmed;

  /// Called when user taps "تأكيل الكل ✓".
  final VoidCallback onConfirmAll;

  @override
  State<OcrPartialExtractionWidget> createState() =>
      _OcrPartialExtractionWidgetState();
}

class _OcrPartialExtractionWidgetState
    extends State<OcrPartialExtractionWidget> {
  final Map<int, TextEditingController> _editingControllers = {};

  @override
  void dispose() {
    for (final c in _editingControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int index, String initial) {
    if (!_editingControllers.containsKey(index)) {
      _editingControllers[index] = TextEditingController(text: initial);
    }
    return _editingControllers[index]!;
  }

  @override
  Widget build(BuildContext context) {
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
          // Header with total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تفاصيل الإيصال',
                style: TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                widget.uncertainCount > 0
                    ? 'المجموع: ${widget.confirmedTotal} + ?? ريال'
                    : 'المجموع: ${widget.confirmedTotal} ريال',
                style: TextStyle(
                  color: widget.uncertainCount > 0 ? _warning : _cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Confirmed items
          ...widget.confirmedItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final name = item['name'] as String? ?? '';
            final price = item['price'] as num? ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: const Border(
                  left: const BorderSide(color: _success, width: 3),
                ),
                color: _success.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  Text(
                    '$price ريال',
                    style: const TextStyle(
                      color: _success,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  if (widget.onEditConfirmed != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => widget.onEditConfirmed?.call(idx),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _muted),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: _muted,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          // Uncertain items placeholder
          if (widget.uncertainCount > 0) ...[
            const SizedBox(height: 6),
            ...List.generate(widget.uncertainCount, (i) {
              final idx = widget.confirmedItems.length + i;
              final controller = _controllerFor(idx, '');
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: const Border(
                    left: const BorderSide(color: _warning, width: 3),
                  ),
                  color: _warning.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: _warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 14,
                          fontFamily: 'Cairo',
                        ),
                        decoration: const InputDecoration(
                          hintText: 'اسم المنتج',
                          hintStyle: TextStyle(
                            color: _muted,
                            fontFamily: 'Cairo',
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 60,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: _warning,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                        decoration: const InputDecoration(
                          hintText: 'سعر',
                          hintStyle: TextStyle(
                            color: _muted,
                            fontFamily: 'Cairo',
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Text(
                      ' ريال',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 10),

          // Confirm all button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: _navy,
                disabledBackgroundColor: _muted,
                disabledForegroundColor: _white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: widget.onConfirmAll,
              child: const Text(
                'تأكيد الكل ✓',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
