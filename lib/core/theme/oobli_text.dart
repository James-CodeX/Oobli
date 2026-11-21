import 'package:material_ui/material_ui.dart';

abstract final class OobliFonts {
  static const primary = 'Outfit';
  static const secondary = 'Nunito';
  static const mono = 'SpaceGrotesk';
}

/// Text styles from the design theme (colourless; colour is applied by the
/// theme's default text colour or explicitly at the call site).
@immutable
class OobliText extends ThemeExtension<OobliText> {
  const OobliText({required this.color});

  final Color color;

  TextStyle _s(String family, double size, FontWeight weight, double height) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
        letterSpacing: family == OobliFonts.primary ? -0.2 : 0,
      );

  TextStyle get displayLarge => _s(OobliFonts.primary, 58, FontWeight.w800, 1.1);
  TextStyle get displayMedium => _s(OobliFonts.primary, 46, FontWeight.w800, 1.15);
  TextStyle get displaySmall => _s(OobliFonts.primary, 38, FontWeight.w800, 1.2);
  TextStyle get headlineLarge => _s(OobliFonts.primary, 32, FontWeight.w700, 1.2);
  TextStyle get headlineMedium => _s(OobliFonts.primary, 26, FontWeight.w700, 1.25);
  TextStyle get headlineSmall => _s(OobliFonts.primary, 24, FontWeight.w700, 1.3);
  TextStyle get titleLarge => _s(OobliFonts.secondary, 20, FontWeight.w700, 1.3);
  TextStyle get titleMedium => _s(OobliFonts.secondary, 17, FontWeight.w700, 1.35);
  TextStyle get titleSmall => _s(OobliFonts.secondary, 14, FontWeight.w700, 1.4);
  TextStyle get bodyLarge => _s(OobliFonts.secondary, 17, FontWeight.w500, 1.5);
  TextStyle get bodyMedium => _s(OobliFonts.secondary, 15, FontWeight.w500, 1.5);
  TextStyle get bodySmall => _s(OobliFonts.secondary, 13, FontWeight.w500, 1.5);
  TextStyle get labelLarge => _s(OobliFonts.mono, 14, FontWeight.w600, 1.3);
  TextStyle get labelMedium => _s(OobliFonts.mono, 12, FontWeight.w600, 1.3);
  TextStyle get labelSmall => _s(OobliFonts.mono, 10, FontWeight.w600, 1.3);

  @override
  OobliText copyWith({Color? color}) => OobliText(color: color ?? this.color);

  @override
  OobliText lerp(OobliText? other, double t) =>
      other == null ? this : OobliText(color: Color.lerp(color, other.color, t)!);
}
