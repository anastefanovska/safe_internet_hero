import '../models/scam_card_model.dart';

/// Seed deck for the "Spot the Scam" mini-game — age-appropriate messages a kid
/// might realistically receive. A mix of scams (phishing links, prize/lottery
/// bait, impersonation, info-harvesting strangers, chain-letter misinformation)
/// and perfectly safe, genuine messages so the answer is never "always scam".
const List<ScamCardModel> scamCards = [
  // ── Scams ───────────────────────────────────────────────────────────────
  ScamCardModel(
    id: 'prize_giftcard',
    channel: ScamChannel.sms,
    sender: '+44 7700 900123',
    content:
        'CONGRATULATIONS! You\'ve won a £1000 gift card 🎉 Claim it in the next 2 hours: bit.ly/claim-now-win',
    isScam: true,
    explanation:
        'You can\'t win a prize you never entered. Surprise "winnings", a rush to act, and a shortened link are classic scam signs.',
  ),
  ScamCardModel(
    id: 'netflix_phish',
    channel: ScamChannel.email,
    sender: 'support@netflx-billing.com',
    subject: 'Your account has been suspended',
    content:
        'We could not process your payment. Your account will be deleted in 24 hours. Confirm your password here: netflx-verify.com',
    isScam: true,
    explanation:
        'The address is misspelled (netflx), it threatens you with a deadline, and real companies never ask for your password by email.',
  ),
  ScamCardModel(
    id: 'talent_scout_dm',
    channel: ScamChannel.dm,
    sender: '@star_maker_official',
    content:
        'Hi! I\'m a talent scout and you could be famous ⭐ Just send me your home address and phone number so we can sign you today!',
    isScam: true,
    explanation:
        'A stranger asking for your address and phone number is a red flag. Never share personal details with people you don\'t know.',
  ),
  ScamCardModel(
    id: 'family_code',
    channel: ScamChannel.sms,
    sender: 'Unknown number',
    content:
        'Hi it\'s Mum, I lost my phone so this is my new number. Quick — text me the security code that just arrived, I need it!',
    isScam: true,
    explanation:
        'Scammers pretend to be family in a panic. A one-time security code is secret — check by calling the person on their real number first.',
  ),
  ScamCardModel(
    id: 'vbucks_generator',
    channel: ScamChannel.dm,
    sender: '@free_vbucks_daily',
    content:
        'FREE V-Bucks generator works 100%! Just log in with your game username and password here to get 10,000 free 👉 vbux-gen.xyz',
    isScam: true,
    explanation:
        'Free "generators" are a trick to steal your account. Never type your username and password into a site to get free game money.',
  ),
  ScamCardModel(
    id: 'parcel_fee',
    channel: ScamChannel.sms,
    sender: 'ROYAL-MAIL',
    content:
        'Your parcel is waiting but a 59p delivery fee is unpaid. Pay now to avoid return: rml-redelivery.info/pay',
    isScam: true,
    explanation:
        'Fake delivery texts create panic over a tiny fee to steal your card details. The odd web link gives it away — go to the real courier site instead.',
  ),
  ScamCardModel(
    id: 'chain_letter',
    channel: ScamChannel.dm,
    sender: '@viral_alerts',
    content:
        '⚠️ SHARE THIS TO 10 FRIENDS NOW or your account will be deleted tomorrow! This is 100% real, admins confirmed it!!!',
    isScam: true,
    explanation:
        'Chain messages that pressure you to share and make scary claims are misinformation. Don\'t forward them — just delete.',
  ),
  ScamCardModel(
    id: 'stranger_school',
    channel: ScamChannel.dm,
    sender: '@cool_gamer_2011',
    content:
        'hey wanna be friends? 😄 what school do you go to and what time do you finish? maybe i can meet you there!',
    isScam: true,
    explanation:
        'A stranger asking where you go to school and when you finish is dangerous. Never share where you\'ll be — tell a trusted adult.',
  ),

  // ── Safe & genuine ──────────────────────────────────────────────────────
  ScamCardModel(
    id: 'friend_football',
    channel: ScamChannel.sms,
    sender: 'Sam 🙂',
    content:
        'Hey! Do you want to come round after school to play football in the park? ⚽',
    isScam: false,
    explanation:
        'This is a normal message from a friend. It asks nothing secret and has no suspicious links — safe to reply.',
  ),
  ScamCardModel(
    id: 'school_trip',
    channel: ScamChannel.email,
    sender: 'office@greenwood-school.sch.uk',
    subject: 'Museum trip permission form',
    content:
        'Dear pupil, please ask a parent or guardian to sign the attached form for Friday\'s museum trip. Thank you!',
    isScam: false,
    explanation:
        'A genuine note from your school. It asks a parent to sign a form and doesn\'t request passwords or money — this one is safe.',
  ),
  ScamCardModel(
    id: 'friend_birthday',
    channel: ScamChannel.dm,
    sender: '@maya_draws',
    content:
        'Happy birthday!!! 🎂🎉 hope you have the best day, see you at the party on saturday!',
    isScam: false,
    explanation:
        'A kind birthday message from a friend you know. No links, no requests — nothing to worry about.',
  ),
  ScamCardModel(
    id: 'library_reminder',
    channel: ScamChannel.sms,
    sender: 'City Library',
    content:
        'Reminder: your library books are due back next Monday. No fee if returned on time. Thank you!',
    isScam: false,
    explanation:
        'A helpful reminder with no link to tap and nothing to pay. This is a normal, safe message.',
  ),
  ScamCardModel(
    id: 'streak_email',
    channel: ScamChannel.email,
    sender: 'hello@duolingo.com',
    subject: 'You hit a 7-day streak! 🔥',
    content:
        'Amazing work — you\'ve practised 7 days in a row! Keep it going tomorrow to protect your streak.',
    isScam: false,
    explanation:
        'A friendly progress email that only encourages you. It never asks for your password or personal details, so it\'s safe.',
  ),
  ScamCardModel(
    id: 'mum_pickup',
    channel: ScamChannel.sms,
    sender: 'Mum ❤️',
    content:
        'Running about 10 minutes late to pick you up — wait by the school gate and I\'ll be there soon 🙂',
    isScam: false,
    explanation:
        'A normal message from your mum on her usual number. It shares nothing secret and asks nothing unusual — safe.',
  ),
  ScamCardModel(
    id: 'grandma_dm',
    channel: ScamChannel.dm,
    sender: 'Grandma Rose',
    content:
        'It\'s Grandma! 💛 So glad you showed me how to use this. Can\'t wait to see you at Sunday lunch!',
    isScam: false,
    explanation:
        'A warm message from a family member you know and have talked to before. Nothing suspicious here — safe.',
  ),
];
