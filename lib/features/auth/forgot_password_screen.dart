import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:azdal/app/brand.dart';
import 'package:azdal/app/providers.dart';
import 'package:azdal/features/auth/auth_service.dart';
import 'package:azdal/features/auth/auth_ui.dart';

/// Password recovery (DEC-051 needs this — login-required without a reset path
/// is a permanent lockout). Two steps in one screen:
///   1. enter email  → a 6-digit code is emailed (OTP path, no deep links)
///   2. enter code + new password → verified and set, then back to /login
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();

  bool _codeSent = false;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Brand.danger : Brand.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (!(_emailKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).sendPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() => _codeSent = true);
      _snack('أرسلنا رمزاً من 6 أرقام إلى بريدك — تحقق منه');
    } catch (e) {
      if (mounted) _snack(arabicAuthError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    if (!(_resetKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).confirmPasswordReset(
            email: _email.text.trim(),
            token: _code.text.trim(),
            newPassword: _newPassword.text,
          );
      if (!mounted) return;
      // verifyOTP established a session; sign out so the user logs in cleanly
      // with the new password (and the router gate lands on /login).
      await ref.read(authServiceProvider).signOut();
      if (!mounted) return;
      _snack('تم تغيير كلمة المرور — سجّل الدخول بها الآن');
      context.go('/login');
    } catch (e) {
      if (mounted) _snack(arabicAuthError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Brand.navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const Center(child: BrandMark(size: 72)),
            const SizedBox(height: 12),
            const Text(
              'استعادة كلمة المرور',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Brand.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _codeSent
                  ? 'اكتب الرمز الذي وصلك وكلمة مرور جديدة'
                  : 'اكتب بريدك ونرسل لك رمزاً لإعادة التعيين',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Brand.muted),
            ),
            const SizedBox(height: 24),
            if (!_codeSent) _emailStep() else _resetStep(),
          ],
        ),
      ),
    );
  }

  Widget _emailStep() {
    return Column(
      children: [
        Form(
          key: _emailKey,
          child: LabeledAuthField(
            label: 'البريد الإلكتروني',
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              decoration: authFieldDecoration(
                icon: Icons.mail_outline,
                hint: 'name@example.com',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty || !t.contains('@') || !t.contains('.')) {
                  return 'اكتب بريداً إلكترونياً صحيحاً';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        AuthSubmitButton(
          label: 'أرسل الرمز',
          loading: _loading,
          onPressed: _sendCode,
        ),
      ],
    );
  }

  Widget _resetStep() {
    return Column(
      children: [
        Form(
          key: _resetKey,
          child: Column(
            children: [
              LabeledAuthField(
                label: 'الرمز (6 أرقام)',
                child: TextFormField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: authFieldDecoration(
                    icon: Icons.password_outlined,
                    hint: '123456',
                  ).copyWith(counterText: ''),
                  validator: (v) => ((v ?? '').trim().length == 6)
                      ? null
                      : 'اكتب الرمز المكوّن من 6 أرقام',
                ),
              ),
              LabeledAuthField(
                label: 'كلمة المرور الجديدة',
                child: TextFormField(
                  controller: _newPassword,
                  obscureText: _obscure,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  decoration: authFieldDecoration(
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Brand.muted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => ((v ?? '').length < 6)
                      ? 'كلمة المرور 6 أحرف على الأقل'
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        AuthSubmitButton(
          label: 'تعيين كلمة المرور',
          loading: _loading,
          onPressed: _resetPassword,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading ? null : _sendCode,
          child: const Text(
            'لم يصلك الرمز؟ أعد الإرسال',
            style: TextStyle(color: Brand.green, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
