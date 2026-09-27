import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/localization/app_translations.dart';

class LanguageModel {
  final String code;
  final String name;
  final String flag;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.flag,
  });
}

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _prefKey = 'gm_selected_language_v1';

  final List<LanguageModel> supportedLanguages = const [
    LanguageModel(code: 'fr', name: 'Français', flag: '🇫🇷'),
    LanguageModel(code: 'en', name: 'English', flag: '🇬🇧'),
    LanguageModel(code: 'ln', name: 'Lingála', flag: '🇨🇩'),
    LanguageModel(code: 'sw', name: 'Kiswahili', flag: '🇹🇿'),
  ];

  String _currentLanguage = 'fr';
  bool _isInitialized = false;

  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;

  LanguageModel get currentLanguageModel =>
      supportedLanguages.firstWhere(
        (l) => l.code == _currentLanguage,
        orElse: () => supportedLanguages.first,
      );

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_prefKey);

      if (savedLang != null && _isSupported(savedLang)) {
        _currentLanguage = savedLang;
      } else {
        _currentLanguage = _detectDeviceLanguage();
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing LanguageService: $e');
      _currentLanguage = _detectDeviceLanguage();
      _isInitialized = true;
      notifyListeners();
    }
  }

  String _detectDeviceLanguage() {
    try {
      final locales = ui.PlatformDispatcher.instance.locales;
      if (locales.isNotEmpty) {
        for (final loc in locales) {
          final lang = loc.languageCode.toLowerCase();
          final country = loc.countryCode?.toUpperCase() ?? '';

          if (lang.startsWith('en') || const ['US', 'GB', 'CA', 'AU', 'NG', 'KE', 'UG', 'ZA', 'GH', 'RW'].contains(country)) {
            return 'en';
          }
          if (lang.startsWith('sw') || const ['TZ', 'KE', 'UG', 'BI'].contains(country)) {
            return 'sw';
          }
          if (lang.startsWith('ln')) {
            return 'ln';
          }
          if (lang.startsWith('fr') || const ['FR', 'CD', 'CG', 'BE', 'CH', 'CI', 'SN', 'CM', 'GA', 'ML', 'BF', 'NE', 'TG', 'BJ', 'GN', 'MG'].contains(country)) {
            return 'fr';
          }
        }
      }

      final single = ui.PlatformDispatcher.instance.locale;
      final singleLang = single.languageCode.toLowerCase();
      if (singleLang.startsWith('en')) return 'en';
      if (singleLang.startsWith('sw')) return 'sw';
      if (singleLang.startsWith('ln')) return 'ln';
      if (singleLang.startsWith('fr')) return 'fr';
    } catch (e) {
      debugPrint('Language auto-detection error: $e');
    }
    return 'fr';
  }

  bool _isSupported(String code) {
    return supportedLanguages.any((l) => l.code == code);
  }

  Future<void> setLanguage(String langCode) async {
    if (!_isSupported(langCode) || _currentLanguage == langCode) return;
    _currentLanguage = langCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  String t(String key) {
    return AppTranslations.tr(key, _currentLanguage);
  }
}
