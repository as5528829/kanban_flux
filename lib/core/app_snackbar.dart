import 'package:flutter/material.dart';

final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

enum AppFeedbackType { success, error, warning, info }

void showAppSnackBar(
  String message, {
  bool isError = false,
  AppFeedbackType? type,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  showAppFeedback(
    message,
    type: type ?? (isError ? AppFeedbackType.error : AppFeedbackType.success),
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

void showAppFeedback(
  String message, {
  AppFeedbackType type = AppFeedbackType.info,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  final view = WidgetsBinding.instance.platformDispatcher.implicitView;
  final screenWidth = view == null
      ? 480.0
      : view.physicalSize.width / view.devicePixelRatio;
  final useFixedWidth = screenWidth >= 460;
  final meta = _feedbackMeta(type);
  final hasAction = actionLabel != null && onAction != null;

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(meta.icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        width: useFixedWidth ? 420 : null,
        margin: useFixedWidth ? null : const EdgeInsets.fromLTRB(16, 0, 16, 18),
        elevation: 10,
        showCloseIcon: !hasAction,
        closeIconColor: Colors.white,
        backgroundColor: meta.background,
        action: !hasAction
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

({IconData icon, Color background}) _feedbackMeta(AppFeedbackType type) {
  return switch (type) {
    AppFeedbackType.success => (
      icon: Icons.check_circle_outline_rounded,
      background: const Color(0xFF047857),
    ),
    AppFeedbackType.error => (
      icon: Icons.error_outline_rounded,
      background: const Color(0xFFDC2626),
    ),
    AppFeedbackType.warning => (
      icon: Icons.warning_amber_rounded,
      background: const Color(0xFFB45309),
    ),
    AppFeedbackType.info => (
      icon: Icons.info_outline_rounded,
      background: const Color(0xFF0F172A),
    ),
  };
}
