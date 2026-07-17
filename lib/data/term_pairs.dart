import '../core/app_locale.dart';
import '../models/term_pair_model.dart';

/// Seed pairs for the "Match Madness" mini-game — core internet-safety terms
/// with short, kid-friendly definitions. Keep each definition to a phrase that
/// fits comfortably on a tile.
///
/// Resolved to the app's content language ([AppLocale.code]); ids stay stable
/// across languages so game logic never changes.
List<TermPairModel> get termPairs =>
    AppLocale.code == 'mk' ? _termPairsMk : _termPairsEn;

const List<TermPairModel> _termPairsEn = [
  TermPairModel(
    id: 'phishing',
    term: 'Phishing',
    definition: 'A fake message that tricks you into giving away private info.',
  ),
  TermPairModel(
    id: 'malware',
    term: 'Malware',
    definition: 'Harmful software that can damage your device or steal data.',
  ),
  TermPairModel(
    id: 'two_factor',
    term: 'Two-Factor (2FA)',
    definition: 'A second check, like a code, that proves it\'s really you.',
  ),
  TermPairModel(
    id: 'password',
    term: 'Strong Password',
    definition: 'A long secret mix of letters, numbers and symbols.',
  ),
  TermPairModel(
    id: 'personal_data',
    term: 'Personal Data',
    definition: 'Private facts about you, like your address or birthday.',
  ),
  TermPairModel(
    id: 'cyberbullying',
    term: 'Cyberbullying',
    definition: 'Being mean or hurtful to someone online.',
  ),
  TermPairModel(
    id: 'privacy_settings',
    term: 'Privacy Settings',
    definition: 'Controls that decide who can see what you share.',
  ),
  TermPairModel(
    id: 'scam',
    term: 'Scam',
    definition: 'A trick to steal your money or your information.',
  ),
  TermPairModel(
    id: 'antivirus',
    term: 'Antivirus',
    definition: 'A program that finds and removes harmful software.',
  ),
  TermPairModel(
    id: 'popup',
    term: 'Pop-up',
    definition: 'A window that appears suddenly, sometimes with fake offers.',
  ),
  TermPairModel(
    id: 'digital_footprint',
    term: 'Digital Footprint',
    definition: 'The trail of information you leave behind online.',
  ),
  TermPairModel(
    id: 'oversharing',
    term: 'Oversharing',
    definition: 'Posting too much private info that others could misuse.',
  ),
];

const List<TermPairModel> _termPairsMk = [
  TermPairModel(
    id: 'phishing',
    term: 'Фишинг',
    definition: 'Лажна порака што те измамува да откриеш приватни податоци.',
  ),
  TermPairModel(
    id: 'malware',
    term: 'Малвер',
    definition: 'Штетен софтвер што може да го оштети уредот или да украде податоци.',
  ),
  TermPairModel(
    id: 'two_factor',
    term: 'Двофакторска (2FA)',
    definition: 'Втора проверка, како код, што докажува дека навистина си ти.',
  ),
  TermPairModel(
    id: 'password',
    term: 'Силна лозинка',
    definition: 'Долга тајна мешавина од букви, бројки и симболи.',
  ),
  TermPairModel(
    id: 'personal_data',
    term: 'Лични податоци',
    definition: 'Приватни факти за тебе, како адресата или роденденот.',
  ),
  TermPairModel(
    id: 'cyberbullying',
    term: 'Сајбер-малтретирање',
    definition: 'Да бидеш злобен или повредувачки кон некого онлајн.',
  ),
  TermPairModel(
    id: 'privacy_settings',
    term: 'Поставки за приватност',
    definition: 'Контроли што одлучуваат кој може да види што споделуваш.',
  ),
  TermPairModel(
    id: 'scam',
    term: 'Измама',
    definition: 'Трик за да ти ги украде парите или информациите.',
  ),
  TermPairModel(
    id: 'antivirus',
    term: 'Антивирус',
    definition: 'Програма што наоѓа и отстранува штетен софтвер.',
  ),
  TermPairModel(
    id: 'popup',
    term: 'Скокачки прозорец',
    definition: 'Прозорец што се појавува одненадеж, понекогаш со лажни понуди.',
  ),
  TermPairModel(
    id: 'digital_footprint',
    term: 'Дигитален отпечаток',
    definition: 'Трагата од информации што ја оставаш зад себе онлајн.',
  ),
  TermPairModel(
    id: 'oversharing',
    term: 'Прекумерно споделување',
    definition: 'Објавување премногу приватни податоци што други можат да ги злоупотребат.',
  ),
];
