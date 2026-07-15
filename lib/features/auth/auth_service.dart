import 'package:supabase_flutter/supabase_flutter.dart';

/// Real auth on top of the existing anonymous-first session (DEC-017).
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  bool get isAnonymous => _client.auth.currentUser?.isAnonymous ?? true;

  /// DEC-017's documented upgrade path: converts the CURRENT anonymous
  /// session into a permanent email/password account while keeping the
  /// same auth.users UUID — every existing row (transactions,
  /// commitments, goals, integrity_scores, purchase_decisions,
  /// financial_profile) stays owned by the user with ZERO migration.
  ///
  /// PREREQUISITE (one-time, Supabase dashboard): Authentication →
  /// Sign In / Providers → Email → "Confirm email" = OFF. Otherwise the
  /// email only PENDS behind a mailed confirmation link.
  ///
  /// Phone is stored as user metadata only — real phone auth (SMS OTP)
  /// is explicitly deferred.
  Future<void> upgradeAnonymousToEmail({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    await _client.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      ),
    );
  }

  /// Sign in to an EXISTING permanent account.
  /// NOTE: replaces the current session — if the current session is
  /// anonymous, its data stays under the old anonymous UUID and becomes
  /// unreachable. The login screen MUST warn before calling this.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }
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
