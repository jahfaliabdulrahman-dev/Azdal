import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:azdal/app/brand.dart';
import 'package:azdal/app/providers.dart';
import 'package:azdal/features/auth/auth_service.dart';
import 'package:azdal/features/auth/auth_ui.dart';

/// REAL login for existing permanent accounts. Email only for now —
/// the field keeps the designer's label, phone input gets an honest
/// Arabic validator message (SMS OTP deferred).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = ref.read(authServiceProvider);
    setState(() => _loading = true);
    try {
      await auth.signInWithEmail(
        email: _identifier.text.trim(),
        password: _password.text,
      );
      // On success the auth-state change refreshes the router's gate, which
      // moves /login → /home automatically (DEC-051). No manual navigation.
      if (mounted) _snack('أهلاً بعودتك!');
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
              'تسجيل الدخول',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Brand.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'مرحباً بعودتك! سجل الدخول للوصول لحسابك.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Brand.muted),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  LabeledAuthField(
                    label: 'رقم الجوال أو البريد الإلكتروني',
                    child: TextFormField(
                      controller: _identifier,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      textInputAction: TextInputAction.next,
                      decoration: authFieldDecoration(
                        icon: Icons.person_outline,
                        hint: 'name@example.com',
                      ),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'اكتب بريدك الإلكتروني';
                        if (!t.contains('@')) {
                          return 'الدخول برقم الجوال غير متاح حالياً — استخدم البريد الإلكتروني';
                        }
                        return null;
                      },
                    ),
                  ),
                  LabeledAuthField(
                    label: 'كلمة المرور',
                    child: TextFormField(
                      controller: _password,
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
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => ((v ?? '').isEmpty)
                          ? 'اكتب كلمة المرور'
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'نسيت كلمة المرور؟',
                  style: TextStyle(
                    color: Brand.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AuthSubmitButton(
              label: 'تسجيل الدخول',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ليس لديك حساب؟',
                  style: TextStyle(fontSize: 13, color: Brand.muted),
                ),
                TextButton(
                  onPressed: () => context.pushReplacement('/signup'),
                  child: const Text(
                    'إنشاء حساب',
                    style: TextStyle(
                      color: Brand.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
