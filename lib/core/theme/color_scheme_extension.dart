// lib/core/theme/color_scheme_extension.dart
import 'package:flutter/material.dart';

extension AppColorSchemeExtension on ColorScheme {
  // Brand & accents
  Color get primaryAccent => brightness == Brightness.dark
      ? const Color(0xFF6B3BC7) // darkPrimary
      : const Color(0xFF482099); // primary

  Color get secondaryAccent => brightness == Brightness.dark
      ? const Color(0xFFB07A5A) // darkSecondary
      : const Color(0xFF8C6042); // secondary

  Color get accentPrimary => brightness == Brightness.dark
      ? const Color(0xFFFFC766) // darkAccent
      : const Color(0xFFFFB547); // accent

  Color get accentSecondary => brightness == Brightness.dark
      ? const Color(0xFF2BC4BD) // darkAccentSecondary
      : const Color(0xFF1BA39C); // accentSecondary

  // Surfaces & backgrounds
  Color get appBackground => brightness == Brightness.dark
      ? const Color(0xFF1A1A1A) // darkBackground
      : const Color(0xFFF9F6D9); // background

  Color get appSurface => brightness == Brightness.dark
      ? const Color(0xFF2D2D2D) // darkSurface
      : const Color(0xFFFFFFFF); // surface

  // Text colors
  Color get primaryText => brightness == Brightness.dark
      ? const Color(0xFFFFFFFF) // darkPrimaryText
      : const Color(0xFF24104C); // primaryText

  Color get secondaryText => brightness == Brightness.dark
      ? const Color(0xFFBBBBBB) // darkSecondaryText
      : const Color(0xFF694731); // secondaryText

  Color get textOnPrimaryAccent => brightness == Brightness.dark
      ? const Color(0xFF000000) // darkTextOnPrimary
      : const Color(0xFFFFFFFF); // textOnPrimary

  Color get textOnAccentPrimary => brightness == Brightness.dark
      ? const Color(0xFFFFFFFF) // darkTextOnAccent
      : const Color(0xFF24104C); // textOnAccent

  // System colors (static)
  Color get success => const Color(0xFF28A745);
  Color get warning => const Color(0xFFFFC107);
  Color get error => const Color(0xFFDC3545);
  Color get disabled => brightness == Brightness.dark
      ? const Color(0xFFD3D3D3).withOpacity(0.7)
      : const Color(0xFFD3D3D3);

  // Additional colors
  Color get surfaceLight => brightness == Brightness.dark
      ? const Color(0xFF2D2D2D) // darkSurface
      : const Color(0xFFF8F9FA); // surfaceLight

  Color get shadow => const Color(0xFF000000);
}