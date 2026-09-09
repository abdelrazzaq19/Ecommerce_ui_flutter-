import 'dart:async';

import 'package:flutter/material.dart';

import '../services/local_store.dart';

/// App preferences.
///
/// Only the theme lives here today. It is its own provider rather than a field
/// on something else because the app root listens to it, and rebuilding the
/// whole app whenever a cart quantity changed would be wasteful.
class SettingsProvider with ChangeNotifier {
  SettingsProvider({LocalStore? store}) : _store = store {
    _themeMode = store?.readThemeMode() ?? ThemeMode.system;
  }

  final LocalStore? _store;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Whether the user has picked a theme rather than following the device.
  bool get followsSystem => _themeMode == ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    unawaited(_store?.writeThemeMode(mode));
  }

  /// Labels for the theme picker.
  static String labelFor(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  static IconData iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };
}
