import 'package:material_ui/material_ui.dart';

/// Spacing scale from the design theme.
abstract final class Sp {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Corner radii from the design theme.
abstract final class Rad {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

/// Hard "Duolingo" drop shadows (no blur) from the design theme.
abstract final class Shadows {
  static const sm = [BoxShadow(color: Color(0x1A000000), offset: Offset(0, 2))];
  static const md = [BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4))];
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 120);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 700);
  static const emphasized = Curves.easeOutBack;
}
