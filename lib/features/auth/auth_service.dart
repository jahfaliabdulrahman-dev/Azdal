import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth for the personal build (DEC-051): email/password only, login required
/// from first launch. No anonymous/guest sessions — every account is permanent
/// from message one, so there is no in-place upgrade and no data-orphaning
/// risk. Supersedes the DEC-017 anonymous-first `upgradeAnonymousToEmail` path.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  bool get isSignedIn => _client.auth.currentSession != null;

  /// Create a NEW permanent account.
  ///
  /// With the Supabase dashboard "Confirm email" = OFF, [signUp] establishes a
  /// session immediately and the returned [AuthResponse.session] is non-null.
  /// With it ON, the session is null until the user confirms via the emailed
  /// link — the caller must handle both (see [SignUpScreen]).
  ///
  /// Phone is stored as user metadata only; real phone auth (SMS OTP) is
  /// explicitly deferred.
  Future<AuthResponse> registerWithEmail({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone},
    );
  }

  /// Sign in to an existing permanent account.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Step 1 of password recovery: email a 6-digit recovery code.
  ///
  /// Uses the OTP (code) path rather than a magic link — the app has no
  /// deep-link scheme configured. REQUIRES the Supabase "Reset Password" email
  /// template to include the code token `{{ .Token }}` (the default template is
  /// link-only). Login-required (DEC-051) would otherwise mean a forgotten
  /// password is a permanent lockout.
  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  /// Step 2 of password recovery: verify the emailed code, then set the new
  /// password. [verifyOTP] with `recovery` establishes a short-lived session
  /// that authorizes the immediately-following [updateUser].
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Sign out — the router's auth gate then sends the user back to /login.
  Future<void> signOut() => _client.auth.signOut();
}

/// Maps auth/network failures to user-facing Arabic messages.
String arabicAuthError(Object error) {
  if (error is AuthException) {
    final code = error.code ?? '';
    final msg = error.message.toLowerCase();
    if (code == 'email_exists' ||
        code == 'user_already_exists' ||
        msg.contains('already registered') ||
        msg.contains('already been registered')) {
      return 'هذا البريد مسجّل مسبقاً — جرّب تسجيل الدخول بدلاً من إنشاء حساب';
    }
    if (code == 'invalid_credentials' || msg.contains('invalid login')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (code == 'otp_expired' ||
        code == 'otp_disabled' ||
        msg.contains('token has expired') ||
        msg.contains('invalid') && msg.contains('token') ||
        msg.contains('otp')) {
      return 'الرمز غير صحيح أو منتهي — اطلب رمزاً جديداً';
    }
    if (code == 'weak_password' || msg.contains('password should')) {
      return 'كلمة المرور ضعيفة — استخدم 6 أحرف على الأقل';
    }
    if (code == 'validation_failed' || msg.contains('invalid format')) {
      return 'تأكد من كتابة البريد الإلكتروني بشكل صحيح';
    }
    if (code.contains('rate_limit')) {
      return 'محاولات كثيرة — انتظر دقيقة ثم أعد المحاولة';
    }
  }
  final text = error.toString().toLowerCase();
  if (text.contains('socket') ||
      text.contains('network') ||
      text.contains('connection')) {
    return 'تحقق من اتصال الإنترنت ثم أعد المحاولة';
  }
  return 'حدث خطأ غير متوقع — أعد المحاولة';
}
