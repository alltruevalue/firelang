# ⚠️ Example Config Folder

You need to **create your own `config/` folder** inside the root of your Flutter project.  
🚨 **This `config/` folder is just an example.**  

Do **not** modify this example config. Instead, create your own `config/` directory in your project and place your language JSON files there.

Example structure:
```
my_flutter_project/
│── config/   <-- Your actual config folder
│   ├── parm_example/
│   │   ├── en.json (or default.json)  <-- Required
│   │   ├── es.json  <-- Optional
│   ├── lang.dart  <-- 🔥 Auto-generated localization class (Move this to `lib/`)
│── lib/
│   ├── main.dart
│   ├── lang.dart  <-- 🔥 Move the generated file here
│── pubspec.yaml
```

Make changes to **your project's `config/` folder**, NOT this example.
