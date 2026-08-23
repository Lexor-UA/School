import 'dart:io';
import 'dart:convert';

void main() {
  final parentKeys = {
    'uk': {
      'parent.tab_home': 'Головна',
      'parent.tab_schedule': 'Розклад',
      'parent.tab_profile': 'Профіль',
      'parent.notifications': 'Сповіщення',
      'parent.notif_rescheduled_title': 'Тренування перенесено',
      'parent.notif_rescheduled_desc': 'Сьогоднішнє заняття о 16:00 перенесено на 16:15.',
      'parent.notif_badge_title': 'Нове досягнення!',
      'parent.notif_badge_desc': 'Ваша дитина отримала бейдж "Акула басейну".',
      'parent.notif_sub_title': 'Абонемент',
      'parent.notif_sub_desc': 'Залишилось 2 заняття. Не забудьте подовжити.',
      'parent.close': 'Закрити',
      'parent.hello': 'Привіт',
      'parent.level': 'Рівень',
      'parent.xp': 'Досвід',
      'parent.today': 'СЬОГОДНІ',
      'parent.class_name': 'Батерфляй (Юніори)',
      'parent.coach_name': 'Тренер: Олександр В.',
      'parent.open_map': 'ВІДКРИТИ 3D КАРТУ',
      'parent.your_pass': 'ВАША ПЕРЕПУСТКА',
      'parent.vip_access': 'VIP ДОСТУП',
      'parent.show_qr': 'Покажіть цей QR-код тренеру'
    },
    'en': {
      'parent.tab_home': 'Home',
      'parent.tab_schedule': 'Schedule',
      'parent.tab_profile': 'Profile',
      'parent.notifications': 'Notifications',
      'parent.notif_rescheduled_title': 'Training Rescheduled',
      'parent.notif_rescheduled_desc': 'Today\'s class at 16:00 has been moved to 16:15.',
      'parent.notif_badge_title': 'New Achievement!',
      'parent.notif_badge_desc': 'Your child got the "Pool Shark" badge.',
      'parent.notif_sub_title': 'Subscription',
      'parent.notif_sub_desc': '2 classes left. Do not forget to renew.',
      'parent.close': 'Close',
      'parent.hello': 'Hello',
      'parent.level': 'Level',
      'parent.xp': 'XP',
      'parent.today': 'TODAY',
      'parent.class_name': 'Butterfly (Juniors)',
      'parent.coach_name': 'Coach: Alex V.',
      'parent.open_map': 'OPEN 3D MAP',
      'parent.your_pass': 'YOUR PASS',
      'parent.vip_access': 'VIP ACCESS',
      'parent.show_qr': 'Show this QR code to the coach'
    },
    'de': {
      'parent.tab_home': 'Startseite',
      'parent.tab_schedule': 'Zeitplan',
      'parent.tab_profile': 'Profil',
      'parent.notifications': 'Benachrichtigungen',
      'parent.notif_rescheduled_title': 'Training verschoben',
      'parent.notif_rescheduled_desc': 'Der heutige Kurs um 16:00 wurde auf 16:15 verlegt.',
      'parent.notif_badge_title': 'Neue Leistung!',
      'parent.notif_badge_desc': 'Ihr Kind hat das Abzeichen "Poolhai" erhalten.',
      'parent.notif_sub_title': 'Abonnement',
      'parent.notif_sub_desc': 'Noch 2 Kurse. Vergessen Sie nicht zu verlängern.',
      'parent.close': 'Schließen',
      'parent.hello': 'Hallo',
      'parent.level': 'Level',
      'parent.xp': 'XP',
      'parent.today': 'HEUTE',
      'parent.class_name': 'Schmetterling (Junioren)',
      'parent.coach_name': 'Trainer: Alex V.',
      'parent.open_map': '3D-KARTE ÖFFNEN',
      'parent.your_pass': 'IHR PASS',
      'parent.vip_access': 'VIP-ZUGANG',
      'parent.show_qr': 'Zeigen Sie diesen QR-Code dem Trainer'
    },
    'ru': {
      'parent.tab_home': 'Главная',
      'parent.tab_schedule': 'Расписание',
      'parent.tab_profile': 'Профиль',
      'parent.notifications': 'Уведомления',
      'parent.notif_rescheduled_title': 'Тренировка перенесена',
      'parent.notif_rescheduled_desc': 'Сегодняшнее занятие в 16:00 перенесено на 16:15.',
      'parent.notif_badge_title': 'Новое достижение!',
      'parent.notif_badge_desc': 'Ваш ребенок получил значок "Акула бассейна".',
      'parent.notif_sub_title': 'Абонемент',
      'parent.notif_sub_desc': 'Осталось 2 занятия. Не забудьте продлить.',
      'parent.close': 'Закрыть',
      'parent.hello': 'Привет',
      'parent.level': 'Уровень',
      'parent.xp': 'Опыт',
      'parent.today': 'СЕГОДНЯ',
      'parent.class_name': 'Баттерфляй (Юниоры)',
      'parent.coach_name': 'Тренер: Александр В.',
      'parent.open_map': 'ОТКРЫТЬ 3D КАРТУ',
      'parent.your_pass': 'ВАШ ПРОПУСК',
      'parent.vip_access': 'VIP ДОСТУП',
      'parent.show_qr': 'Покажите этот QR-код тренеру'
    }
  };

  for (final lang in parentKeys.keys) {
    final file = File('assets/translations/$lang.json');
    if (file.existsSync()) {
      final str = utf8.decode(file.readAsBytesSync());
      final map = jsonDecode(str) as Map<String, dynamic>;
      
      map.addAll(parentKeys[lang]!);
      
      file.writeAsBytesSync(utf8.encode(JsonEncoder.withIndent('  ').convert(map)));
      print('Updated $lang.json with parent keys');
    }
  }
}
