// lib/services/storage_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:products/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _shoppingListKey = 'shopping_list';
  static const _settingsKey = 'app_settings';
  static const _themeKey = 'app_theme';

  Future<void> saveShoppingList(List<ShoppingListItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _shoppingListKey,
      jsonEncode(items.map((i) => i.toJson()).toList()),
    );
  }

  Future<List<ShoppingListItem>> loadShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_shoppingListKey);
    if (data == null) return [];
    return (jsonDecode(data) as List)
        .map((i) => ShoppingListItem.fromJson(i))
        .toList();
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_settingsKey);
    if (data == null) return {'expiringSoonDays': 7}; // Default value
    return jsonDecode(data);
  }

  Future<void> saveTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode.name);
  }

  Future<ThemeMode> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? ThemeMode.system.name;
    return ThemeMode.values.firstWhere((e) => e.name == themeName);
  }

  Future<void> clearSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shoppingListKey);
    await prefs.remove(_settingsKey);
  }
}
