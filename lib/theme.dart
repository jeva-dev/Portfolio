import 'package:flutter/material.dart';

abstract final class Palette {
  static const ink = Color(0xFF0C0E11);
  static const panel = Color(0xFF13161B);
  static const line = Color(0xFF2A3038);
  static const paper = Color(0xFFECE9E1);
  static const muted = Color(0xFF979CA5);
  static const amber = Color(0xFFFFB224);
  static const teal = Color(0xFF5FD4C4);
  static const coral = Color(0xFFFF6B4A);
}

/// Archivo and JetBrains Mono ship as variable fonts, so every weight goes
/// through font variations. That is also what lets the hero animate them.
abstract final class Fonts {
  static TextStyle display(
    double size, {
    double wght = 800,
    double wdth = 100,
    Color color = Palette.paper,
    double height = 1.0,
    double tracking = -0.02,
  }) {
    return TextStyle(
      fontFamily: 'Archivo',
      fontSize: size,
      height: height,
      letterSpacing: size * tracking,
      color: color,
      fontVariations: [
        FontVariation('wght', wght),
        FontVariation('wdth', wdth),
      ],
    );
  }

  static TextStyle body(
    double size, {
    Color color = Palette.paper,
    double wght = 400,
  }) {
    return TextStyle(
      fontFamily: 'Archivo',
      fontSize: size,
      height: 1.55,
      color: color,
      fontVariations: [FontVariation('wght', wght)],
    );
  }

  static TextStyle mono(
    double size, {
    Color color = Palette.muted,
    double wght = 400,
    double height = 1.5,
    double tracking = 0,
  }) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: size,
      height: height,
      letterSpacing: size * tracking,
      color: color,
      fontVariations: [FontVariation('wght', wght)],
      fontFeatures: const [FontFeature.disable('liga')],
    );
  }
}

abstract final class Motion {
  /// Fast launch and a long settle. Used by nearly every entrance.
  static const settle = Cubic(0.16, 1, 0.3, 1);
}

abstract final class Layout {
  static const maxWidth = 1240.0;
  static const wide = 900.0;

  static double gutter(double width) => width < 600 ? 20 : 48;
}

ThemeData buildTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Palette.ink,
    colorScheme: const ColorScheme.dark(
      primary: Palette.amber,
      secondary: Palette.teal,
      surface: Palette.panel,
      onSurface: Palette.paper,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Palette.amber,
      selectionColor: Palette.amber.withValues(alpha: 0.3),
    ),
    fontFamily: 'Archivo',
  );
}
