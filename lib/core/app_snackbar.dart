import 'package:flutter/material.dart';

final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar(String message, {bool isError = false}) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        width: 420,
        elevation: 8,
        backgroundColor: isError ? Colors.red : const Color(0xFF0F172A),
      ),
    );
}
