import 'package:flutter/material.dart';

/// Shared brand tokens + brand widgets for the standalone (non-chat)
/// screens: splash, onboarding, auth, courses, account, bank linking.
///
/// Palette values come from docs/design/visual-identity.md §2.
/// The chat widget catalog (widget_catalog.dart) keeps its own dark-card
/// tokens on purpose — the two visual registers are intentional (DEC-041):
/// dark data-cards live INSIDE chat bubbles; standalone pages are light.
class Brand {
  Brand._();

  // Mandatory brand anchors (DEC-007 / DEC-013 — unchanged).
  static const navy = Color(0xFF001F5E);
  static const cyan = Color(0xFF32C2FF);

  // Light-screen palette (visual-identity.md §2).
  static const surface = Color(0xFFF7F8FA);
  static const ink = Color(0xFF1B1B1F);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE1E4E8);
  static const green = Color(0xFF2E7D32);
  static const greenTint = Color(0xFFE8F5E9);
  static const cyanTint = Color(0xFFE7F6FF);
  static const danger = Color(0xFFD32F2F);

  // Mandatory brand copy (DEC-013).
  static const appName = 'أزدل';
  static const taglineStart = 'من مديون...';
  static const taglineEnd = 'إلى مستثمر';
  static const taglineEn = 'Azdal — Spend Aware';

  // Assets. azdal-mark.png = a future icon-only export (square,
  // transparent). The current file is the fallback and is already the
  // correct DEC-013 mark (verified directly) — just a wide white-bg JPEG.
  static const markPng = 'assets/branding/azdal-mark.png';
  static const markJpegFallback = 'assets/branding/Azdal logo.jpeg';
}

/// The shield+bars+sweep icon mark (DEC-013).
/// PNG → legacy JPEG → Material icon: a missing asset can never crash a demo.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Brand.markPng,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        Brand.markJpegFallback,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.shield_outlined, size: size, color: Brand.navy),
      ),
    );
  }
}

/// "من مديون... إلى مستثمر" with the payoff word emphasised in green,
/// exactly as styled in the designer's onboarding reference.
class BrandTagline extends StatelessWidget {
  const BrandTagline({super.key, this.fontSize = 20, this.twoLines = false});

  final double fontSize;
  final bool twoLines;

  @override
  Widget build(BuildContext context) {
    final startStyle = TextStyle(
      color: Brand.ink,
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      height: 1.5,
    );
    final endStyle = TextStyle(
      color: Brand.green,
      fontWeight: FontWeight.w900,
      fontSize: fontSize,
      height: 1.5,
    );

    if (twoLines) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(Brand.taglineStart,
              style: startStyle, textAlign: TextAlign.center),
          Text(Brand.taglineEnd, style: endStyle, textAlign: TextAlign.center),
        ],
      );
    }
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: Brand.taglineStart, style: startStyle),
        const TextSpan(text: ' '),
        TextSpan(text: Brand.taglineEnd, style: endStyle),
      ]),
      textAlign: TextAlign.center,
    );
  }
}
