// lib/utils/toast.dart
import 'package:flutter/material.dart';

void showToast(
  BuildContext context, {
  required String title,
  required String description,
  bool isError = false,
  IconData? icon,
  Duration duration = const Duration(seconds: 3),
}) {
  final t = Theme.of(context);
  final color = isError ? t.colorScheme.error : t.colorScheme.primary;

  final toastIcon =
      icon ?? (isError ? Icons.error_outline : Icons.check_circle_outline);

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: duration,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(toastIcon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: t.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: t.textTheme.bodySmall?.copyWith(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
