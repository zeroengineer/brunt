import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Dark-only theme (spec §1): black, blue accent, Manrope.
ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: BColors.primary,
    onPrimary: BColors.text,
    secondary: BColors.primaryLight,
    onSecondary: BColors.bg,
    surface: BColors.surface,
    onSurface: BColors.text,
    error: BColors.danger,
    onError: BColors.bg,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: BText.family,
    scaffoldBackgroundColor: BColors.bg,
    canvasColor: BColors.bg,
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: BColors.text, displayColor: BColors.text, fontFamily: BText.family),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, foregroundColor: BColors.text, elevation: 0),
    dividerTheme: const DividerThemeData(color: BColors.border, thickness: 1, space: 1),
    iconTheme: const IconThemeData(color: BColors.text, size: 22),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: BColors.primaryLight,
      selectionColor: BColors.primary.withValues(alpha: 0.5),
      selectionHandleColor: BColors.primaryLight,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: BColors.primaryLight, textStyle: BText.label),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BColors.primary,
      foregroundColor: BColors.text,
      shape: CircleBorder(),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: BColors.surface,
      headerBackgroundColor: BColors.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BRadius.card)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: BColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BRadius.card)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: BColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BRadius.card)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: BColors.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: BText.body,
    ),
    listTileTheme: const ListTileThemeData(iconColor: BColors.primaryLight, textColor: BColors.text),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: BColors.primaryLight),
  );
}
