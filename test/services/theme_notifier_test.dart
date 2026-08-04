import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronger/infrastructure/services/theme_notifier.dart';

void main() {
  test('loads, persists and toggles the selected theme', () async {
    SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
    final notifier = ThemeNotifier();
    await pumpEventQueue();
    expect(notifier.value, ThemeMode.dark);

    await notifier.setThemeMode(ThemeMode.light);
    expect(notifier.value, ThemeMode.light);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('themeMode'), 'light');

    notifier.toggleTheme(Brightness.light);
    await pumpEventQueue();
    expect(notifier.value, ThemeMode.dark);
  });
}
