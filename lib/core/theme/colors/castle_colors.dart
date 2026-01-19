import 'package:flutter/material.dart';

class CastleColors {
  // Castle brand colors
  static const Color primary = Color(0xFFa30218);
  static const Color secondary = Color(0xFFc3021f);
  static const Color accent = Color(0xFF9c865a);
  static const Color dark = Color(0xFF880e21);
  static const Color white = Color(0xFFffffff);

  // Additional Castle theme colors
  static const Color lightBackground = Color(0xFFf8f8f8);
  static const Color darkBackground = Color(0xFF1a1a1a);
  static const Color surface = Color(0xFFffffff);
  static const Color surfaceDark = Color(0xFF2d2d2d);
  static const Color textPrimary = Color(0xFF2c2c2c);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textDark = Color(0xFFffffff);
  static const Color textSecondaryDark = Color(0xFFbbbbbb);

  // Castle color scheme for light theme
  static const ColorScheme lightColorScheme = ColorScheme.light(
    primary: primary,
    secondary: secondary,
    tertiary: accent,
    surface: surface,
    background: lightBackground,
    error: Color(0xFFd32f2f),
    onPrimary: white,
    onSecondary: white,
    onTertiary: white,
    onSurface: textPrimary,
    onBackground: textPrimary,
    onError: white,
  );

  // Castle color scheme for dark theme
  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: primary,
    secondary: secondary,
    tertiary: accent,
    surface: surfaceDark,
    background: darkBackground,
    error: Color(0xFFd32f2f),
    onPrimary: white,
    onSecondary: white,
    onTertiary: white,
    onSurface: textDark,
    onBackground: textDark,
    onError: white,
  );
}
