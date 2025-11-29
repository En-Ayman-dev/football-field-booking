import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class SettingsNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  SettingsNotifier() {
    // Load persisted theme mode from DB at creation
    loadThemeMode();
  }

  Future<void> loadThemeMode() async {
    try {
      final db = await DatabaseHelper().database;
      await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
      final rows = await db.query('settings', where: 'key = ?', whereArgs: ['theme_mode'], limit: 1);
      if (rows.isNotEmpty) {
        final val = rows.first['value']?.toString() ?? 'light';
        _themeMode = _stringToThemeMode(val);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Error loading theme mode: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final db = await DatabaseHelper().database;
      await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
      final modeString = _themeModeToString(mode);
      await db.insert('settings', {'key': 'theme_mode', 'value': modeString}, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (kDebugMode) print('Error saving theme mode: $e');
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      default:
        return 'system';
    }
  }

  ThemeMode _stringToThemeMode(String s) {
    switch (s) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }
}
