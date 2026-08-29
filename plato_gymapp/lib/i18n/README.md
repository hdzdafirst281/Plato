# 🌍 Plato Localization (i18n) System

Plato's localization system is centrally managed via **Google Sheets** to provide a seamless collaborative environment for translators and developers. It leverages the `slang` package to generate strongly-typed, compile-safe localization classes in Flutter.

## 🌟 Workflow Overview

1. **Single Source of Truth**: The Google Sheet is the definitive source for all localization strings. All additions, modifications, or deletions of translation keys must be performed directly on this sheet.
2. **Automated Data Fetching**: A custom script (`fetch_langs.dart`) downloads the latest translation data from Google Sheets in CSV format.
3. **Parse & Code Generation**: The script automatically parses the downloaded CSV, generates the corresponding `.i18n.json` files (e.g., `strings_en.i18n.json` and `strings_vi.i18n.json`), and then triggers `slang` to rebuild the `strings.g.dart` file.

---

## 🛠 How to Update Translations

Whenever a modification is made on the Google Sheet, please wait for **1 to 2 minutes** to allow Google to update its CSV export cache. Afterward, run the synchronization script from the `plato_gymapp` root directory:

```bash
dart scripts/fetch_langs.dart
```

**What happens during this process?**
- The script downloads the latest translations.
- It compares the new data with the existing JSON files and outputs a **Synchronization Report (Diff)** directly in your terminal, detailing all added, modified, or deleted keys.
- It automatically invokes the `slang` build runner to update `strings.g.dart`.

> **⚠️ IMPORTANT WARNING**
> **Do not** manually edit `strings_en.i18n.json`, `strings_vi.i18n.json`, or `strings.g.dart`. These files are auto-generated and any manual changes will be overwritten the next time the sync script runs.

---

## 📝 Google Sheets Formatting Rules

The Google Sheet is strictly structured with three primary columns in the following order:

1. `key`: The unique identifier for the string (e.g., `auth.btn_login`).
2. `en`: The English translation.
3. `vi`: The Vietnamese translation.

> **💡 Note on Key Organization:**
> The keys in the sheet are automatically organized by an **Advanced Sort** algorithm. They are grouped by Module and then further sorted by their prefixes (`title`, `desc`, `lbl`, `btn`, `msg`, etc.). This ensures related UI components remain logically grouped together, making the sheet highly maintainable.

---

## ⚙️ Slang Configuration (`slang.yaml`)

The system is configured to read the script-generated `.i18n.json` files seamlessly:

```yaml
base_locale: en
fallback_strategy: base_locale
input_directory: lib/i18n
input_file_pattern: .i18n.json
output_directory: lib/i18n
output_file_name: strings.g.dart
string_interpolation: braces
key_case: snake
```
