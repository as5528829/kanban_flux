import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/app_config.dart';
import '../../data/datasources/auth_remote_data_source.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  late final AuthRemoteDataSource _authDataSource;

  @override
  User? build() {
    _authDataSource = AuthRemoteDataSource(Supabase.instance.client);

    // 💡 外商高級技巧：監聽 Supabase 的認證狀態變動（例如 Token 過期、在別台設備登出）
    // 只要狀態一變，就自動更新 Riverpod 的 state
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      state = data.session?.user;
    });

    // 預設回傳目前有沒有登入的使用者
    return _authDataSource.getCurrentUser();
  }

  /// 執行登入
  Future<void> login(String email, String password) async {
    await _authDataSource.signInWithEmail(email: email, password: password);
    // 💡 登入成功後，onAuthStateChange 會自動觸發並更新 state，UI 會隨之變動
  }

  /// 執行註冊
  Future<void> register(String email, String password) async {
    await _authDataSource.signUpWithEmail(email: email, password: password);
  }

  /// 寄送忘記密碼重設信
  Future<void> sendPasswordResetEmail(String email) async {
    await _authDataSource.sendPasswordResetEmail(
      email: email,
      redirectTo: AppConfig.passwordResetRedirectUrl,
    );
  }

  /// 執行登出
  Future<void> logout() async {
    await _authDataSource.signOut();
  }
}
