import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:azdal/app/brand.dart';

/// Bank-linking flow — MOCK (no network, no persistence; DEC-042 draft).
/// Three steps in one route matching the designer's reference:
/// picker → connecting (timed) → success.
/// Bank tiles use colored generic icons, NOT real bank logos (no
/// trademarked assets shipped).
enum _Step { pick, connecting, done }

class _Bank {
  const _Bank(this.name, this.color);

  final String name;
  final Color color;
}

const _banks = [
  _Bank('البنك الأهلي السعودي (SNB)', Color(0xFF1B6B4A)),
  _Bank('مصرف الراجحي', Color(0xFF4B2E83)),
  _Bank('بنك الرياض', Color(0xFF00747A)),
  _Bank('مصرف الإنماء', Color(0xFF3E3A36)),
  _Bank('البنك العربي الوطني (anb)', Color(0xFF1565C0)),
  _Bank('بنك البلاد', Color(0xFFD84315)),
];

class BankLinkFlowScreen extends StatefulWidget {
  const BankLinkFlowScreen({super.key});

  @override
  State<BankLinkFlowScreen> createState() => _BankLinkFlowScreenState();
}

class _BankLinkFlowScreenState extends State<BankLinkFlowScreen> {
  _Step _step = _Step.pick;
  _Bank? _selected;
  String _query = '';
  Timer? _timer;

  void _connect(_Bank bank) {
    setState(() {
      _selected = bank;
      _step = _Step.connecting;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted && _step == _Step.connecting) {
        setState(() => _step = _Step.done);
      }
    });
  }

  void _cancelConnect() {
    _timer?.cancel();
    setState(() => _step = _Step.pick);
  }

  void _mockSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: AppBar(
        title: const Text('الربط البنكي'),
        automaticallyImplyLeading: _step != _Step.connecting,
        actions: [
          if (_step == _Step.connecting)
            TextButton(
              onPressed: _cancelConnect,
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: switch (_step) {
        _Step.pick => _buildPick(),
        _Step.connecting => _buildConnecting(),
        _Step.done => _buildDone(),
      },
    );
  }

  Widget _buildPick() {
    final filtered = _query.trim().isEmpty
        ? _banks
        : _banks.where((b) => b.name.contains(_query.trim())).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Brand.navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Brand.navy,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اربط حساباتك البنكية',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'لكي يستطيع أزدل متابعة مصروفاتك تلقائياً',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'اختر البنك',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Brand.ink,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'ابحث عن البنك الذي تتعامل معه...',
            hintStyle: const TextStyle(color: Brand.muted, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Brand.muted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Brand.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Brand.navy, width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            for (final bank in filtered)
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _connect(bank),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Brand.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: bank.color.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.account_balance,
                            color: bank.color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bank.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Brand.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Brand.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هل مصرفك غير موجود؟',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Brand.ink,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'أخبرنا عنه وسنعمل على إضافته قريباً',
                style: TextStyle(fontSize: 12, color: Brand.muted),
              ),
              TextButton(
                onPressed: () =>
                    _mockSnack('الدعم الفني — قريباً (نسخة تجريبية)'),
                child: const Text(
                  'تواصل مع الدعم الفني',
                  style: TextStyle(
                    color: Brand.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnecting() {
    final bank = _selected!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          CircleAvatar(
            radius: 34,
            backgroundColor: bank.color.withValues(alpha: 0.12),
            child: Icon(Icons.account_balance, color: bank.color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            bank.name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Brand.ink,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'جاري الاتصال بحسابك البنكي بأمان',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Brand.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'يرجى عدم إغلاق التطبيق',
            style: TextStyle(fontSize: 13, color: Brand.muted),
          ),
          const SizedBox(height: 36),
          const SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 6,
                  color: Brand.green,
                  backgroundColor: Brand.greenTint,
                ),
                Center(
                  child: Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Brand.green,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Brand.greenTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: Brand.green, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'نحن نستخدم أعلى معايير الأمان لحماية بياناتك',
                    style: TextStyle(fontSize: 13, color: Brand.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDone() {
    final bank = _selected!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Brand.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 10),
              const Text(
                'تم الربط بنجاح',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'تم ربط حسابك في ${bank.name} بنجاح',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _mockSnack('عرض الحسابات — قريباً (نسخة تجريبية)'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Brand.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Brand.greenTint,
                    child: Icon(
                      Icons.account_balance,
                      color: Brand.green,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الحسابات المرتبطة',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: Brand.ink,
                          ),
                        ),
                        Text(
                          '1 حساب نشط',
                          style: TextStyle(fontSize: 12, color: Brand.muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left, color: Brand.muted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Brand.greenTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بدأ أزدل بتحليل مصروفاتك ✨',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Brand.ink,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'سيصلك أول تقرير خلال دقائق',
                style: TextStyle(fontSize: 12, color: Brand.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Brand.navy,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
            ),
            onPressed: () => context.pop(),
            child: const Text('الانتقال للرئيسية'),
          ),
        ),
        TextButton(
          onPressed: () => _mockSnack('عرض الحسابات — قريباً (نسخة تجريبية)'),
          child: const Text(
            'عرض الحسابات',
            style: TextStyle(color: Brand.green, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
