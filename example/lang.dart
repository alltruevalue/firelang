import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class Lang with ChangeNotifier {
  static final Lang _instance = Lang._internal();
  factory Lang() => _instance;
  Lang._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static Map<String, dynamic> _translations = {}; // Cached translations
  static String? _forcedLanguage; // Null means dynamic detection is active
  static bool _initialized = false; // Prevents unnecessary fetching
  late BuildContext _context;

  /// Localization Delegate for automatic language updates
  static const LocalizationsDelegate<Lang> delegate = _LangDelegate();

  /// Initializes Remote Config and loads translations (only once)
  Future<void> init() async {
    if (!_initialized) {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: const Duration(seconds: 1800),
        ),
      );
      await _remoteConfig.fetchAndActivate();
      _loadTranslations();
      _initialized = true;
    }
  }

  /// Force-set a language (setLanguage('') resets to auto-detection)
  static void setLanguage(String? languageCode) {
    _forcedLanguage = (languageCode?.isEmpty ?? true) ? null : languageCode;
  }

  /// Retrieves an instance of Lang for the current context
  static Lang of(BuildContext context) {
    final lang = Localizations.of<Lang>(context, Lang)!;
    lang._context = context;
    return lang;
  }

  /// Internal method for translation lookup
  String translate(String key) {
    String langCode = _forcedLanguage ?? _getDeviceLanguage();
    return _translations[langCode]?[key] ?? _translations['en']?[key] ?? key;
  }

  /// Returns the current language code (either forced or detected)
  static String getCurrentLanguage() {
    return _forcedLanguage ?? _instance._getDeviceLanguage();
  }

  /// Loads translations from Firebase Remote Config
  void _loadTranslations() {
    if (_translations.isEmpty) {
      String jsonString = _remoteConfig.getString('parm_example');
      if (jsonString.isNotEmpty) {
        _translations = jsonDecode(jsonString);
      }
    }
  }

  /// Gets the device language (or fallback)
  String _getDeviceLanguage() {
    return Localizations.localeOf(_context).languageCode;
  }

  // Generated getters for translation keys
  String get contractor => translate("helloWorld");
}

/// Custom Localization Delegate for Lang
class _LangDelegate extends LocalizationsDelegate<Lang> {
  const _LangDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<Lang> load(Locale locale) async {
    await Lang().init();
    return Lang();
  }

  @override
  bool shouldReload(_LangDelegate old) => true;
}
