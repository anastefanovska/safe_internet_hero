import 'package:flutter/widgets.dart';

/// The languages the app ships with.
enum AppLanguage {
  en('en'),
  mk('mk');

  const AppLanguage(this.code);

  final String code;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.en);
}

/// Language used to resolve *Firestore content* — question text, options and
/// explanations — as opposed to UI chrome, which `AppLocalizations` handles.
///
/// This is deliberately a mutable global. `QuestionModel.fromMap` is called
/// from fifteen places inside [QuestionService], none of which hold a
/// `BuildContext`, and several of the widgets that own a `QuestionService`
/// build it in a field initialiser where `context` is not yet safe to read.
/// Threading a language parameter through all of that would touch every screen
/// that loads a question, for a value that is process-wide anyway.
///
/// `LocaleProvider` is the only writer. Tests and the AI de-duplication path
/// pass `lang:` explicitly rather than relying on this.
class AppLocale {
  AppLocale._();

  static String code = AppLanguage.en.code;
}

/// Resolves a Firestore content field that is either a plain string (an
/// un-migrated, English-only doc) or a `{en: ..., mk: ...}` map to [lang]
/// (defaults to the live [AppLocale.code]), falling back to English when the
/// requested language is missing or empty.
///
/// Read this in a *getter* (not cached in a field) so the value re-resolves on
/// each access — that keeps content reactive to a language switch even when the
/// model instance came from a stale Firestore stream snapshot.
String resolveLocalized(dynamic raw, [String? lang]) {
  final code = lang ?? AppLocale.code;
  if (raw is Map) {
    final value = raw[code];
    if (value is String && value.isNotEmpty) return value;
    final fallback = raw['en'];
    return fallback is String ? fallback : '';
  }
  return raw is String ? raw : '';
}

/// Builds the Firestore value for a translatable field, filing [value] under
/// [lang] while keeping any other language already present. A plain English
/// string is promoted into an `{en, mk}` map the first time it's translated.
dynamic mergeLocalized(dynamic raw, String value, String lang) {
  if (raw is Map) return {...raw.cast<String, dynamic>(), lang: value};
  if (raw is String && raw.isNotEmpty && lang != 'en') {
    return {'en': raw, lang: value};
  }
  return {lang: value};
}
