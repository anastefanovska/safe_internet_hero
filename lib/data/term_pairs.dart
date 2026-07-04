import '../models/term_pair_model.dart';

/// Seed pairs for the "Match Madness" mini-game — core internet-safety terms
/// with short, kid-friendly definitions. Keep each definition to a phrase that
/// fits comfortably on a tile.
const List<TermPairModel> termPairs = [
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
