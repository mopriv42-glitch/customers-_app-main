// lib/core/extensions/context_extension.dart
import 'package:flutter/material.dart';
import '../theme/color_scheme_extension.dart';
import 'package:private_4t_app/core/theme/colors/castle_colors.dart';
import 'package:riverpod_context/riverpod_context.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/providers/theme_provider.dart';

extension ThemeExtensions on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  bool get _isCastleBrand {
    final themeNotifier = read(ApiProviders.themeProvider.notifier);
    return themeNotifier.currentBrand == BrandTheme.castle;
  }

  // Brand & accents
  Color get primary => _isCastleBrand ? CastleColors.primary : colors.primary;
  Color get primaryAccent =>
      _isCastleBrand ? CastleColors.primary : colors.primaryAccent;
  Color get secondary =>
      _isCastleBrand ? CastleColors.secondary : colors.secondaryAccent;
  Color get accentPrimary => colors.accentPrimary;
  Color get accent => colors.accentPrimary;
  Color get accentSecondary =>
      _isCastleBrand ? CastleColors.secondary : colors.accentSecondary;

  // Surfaces & backgrounds
  Color get background => _isCastleBrand
      ? const Color.fromARGB(255, 216, 185, 123)
      : colors.appBackground;
  Color get surface =>
      _isCastleBrand ? CastleColors.surface : colors.appSurface;

  // Text colors
  Color get primaryText => colors.primaryText;
  Color get secondaryText => colors.secondaryText;
  Color get textOnPrimary => colors.textOnPrimaryAccent;
  Color get textOnAccent => colors.textOnAccentPrimary;

  // System colors
  Color get success => colors.success;
  Color get warning => colors.warning;
  Color get error => colors.error;
  Color get disabled => colors.disabled;

  // Additional
  Color get surfaceLight => colors.surfaceLight;
  Color get shadow => colors.shadow;
  Color get border => _isCastleBrand ? CastleColors.primary : colors.primary;

  // Castle brand constants (useful when you need exact Castle palette)
  Color get castlePrimary => CastleColors.primary;
  Color get castleSecondary => CastleColors.secondary;
  Color get castleAccent => CastleColors.accent;
  Color get castleDark => CastleColors.dark;
  Color get castleWhite => CastleColors.white;

  // Castle text colors
  Color get castleTextPrimary => CastleColors.textPrimary;
  Color get castleTextSecondary => CastleColors.textSecondary;
  Color get castleTextDark => CastleColors.textDark;
  Color get castleTextSecondaryDark => CastleColors.textSecondaryDark;

  // Castle backgrounds
  Color get castleLightBackground => CastleColors.lightBackground;
  Color get castleDarkBackground => CastleColors.darkBackground;
}
