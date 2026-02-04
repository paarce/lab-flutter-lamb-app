import 'package:flutter/material.dart';

import '../models/app_theme.dart';

/// Provider para gestion de tema
///
/// Permite cambiar entre tema estandar y alto contraste
class ThemeProvider extends ChangeNotifier {
  AppThemeMode _currentMode = AppThemeMode.standard;

  AppThemeMode get currentMode => _currentMode;

  ThemeData get currentTheme {
    switch (_currentMode) {
      case AppThemeMode.standard:
        return AppTheme.buildStandardTheme();
      case AppThemeMode.highContrast:
        return AppTheme.buildHighContrastTheme();
    }
  }

  bool get isHighContrast => _currentMode == AppThemeMode.highContrast;

  /// Alterna entre tema estandar y alto contraste
  void toggleContrast() {
    _currentMode = _currentMode == AppThemeMode.standard
        ? AppThemeMode.highContrast
        : AppThemeMode.standard;
    notifyListeners();
  }

  /// Establece tema especifico
  void setThemeMode(AppThemeMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }
}
