import '../core/app_locale.dart';
import '../models/scam_card_model.dart';

/// Seed deck for the "Spot the Scam" mini-game — age-appropriate messages a kid
/// might realistically receive. A mix of scams (phishing links, prize/lottery
/// bait, impersonation, info-harvesting strangers, chain-letter misinformation)
/// and perfectly safe, genuine messages so the answer is never "always scam".
///
/// Resolved to the app's content language ([AppLocale.code]); ids and [isScam]
/// stay identical across languages so the game logic never changes.
List<ScamCardModel> get scamCards =>
    AppLocale.code == 'mk' ? _scamCardsMk : _scamCardsEn;

const List<ScamCardModel> _scamCardsEn = [
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

const List<ScamCardModel> _scamCardsMk = [
  // ── Измами ──────────────────────────────────────────────────────────────
  ScamCardModel(
    id: 'prize_giftcard',
    channel: ScamChannel.sms,
    sender: '+44 7700 900123',
    content:
        'ЧЕСТИТКИ! Освои подарок-картичка од £1000 🎉 Земи ја во следните 2 часа: bit.ly/claim-now-win',
    isScam: true,
    explanation:
        'Не можеш да освоиш награда за која никогаш не си се пријавил. Изненадувачки „добивки“, брзање и скратен линк се класични знаци за измама.',
  ),
  ScamCardModel(
    id: 'netflix_phish',
    channel: ScamChannel.email,
    sender: 'support@netflx-billing.com',
    subject: 'Твојата сметка е суспендирана',
    content:
        'Не можевме да го обработиме твоето плаќање. Твојата сметка ќе биде избришана за 24 часа. Потврди ја лозинката тука: netflx-verify.com',
    isScam: true,
    explanation:
        'Адресата е погрешно напишана (netflx), те заплашува со рок, а вистинските компании никогаш не бараат лозинка преку е-пошта.',
  ),
  ScamCardModel(
    id: 'talent_scout_dm',
    channel: ScamChannel.dm,
    sender: '@star_maker_official',
    content:
        'Здраво! Јас сум ловец на таленти и ти можеш да станеш познат ⭐ Само испрати ми ја домашната адреса и телефонскиот број за да те потпишеме денес!',
    isScam: true,
    explanation:
        'Странец што бара твоја адреса и телефонски број е предупредувачки знак. Никогаш не споделувај лични податоци со луѓе што не ги познаваш.',
  ),
  ScamCardModel(
    id: 'family_code',
    channel: ScamChannel.sms,
    sender: 'Непознат број',
    content:
        'Здраво, мама е, го изгубив телефонот па ова е мојот нов број. Брзо — испрати ми го безбедносниот код што штотуку пристигна, ми треба!',
    isScam: true,
    explanation:
        'Измамниците се преправаат дека се член на семејството во паника. Еднократниот безбедносен код е тајна — провери прво со повик на вистинскиот број на лицето.',
  ),
  ScamCardModel(
    id: 'vbucks_generator',
    channel: ScamChannel.dm,
    sender: '@free_vbucks_daily',
    content:
        'БЕСПЛАТЕН генератор на V-Bucks работи 100%! Само најави се со твоето корисничко име и лозинка тука за да добиеш 10.000 бесплатно 👉 vbux-gen.xyz',
    isScam: true,
    explanation:
        'Бесплатните „генератори“ се трик за да ти го украдат профилот. Никогаш не внесувај корисничко име и лозинка на страница за да добиеш бесплатни пари во игра.',
  ),
  ScamCardModel(
    id: 'parcel_fee',
    channel: ScamChannel.sms,
    sender: 'ROYAL-MAIL',
    content:
        'Твојот пакет чека, но такса за достава од 59 пени не е платена. Плати сега за да избегнеш враќање: rml-redelivery.info/pay',
    isScam: true,
    explanation:
        'Лажни пораки за достава создаваат паника околу ситна такса за да ти ги украдат податоците од картичката. Чудниот линк го открива — оди на вистинската страница на курирот.',
  ),
  ScamCardModel(
    id: 'chain_letter',
    channel: ScamChannel.dm,
    sender: '@viral_alerts',
    content:
        '⚠️ СПОДЕЛИ ГО ОВА НА 10 ПРИЈАТЕЛИ ВЕДНАШ или твојата сметка ќе биде избришана утре! Ова е 100% вистина, администраторите го потврдија!!!',
    isScam: true,
    explanation:
        'Синџир-пораки што те притискаат да споделиш и даваат страшни тврдења се дезинформации. Не ги препраќај — само избриши ги.',
  ),
  ScamCardModel(
    id: 'stranger_school',
    channel: ScamChannel.dm,
    sender: '@cool_gamer_2011',
    content:
        'еј сакаш да бидеме пријатели? 😄 во кое училиште одиш и во колку часот завршуваш? можеби можам да те сретнам таму!',
    isScam: true,
    explanation:
        'Странец што прашува во кое училиште одиш и кога завршуваш е опасен. Никогаш не споделувај каде ќе бидеш — кажи на возрасен на кого му веруваш.',
  ),

  // ── Безбедни и вистински ────────────────────────────────────────────────
  ScamCardModel(
    id: 'friend_football',
    channel: ScamChannel.sms,
    sender: 'Sam 🙂',
    content:
        'Еј! Сакаш да дојдеш по училиште да играме фудбал во паркот? ⚽',
    isScam: false,
    explanation:
        'Ова е нормална порака од пријател. Не бара ништо тајно и нема сомнителни линкови — безбедно е да одговориш.',
  ),
  ScamCardModel(
    id: 'school_trip',
    channel: ScamChannel.email,
    sender: 'office@greenwood-school.sch.uk',
    subject: 'Формулар за дозвола за посета на музеј',
    content:
        'Почитуван ученику, замоли родител или старател да го потпише прикачениот формулар за петочната посета на музејот. Благодариме!',
    isScam: false,
    explanation:
        'Вистинска порака од твоето училиште. Бара родител да потпише формулар и не бара лозинки или пари — оваа е безбедна.',
  ),
  ScamCardModel(
    id: 'friend_birthday',
    channel: ScamChannel.dm,
    sender: '@maya_draws',
    content:
        'Среќен роденден!!! 🎂🎉 се надевам дека ќе имаш најубав ден, се гледаме на забавата во сабота!',
    isScam: false,
    explanation:
        'Љубезна роденденска порака од пријател што го познаваш. Нема линкови, нема барања — нема од што да се грижиш.',
  ),
  ScamCardModel(
    id: 'library_reminder',
    channel: ScamChannel.sms,
    sender: 'Градска библиотека',
    content:
        'Потсетник: твоите книги од библиотеката треба да се вратат следниот понеделник. Нема такса ако се вратат навреме. Благодариме!',
    isScam: false,
    explanation:
        'Корисен потсетник без линк за допирање и ништо за плаќање. Ова е нормална, безбедна порака.',
  ),
  ScamCardModel(
    id: 'streak_email',
    channel: ScamChannel.email,
    sender: 'hello@duolingo.com',
    subject: 'Достигна серија од 7 дена! 🔥',
    content:
        'Одлична работа — вежбаше 7 дена по ред! Продолжи утре за да ја заштитиш серијата.',
    isScam: false,
    explanation:
        'Пријателска порака за напредок што само те охрабрува. Никогаш не бара лозинка или лични податоци, па е безбедна.',
  ),
  ScamCardModel(
    id: 'mum_pickup',
    channel: ScamChannel.sms,
    sender: 'Мама ❤️',
    content:
        'Доцнам околу 10 минути да те земам — чекај кај училишната порта и ќе бидам таму наскоро 🙂',
    isScam: false,
    explanation:
        'Нормална порака од твојата мама на нејзиниот вообичаен број. Не споделува ништо тајно и не бара ништо необично — безбедно.',
  ),
  ScamCardModel(
    id: 'grandma_dm',
    channel: ScamChannel.dm,
    sender: 'Баба Роза',
    content:
        'Баба е! 💛 Многу ми е драго што ми покажа како да го користам ова. Едвај чекам да те видам на неделниот ручек!',
    isScam: false,
    explanation:
        'Топла порака од член на семејството што го познаваш и со кого си зборувал претходно. Ништо сомнително тука — безбедно.',
  ),
];
