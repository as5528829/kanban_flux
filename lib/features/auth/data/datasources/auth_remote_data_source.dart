import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  final SupabaseClient _supabaseClient;

  AuthRemoteDataSource(this._supabaseClient);

  /// 1. 用 Email 與密碼註冊新帳號
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(friendlyAuthMessage(e, fallback: '註冊失敗，請稍後再試。'));
    } catch (_) {
      throw const AuthFailure('註冊失敗，請稍後再試。');
    }
  }

  /// 2. 用 Email 與密碼登入
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(friendlyAuthMessage(e, fallback: '登入失敗，請稍後再試。'));
    } catch (_) {
      throw const AuthFailure('登入失敗，請稍後再試。');
    }
  }

  /// 3. 寄送忘記密碼重設信
  Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo?.isEmpty == true ? null : redirectTo,
      );
    } on AuthException catch (e) {
      throw AuthFailure(friendlyAuthMessage(e, fallback: '重設密碼信寄送失敗，請稍後再試。'));
    } catch (_) {
      throw const AuthFailure('重設密碼信寄送失敗，請稍後再試。');
    }
  }

  /// 4. 登出
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(friendlyAuthMessage(e, fallback: '登出失敗，請稍後再試。'));
    } catch (_) {
      throw const AuthFailure('登出失敗，請稍後再試。');
    }
  }

  /// 5. 獲取當前登入的使用者資訊（若未登入則回傳 null）
  User? getCurrentUser() {
    return _supabaseClient.auth.currentUser;
  }
}

String friendlyAuthMessage(AuthException error, {required String fallback}) {
  final code = error.code;
  final message = error.message.toLowerCase();

  if (code == 'invalid_credentials' ||
      message.contains('invalid login credentials')) {
    return 'Email 或密碼錯誤，請再確認一次。';
  }
  if (message.contains('email not confirmed')) {
    return '請先完成 Email 驗證後再登入。';
  }
  if (message.contains('user already registered') ||
      message.contains('already registered')) {
    return '這個 Email 已經註冊過了，請直接登入。';
  }
  if (message.contains('password')) {
    return '密碼格式不符合要求，請重新輸入。';
  }
  if (message.contains('rate limit') || message.contains('too many')) {
    return '嘗試次數太多，請稍後再試。';
  }

  return fallback;
}

class AuthFailure implements Exception {
  final String message;

  const AuthFailure(this.message);

  @override
  String toString() => message;
}
