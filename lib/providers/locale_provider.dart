import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_locale.dart';

/// Holds the app language and persists it to the device.
///
/// Stored locally rather than on the Firestore user document so the splash and
/// login screens — which render before a user exists — come up in the language
/// the user last chose.
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'app_language';

  AppLanguage _language = AppLanguage.en;

  AppLanguage get language => _language;

  Locale get locale => _language.locale;

  /// Reads the saved language before the first frame, so the app never flashes
  /// English on the way to Macedonian.
  static Future<LocaleProvider> load() async {
    final provider = LocaleProvider();
    final prefs = await SharedPreferences.getInstance();
    provider._apply(AppLanguage.fromCode(prefs.getString(_prefsKey)));
    return provider;
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _apply(language);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }

  void _apply(AppLanguage language) {
    _language = language;
    // Keep the content-resolution language in step with the UI language.
    AppLocale.code = language.code;
  }
}
