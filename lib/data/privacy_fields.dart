import 'package:flutter/material.dart';
import '../models/privacy_field_model.dart';

/// Seed profile fields for "Privacy Setup". A balanced mix across the three
/// visibility levels so the lesson is nuanced — not everything is "hide it all".
const List<PrivacyFieldModel> privacyFields = [
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
