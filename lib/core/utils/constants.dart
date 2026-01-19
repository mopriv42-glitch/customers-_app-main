import 'package:flutter/material.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:riverpod_context/riverpod_context.dart';

/// Centralised app-wide constants and design tokens
class Constants {
  static const appName = 'Your App Name';
  static const baseUrl = 'https://api.yourdomain.com/v1/';
}

/// Semantic color tokens based on the approved design system
class AppColors {
  // Brand & accents - Light Theme
  static const _primary = Color(0xFF482099); // color-primary-default
  static const _secondary = Color(0xFF8C6042); // color-secondary-default
  static const _accent = Color(0xFFFFB547); // color-accent-primary
  static const _accentSecondary = Color(0xFF1BA39C); // color-accent-secondary

  // Surfaces & text - Light Theme
  static const _background = Color(0xFFF9F6D9); // color-background-default
  static const _surface = Color(0xFFFFFFFF); // color-surface-default
  static const _primaryText = Color(0xFF24104C); // color-text-primary
  static const _secondaryText = Color(0xFF694731); // color-text-secondary
  static const _textOnPrimary = Color(0xFFFFFFFF); // color-text-on-primary
  static const _textOnAccent = Color(0xFF24104C); // color-text-on-accent

  // System & states - Light Theme
  static const _success = Color(0xFF28A745); // color-system-success
  static const _warning = Color(0xFFFFC107); // color-system-warning
  static const _error = Color(0xFFDC3545); // color-system-error
  static const _disabled = Color(0xFFD3D3D3); // color-state-disabled

  // Additional colors needed for theme provider
  static const _primaryLight = Color(0xFF6B3BC7); // Lighter version of primary
  static const _primaryDark = Color(0xFF2D1B4D); // Darker version of primary
  static const _primaryVariant = Color(0xFF8B5CF6); // Variant of primary
  static const _surfaceLight = Color(0xFFF8F9FA); // Light surface variant
  static const _shadow = Color(0xFF000000); // Shadow color

  // Dark Theme Colors - Derived from light theme
  static const _darkPrimary = Color(0xFF6B3BC7); // Lighter version of primary
  static const _darkSecondary = Color(
    0xFFB07A5A,
  ); // Lighter version of secondary
  static const _darkAccent = Color(0xFFFFC766); // Lighter version of accent
  static const _darkAccentSecondary = Color(
    0xFF2BC4BD,
  ); // Lighter version of accentSecondary

  static const _darkBackground = Color(0xFF1A1A1A); // Dark background
  static const _darkSurface = Color(0xFF2D2D2D); // Dark surface
  static const _darkPrimaryText = Color(0xFFFFFFFF); // White text on dark
  static const _darkSecondaryText = Color(0xFFBBBBBB); // Light gray text
  static const _darkTextOnPrimary = Color(
    0xFF000000,
  ); // Black text on light primary
  static const _darkTextOnAccent = Color(
    0xFFFFFFFF,
  ); // White text on dark accent

  // --- Helper to get current theme mode dynamically ---
  // This is the key change. It fetches the current theme state from the provider.
  // Ensure NavigationService.rootNavigatorKey and ApiProviders.themeProvider are correctly set up.
  static ThemeMode _getCurrentThemeMode() {
    // Get the current context from the global navigator key
    final context = NavigationService.rootNavigatorKey.currentContext;
    if (context != null) {
      // Use context.read to get the current state of the theme provider
      // context.read does not rebuild the widget but gets the current value
      try {
        return context.read(ApiProviders.themeProvider);
      } catch (e) {
        // Handle potential errors if the provider isn't available in context yet
        // Fallback to light mode or handle appropriately
        debugPrint("Error reading theme provider: $e");
        return ThemeMode.light; // Or a default/fallback
      }
    }
    // Fallback if context is null (e.g., called very early)
    return ThemeMode.light; // Or a default/fallback
  }

  // --- Theme-aware getters that now dynamically check the theme ---
  // These getters now call _getCurrentThemeMode() every time they are accessed.
  static Color get primary =>
      _getCurrentThemeMode() == ThemeMode.dark ? _darkPrimary : _primary;
  static Color get border =>
      _getCurrentThemeMode() == ThemeMode.dark ? _darkPrimary : _primary;
  static Color get secondary =>
      _getCurrentThemeMode() == ThemeMode.dark ? _darkSecondary : _secondary;
  static Color get accent =>
      _getCurrentThemeMode() == ThemeMode.dark ? _darkAccent : _accent;
  static Color get accentSecondary => _getCurrentThemeMode() == ThemeMode.dark
      ? _darkAccentSecondary
      : _accentSecondary;

  static Color get background =>
      _getCurrentThemeMode() == ThemeMode.dark ? _darkBackground : _background;
  static Color get surface =>
      _getCurrentThemeMode() == ThemeMode.dark ? _darkSurface : _surface;
  static Color get primaryText => _getCurrentThemeMode() == ThemeMode.dark
      ? _darkPrimaryText
      : _primaryText;
  static Color get secondaryText => _getCurrentThemeMode() == ThemeMode.dark
      ? _darkSecondaryText
      : _secondaryText;
  static Color get textOnPrimary => _getCurrentThemeMode() == ThemeMode.dark
      ? _darkTextOnPrimary
      : _textOnPrimary;
  static Color get textOnAccent => _getCurrentThemeMode() == ThemeMode.dark
      ? _darkTextOnAccent
      : _textOnAccent;

  // System colors usually stay the same, but you can make them dynamic if needed
  static Color get success => _success;
  static Color get warning => _warning;
  static Color get error => _error;
  static Color get disabled => (_getCurrentThemeMode() == ThemeMode.dark
      ? _disabled.withOpacity(0.7)
      : _disabled);

  // Additional getters (make dynamic if needed)
  static Color get primaryLight => _primaryLight;
  static Color get primaryDark => _primaryDark;
  static Color get primaryVariant => _primaryVariant;
  static Color get surfaceLight =>
      _getCurrentThemeMode() == ThemeMode.dark ? _darkSurface : _surfaceLight;
  static Color get shadow => _shadow;

  // Theme detection helper
  static bool _isDarkMode =
      NavigationService.rootNavigatorKey.currentContext?.read(
        ApiProviders.themeProvider,
      ) ==
      ThemeMode.dark;

  // Method to update theme mode
  static void setThemeMode(bool isDark) {
    _isDarkMode = isDark;
  }

  // Method to get current theme mode
  static bool get isDarkMode => _isDarkMode;

  // Method to toggle theme
  static void toggleTheme() {
    _isDarkMode = !_isDarkMode;
  }

  // Method to get color scheme for theme provider
  static ColorScheme getColorScheme(bool isDark) {
    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: _primary,
      onPrimary: Colors.white,
      secondary: _secondary,
      onSecondary: Colors.white,
      tertiary: _accent,
      onTertiary: _primaryText,
      error: _error,
      onError: Colors.white,
      background: isDark ? _darkBackground : _background,
      onBackground: isDark ? _darkPrimaryText : _primaryText,
      surface: isDark ? _darkSurface : _surface,
      onSurface: isDark ? _darkPrimaryText : _primaryText,
      surfaceVariant: isDark ? _darkSurface : _surfaceLight,
      onSurfaceVariant: isDark ? _darkSecondaryText : _secondaryText,
      outline: isDark ? _darkSurface : _surface,
      outlineVariant: isDark ? _darkSurface : _surfaceLight,
      shadow: _shadow,
      scrim: _shadow.withOpacity(0.5),
      inverseSurface: isDark ? _surface : _darkSurface,
      onInverseSurface: isDark ? _primaryText : _darkPrimaryText,
      inversePrimary: isDark ? _primaryLight : _primaryDark,
      surfaceTint: _primary.withOpacity(0.05),
    );
  }
}
