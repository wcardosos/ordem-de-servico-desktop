import 'package:flutter/material.dart';

enum SnackBarKind { success, warning, error }

const Color _successColor = Color(0xFF2E7D32);
const Color _warningColor = Color(0xFFE65100);

Color snackBarColor(SnackBarKind kind, ColorScheme colors) {
  return switch (kind) {
    SnackBarKind.success => _successColor,
    SnackBarKind.warning => _warningColor,
    SnackBarKind.error => colors.error,
  };
}

Color _snackBarForegroundColor(SnackBarKind kind, ColorScheme colors) {
  return switch (kind) {
    SnackBarKind.success || SnackBarKind.warning => Colors.white,
    SnackBarKind.error => colors.onError,
  };
}

IconData snackBarIcon(SnackBarKind kind) {
  return switch (kind) {
    SnackBarKind.success => Icons.check_circle_outline,
    SnackBarKind.warning => Icons.warning_amber_rounded,
    SnackBarKind.error => Icons.error_outline,
  };
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  required SnackBarKind kind,
}) {
  final ColorScheme colors = Theme.of(context).colorScheme;
  final Color foreground = _snackBarForegroundColor(kind, colors);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBarColor(kind, colors),
        content: Row(
          children: <Widget>[
            Icon(snackBarIcon(kind), color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
}
