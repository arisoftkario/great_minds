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
    LanguageModel(code: 'es', name: 'Español', flag: '🇪🇸'),
    LanguageModel(code: 'ar', name: 'العربية', flag: '🇸🇦'),
    LanguageModel(code: 'pt', name: 'Português', flag: '🇵🇹'),
    LanguageModel(code: 'zh', name: '中文', flag: '🇨🇳'),
    LanguageModel(code: 'ko', name: '한국어', flag: '🇰🇷'),
    LanguageModel(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
    LanguageModel(code: 'it', name: 'Italiano', flag: '🇮🇹'),
    LanguageModel(code: 'ru', name: 'Русский', flag: '🇷🇺'),
    LanguageModel(code: 'ja', name: '日本語', flag: '🇯🇵'),
    LanguageModel(code: 'tr', name: 'Türkçe', flag: '🇹🇷'),
    LanguageModel(code: 'hi', name: 'हिन्दी', flag: '🇮🇳'),
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
          final detected = _matchLanguageCode(lang);
          if (detected != null) return detected;
        }
      }

      final single = ui.PlatformDispatcher.instance.locale;
      final singleLang = single.languageCode.toLowerCase();
      final detectedSingle = _matchLanguageCode(singleLang);
      if (detectedSingle != null) return detectedSingle;
    } catch (e) {
      debugPrint('Language auto-detection error: $e');
    }
    return 'fr';
  }

  String? _matchLanguageCode(String code) {
    if (code.startsWith('fr')) return 'fr';
    if (code.startsWith('en')) return 'en';
    if (code.startsWith('ln')) return 'ln';
    if (code.startsWith('sw')) return 'sw';
    if (code.startsWith('es')) return 'es';
    if (code.startsWith('ar')) return 'ar';
    if (code.startsWith('pt')) return 'pt';
    if (code.startsWith('zh')) return 'zh';
    if (code.startsWith('ko')) return 'ko';
    if (code.startsWith('de')) return 'de';
    if (code.startsWith('it')) return 'it';
    if (code.startsWith('ru')) return 'ru';
    if (code.startsWith('ja')) return 'ja';
    if (code.startsWith('tr')) return 'tr';
    if (code.startsWith('hi')) return 'hi';
    return null;
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
