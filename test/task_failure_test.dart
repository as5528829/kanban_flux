import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanban_flux/features/todo_kanban/domain/errors/task_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('friendlyTaskFailure', () {
    test('classifies network errors', () {
      final failure = friendlyTaskFailure(
        const SocketException('Failed host lookup'),
      );

      expect(failure.type, TaskFailureType.network);
      expect(failure.message, contains('網路連線異常'));
    });

    test('classifies timeout errors', () {
      final failure = friendlyTaskFailure(TimeoutException('timed out'));

      expect(failure.type, TaskFailureType.timeout);
      expect(failure.message, contains('同步逾時'));
    });

    test('classifies RLS permission errors', () {
      final failure = friendlyTaskFailure(
        const PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501',
        ),
      );

      expect(failure.type, TaskFailureType.permission);
      expect(failure.message, contains('沒有權限'));
    });

    test('classifies missing schema errors', () {
      final failure = friendlyTaskFailure(
        const PostgrestException(
          message: 'column tasks.priority does not exist',
          code: '42703',
        ),
      );

      expect(failure.type, TaskFailureType.schema);
      expect(failure.message, contains('migration'));
    });

    test('classifies expired auth errors', () {
      final failure = friendlyTaskFailure(
        const AuthException('JWT expired', code: 'jwt_expired'),
      );

      expect(failure.type, TaskFailureType.authExpired);
      expect(failure.message, contains('重新登入'));
    });

    test('falls back for unknown errors', () {
      final failure = friendlyTaskFailure(Exception('Unexpected'));

      expect(failure.type, TaskFailureType.unknown);
      expect(failure.message, isNot(contains('Unexpected')));
    });
  });
}
