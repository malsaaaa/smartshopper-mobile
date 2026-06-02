import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the current [ThemeMode] for the app.
/// Defaults to light mode.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  /// Toggle between light and dark. If currently system, treat current
  /// platform brightness as the baseline when toggling.
  void toggle(BuildContext context) {
    final platformIsDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    switch (state) {
      case ThemeMode.system:
        // Toggle away from whatever the system currently shows
        state = platformIsDark ? ThemeMode.light : ThemeMode.dark;
      case ThemeMode.light:
        state = ThemeMode.dark;
      case ThemeMode.dark:
        state = ThemeMode.light;
    }
  }

  void setLight() => state = ThemeMode.light;
  void setDark() => state = ThemeMode.dark;
  void setSystem() => state = ThemeMode.system;
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (_) => ThemeModeNotifier(),
);
