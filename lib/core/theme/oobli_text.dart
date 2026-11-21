import 'package:material_ui/material_ui.dart';

/// One geometric family throughout (like modern Kenyan banking apps).
/// Poppins is the closest open-licence match to Gilroy; swapping the family
/// here (and in pubspec.yaml) re-skins the whole app.
abstract final class OobliFonts {
  static const family = 'Poppins';
}

/// Compact type scale. Colourless by default (the theme supplies colour);
/// call sites tint with `copyWith(color: ...)`.
@immutable
class OobliText extends ThemeExtension<OobliText> {
  const OobliText({required this.color});

  final Color color;

  TextStyle _s(double size, FontWeight weight, double height, {double tracking = 0}) => TextStyle(
        fontFamily: OobliFonts.family,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
        letterSpacing: tracking,
      );

  // Display / headlines: tight tracking for a confident, compact look.
  TextStyle get displayLarge => _s(40, FontWeight.w800, 1.1, tracking: -1);
  TextStyle get displayMedium => _s(34, FontWeight.w800, 1.12, tracking: -0.8);
  TextStyle get displaySmall => _s(30, FontWeight.w700, 1.15, tracking: -0.6);
  TextStyle get headlineLarge => _s(26, FontWeight.w700, 1.2, tracking: -0.5);
  TextStyle get headlineMedium => _s(22, FontWeight.w700, 1.25, tracking: -0.4);
  TextStyle get headlineSmall => _s(19, FontWeight.w600, 1.3, tracking: -0.2);

  // Titles: list rows, card headers.
  TextStyle get titleLarge => _s(16, FontWeight.w600, 1.35, tracking: -0.1);
  TextStyle get titleMedium => _s(15, FontWeight.w600, 1.35);
  TextStyle get titleSmall => _s(13, FontWeight.w600, 1.4);

  // Body.
  TextStyle get bodyLarge => _s(14, FontWeight.w400, 1.5);
  TextStyle get bodyMedium => _s(13, FontWeight.w400, 1.5);
  TextStyle get bodySmall => _s(12, FontWeight.w400, 1.45);

  // Labels: buttons, chips, captions.
  TextStyle get labelLarge => _s(13, FontWeight.w600, 1.3, tracking: 0.1);
  TextStyle get labelMedium => _s(11, FontWeight.w500, 1.3, tracking: 0.1);
  TextStyle get labelSmall => _s(10, FontWeight.w500, 1.3, tracking: 0.2);

  @override
  OobliText copyWith({Color? color}) => OobliText(color: color ?? this.color);

  @override
  OobliText lerp(OobliText? other, double t) =>
      other == null ? this : OobliText(color: Color.lerp(color, other.color, t)!);
}
