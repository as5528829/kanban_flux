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
    } catch (e) {
      throw Exception('註冊失敗: $e');
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
    } catch (e) {
      throw Exception('登入失敗: $e');
    }
  }

  /// 3. 登出
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      throw Exception('登出失敗: $e');
    }
  }

  /// 4. 獲取當前登入的使用者資訊（若未登入則回傳 null）
  User? getCurrentUser() {
    return _supabaseClient.auth.currentUser;
  }
}