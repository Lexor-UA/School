import 'dart:io';
import 'dart:convert';

void main() {
  final basePath = r'c:\Users\Nelia\Desktop\School';

  final filesMap = {
    r'lib\features\parent\presentation\parent_schedule_tab.dart': {
      "'Усі'": "'parent.all'.tr()",
      "'Плавання'": "'parent.swimming'.tr()",
      "'Стрибки'": "'parent.diving'.tr()",
      "'Змагання'": "'parent.competitions'.tr()",
      "'Розклад та Історія'": "'parent.schedule_history'.tr()",
      "'Майбутні Заняття'": "'parent.upcoming_classes'.tr()",
      "'Немає доступних занять'": "'parent.no_classes_available'.tr()",
      "'Мої Бронювання'": "'parent.my_bookings'.tr()",
      "'Ви ще не забронювали жодного заняття.'": "'parent.no_bookings_yet'.tr()",
      r"'Помилка завантаження: $err'": r"'parent.loading_error'.tr(args: [err.toString()])",
      "'Вільних місць: '": "'parent.free_slots'.tr() + ': '",
      "'Успішно заброньовано!'": "'parent.booked_successfully'.tr()",
      "'Помилка бронювання. Перевірте залишок занять.'": "'parent.booking_error'.tr()",
      "'Ви записані'": "'parent.enrolled'.tr()",
      "'Місць немає'": "'parent.no_seats'.tr()",
      "'Записатися'": "'parent.enroll'.tr()",
      "'Пнд'": "'parent.mon'.tr()",
      "'Втр'": "'parent.tue'.tr()",
      "'Срд'": "'parent.wed'.tr()",
      "'Чтв'": "'parent.thu'.tr()",
      "'Птн'": "'parent.fri'.tr()",
      "'Сбт'": "'parent.sat'.tr()",
      "'Ндл'": "'parent.sun'.tr()",
      "'Юніори (Плавання)'": "'parent.juniors_swimming'.tr()",
      "'Відмінно'": "'parent.excellent'.tr()",
      "'Добре'": "'parent.good'.tr()",
    },
    r'lib\features\parent\presentation\parent_profile_tab.dart': {
      "'Мій Профіль'": "'parent.my_profile'.tr()",
      "'Мія К.'": "'parent.mia_k'.tr()",
      "'Група: Юніори Pro'": "'parent.group_juniors_pro'.tr()",
      r"'Рівень ${user.level}: Дельфін'": r"'parent.level_dolphin'.tr(args: [user.level.toString()])",
      "'Занять'": "'parent.classes'.tr()",
      "'Дистанція'": "'parent.distance'.tr()",
      "'Улюблений'": "'parent.favorite'.tr()",
      "'Анатомія Прогресу'": "'parent.anatomy_progress'.tr()",
      r"'Переглянути розвиток м\'язів'": "'parent.view_muscle_development'.tr()",
      "'Вітрина Трофеїв'": "'parent.trophy_showcase'.tr()",
      "'Увійти в 3D Кімнату'": "'parent.enter_3d_room'.tr()",
      "'Немає досягнень'": "'parent.no_achievements'.tr()",
      "'Налаштування акаунту'": "'parent.account_settings'.tr()",
      "'Оплата та підписки'": "'parent.payment_subscriptions'.tr()",
      "'Сповіщення'": "'parent.notifications'.tr()",
      "'Допомога та Підтримка'": "'parent.help_support'.tr()",
      "'Вийти з акаунту'": "'parent.logout'.tr()",
      "'Кроль'": "'parent.freestyle'.tr()",
    },
    r'lib\features\parent\presentation\anatomy_progress_screen.dart': {
      "'АНАТОМІЯ ПРОГРЕСУ'": "'parent.anatomy_progress_upper'.tr()",
      "'БІОМЕТРИЧНИЙ АНАЛІЗ...'": "'parent.biometric_analysis'.tr()",
      "'КРОЛЬ'": "'parent.freestyle_upper'.tr()",
      "'БРАС'": "'parent.breaststroke_upper'.tr()",
      "'БАТЕРФЛЯЙ'": "'parent.butterfly_upper'.tr()",
      "'НА СПИНІ'": "'parent.backstroke_upper'.tr()",
      r"'АКТИВНІ М\'ЯЗОВІ ГРУПИ'": "'parent.active_muscle_groups'.tr()",
      "'ПЛЕЧІ'": "'parent.shoulders'.tr()",
      "'РУКИ'": "'parent.arms'.tr()",
      "'СЕНСОРИ АКТИВНІ'": "'parent.sensors_active'.tr()",
      "'ГРУДИ'": "'parent.chest'.tr()",
      "'КОР'": "'parent.core'.tr()",
      "'СПИНА'": "'parent.back'.tr()",
      "'НОГИ'": "'parent.legs'.tr()",
    },
    r'lib\features\parent\presentation\pool_map_screen.dart': {
      "'Юніори Pro'": "'parent.juniors_pro'.tr()",
      "'Олександр В.'": "'parent.oleksandr_v'.tr()",
      "'3D Карта Басейну'": "'parent.3d_pool_map'.tr()",
      "'Проведіть пальцем для обертання'": "'parent.swipe_to_rotate'.tr()",
      "'Локація'": "'parent.location'.tr()",
      "'Час'": "'parent.time'.tr()",
      "'Вода'": "'parent.water'.tr()",
      r"'ДОРІЖКА ${(widget.targetLane ?? 0) + 1} • МАРІЯ'": r"'parent.lane_mariia'.tr(args: [((widget.targetLane ?? 0) + 1).toString()])",
      r"'Доріжка ${(widget.targetLane ?? 0) + 1}'": r"'parent.lane_number'.tr(args: [((widget.targetLane ?? 0) + 1).toString()])",
    },
    r'lib\features\parent\presentation\trophy_room_screen.dart': {
      "'Золотий Дельфін'": "'parent.golden_dolphin'.tr()",
      "'За ідеальну техніку Батерфляй'": "'parent.perfect_butterfly_technique'.tr()",
      "'15 Серпня 2026'": "'parent.august_15_2026'.tr()",
      "'Швидка Акула'": "'parent.fast_shark'.tr()",
      "'100 метрів Кролем менш ніж за 1:20'": "'parent.100m_freestyle_under_1_20'.tr()",
      "'2 Вересня 2026'": "'parent.september_2_2026'.tr()",
      "'Майстер Глибин'": "'parent.master_of_depths'.tr()",
      "'Здано норматив із затримки дихання (2 хвилини)'": "'parent.breath_holding_passed'.tr()",
      "'Заблоковано'": "'parent.locked'.tr()",
      "'Залізна Витримка'": "'parent.iron_endurance'.tr()",
      "'10 тренувань без пропусків'": "'parent.10_trainings_without_skips'.tr()",
      "'Вітрина Трофеїв'": "'parent.trophy_showcase'.tr()",
      "'Натисніть на трофей для деталей'": "'parent.click_trophy_for_details'.tr()",
      r"'Здобуто: ${trophy['date']}'": r"'parent.unlocked_date'.tr(args: [trophy['date'].toString()])",
      "'ЗАКРИТИ'": "'parent.close'.tr()",
    },
    r'lib\features\parent\presentation\parent_dashboard.dart': {
      "'Schedule'": "'parent.bottom_nav_schedule'.tr()",
      "'Profile'": "'parent.bottom_nav_profile'.tr()",
    }
  };

  for (final relPath in filesMap.keys) {
    final replacements = filesMap[relPath]!;
    final file = File('$basePath\\$relPath');
    if (!file.existsSync()) {
      print('Skipping $relPath, does not exist');
      continue;
    }

    var content = file.readAsStringSync();
    
    if (!content.contains("import 'package:easy_localization/easy_localization.dart';")) {
      content = "import 'package:easy_localization/easy_localization.dart';\n" + content;
    }

    for (final oldStr in replacements.keys) {
      final newStr = replacements[oldStr]!;
      content = content.replaceAll(oldStr, newStr);
    }

    file.writeAsStringSync(content);
  }

  final locales = {
    'uk': {
        'all': 'Усі', 'swimming': 'Плавання', 'diving': 'Стрибки', 'competitions': 'Змагання',
        'schedule_history': 'Розклад та Історія', 'upcoming_classes': 'Майбутні Заняття',
        'no_classes_available': 'Немає доступних занять', 'my_bookings': 'Мої Бронювання',
        'no_bookings_yet': 'Ви ще не забронювали жодного заняття.', 'loading_error': 'Помилка завантаження: {}',
        'free_slots': 'Вільних місць', 'booked_successfully': 'Успішно заброньовано!',
        'booking_error': 'Помилка бронювання. Перевірте залишок занять.', 'enrolled': 'Ви записані',
        'no_seats': 'Місць немає', 'enroll': 'Записатися', 'mon': 'Пнд', 'tue': 'Втр',
        'wed': 'Срд', 'thu': 'Чтв', 'fri': 'Птн', 'sat': 'Сбт', 'sun': 'Ндл',
        'juniors_swimming': 'Юніори (Плавання)', 'excellent': 'Відмінно', 'good': 'Добре',
        'my_profile': 'Мій Профіль', 'mia_k': 'Мія К.', 'group_juniors_pro': 'Група: Юніори Pro',
        'level_dolphin': 'Рівень {}: Дельфін', 'classes': 'Занять', 'distance': 'Дистанція',
        'favorite': 'Улюблений', 'anatomy_progress': 'Анатомія Прогресу', 'view_muscle_development': "Переглянути розвиток м'язів",
        'trophy_showcase': 'Вітрина Трофеїв', 'enter_3d_room': 'Увійти в 3D Кімнату',
        'no_achievements': 'Немає досягнень', 'account_settings': 'Налаштування акаунту',
        'payment_subscriptions': 'Оплата та підписки', 'notifications': 'Сповіщення',
        'help_support': 'Допомога та Підтримка', 'logout': 'Вийти з акаунту', 'freestyle': 'Кроль',
        'anatomy_progress_upper': 'АНАТОМІЯ ПРОГРЕСУ', 'biometric_analysis': 'БІОМЕТРИЧНИЙ АНАЛІЗ...',
        'freestyle_upper': 'КРОЛЬ', 'breaststroke_upper': 'БРАС', 'butterfly_upper': 'БАТЕРФЛЯЙ',
        'backstroke_upper': 'НА СПИНІ', 'active_muscle_groups': "АКТИВНІ М'ЯЗОВІ ГРУПИ",
        'shoulders': 'ПЛЕЧІ', 'arms': 'РУКИ', 'sensors_active': 'СЕНСОРИ АКТИВНІ',
        'chest': 'ГРУДИ', 'core': 'КОР', 'back': 'СПИНА', 'legs': 'НОГИ',
        'juniors_pro': 'Юніори Pro', 'oleksandr_v': 'Олександр В.', '3d_pool_map': '3D Карта Басейну',
        'swipe_to_rotate': 'Проведіть пальцем для обертання', 'location': 'Локація',
        'time': 'Час', 'water': 'Вода', 'lane_mariia': 'ДОРІЖКА {} • МАРІЯ', 'lane_number': 'Доріжка {}',
        'golden_dolphin': 'Золотий Дельфін', 'perfect_butterfly_technique': 'За ідеальну техніку Батерфляй',
        'august_15_2026': '15 Серпня 2026', 'fast_shark': 'Швидка Акула',
        '100m_freestyle_under_1_20': '100 метрів Кролем менш ніж за 1:20', 'september_2_2026': '2 Вересня 2026',
        'master_of_depths': 'Майстер Глибин', 'breath_holding_passed': 'Здано норматив із затримки дихання (2 хвилини)',
        'locked': 'Заблоковано', 'iron_endurance': 'Залізна Витримка',
        '10_trainings_without_skips': '10 тренувань без пропусків', 'click_trophy_for_details': 'Натисніть на трофей для деталей',
        'unlocked_date': 'Здобуто: {}', 'close': 'ЗАКРИТИ', 'bottom_nav_schedule': 'Розклад', 'bottom_nav_profile': 'Профіль'
    },
    'en': {
        'all': 'All', 'swimming': 'Swimming', 'diving': 'Diving', 'competitions': 'Competitions',
        'schedule_history': 'Schedule & History', 'upcoming_classes': 'Upcoming Classes',
        'no_classes_available': 'No classes available', 'my_bookings': 'My Bookings',
        'no_bookings_yet': "You haven't booked any classes yet.", 'loading_error': 'Loading error: {}',
        'free_slots': 'Available slots', 'booked_successfully': 'Successfully booked!',
        'booking_error': 'Booking error. Check remaining classes.', 'enrolled': 'Enrolled',
        'no_seats': 'No seats', 'enroll': 'Enroll', 'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed',
        'thu': 'Thu', 'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun', 'juniors_swimming': 'Juniors (Swimming)',
        'excellent': 'Excellent', 'good': 'Good', 'my_profile': 'My Profile', 'mia_k': 'Mia K.',
        'group_juniors_pro': 'Group: Juniors Pro', 'level_dolphin': 'Level {}: Dolphin',
        'classes': 'Classes', 'distance': 'Distance', 'favorite': 'Favorite', 'anatomy_progress': 'Anatomy of Progress',
        'view_muscle_development': 'View muscle development', 'trophy_showcase': 'Trophy Showcase',
        'enter_3d_room': 'Enter 3D Room', 'no_achievements': 'No achievements', 'account_settings': 'Account Settings',
        'payment_subscriptions': 'Payment & Subscriptions', 'notifications': 'Notifications',
        'help_support': 'Help & Support', 'logout': 'Log Out', 'freestyle': 'Freestyle',
        'anatomy_progress_upper': 'ANATOMY OF PROGRESS', 'biometric_analysis': 'BIOMETRIC ANALYSIS...',
        'freestyle_upper': 'FREESTYLE', 'breaststroke_upper': 'BREASTSTROKE', 'butterfly_upper': 'BUTTERFLY',
        'backstroke_upper': 'BACKSTROKE', 'active_muscle_groups': 'ACTIVE MUSCLE GROUPS',
        'shoulders': 'SHOULDERS', 'arms': 'ARMS', 'sensors_active': 'SENSORS ACTIVE',
        'chest': 'CHEST', 'core': 'CORE', 'back': 'BACK', 'legs': 'LEGS',
        'juniors_pro': 'Juniors Pro', 'oleksandr_v': 'Oleksandr V.', '3d_pool_map': '3D Pool Map',
        'swipe_to_rotate': 'Swipe to rotate', 'location': 'Location', 'time': 'Time', 'water': 'Water',
        'lane_mariia': 'LANE {} • MARIIA', 'lane_number': 'Lane {}', 'golden_dolphin': 'Golden Dolphin',
        'perfect_butterfly_technique': 'For perfect Butterfly technique', 'august_15_2026': 'August 15, 2026',
        'fast_shark': 'Fast Shark', '100m_freestyle_under_1_20': '100m Freestyle in under 1:20',
        'september_2_2026': 'September 2, 2026', 'master_of_depths': 'Master of Depths',
        'breath_holding_passed': 'Passed breath holding test (2 minutes)', 'locked': 'Locked',
        'iron_endurance': 'Iron Endurance', '10_trainings_without_skips': '10 trainings without skips',
        'click_trophy_for_details': 'Click trophy for details', 'unlocked_date': 'Unlocked: {}',
        'close': 'CLOSE', 'bottom_nav_schedule': 'Schedule', 'bottom_nav_profile': 'Profile'
    },
    'ru': {
        'all': 'Все', 'swimming': 'Плавание', 'diving': 'Прыжки', 'competitions': 'Соревнования',
        'schedule_history': 'Расписание и История', 'upcoming_classes': 'Предстоящие Занятия',
        'no_classes_available': 'Нет доступных занятий', 'my_bookings': 'Мои Бронирования',
        'no_bookings_yet': 'Вы еще не забронировали ни одного занятия.', 'loading_error': 'Ошибка загрузки: {}',
        'free_slots': 'Свободных мест', 'booked_successfully': 'Успешно забронировано!',
        'booking_error': 'Ошибка бронирования. Проверьте остаток занятий.', 'enrolled': 'Вы записаны',
        'no_seats': 'Мест нет', 'enroll': 'Записаться', 'mon': 'Пнд', 'tue': 'Втр', 'wed': 'Срд',
        'thu': 'Чтв', 'fri': 'Птн', 'sat': 'Сбт', 'sun': 'Вск', 'juniors_swimming': 'Юниоры (Плавание)',
        'excellent': 'Отлично', 'good': 'Хорошо', 'my_profile': 'Мой Профиль', 'mia_k': 'Мия К.',
        'group_juniors_pro': 'Группа: Юниоры Pro', 'level_dolphin': 'Уровень {}: Дельфин',
        'classes': 'Занятий', 'distance': 'Дистанция', 'favorite': 'Любимый', 'anatomy_progress': 'Анатомия Прогресса',
        'view_muscle_development': 'Посмотреть развитие мышц', 'trophy_showcase': 'Витрина Трофеев',
        'enter_3d_room': 'Войти в 3D Комнату', 'no_achievements': 'Нет достижений', 'account_settings': 'Настройки аккаунта',
        'payment_subscriptions': 'Оплата и подписки', 'notifications': 'Уведомления',
        'help_support': 'Помощь и Поддержка', 'logout': 'Выйти из аккаунта', 'freestyle': 'Кроль',
        'anatomy_progress_upper': 'АНАТОМИЯ ПРОГРЕССА', 'biometric_analysis': 'БИОМЕТРИЧЕСКИЙ АНАЛИЗ...',
        'freestyle_upper': 'КРОЛЬ', 'breaststroke_upper': 'БРАСС', 'butterfly_upper': 'БАТТЕРФЛЯЙ',
        'backstroke_upper': 'НА СПИНЕ', 'active_muscle_groups': 'АКТИВНЫЕ МЫШЕЧНЫЕ ГРУППЫ',
        'shoulders': 'ПЛЕЧИ', 'arms': 'РУКИ', 'sensors_active': 'СЕНСОРЫ АКТИВНЫ',
        'chest': 'ГРУДЬ', 'core': 'КОР', 'back': 'СПИНА', 'legs': 'НОГИ',
        'juniors_pro': 'Юниоры Pro', 'oleksandr_v': 'Александр В.', '3d_pool_map': '3D Карта Бассейна',
        'swipe_to_rotate': 'Проведите пальцем для вращения', 'location': 'Локация', 'time': 'Время', 'water': 'Вода',
        'lane_mariia': 'ДОРОЖКА {} • МАРИЯ', 'lane_number': 'Дорожка {}', 'golden_dolphin': 'Золотой Дельфин',
        'perfect_butterfly_technique': 'За идеальную технику Баттерфляй', 'august_15_2026': '15 Августа 2026',
        'fast_shark': 'Быстрая Акула', '100m_freestyle_under_1_20': '100 метров Кролем менее чем за 1:20',
        'september_2_2026': '2 Сентября 2026', 'master_of_depths': 'Мастер Глубин',
        'breath_holding_passed': 'Сдан норматив по задержке дыхания (2 минуты)', 'locked': 'Заблокировано',
        'iron_endurance': 'Железная Выдержка', '10_trainings_without_skips': '10 тренировок без пропусков',
        'click_trophy_for_details': 'Нажмите на трофей для деталей', 'unlocked_date': 'Получено: {}',
        'close': 'ЗАКРЫТЬ', 'bottom_nav_schedule': 'Расписание', 'bottom_nav_profile': 'Профиль'
    },
    'de': {
        'all': 'Alle', 'swimming': 'Schwimmen', 'diving': 'Springen', 'competitions': 'Wettbewerbe',
        'schedule_history': 'Zeitplan & Historie', 'upcoming_classes': 'Kommende Kurse',
        'no_classes_available': 'Keine Kurse verfügbar', 'my_bookings': 'Meine Buchungen',
        'no_bookings_yet': 'Du hast noch keine Kurse gebucht.', 'loading_error': 'Ladefehler: {}',
        'free_slots': 'Freie Plätze', 'booked_successfully': 'Erfolgreich gebucht!',
        'booking_error': 'Buchungsfehler. Überprüfe verbleibende Kurse.', 'enrolled': 'Angemeldet',
        'no_seats': 'Keine Plätze', 'enroll': 'Anmelden', 'mon': 'Mo', 'tue': 'Di', 'wed': 'Mi',
        'thu': 'Do', 'fri': 'Fr', 'sat': 'Sa', 'sun': 'So', 'juniors_swimming': 'Junioren (Schwimmen)',
        'excellent': 'Ausgezeichnet', 'good': 'Gut', 'my_profile': 'Mein Profil', 'mia_k': 'Mia K.',
        'group_juniors_pro': 'Gruppe: Junioren Pro', 'level_dolphin': 'Level {}: Delfin',
        'classes': 'Kurse', 'distance': 'Distanz', 'favorite': 'Favorit', 'anatomy_progress': 'Anatomie des Fortschritts',
        'view_muscle_development': 'Muskelentwicklung ansehen', 'trophy_showcase': 'Trophäenvitrine',
        'enter_3d_room': '3D-Raum betreten', 'no_achievements': 'Keine Erfolge', 'account_settings': 'Kontoeinstellungen',
        'payment_subscriptions': 'Zahlung & Abos', 'notifications': 'Benachrichtigungen',
        'help_support': 'Hilfe & Support', 'logout': 'Abmelden', 'freestyle': 'Freistil',
        'anatomy_progress_upper': 'ANATOMIE DES FORTSCHRITTS', 'biometric_analysis': 'BIOMETRISCHE ANALYSE...',
        'freestyle_upper': 'FREISTIL', 'breaststroke_upper': 'BRUST', 'butterfly_upper': 'SCHMETTERLING',
        'backstroke_upper': 'RÜCKEN', 'active_muscle_groups': 'AKTIVE MUSKELGRUPPEN',
        'shoulders': 'SCHULTERN', 'arms': 'ARME', 'sensors_active': 'SENSOREN AKTIV',
        'chest': 'BRUST', 'core': 'CORE', 'back': 'RÜCKEN', 'legs': 'BEINE',
        'juniors_pro': 'Junioren Pro', 'oleksandr_v': 'Oleksandr V.', '3d_pool_map': '3D Pool Map',
        'swipe_to_rotate': 'Zum Drehen wischen', 'location': 'Ort', 'time': 'Zeit', 'water': 'Wasser',
        'lane_mariia': 'BAHN {} • MARIIA', 'lane_number': 'Bahn {}', 'golden_dolphin': 'Goldener Delfin',
        'perfect_butterfly_technique': 'Für perfekte Schmetterling-Technik', 'august_15_2026': '15. August 2026',
        'fast_shark': 'Schneller Hai', '100m_freestyle_under_1_20': '100m Freistil in unter 1:20',
        'september_2_2026': '2. September 2026', 'master_of_depths': 'Meister der Tiefen',
        'breath_holding_passed': 'Atemanhaltetest bestanden (2 Minuten)', 'locked': 'Gesperrt',
        'iron_endurance': 'Eiserne Ausdauer', '10_trainings_without_skips': '10 Trainings ohne Fehlzeiten',
        'click_trophy_for_details': 'Trophäe für Details anklicken', 'unlocked_date': 'Freigeschaltet: {}',
        'close': 'SCHLIESSEN', 'bottom_nav_schedule': 'Zeitplan', 'bottom_nav_profile': 'Profil'
    },
  };

  for (final lang in locales.keys) {
    final new_data = locales[lang]!;
    final file = File('$basePath\\assets\\translations\\$lang.json');
    if (!file.existsSync()) continue;

    final content = file.readAsStringSync();
    final data = jsonDecode(content) as Map<String, dynamic>;
    
    if (!data.containsKey('parent')) {
      data['parent'] = <String, dynamic>{};
    }
    
    for (final k in new_data.keys) {
      data['parent'][k] = new_data[k];
    }
    
    final encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(data));
  }

  print('Translation script complete!');
}
