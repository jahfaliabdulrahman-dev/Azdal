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

    // Data-safety guard: logging in REPLACES the anonymous session, so
    // this device's guest data becomes unreachable. Warn first.
    if (auth.isAnonymous) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تنبيه'),
          content: const Text(
            'تسجيل الدخول بحساب آخر سيفصل هذا الجهاز عن بيانات الضيف الحالية.\n'
            'إذا كنت تريد الاحتفاظ ببياناتك الحالية، أنشئ حساباً جديداً بدلاً من ذلك.',
            style: TextStyle(height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('رجوع'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'متابعة الدخول',
                style: TextStyle(color: Brand.danger),
              ),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _loading = true);
    try {
      await auth.signInWithEmail(
        email: _identifier.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      _snack('أهلاً بعودتك!');
      context.pop();
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
            const SizedBox(height: 12),
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
