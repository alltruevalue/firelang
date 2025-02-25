import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

void main() async {
  final Directory configDir = Directory('config');

  if (!configDir.existsSync()) {
    developer.log(
      '❌ Error: "config/" folder not found. Please ensure your project structure is correct.',
    );
    exit(1);
  }

  final Map<String, dynamic> remoteConfigData = {
    "conditions": [],
    "parameters": {},
  };

  // Get all parameter folders inside "config/"
  List<String> params =
      configDir
          .listSync()
          .whereType<Directory>()
          .map((dir) => dir.path.split('/').last)
          .toList();

  if (params.isEmpty) {
    developer.log(
      '❌ Error: No parameter directories found inside "config/". Ensure at least one parameter folder exists.',
    );
    exit(1);
  }

  for (String param in params) {
    final Directory paramDir = Directory('config/$param');
    Map<String, Map<String, dynamic>> translations = {};
    Map<String, dynamic> defaultJson = {};
    String defaultLanguage = "en";
    Set<String> supportedLocales = {};

    // Find all JSON files in this parameter's directory
    List<File> languageFiles =
        paramDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList();

    if (languageFiles.isEmpty) {
      developer.log(
        '❌ Error: No language JSON files found in "config/$param". Each parameter must have at least one valid language.',
      );
      exit(1);
    }

    // Read each JSON file and determine supported languages
    for (File file in languageFiles) {
      String locale = file.path.split('/').last.replaceAll('.json', '');
      Map<String, dynamic> jsonData = jsonDecode(file.readAsStringSync());

      translations[locale] = jsonData;
      supportedLocales.add(locale);

      if (locale == 'default') {
        defaultJson = jsonData;
        defaultLanguage = "default";
      } else if (locale == 'en' && defaultJson.isEmpty) {
        defaultJson = jsonData;
        defaultLanguage = "en";
      }
    }

    if (defaultJson.isEmpty) {
      developer.log(
        '❌ Error: Missing required "default.json" or "en.json" in "config/$param". Each parameter must have at least one default language.',
      );
      exit(1);
    }

    Set<String> globalKeys = {};

    // Collect all keys from all translations
    for (String locale in supportedLocales) {
      globalKeys.addAll(translations[locale]!.keys.map((key) => key.trim()));
    }

    // Validate that every language JSON contains all required keys (except "tagColor")
    for (String locale in supportedLocales) {
      Map<String, dynamic> jsonData = translations[locale]!;
      Set<String> keys = jsonData.keys.map((key) => key.trim()).toSet();

      Set<String> missingKeys = globalKeys.difference(keys);
      Set<String> extraKeys = keys.difference(globalKeys);

      // Ignore "tagColor" in validation

      if (missingKeys.isNotEmpty || extraKeys.isNotEmpty) {
        developer.log(
          '❌ Error: Inconsistent keys in "$locale.json" under "config/$param".',
        );
        if (missingKeys.isNotEmpty) {
          developer.log('   Missing keys: $missingKeys');
        }
        if (extraKeys.isNotEmpty) developer.log('   Extra keys: $extraKeys');
        exit(1); // Stop execution since key consistency is required
      }
    }
    // Construct Firebase Remote Config format
    Map<String, dynamic> paramConfig = {
      "defaultValue": {"value": jsonEncode(defaultJson)},
      "conditionalValues": {},
      "valueType": "JSON",
    };

    // Ensure `conditionalValues` are properly set for each language
    for (String locale in supportedLocales.where((l) => l != defaultLanguage)) {
      if (translations.containsKey(locale)) {
        paramConfig["conditionalValues"][locale] = {
          "value": jsonEncode(translations[locale]),
        };
      }
    }

    // Store translations for Firebase Remote Config
    remoteConfigData["parameters"][param] = paramConfig;
    // Add conditions for each language, ensuring tagColor is set to "ORANGE"
    for (String locale in supportedLocales.where((l) => l != defaultLanguage)) {
      remoteConfigData["conditions"].add({
        "name": locale,
        "expression": "device.language in ['${locale.replaceAll('_', '-')}']",
        "tagColor": "BLUE",
      });
    }
  }

  // Generate properly formatted Remote Config JSON in the project root
  File remoteConfigFile = File('remoteconfig.template.json');
  remoteConfigFile.writeAsStringSync(
    JsonEncoder.withIndent('  ').convert(remoteConfigData),
  );
  developer.log(
    '✅ remoteconfig.template.json generated successfully at project root!',
  );

  // Deploy to Firebase Remote Config
  await deployToFirebase();

  // Generate lang.dart
  generateLangDart();
}

Future<void> deployToFirebase() async {
  developer.log('🚀 Deploying updated Firebase Remote Config...');

  var deployResult = await Process.run('firebase', [
    'deploy',
    '--only',
    'remoteconfig',
  ], runInShell: true);
  if (deployResult.exitCode != 0) {
    developer.log(
      '❌ Error deploying Firebase Remote Config:\n${deployResult.stderr}\nOutput: ${deployResult.stdout}',
    );
    exit(1);
  }

  developer.log('✅ Firebase Remote Config deployed successfully!');
}

/// Generates the lang.dart file with the Lang class
void generateLangDart() {
  // Determine the user's project root
  Directory projectRoot = Directory.current;
  File remoteConfigFile = File(
    '${projectRoot.path}/remoteconfig.template.json',
  );

  if (!remoteConfigFile.existsSync()) {
    developer.log(
      '❌ Error: remoteconfig.template.json not found. Cannot generate lang.dart.',
    );
    exit(1);
  }

  // Read Remote Config JSON
  Map<String, dynamic> remoteConfigData = jsonDecode(
    remoteConfigFile.readAsStringSync(),
  );
  if (!remoteConfigData.containsKey("parameters")) {
    developer.log('❌ Error: Invalid remoteconfig.template.json format.');
    exit(1);
  }

  String paramKey = remoteConfigData["parameters"].keys.first;
  Map<String, dynamic> defaultValues = jsonDecode(
    remoteConfigData["parameters"][paramKey]["defaultValue"]["value"],
  );
  List<String> keys = defaultValues.keys.toList();

  String langClass = """
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class Lang with ChangeNotifier {
  static final Lang _instance = Lang._internal();
  factory Lang() => _instance;
  Lang._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static Map<String, dynamic> _translations = {};
  static String? _forcedLanguage;
  static bool _initialized = false;
  late BuildContext _context;

  static const LocalizationsDelegate<Lang> delegate = _LangDelegate();

  Future<void> init() async {
    if (!_initialized) {
      await _remoteConfig.fetchAndActivate();
      _loadTranslations();
      _initialized = true;
    }
  }

  static Lang of(BuildContext context) {
    final lang = Localizations.of<Lang>(context, Lang)!;
    lang._context = context;
    return lang;
  }

  String translate(String key) {
    String langCode = _forcedLanguage ?? _getDeviceLanguage();
    return _translations[langCode]?[key] ?? _translations['default']?[key] ?? _translations['en']?[key] ?? key;
  }

  static void setLanguage(String? languageCode) {
    _forcedLanguage = (languageCode?.isEmpty ?? true) ? null : languageCode;
  }

  void _loadTranslations() {
    if (_translations.isEmpty) {
      String jsonString = _remoteConfig.getString('$paramKey');
      if (jsonString.isNotEmpty) {
        _translations = jsonDecode(jsonString);
      }
    }
  }

  String _getDeviceLanguage() {
    return Localizations.localeOf(_context).languageCode;
  }

${keys.map((key) => '  String get $key => translate("$key");').join('\n')}
}

class _LangDelegate extends LocalizationsDelegate<Lang> {
  const _LangDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Lang> load(Locale locale) async {
    await Lang().init();
    return Lang();
  }

  @override
  bool shouldReload(_LangDelegate old) => true;
}
""";

  // Ensure the user's lib folder exists
  Directory libDir = Directory('${projectRoot.path}/lib');
  if (!libDir.existsSync()) {
    libDir.createSync(recursive: true);
  }

  // Save lang.dart in the user's lib/ directory
  File langFile = File('${libDir.path}/lang.dart');
  langFile.writeAsStringSync(langClass);
  developer.log(
    '✅ lib/lang.dart generated successfully in the user’s project!',
  );
}
