import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const storageKey = 'stockmind_locale';
  static const supportedLocales = [
    Locale('es'),
    Locale('en'),
  ];

  Locale _locale = const Locale('es');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isSpanish => languageCode == 'es';
  bool get isEnglish => languageCode == 'en';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(storageKey);
    if (savedCode == null || savedCode.trim().isEmpty) {
      _locale = const Locale('es');
      return;
    }
    _locale = _resolve(savedCode);
  }

  Future<void> setLanguageCode(String code) async {
    final locale = _resolve(code);
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, locale.languageCode);
  }

  Locale _resolve(String code) {
    for (final locale in supportedLocales) {
      if (locale.languageCode == code.trim().toLowerCase()) {
        return locale;
      }
    }
    return const Locale('es');
  }
}
