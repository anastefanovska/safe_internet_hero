import 'package:flutter/material.dart';
import '../core/app_locale.dart';
import '../models/privacy_field_model.dart';

/// Seed profile fields for "Privacy Setup". A balanced mix across the three
/// visibility levels so the lesson is nuanced — not everything is "hide it all".
///
/// Resolved to the app's content language ([AppLocale.code]); ids and
/// [FieldVisibility] stay identical across languages so the game logic never
/// changes.
List<PrivacyFieldModel> get privacyFields =>
    AppLocale.code == 'mk' ? _privacyFieldsMk : _privacyFieldsEn;

const List<PrivacyFieldModel> _privacyFieldsEn = [
  PrivacyFieldModel(
    id: 'home_address',
    label: 'Home address',
    icon: Icons.home_rounded,
    recommended: FieldVisibility.private,
    explanation:
        'Your address should never be on a profile — keep it fully private.',
  ),
  PrivacyFieldModel(
    id: 'phone_number',
    label: 'Phone number',
    icon: Icons.phone_rounded,
    recommended: FieldVisibility.private,
    explanation:
        'Keep your number private and only give it to people you trust in person.',
  ),
  PrivacyFieldModel(
    id: 'live_location',
    label: 'Live location',
    icon: Icons.location_on_rounded,
    recommended: FieldVisibility.private,
    explanation:
        'Never broadcast where you are right now — keep live location private.',
  ),
  PrivacyFieldModel(
    id: 'pet_name',
    label: 'Pet\'s name',
    icon: Icons.pets_rounded,
    recommended: FieldVisibility.private,
    explanation:
        'A pet\'s name is often a password security answer, so keep it private.',
  ),
  PrivacyFieldModel(
    id: 'birthday',
    label: 'Birthday (day & month)',
    icon: Icons.cake_rounded,
    recommended: FieldVisibility.friends,
    explanation:
        'Fun for friends to know — but hide the year and keep it off public.',
  ),
  PrivacyFieldModel(
    id: 'photos',
    label: 'Photos of you',
    icon: Icons.photo_camera_rounded,
    recommended: FieldVisibility.friends,
    explanation:
        'Let friends see your photos, but not the whole internet.',
  ),
  PrivacyFieldModel(
    id: 'school',
    label: 'Your school',
    icon: Icons.school_rounded,
    recommended: FieldVisibility.friends,
    explanation:
        'Real friends already know your school; strangers shouldn\'t be able to find it.',
  ),
  PrivacyFieldModel(
    id: 'favourite_game',
    label: 'Favourite game',
    icon: Icons.sports_esports_rounded,
    recommended: FieldVisibility.public,
    explanation:
        'Totally safe — sharing what you like to play can\'t be used to find you.',
  ),
  PrivacyFieldModel(
    id: 'hobbies',
    label: 'Hobbies',
    icon: Icons.palette_rounded,
    recommended: FieldVisibility.public,
    explanation:
        'Safe to share, and a nice way to meet people who like the same things.',
  ),
];

const List<PrivacyFieldModel> _privacyFieldsMk = [
  PrivacyFieldModel(
    id: 'home_address',
    label: 'Домашна адреса',
    icon: Icons.home_rounded,
    recommended: FieldVisibility.private,
    explanation:
        'Твојата адреса никогаш не треба да е на профил — чувај ја целосно приватна.',
  ),
  PrivacyFieldModel(
    id: 'phone_number',
    label: 'Телефонски број',
    icon: Icons.phone_rounded,
    recommended: FieldVisibility.private,
    explanation:
        'Чувај го бројот приватен и давај го само на луѓе на кои им веруваш лично.',
  ),
  PrivacyFieldModel(
    id: 'live_location',
    label: 'Тековна локација',
    icon: Icons.location_on_rounded,
    recommended: FieldVisibility.private,
    explanation:
        'Никогаш не објавувај каде си во моментот — чувај ја тековната локација приватна.',
  ),
  PrivacyFieldModel(
    id: 'pet_name',
    label: 'Име на миленик',
    icon: Icons.pets_rounded,
    recommended: FieldVisibility.private,
    explanation:
        'Името на миленик често е одговор за безбедност на лозинка, затоа чувај го приватно.',
  ),
  PrivacyFieldModel(
    id: 'birthday',
    label: 'Роденден (ден и месец)',
    icon: Icons.cake_rounded,
    recommended: FieldVisibility.friends,
    explanation:
        'Забавно е пријателите да знаат — но сокриј ја годината и не биди јавен.',
  ),
  PrivacyFieldModel(
    id: 'photos',
    label: 'Твои фотографии',
    icon: Icons.photo_camera_rounded,
    recommended: FieldVisibility.friends,
    explanation:
        'Нека пријателите ги гледаат твоите фотографии, но не целиот интернет.',
  ),
  PrivacyFieldModel(
    id: 'school',
    label: 'Твоето училиште',
    icon: Icons.school_rounded,
    recommended: FieldVisibility.friends,
    explanation:
        'Вистинските пријатели веќе го знаат твоето училиште; странците не треба да можат да го најдат.',
  ),
  PrivacyFieldModel(
    id: 'favourite_game',
    label: 'Омилена игра',
    icon: Icons.sports_esports_rounded,
    recommended: FieldVisibility.public,
    explanation:
        'Сосема безбедно — споделувањето што сакаш да играш не може да се искористи за да те најдат.',
  ),
  PrivacyFieldModel(
    id: 'hobbies',
    label: 'Хобија',
    icon: Icons.palette_rounded,
    recommended: FieldVisibility.public,
    explanation:
        'Безбедно за споделување и убав начин да запознаеш луѓе со исти интереси.',
  ),
];
