import 'package:flutter/material.dart';

ButtonStyle destructiveIconButtonStyle(ColorScheme colors) {
  return IconButton.styleFrom(foregroundColor: colors.error);
}

ButtonStyle destructiveOutlinedButtonStyle(ColorScheme colors) {
  return OutlinedButton.styleFrom(foregroundColor: colors.error).copyWith(
    side: WidgetStateProperty.resolveWith<BorderSide>(
      (Set<WidgetState> states) => BorderSide(
        color: states.contains(WidgetState.disabled)
            ? colors.onSurface.withValues(alpha: 0.12)
            : colors.error,
      ),
    ),
  );
}

ButtonStyle destructiveFilledButtonStyle(ColorScheme colors) {
  return FilledButton.styleFrom(
    backgroundColor: colors.error,
    foregroundColor: colors.onError,
  );
}
