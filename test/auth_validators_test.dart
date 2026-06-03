import 'package:flutter_test/flutter_test.dart';
import 'package:kanban_flux/features/auth/presentation/utils/auth_validators.dart';

void main() {
  group('validateEmail', () {
    test('accepts common valid email addresses', () {
      expect(validateEmail('user@example.com'), isNull);
      expect(validateEmail('first.last+tag@sub.example.co'), isNull);
      expect(validateEmail('  user-name@example.io  '), isNull);
    });

    test('rejects loose or malformed email addresses', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('user'), isNotNull);
      expect(validateEmail('user@'), isNotNull);
      expect(validateEmail('user@example'), isNotNull);
      expect(validateEmail('user@@example.com'), isNotNull);
      expect(validateEmail('user name@example.com'), isNotNull);
      expect(validateEmail('user@-example.com'), isNotNull);
    });
  });

  group('validatePassword', () {
    test('requires at least six non-whitespace characters after trim', () {
      expect(validatePassword('12345'), isNotNull);
      expect(validatePassword('123456'), isNull);
      expect(validatePassword(' 123456 '), isNull);
    });
  });
}
