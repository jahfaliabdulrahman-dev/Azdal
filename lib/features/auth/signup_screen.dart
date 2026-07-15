import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:azdal/app/brand.dart';
import 'package:azdal/app/providers.dart';
import 'package:azdal/features/auth/auth_service.dart';
import 'package:azdal/features/auth/auth_ui.dart';

/// REAL signup = anonymous → permanent upgrade (same UUID, DEC-017).
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _agreed = false;
  bool _loading = false;

  static final _phoneRegex = RegExp(r'^05\d{8}$');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
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
    if (!_agreed) {
      _snack('يجب الموافقة على شروط الخدمة وسياسة الخصوصية أولاً',
          error: true);
      return;
    }
    final auth = ref.read(authServiceProvider);
    if (!auth.isAnonymous) {
      _snack('لديك حساب دائم بالفعل على هذا الجهاز');
      return;
    }
    setState(() => _loading = true);
    try {
      await auth.upgradeAnonymousToEmail(
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      _snack('تم إنشاء حسابك بنجاح — كل بياناتك السابقة محفوظة معك ✨');
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
              'أنشئ حسابك في أزدل',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Brand.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ابدأ رحلتك نحو حياة مالية أفضل',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Brand.muted),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  LabeledAuthField(
                    label: 'الاسم الكامل',
                    child: TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: authFieldDecoration(
                        icon: Icons.person_outline,
                        hint: 'سارة أحمد',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'اكتب اسمك الكامل'
                          : null,
                    ),
                  ),
                  LabeledAuthField(
                    label: 'رقم الجوال',
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      textInputAction: TextInputAction.next,
                      decoration: authFieldDecoration(
                        icon: Icons.phone_android_outlined,
                        hint: '05xxxxxxxx',
                      ),
                      validator: (v) =>
                          _phoneRegex.hasMatch((v ?? '').trim())
                              ? null
                              : 'اكتب رقم جوال سعودي صحيح (05xxxxxxxx)',
                    ),
                  ),
                  LabeledAuthField(
                    label: 'البريد الإلكتروني',
                    child: TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      textInputAction: TextInputAction.next,
                      decoration: authFieldDecoration(
                        icon: Icons.mail_outline,
                        hint: 'name@example.com',
                      ),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty ||
                            !t.contains('@') ||
                            !t.contains('.')) {
                          return 'اكتب بريداً إلكترونياً صحيحاً';
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
                      validator: (v) => ((v ?? '').length < 6)
                          ? 'كلمة المرور 6 أحرف على الأقل'
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreed,
                  activeColor: Brand.green,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 12.5, color: Brand.ink),
                          children: [
                            TextSpan(text: 'أوافق على '),
                            TextSpan(
                              text: 'شروط الخدمة',
                              style: TextStyle(
                                color: Brand.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' و '),
                            TextSpan(
                              text: 'سياسة الخصوصية',
                              style: TextStyle(
                                color: Brand.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' الخاصة بتطبيق أزدل'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AuthSubmitButton(
              label: 'إنشاء حساب',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'لديك حساب بالفعل؟',
                  style: TextStyle(fontSize: 13, color: Brand.muted),
                ),
                TextButton(
                  onPressed: () => context.pushReplacement('/login'),
                  child: const Text(
                    'سجّل دخولك',
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
