import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:private_4t_app/core/utils/constants.dart';

enum BrandTheme { private, castle }

class ThemeProvider extends StateNotifier<ThemeMode> {
  BrandTheme _currentBrand = BrandTheme.private;

  ThemeProvider() : super(ThemeMode.system) {
    _loadTheme();
  }

  BrandTheme get currentBrand => _currentBrand;

  ThemeData get theme {
    if (_currentBrand == BrandTheme.castle) {
      return state == ThemeMode.dark
          ? AppThemes.castleDark
          : AppThemes.castleLight;
    }
    return state == ThemeMode.dark ? AppThemes.dark : AppThemes.light;
  }

  ThemeData get privateTheme =>
      state == ThemeMode.dark ? AppThemes.dark : AppThemes.light;

  ThemeData get castleTheme =>
      state == ThemeMode.dark ? AppThemes.castleDark : AppThemes.castleLight;

  void setThemeMode(ThemeMode themeMode) {
    state = themeMode;
  }

  static const String _themeKey = 'theme_mode';
  static const String _brandKey = 'brand_theme';

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      final brandIndex = prefs.getInt(_brandKey);

      state = ThemeMode.light;
      // themeIndex != null ? ThemeMode.values[themeIndex] : ThemeMode.light;
      _currentBrand = brandIndex != null
          ? BrandTheme.values[brandIndex]
          : BrandTheme.private;

      if (kDebugMode) {
        print(
          '🔄 Loading theme: $state, brand: $_currentBrand (themeIndex: $themeIndex, brandIndex: $brandIndex)',
        );
      }
      if (kDebugMode) {
        print('✅ Theme loaded: $state, brand: $_currentBrand');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading theme: $e');
      }
      state = ThemeMode.light;
      _currentBrand = BrandTheme.private;
    }

    AppColors.setThemeMode(state == ThemeMode.dark);
  }

  Future<void> _saveTheme(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setInt(_themeKey, themeMode.index);
      if (kDebugMode) {
        print(
          '💾 Theme saved: $themeMode (index: ${themeMode.index}), result: $result',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving theme: $e');
      }
    }
  }

  Future<void> _saveBrand(BrandTheme brand) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setInt(_brandKey, brand.index);
      if (kDebugMode) {
        print(
          '💾 Brand saved: $brand (index: ${brand.index}), result: $result',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving brand: $e');
      }
    }
  }

  void setTheme(ThemeMode themeMode) {
    if (kDebugMode) {
      print('🎨 Setting theme: $themeMode (current: $state)');
    }

    setThemeMode(themeMode);

    // Update AppColors theme mode
    AppColors.setThemeMode(themeMode == ThemeMode.dark);

    _saveTheme(themeMode);

    if (kDebugMode) {
      print('✅ Theme set to: $state');
    }
  }

  void setBrand(BrandTheme brand) {
    if (kDebugMode) {
      print('🏰 Setting brand: $brand (current: $_currentBrand)');
    }

    _currentBrand = brand;
    _saveBrand(brand);

    if (kDebugMode) {
      print('✅ Brand set to: $_currentBrand');
    }

    // Force listeners to rebuild, since BrandTheme change does not
    // mutate the ThemeMode state by itself.
    state = state;
  }

  void setBrandFromPlatform(String? platform) {
    if (platform == 'castle') {
      setBrand(BrandTheme.castle);
    } else {
      setBrand(BrandTheme.private);
    }
  }

  void toggleDarkMode() {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    if (kDebugMode) {
      print('🔄 Toggling theme from $state to $newMode');
    }
    setTheme(newMode);
  }

  bool get isDarkMode => state == ThemeMode.dark;
  bool get isSystemMode => state == ThemeMode.system;

  // Initialize theme from storage
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🔄 Initializing theme provider...');
    }

    await _loadTheme();

    if (kDebugMode) {
      print('✅ Theme provider initialized with: $state');
    }
  }
}
