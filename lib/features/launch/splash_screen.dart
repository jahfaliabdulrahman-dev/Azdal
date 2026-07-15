import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:azdal/app/brand.dart';
import 'package:azdal/app/launch_flags.dart';

/// Splash: icon-only mark + live "أزدل" wordmark + two-tone tagline,
/// composed as layered widgets (no pre-baked lockup image — DEC-040).
/// Pure-white background so the legacy white-bg JPEG fallback is seamless.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), _next);
  }

  void _next() {
    if (!mounted) return;
    context.go(azdalFirstLaunch ? '/onboarding' : '/home');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (context, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          // A bare Column under Scaffold/SafeArea gets a LOOSE width
          // constraint and shrink-wraps to its widest child (here, the
          // "أزدل" title) instead of filling the screen — then that
          // narrow box sits flush at the left edge since nothing centers
          // it. The SizedBox forces a tight, full-width constraint so
          // CrossAxisAlignment.center actually has the full screen to
          // center within.
          child: const SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 3),
                const BrandMark(size: 140),
                const SizedBox(height: 20),
                const Text(
                  Brand.appName,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Brand.navy,
                  ),
                ),
                const SizedBox(height: 6),
                const BrandTagline(fontSize: 20),
                const Spacer(flex: 4),
                const Text(
                  Brand.taglineEn,
                  style: TextStyle(fontSize: 12, color: Brand.muted),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
