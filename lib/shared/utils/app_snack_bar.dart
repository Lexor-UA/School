import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Centralized utility for presenting clean, non-spammy floating notifications.
///
/// Features:
/// - Immediately clears any queued snackbars ([clearSnackBars]) to prevent notification queues
/// - Throttles identical messages within 1.2s to prevent rapid multi-tap spam
/// - Floating aesthetic with rounded corners and bottom offset above navigation bars
/// - Snappy duration (2.2s) instead of the sluggish default (4s)
class AppSnackBar {
  static DateTime _lastShowTime = DateTime.fromMillisecondsSinceEpoch(0);
  static String? _lastMessage;

  static void show(
    BuildContext context, {
    required String message,
    Color backgroundColor = const Color(0xFFD97706),
    Duration duration = const Duration(milliseconds: 2200),
    SnackBarAction? action,
    IconData? icon,
    double bottomMargin = 84,
  }) {
    if (!context.mounted) return;

    final now = DateTime.now();
    // Throttle identical messages fired within 1200ms
    if (_lastMessage == message && now.difference(_lastShowTime).inMilliseconds < 1200) {
      return;
    }
    _lastShowTime = now;
    _lastMessage = message;

    final messenger = ScaffoldMessenger.of(context);
    // Instantly wipe all pending and active snackbars to prevent spam queueing
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: bottomMargin, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        action: action,
      ),
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    double bottomMargin = 84,
  }) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFFD97706),
      icon: LucideIcons.triangleAlert,
      action: action,
      bottomMargin: bottomMargin,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    double bottomMargin = 84,
  }) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFFEF4444),
      icon: LucideIcons.circleAlert,
      action: action,
      bottomMargin: bottomMargin,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    double bottomMargin = 84,
  }) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFF10B981),
      icon: LucideIcons.checkCircle2,
      action: action,
      bottomMargin: bottomMargin,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    double bottomMargin = 84,
  }) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFF0284C7),
      icon: LucideIcons.info,
      action: action,
      bottomMargin: bottomMargin,
    );
  }
}
