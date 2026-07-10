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
