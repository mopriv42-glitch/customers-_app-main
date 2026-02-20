import 'package:flutter/material.dart';
import 'package:private_4t_app/core/theme/colors/castle_colors.dart';

class AppThemes {
  // Private brand themes (renamed from light/dark)
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF482099),
      brightness: Brightness.light,
    ).copyWith(background: const Color(0xFFF9F6D9), surface: Colors.white),
    scaffoldBackgroundColor: const Color(0xFFF9F6D9),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF482099),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(color: Colors.black87),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF24104C)),
      bodyMedium: TextStyle(color: Color(0xFF24104C)),
      bodySmall: TextStyle(color: Color(0xFF694731)),
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B3BC7),
          brightness: Brightness.dark,
        ).copyWith(
          background: const Color(0xFF1A1A1A),
          surface: const Color(0xFF2D2D2D),
        ),
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF6B3BC7),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Color(0xFFBBBBBB)),
    ),
  );

  // Castle brand themes
  static final castleLight = ThemeData(
    useMaterial3: true,
    colorScheme: CastleColors.lightColorScheme,
    scaffoldBackgroundColor: CastleColors.lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: CastleColors.primary,
      foregroundColor: CastleColors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: CastleColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: CastleColors.textPrimary),
      bodyMedium: TextStyle(color: CastleColors.textPrimary),
      bodySmall: TextStyle(color: CastleColors.textSecondary),
      headlineLarge: TextStyle(color: CastleColors.textPrimary),
      headlineMedium: TextStyle(color: CastleColors.textPrimary),
      headlineSmall: TextStyle(color: CastleColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CastleColors.primary,
        foregroundColor: CastleColors.white,
        elevation: 2,
      ),
    ),
    primarySwatch: MaterialColor(CastleColors.primary.value, <int, Color>{
      50: CastleColors.primary.withOpacity(0.1),
      100: CastleColors.primary.withOpacity(0.2),
      200: CastleColors.primary.withOpacity(0.3),
      300: CastleColors.primary.withOpacity(0.4),
      400: CastleColors.primary.withOpacity(0.5),
      500: CastleColors.primary,
      600: CastleColors.secondary,
      700: CastleColors.dark,
      800: CastleColors.dark.withOpacity(0.8),
      900: CastleColors.dark.withOpacity(0.9),
    }),
  );

  static final castleDark = ThemeData(
    useMaterial3: true,
    colorScheme: CastleColors.darkColorScheme,
    scaffoldBackgroundColor: CastleColors.darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: CastleColors.primary,
      foregroundColor: CastleColors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: CastleColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: CastleColors.textDark),
      bodyMedium: TextStyle(color: CastleColors.textDark),
      bodySmall: TextStyle(color: CastleColors.textSecondaryDark),
      headlineLarge: TextStyle(color: CastleColors.textDark),
      headlineMedium: TextStyle(color: CastleColors.textDark),
      headlineSmall: TextStyle(color: CastleColors.textDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CastleColors.primary,
        foregroundColor: CastleColors.white,
        elevation: 2,
      ),
    ),
    primarySwatch: MaterialColor(CastleColors.primary.value, <int, Color>{
      50: CastleColors.primary.withOpacity(0.1),
      100: CastleColors.primary.withOpacity(0.2),
      200: CastleColors.primary.withOpacity(0.3),
      300: CastleColors.primary.withOpacity(0.4),
      400: CastleColors.primary.withOpacity(0.5),
      500: CastleColors.primary,
      600: CastleColors.secondary,
      700: CastleColors.dark,
      800: CastleColors.dark.withOpacity(0.8),
      900: CastleColors.dark.withOpacity(0.9),
    }),
  );
}
