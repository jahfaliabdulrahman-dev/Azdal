import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:azdal/app/brand.dart';

/// رحلتك المالية — the 3-tier vision screen (Coach → Smart Lender → Wealth
/// Builder). 100% static mock content: no real data, no investment logic.
/// Pushed from the Account tab, mirroring the bank-linking flow.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: AppBar(title: const Text('رحلتك المالية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header: the tagline as the page's thesis ──
          const Text(
            'من مديون... إلى مستثمر',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Brand.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ثلاث مراحل: مدرب يفهم عاداتك، تمويل يعالج ديونك، ثم ثروة تبنيها.',
            style: TextStyle(fontSize: 14, color: Brand.muted),
          ),
          const SizedBox(height: 20),

          // ── The three tiers as one connected timeline ──
          const _TierCard(
            number: '1',
            title: 'المدرب المالي',
            status: _TierStatus.active,
            statusLabel: 'أنت هنا',
            points: [
              'يفهم عاداتك من المحادثة اليومية',
              'يرصد مصاريفك والتزاماتك',
              'يبني درجة التزامك المالي',
            ],
          ),
          const _TierConnector(),
          _TierCard(
            number: '2',
            title: 'التمويل الذكي',
            status: _TierStatus.next,
            statusLabel: 'قيد التفعيل',
            points: const [
              'ربط حساباتك البنكية بأمان',
              'خطة سداد تعالج ديونك المتعثرة',
              'خفض نسبة الدين إلى الدخل (DTI)',
            ],
            action: OutlinedButton.icon(
              onPressed: () => context.push('/bank-linking'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Brand.green,
                side: const BorderSide(color: Brand.green),
              ),
              icon: const Icon(Icons.account_balance_rounded, size: 18),
              label: const Text('اربط حساباتك'),
            ),
          ),
          const _TierConnector(),
          const _TierCard(
            number: '3',
            title: 'بناء الثروة',
            status: _TierStatus.locked,
            statusLabel: 'قريباً',
            points: [
              'محفظة استثمارية تُفتح تلقائياً عند اكتمال المتطلبات',
              'صناديق منخفضة المخاطر أولاً — بحسب وضعك',
              'أهداف ادخار واستثمار يتابعها مدربك نفسه',
            ],
          ),
          const SizedBox(height: 24),

          // ── Tier-3 preview: net worth, from debt to wealth ──
          const Text(
            'معاينة: من صافي دين إلى صافي ثروة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Brand.navy,
            ),
          ),
          const SizedBox(height: 10),
          _WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 150,
                  child: CustomPaint(painter: _ProjectionPainter()),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _LegendDot(
                      color: Color(0xFFC62828),
                      label: 'اليوم: -18,500 ر.س',
                    ),
                    _LegendDot(
                      color: Brand.green,
                      label: 'بعد 24 شهراً: +42,000 ر.س',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'مسار تقديري بناءً على خطة السداد ومعدل ادخار 15%',
                  style: TextStyle(fontSize: 11, color: Brand.muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Unlock requirements, tied to already-mocked concepts ──
          const Text(
            'متطلبات فتح الاستثمار',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Brand.navy,
            ),
          ),
          const SizedBox(height: 10),
          const _WhiteCard(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _RequirementTile(
                  done: true,
                  label: 'تفعيل المدرب المالي والالتزام بالخطة',
                  detail: 'مكتمل',
                ),
                _RequirementTile(
                  done: false,
                  label: 'ربط حساب بنكي واحد على الأقل',
                  detail: 'من شاشة ربط الحسابات',
                ),
                _RequirementTile(
                  done: false,
                  label: 'خفض نسبة الدين إلى الدخل تحت 30%',
                  detail: '41% حالياً',
                ),
                _RequirementTile(
                  done: false,
                  label: 'درجة التزام 80+ لمدة 3 أشهر',
                  detail: '72 حالياً',
                ),
                _RequirementTile(
                  done: false,
                  label: 'صندوق طوارئ يغطي شهرين من مصاريفك',
                  detail: '1,200 من 6,000 ر.س',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Locked green CTA ──
          FilledButton(
            onPressed: null, // intentionally disabled — Tier 3 is vision
            style: FilledButton.styleFrom(
              backgroundColor: Brand.green,
              disabledBackgroundColor: Brand.green.withValues(alpha: 0.35),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'افتح بوابة الاستثمار — قريباً',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أكمل المتطلبات وسيصلك إشعار عند الإطلاق',
            style: TextStyle(fontSize: 12, color: Brand.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

enum _TierStatus { active, next, locked }

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.number,
    required this.title,
    required this.status,
    required this.statusLabel,
    required this.points,
    this.action,
  });

  final String number;
  final String title;
  final _TierStatus status;
  final String statusLabel;
  final List<String> points;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (status) {
      _TierStatus.active => Brand.green,
      _TierStatus.next => Brand.navy,
      _TierStatus.locked => Brand.muted,
    };
    return _WhiteCard(
      borderColor: status == _TierStatus.active ? Brand.green : Brand.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accent.withValues(alpha: 0.12),
                child: status == _TierStatus.locked
                    ? Icon(Icons.lock_rounded, size: 16, color: accent)
                    : Text(
                        number,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Brand.navy,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == _TierStatus.active
                      ? Brand.green
                      : accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        status == _TierStatus.active ? Colors.white : accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Brand.ink,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (action != null) ...[
            const SizedBox(height: 8),
            Align(alignment: AlignmentDirectional.centerStart, child: action!),
          ],
        ],
      ),
    );
  }
}

class _TierConnector extends StatelessWidget {
  const _TierConnector();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: 30),
      child: SizedBox(
        width: 2,
        height: 18,
        child: ColoredBox(color: Brand.border),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Brand.border),
      ),
      child: child,
    );
  }
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({
    required this.done,
    required this.label,
    required this.detail,
  });

  final bool done;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: done ? Brand.green : Brand.muted,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: done ? Brand.muted : Brand.ink,
          decoration: done ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: Text(
        detail,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: done ? Brand.green : Brand.muted,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Mock net-worth projection: starts in debt (right side — RTL reading
/// direction), crosses zero, ends positive. Red zone below the dashed zero
/// line, green zone above. No text is painted (labels live in widgets).
class _ProjectionPainter extends CustomPainter {
  const _ProjectionPainter();

  static const List<double> _values = [
    -18500, -16800, -14200, -10500, -6200, -1500, 8000, 22500, 42000,
  ];
  static const double _min = -22000, _max = 46000;
  static const Color _red = Color(0xFFC62828);

  @override
  void paint(Canvas canvas, Size size) {
    double dx(int i) => size.width * (1 - i / (_values.length - 1)); // RTL
    double dy(double v) => size.height * (1 - (v - _min) / (_max - _min));
    final zeroY = dy(0);

    // Debt zone (below zero) and wealth zone (above zero) tints.
    canvas.drawRect(
      Rect.fromLTRB(0, zeroY, size.width, size.height),
      Paint()..color = _red.withValues(alpha: 0.05),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, zeroY),
      Paint()..color = Brand.green.withValues(alpha: 0.05),
    );

    // Dashed zero baseline.
    final dash = Paint()
      ..color = Brand.border
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, zeroY), Offset(x + 5, zeroY), dash);
    }

    // The journey line.
    final path = Path()..moveTo(dx(0), dy(_values[0]));
    for (var i = 1; i < _values.length; i++) {
      path.lineTo(dx(i), dy(_values[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Brand.navy,
    );

    // Start dot (in debt, red) and end dot (investor, green).
    canvas.drawCircle(Offset(dx(0), dy(_values.first)), 5, Paint()..color = _red);
    canvas.drawCircle(
      Offset(dx(_values.length - 1), dy(_values.last)),
      5,
      Paint()..color = Brand.green,
    );
  }

  @override
  bool shouldRepaint(covariant _ProjectionPainter oldDelegate) => false;
}
