import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:azdal/app/brand.dart';

/// 4-page onboarding, faithful to the designer's reference set:
/// p0 welcome (logo + tagline + green CTA), p1-p3 feature pages with a
/// 3-dot indicator, navy "التالي" + "تخطي", final green "ابدأ الآن".
/// Illustrations are icon compositions for now — if the designer exports
/// PNGs, swap inside _FeaturePage only.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _features = [
    (
      icon: Icons.receipt_long_outlined,
      title: 'تتبع مصروفاتك بدقة',
      body:
          'اعرف اين تذهب اموالك من خلال ميزة التتبع الذكي التي تصنف معاملاتك تلقائياً',
    ),
    (
      icon: Icons.chat_bubble_outline,
      title: 'مدرب مالي ذكي',
      body: 'اسأل، صور فاتورة أو تحدث الى أزدل',
    ),
    (
      icon: Icons.trending_up,
      title: 'رحلتك تبدأ اليوم',
      body: 'كل إنجاز صغير يقربك من أهدافك المالية.',
    ),
  ];

  bool get _isWelcome => _page == 0;
  bool get _isLast => _page == _features.length;

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _finish() => context.go('/home');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: _isWelcome
                  ? null
                  : Center(
                      child: _Dots(
                        count: _features.length,
                        active: _page - 1,
                      ),
                    ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _WelcomePage(),
                  for (final f in _features)
                    _FeaturePage(icon: f.icon, title: f.title, body: f.body),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: (_isWelcome || _isLast)
                            ? Brand.green
                            : Brand.navy,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      onPressed: _isLast ? _finish : _next,
                      child: Text(
                        _isWelcome
                            ? 'ابدأ رحلتك'
                            : (_isLast ? 'ابدأ الآن' : 'التالي'),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: (_isWelcome || _isLast)
                        ? null
                        : TextButton(
                            onPressed: _finish,
                            child: const Text(
                              'تخطي',
                              style: TextStyle(
                                color: Brand.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BrandMark(size: 150),
          SizedBox(height: 24),
          Text(
            Brand.appName,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Brand.navy,
            ),
          ),
          SizedBox(height: 12),
          BrandTagline(fontSize: 26, twoLines: true),
        ],
      ),
    );
  }
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: const BoxDecoration(
              color: Brand.greenTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 88, color: Brand.navy),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Brand.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Brand.muted,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? Brand.navy : Brand.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
