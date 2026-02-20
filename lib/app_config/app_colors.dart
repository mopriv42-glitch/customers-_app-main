import 'package:flutter/material.dart';

class AppColors {
  // Original App Colors (Preserved Identity)
  static const Color blueAppColor = Color(0XFF222338);
  static const Color redAppColor = Color(0XFF954043);
  static const Color yellowAppColor = Color(0XFFFAF6D9);
  static const Color textFiledAppColor = Color.fromARGB(34, 35, 56, 1);

  // Primary Colors (Based on blueAppColor)
  static const Color primary = Color(0XFF222338);
  static const Color primaryLight = Color(0XFF3A3B5A);
  static const Color primaryDark = Color(0XFF1A1B2E);
  static const Color primaryVariant = Color(0XFF4A4B6A);

  // Secondary Colors (Based on redAppColor)
  static const Color secondary = Color(0XFF954043);
  static const Color secondaryLight = Color(0XFFB55A5D);
  static const Color secondaryDark = Color(0XFF7A2F32);
  static const Color secondaryVariant = Color(0XFFD56A6D);

  // Accent Colors (Based on yellowAppColor)
  static const Color accent = Color(0XFFFAF6D9);
  static const Color accentLight = Color(0XFFFFF8E0);
  static const Color accentDark = Color(0XFFF0E8C0);
  static const Color accentVariant = Color(0XFFFFF0B0);

  // Background Colors
  static const Color background = Color(0XFFFFFFFF);
  static const Color backgroundLight = Color(0XFFF8F9FA);
  static const Color backgroundDark = Color(0XFFF1F3F4);

  // Surface Colors
  static const Color surface = Color(0XFFFFFFFF);
  static const Color surfaceLight = Color(0XFFF8F9FA);
  static const Color surfaceDark = Color(0XFFF1F3F4);

  // Text Colors
  static const Color primaryText = Color(0XFF1A1A1A);
  static const Color secondaryText = Color(0XFF666666);
  static const Color disabledText = Color(0XFF999999);
  static const Color inverseText = Color(0XFFFFFFFF);

  // Status Colors
  static const Color success = Color(0XFF4CAF50);
  static const Color warning = Color(0XFFFF9800);
  static const Color error = Color(0XFFF44336);
  static const Color info = Color(0XFF2196F3);

  // Border Colors
  static const Color border = Color(0XFFE0E0E0);
  static const Color borderLight = Color(0XFFF0F0F0);
  static const Color borderDark = Color(0XFFCCCCCC);

  // Shadow Colors
  static const Color shadow = Color(0XFF000000);
  static const Color shadowLight = Color(0XFF000000);

  // Dark Theme Colors
  static const Color darkBackground = Color(0XFF1A1A1A);
  static const Color darkBackgroundLight = Color(0XFF2D2D2D);
  static const Color darkBackgroundDark = Color(0XFF0F0F0F);

  static const Color darkSurface = Color(0XFF2D2D2D);
  static const Color darkSurfaceLight = Color(0XFF3D3D3D);
  static const Color darkSurfaceDark = Color(0XFF1F1F1F);

  static const Color darkPrimaryText = Color(0XFFFFFFFF);
  static const Color darkSecondaryText = Color(0XFFBBBBBB);
  static const Color darkDisabledText = Color(0XFF888888);

  static const Color darkBorder = Color(0XFF444444);
  static const Color darkBorderLight = Color(0XFF555555);
  static const Color darkBorderDark = Color(0XFF333333);

  // Semantic Colors
  static const Color link = Color(0XFF1976D2);
  static const Color linkVisited = Color(0XFF7B1FA2);
  static const Color linkHover = Color(0XFF1565C0);

  // Overlay Colors
  static const Color overlay = Color(0XFF000000);
  static const Color overlayLight = Color(0XFF000000);
  static const Color overlayDark = Color(0XFF000000);

  // Getter methods for theme-aware colors
  static Color getBackgroundColor(bool isDark) => isDark ? darkBackground : background;
  static Color getSurfaceColor(bool isDark) => isDark ? darkSurface : surface;
  static Color getPrimaryTextColor(bool isDark) => isDark ? darkPrimaryText : primaryText;
  static Color getSecondaryTextColor(bool isDark) => isDark ? darkSecondaryText : secondaryText;
  static Color getBorderColor(bool isDark) => isDark ? darkBorder : border;
  
  // Getter for current theme colors
  static ColorScheme getColorScheme(bool isDark) {
    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      tertiary: accent,
      onTertiary: primaryText,
      error: error,
      onError: Colors.white,
      background: getBackgroundColor(isDark),
      onBackground: getPrimaryTextColor(isDark),
      surface: getSurfaceColor(isDark),
      onSurface: getPrimaryTextColor(isDark),
      surfaceVariant: isDark ? darkSurfaceLight : surfaceLight,
      onSurfaceVariant: getSecondaryTextColor(isDark),
      outline: getBorderColor(isDark),
      outlineVariant: isDark ? darkBorderLight : borderLight,
      shadow: shadow,
      scrim: overlay,
      inverseSurface: isDark ? surface : darkSurface,
      onInverseSurface: isDark ? primaryText : darkPrimaryText,
      inversePrimary: isDark ? primaryLight : primaryDark,
      surfaceTint: primary.withValues(alpha: 0.05),
    );
  }
}
