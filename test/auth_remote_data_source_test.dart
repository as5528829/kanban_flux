import 'package:flutter_test/flutter_test.dart';
import 'package:kanban_flux/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('friendlyAuthMessage', () {
    test('maps invalid login credentials to a user-friendly message', () {
      final message = friendlyAuthMessage(
        const AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
        fallback: '登入失敗',
      );

      expect(message, 'Email 或密碼錯誤，請再確認一次。');
      expect(message, isNot(contains('AuthApiException')));
    });

    test('maps already registered email to a user-friendly message', () {
      final message = friendlyAuthMessage(
        const AuthException('User already registered'),
        fallback: '註冊失敗',
      );

      expect(message, '這個 Email 已經註冊過了，請直接登入。');
    });

    test('falls back for unknown auth errors', () {
      final message = friendlyAuthMessage(
        const AuthException('Unexpected server response'),
        fallback: '操作失敗',
      );

      expect(message, '操作失敗');
    });
  });
}
