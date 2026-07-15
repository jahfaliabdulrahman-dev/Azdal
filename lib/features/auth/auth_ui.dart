import 'package:flutter/material.dart';

import 'package:azdal/app/brand.dart';

/// Label-above-field pattern from the designer's login/signup reference.
class LabeledAuthField extends StatelessWidget {
  const LabeledAuthField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: Brand.ink,
          ),
        ),
        const SizedBox(height: 6),
        child,
        const SizedBox(height: 14),
      ],
    );
  }
}

InputDecoration authFieldDecoration({
  required IconData icon,
  String? hint,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    prefixIcon: Icon(icon, color: Brand.muted, size: 20),
    suffixIcon: suffix,
    hintText: hint,
    hintStyle: const TextStyle(color: Brand.muted, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: border(Brand.border),
    focusedBorder: border(Brand.navy, 1.4),
    errorBorder: border(Brand.danger),
    focusedErrorBorder: border(Brand.danger, 1.4),
    errorStyle: const TextStyle(fontSize: 11.5, color: Brand.danger),
  );
}

/// Full-width green pill CTA with a built-in loading state.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Brand.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Brand.green.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
