import 'package:material_ui/material_ui.dart';

/// Design tokens from the Oobli theme (light + dark), exposed as a
/// [ThemeExtension] so widgets read them with `context.colors`.
@immutable
class OobliColors extends ThemeExtension<OobliColors> {
  const OobliColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.background,
    required this.onBackground,
    required this.secondaryBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.primaryText,
    required this.secondaryText,
    required this.hint,
    required this.outline,
    required this.divider,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.error,
    required this.onError,
    required this.info,
    required this.fullContrast,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color background;
  final Color onBackground;
  final Color secondaryBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color primaryText;
  final Color secondaryText;
  final Color hint;
  final Color outline;
  final Color divider;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color error;
  final Color onError;
  final Color info;
  final Color fullContrast;

  static const light = OobliColors(
    primary: Color(0xFF58CC02),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0x1A58CC02),
    onPrimaryContainer: Color(0xFF4B4B4B),
    secondary: Color(0xFF1CB0F6),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0x1A1CB0F6),
    accent: Color(0xFFFFC800),
    onAccent: Color(0xFF000000),
    accentContainer: Color(0x1AFFC800),
    background: Color(0xFFFFFFFF),
    onBackground: Color(0xFF4B4B4B),
    secondaryBackground: Color(0xFFF7F7F7),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF4B4B4B),
    surfaceVariant: Color(0xFFE5E5E5),
    onSurfaceVariant: Color(0xFF777777),
    primaryText: Color(0xFF4B4B4B),
    secondaryText: Color(0xFF777777),
    hint: Color(0xFFAFAFAF),
    outline: Color(0xFFE5E5E5),
    divider: Color(0xFFE5E5E5),
    success: Color(0xFF58CC02),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFFF9600),
    onWarning: Color(0xFFFFFFFF),
    error: Color(0xFFEA2B2B),
    onError: Color(0xFFFFFFFF),
    info: Color(0xFF1CB0F6),
    fullContrast: Color(0xFF000000),
  );

  static const dark = OobliColors(
    primary: Color(0xFF78D937),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0x2478D937),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFF49C0F8),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0x2449C0F8),
    accent: Color(0xFFFFD933),
    onAccent: Color(0xFF000000),
    accentContainer: Color(0x24FFD933),
    background: Color(0xFF131F24),
    onBackground: Color(0xFFFFFFFF),
    secondaryBackground: Color(0xFF202F36),
    surface: Color(0xFF202F36),
    onSurface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFF37464F),
    onSurfaceVariant: Color(0xFFAFAFAF),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFAFAFAF),
    hint: Color(0xFF777777),
    outline: Color(0xFF37464F),
    divider: Color(0xFF37464F),
    success: Color(0xFF78D937),
    onSuccess: Color(0xFF000000),
    warning: Color(0xFFFFB340),
    onWarning: Color(0xFF000000),
    error: Color(0xFFFF4B4B),
    onError: Color(0xFFFFFFFF),
    info: Color(0xFF49C0F8),
    fullContrast: Color(0xFFFFFFFF),
  );

  @override
  OobliColors copyWith() => this;

  @override
  OobliColors lerp(OobliColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return OobliColors(
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      onPrimaryContainer: l(onPrimaryContainer, other.onPrimaryContainer),
      secondary: l(secondary, other.secondary),
      onSecondary: l(onSecondary, other.onSecondary),
      secondaryContainer: l(secondaryContainer, other.secondaryContainer),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentContainer: l(accentContainer, other.accentContainer),
      background: l(background, other.background),
      onBackground: l(onBackground, other.onBackground),
      secondaryBackground: l(secondaryBackground, other.secondaryBackground),
      surface: l(surface, other.surface),
      onSurface: l(onSurface, other.onSurface),
      surfaceVariant: l(surfaceVariant, other.surfaceVariant),
      onSurfaceVariant: l(onSurfaceVariant, other.onSurfaceVariant),
      primaryText: l(primaryText, other.primaryText),
      secondaryText: l(secondaryText, other.secondaryText),
      hint: l(hint, other.hint),
      outline: l(outline, other.outline),
      divider: l(divider, other.divider),
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      warning: l(warning, other.warning),
      onWarning: l(onWarning, other.onWarning),
      error: l(error, other.error),
      onError: l(onError, other.onError),
      info: l(info, other.info),
      fullContrast: l(fullContrast, other.fullContrast),
    );
  }
}

/// Semantic colour roles used by cards, tiles, charts and chips.
enum Tone { primary, success, secondary, accent, warning, error, info, neutral }

extension ToneColors on OobliColors {
  Color tone(Tone tone) => switch (tone) {
        Tone.primary => primary,
        Tone.success => success,
        Tone.secondary => secondary,
        Tone.accent => accent,
        Tone.warning => warning,
        Tone.error => error,
        Tone.info => info,
        Tone.neutral => hint,
      };

  Color onTone(Tone tone) => switch (tone) {
        Tone.primary => onPrimary,
        Tone.success => onSuccess,
        Tone.secondary => onSecondary,
        Tone.accent => onAccent,
        Tone.warning => onWarning,
        Tone.error => onError,
        Tone.info => onSecondary,
        Tone.neutral => background,
      };

  Color toneContainer(Tone tone) => this.tone(tone).withValues(alpha: 0.14);
}
