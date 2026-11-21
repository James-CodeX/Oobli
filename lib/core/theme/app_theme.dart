import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'oobli_colors.dart';
import 'oobli_text.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(OobliColors.light, Brightness.light);
  static ThemeData dark() => _build(OobliColors.dark, Brightness.dark);

  static ThemeData _build(OobliColors c, Brightness brightness) {
    final text = OobliText(color: c.primaryText);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.secondary,
      onSecondary: c.onSecondary,
      tertiary: c.accent,
      onTertiary: c.onAccent,
      error: c.error,
      onError: c.onError,
      surface: c.surface,
      onSurface: c.onSurface,
      surfaceContainerHighest: c.surfaceVariant,
      onSurfaceVariant: c.onSurfaceVariant,
      outline: c.outline,
      outlineVariant: c.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: OobliFonts.family,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: c.divider,
      extensions: [c, text],
      textTheme: TextTheme(
        displayLarge: text.displayLarge,
        displayMedium: text.displayMedium,
        displaySmall: text.displaySmall,
        headlineLarge: text.headlineLarge,
        headlineMedium: text.headlineMedium,
        headlineSmall: text.headlineSmall,
        titleLarge: text.titleLarge,
        titleMedium: text.titleMedium,
        titleSmall: text.titleSmall,
        bodyLarge: text.bodyLarge,
        bodyMedium: text.bodyMedium,
        bodySmall: text.bodySmall,
        labelLarge: text.labelLarge,
        labelMedium: text.labelMedium,
        labelSmall: text.labelSmall,
      ),
      iconTheme: IconThemeData(color: c.primaryText),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.3),
        selectionHandleColor: c.primary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.surfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.xxl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: Rad.all(Rad.xl)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium.copyWith(color: c.secondaryText),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceVariant,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: Rad.all(Rad.md)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onPrimary : c.secondaryText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.surfaceVariant,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.surfaceVariant,
        thumbColor: c.primary,
        overlayColor: c.primary.withValues(alpha: 0.15),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: c.secondaryBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
    );
  }
}

extension ThemeContext on BuildContext {
  OobliColors get colors => Theme.of(this).extension<OobliColors>()!;
  OobliText get text => Theme.of(this).extension<OobliText>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
