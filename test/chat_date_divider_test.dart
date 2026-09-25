import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/shared/widgets/chat_date_divider.dart';

void main() {
  group('ChatDateDivider Tests', () {
    test('isSameDay correctly identifies same vs different days', () {
      final date1 = DateTime(2026, 9, 25, 10, 30);
      final date2 = DateTime(2026, 9, 25, 23, 59);
      final date3 = DateTime(2026, 9, 24, 23, 59);
      final date4 = DateTime(2025, 9, 25, 10, 30);
      final date5 = DateTime(2026, 8, 25, 10, 30);

      expect(ChatDateDivider.isSameDay(date1, date2), isTrue);
      expect(ChatDateDivider.isSameDay(date1, date3), isFalse);
      expect(ChatDateDivider.isSameDay(date1, date4), isFalse);
      expect(ChatDateDivider.isSameDay(date1, date5), isFalse);
    });

    test('formatChatDate returns "Сьогодні" for today', () {
      final now = DateTime.now();
      final todayMsg = DateTime(now.year, now.month, now.day, 14, 20);

      expect(ChatDateDivider.formatChatDate(todayMsg), 'Сьогодні');
    });

    test('formatChatDate returns "Вчора" for yesterday', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayMsg = DateTime(yesterday.year, yesterday.month, yesterday.day, 20, 45);

      expect(ChatDateDivider.formatChatDate(yesterdayMsg), 'Вчора');
    });

    test('formatChatDate formats specific date in Ukrainian', () {
      final now = DateTime.now();
      final pastDate = DateTime(now.year, 9, 22, 12, 0);

      final label = ChatDateDivider.formatChatDate(pastDate);
      // Either "22 вересня" or "Сьогодні"/"Вчора" if test runs on those dates
      expect(label.isNotEmpty, isTrue);

      final previousYearDate = DateTime(2024, 11, 22, 10, 15);
      final prevLabel = ChatDateDivider.formatChatDate(previousYearDate);
      expect(prevLabel.contains('22'), isTrue);
      expect(prevLabel.contains('листопада'), isTrue);
      expect(prevLabel.contains('2024'), isTrue);
    });

    test('Sequence of messages detects day transitions properly', () {
      final messages = [
        DateTime(2026, 9, 23, 10, 0),
        DateTime(2026, 9, 23, 14, 15),
        DateTime(2026, 9, 23, 20, 45), // Same day
        DateTime(2026, 9, 24, 9, 0),   // Next day transition
        DateTime(2026, 9, 24, 12, 29),  // Same day
        DateTime(2026, 9, 25, 8, 30),   // Next day transition
      ];

      final dividerIndices = <int>[];
      for (int i = 0; i < messages.length; i++) {
        final showDivider = i == 0 || !ChatDateDivider.isSameDay(messages[i - 1], messages[i]);
        if (showDivider) {
          dividerIndices.add(i);
        }
      }

      // Dividers should appear at:
      // Index 0 (first message on Sept 23)
      // Index 3 (first message on Sept 24)
      // Index 5 (first message on Sept 25)
      expect(dividerIndices, [0, 3, 5]);
    });
  });
}
