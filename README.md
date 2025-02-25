# 🚀 FireLang - Firebase Lang Config

**FireLang** is an open-source **Dart/Flutter package** that automates **multi-language translations** for **Firebase Remote Config**. 

🔹 It reads translation files from **your project's** `config/` directory and generates:
- ✅ **RemoteConfig JSON** (`remoteconfig.template.json`) for Firebase.
- ✅ **Dart Localization Class** (`lib/lang.dart`) for Flutter apps.

---

## 📌 Features
- 🔹 **Automates Firebase Remote Config multi-language setup**.
- 🔹 **Ensures translation consistency across all locales**.
- 🔹 **Supports any number of languages** (JSON-based translations).
- 🔹 **Generates a Dart localization class (`Lang`)** for use in Flutter.
- 🔹 **Validates missing or extra keys to prevent translation mismatches**.
- 🔹 **Supports deployment as a dev dependency** for easy use.

---

## 🚀 Installation

### 1️⃣ Install from `pub.dev`
Once the package is **published**, you can add it to your `pubspec.yaml`:
```yaml
dev_dependencies:
  firelang: ^1.0.2
```
Then run:
```bash
dart pub get
```

---

### 2️⃣ Setup Translation Files (Inside Your Project)
Inside your **Flutter/Dart project root**, create a `config/` directory:

```
my_flutter_project/
│── config/
│   ├── dp/
│   │   ├── default.json  <-- Default translations (required)
│   │   ├── en.json  <-- English translations (required)
│   │   ├── es.json  <-- Spanish translations (optional)
│   │   ├── fr.json  <-- French translations (optional)
│── lib/
│   ├── main.dart
│   ├── lang.dart  <-- 🔥 Auto-generated localization class
│── pubspec.yaml
```

---

### 3️⃣ Translation JSON Structure
Each **JSON file** inside `config/` should have the **same keys** across all languages.

#### ✅ Example: `config/dp/en.json`
```json
{
  "welcome": "Welcome",
  "logout": "Log Out",
  "error": "Something went wrong"
}
```
#### ✅ Example: `config/dp/es.json`
```json
{
  "welcome": "Bienvenido",
  "logout": "Cerrar sesión",
  "error": "Algo salió mal"
}
```
🚨 **Every translation file must have the same keys.**  
If any language is missing a key, the script will **throw an error**.

---

## ⚡️ Usage

### 1️⃣ Build & Deploy
Run this command inside your **Flutter project root**:
```bash
dart run firelang
```

### What This Command Does
- ✅ Reads translations from **your** `config/` folder.
- ✅ Generates **`remoteconfig.template.json`** in **your project root**.
- ✅ Deploys **Firebase Remote Config** using `firebase deploy`.
- ✅ Creates **`lib/lang.dart`** in **your project's `lib/` folder**.

---
## 📌 How to Use `lang.dart` in Flutter

Your **Dart localization class (`Lang`)** will be auto-generated inside **your** `lib/lang.dart`.

### 1️⃣ Add `Lang.delegate` to `MaterialApp`
Inside your `main.dart`, add `Lang.delegate`:
```dart
import 'package:flutter/material.dart';
import 'package:firelang/lang.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Lang().init(); // Initialize translations
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        Lang.delegate, 
      ],
      home: HomeScreen(),
    );
  }
}
```

---
### 2️⃣ Access Translations in Your App
```dart
Lang.of(context).welcome   // Gets "Welcome" in English or "Bienvenido" in Spanish
Lang.of(context).logout    // Gets "Log Out" or "Cerrar sesión"
```

---
### 3️⃣ Manually Set Language
If you want to **force a specific language**, call:
```dart
Lang.setLanguage('es');  // Switch to Spanish
Lang.setLanguage('en');  // Switch back to English
Lang.setLanguage('');    // Reset to device default
```

---
## 🔧 Firebase Deployment
After building your config, **deploy it manually** using:
```bash
firebase deploy --only remoteconfig
```
🚀 This will update **Firebase Remote Config** with your latest translations.

---
## ❓ FAQ

### **Where does `lang.dart` go?**
✅ It is generated in **your project's `lib/` directory**.

### **Where does `remoteconfig.template.json` go?**
✅ It is generated in **your project's root directory**.

### **What if a translation file is missing a key?**
🚨 The script will **throw an error** and show which keys are missing.

### **Can I add more languages later?**
Yes! Just add new `.json` files inside `config/dp/`, then **run the build command** again:
```bash
dart run firelang
```

---
## 👨‍💻 Contributing
We welcome contributions! Feel free to:
1. **Fork the repo**.
2. **Create a feature branch**.
3. **Submit a pull request**.

---
## 📜 License
This project is licensed under the **MIT License**.

---
## 🚀 Final Thoughts
🎯 **FireLang** simplifies **multi-language support** for Firebase Remote Config and Flutter.  
🔥 **One command** to sync translations across **Dart, Flutter, and Firebase**.

---
**✨ Star this repo if you found it useful!** 🚀  
📌 **GitHub Repo:** [https://github.com/alltruevalue/firelang](https://github.com/alltruevalue/firelang)
