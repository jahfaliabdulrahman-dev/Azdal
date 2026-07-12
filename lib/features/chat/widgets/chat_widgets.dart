/// Shared chat widgets for Azdal — ErrorBubble, typing indicator, etc.
library;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────

const _danger = Color(0xFFD32F2F);

// ─────────────────────────────────────────────────────────────────────
// ErrorBubble — reusable inline error display
// ─────────────────────────────────────────────────────────────────────

/// A reusable inline error bubble shown in place of a bot message.
///
/// Displays a red-tinted background with a red left border accent,
/// Arabic error text, and a retry icon at the end.
///
/// Used for: Gemini failures, Supabase write failures, network errors.
class ErrorBubble extends StatelessWidget {
  const ErrorBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// Error message to display (Arabic).
  final String message;

  /// Optional callback when the retry icon is tapped.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 40,
        right: 16,
        top: 4,
        bottom: 4,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _danger.withAlpha(25),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: const Border(
          left: BorderSide(color: _danger, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _danger,
                fontSize: 14,
                fontFamily: 'Cairo',
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: const Icon(
                Icons.refresh,
                color: _danger,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TypingIndicator — 3 animated cyan dots
// ─────────────────────────────────────────────────────────────────────

/// Three animated cyan dots shown when the AI is processing.
///
/// Appears in the bot bubble area. Disappears when the response arrives.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
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
      margin: const EdgeInsets.only(
        left: 40,
        right: 16,
        top: 4,
        bottom: 4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF001F5E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final delay = i * 0.2;
              final t = (_controller.value - delay).clamp(0.0, 1.0);
              final opacity = (t < 0.5 ? t * 2 : 2 - t * 2).clamp(0.2, 1.0);
              final scale = 0.6 + (opacity * 0.4);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF32C2FF),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Offline banner — shown in input area when no connectivity
// ─────────────────────────────────────────────────────────────────────

/// Inline message shown below the text field when offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: const Text(
        'أنت غير متصل. سترسل العملية عند عودة الاتصال.',
        style: TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 11,
          fontFamily: 'Cairo',
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
