import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

enum TaskFailureType {
  network,
  permission,
  schema,
  authExpired,
  timeout,
  unknown,
}

class TaskFailure implements Exception {
  final TaskFailureType type;
  final String message;
  final Object? cause;

  const TaskFailure({required this.type, required this.message, this.cause});

  @override
  String toString() => message;
}

TaskFailure friendlyTaskFailure(Object error) {
  if (error is TaskFailure) return error;

  final raw = error.toString().toLowerCase();
  final code = error is PostgrestException ? error.code?.toLowerCase() : null;

  if (error is TimeoutException) {
    return TaskFailure(
      type: TaskFailureType.timeout,
      message: '同步逾時，請確認網路後再試一次。',
      cause: error,
    );
  }

  if (error is SocketException ||
      raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('network') ||
      raw.contains('clientexception') ||
      raw.contains('connection refused')) {
    return TaskFailure(
      type: TaskFailureType.network,
      message: '網路連線異常，請確認連線後再試一次。',
      cause: error,
    );
  }

  if (error is AuthException ||
      raw.contains('jwt expired') ||
      raw.contains('invalid jwt') ||
      raw.contains('token has expired') ||
      raw.contains('not authenticated')) {
    return TaskFailure(
      type: TaskFailureType.authExpired,
      message: '登入狀態已過期，請重新登入。',
      cause: error,
    );
  }

  if (code == '42501' ||
      raw.contains('row-level security') ||
      raw.contains('permission denied') ||
      raw.contains('violates row-level security')) {
    return TaskFailure(
      type: TaskFailureType.permission,
      message: '沒有權限操作此任務，請確認登入帳號或 RLS 設定。',
      cause: error,
    );
  }

  if (code == '42703' ||
      code == '42p01' ||
      raw.contains('column') && raw.contains('does not exist') ||
      raw.contains('relation') && raw.contains('does not exist') ||
      raw.contains('schema cache')) {
    return TaskFailure(
      type: TaskFailureType.schema,
      message: '資料庫欄位尚未更新，請先執行最新 migration。',
      cause: error,
    );
  }

  return TaskFailure(
    type: TaskFailureType.unknown,
    message: '同步失敗，請稍後再試一次。',
    cause: error,
  );
}
