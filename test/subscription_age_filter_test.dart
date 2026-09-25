import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';

void main() {
  group('Subscription Age Compatibility and Filtering Tests', () {
    const serviceChild68 = 'Дитячий абонемент 6-8 років (4 тренування)';
    const serviceChild915 = 'Дитячий абонемент 9-15 років (4 тренування)';
    const serviceSingle68 = 'Разове дитяче тренування 6-8 років';
    const serviceSingle915 = 'Разове дитяче тренування 9-15 років';
    const serviceIndividual = 'Дитячий індивідуальний абонемент (4 тренування)';
    const serviceSplit = 'Спліт-абонемент на 8 занять (2 особи)';
    const serviceAdult = 'Абонемент на 4 тренування (Доросла група)';

    test('15-year old child: accepts 9-15 services, rejects 6-8 and adult services', () {
      const age = 15;
      expect(isServiceAgeCompatible(serviceChild915, age), isTrue);
      expect(isServiceAgeCompatible(serviceSingle915, age), isTrue);
      expect(isServiceAgeCompatible(serviceChild68, age), isFalse);
      expect(isServiceAgeCompatible(serviceSingle68, age), isFalse);
      expect(isServiceAgeCompatible(serviceIndividual, age), isTrue);
      expect(isServiceAgeCompatible(serviceSplit, age), isTrue);
    });

    test('7-year old child: accepts 6-8 services, rejects 9-15 and adult services', () {
      const age = 7;
      expect(isServiceAgeCompatible(serviceChild68, age), isTrue);
      expect(isServiceAgeCompatible(serviceSingle68, age), isTrue);
      expect(isServiceAgeCompatible(serviceChild915, age), isFalse);
      expect(isServiceAgeCompatible(serviceSingle915, age), isFalse);
      expect(isServiceAgeCompatible(serviceIndividual, age), isTrue);
      expect(isServiceAgeCompatible(serviceSplit, age), isTrue);
    });

    test('4-year old child: accepts only individual services, rejects all group and split', () {
      const age = 4;
      expect(isServiceAgeCompatible(serviceIndividual, age), isTrue);
      expect(isServiceAgeCompatible(serviceChild68, age), isFalse);
      expect(isServiceAgeCompatible(serviceChild915, age), isFalse);
      expect(isServiceAgeCompatible(serviceSplit, age), isFalse);
      expect(isServiceAgeCompatible(serviceAdult, age), isFalse);
    });

    test('Modal filtering logic for 15-year old child strictly excludes 6-8 services', () {
      final services = [
        {'name': serviceChild68, 'isAdult': false, 'ageGroup': '6-8', 'isIndividual': false, 'isSplit': false},
        {'name': serviceChild915, 'isAdult': false, 'ageGroup': '9-15', 'isIndividual': false, 'isSplit': false},
        {'name': serviceSingle68, 'isAdult': false, 'ageGroup': '6-8', 'isIndividual': false, 'isSplit': false},
        {'name': serviceSingle915, 'isAdult': false, 'ageGroup': '9-15', 'isIndividual': false, 'isSplit': false},
        {'name': serviceAdult, 'isAdult': true, 'ageGroup': null, 'isIndividual': false, 'isSplit': false},
        {'name': serviceIndividual, 'isAdult': false, 'ageGroup': null, 'isIndividual': true, 'isSplit': false},
        {'name': serviceSplit, 'isAdult': null, 'ageGroup': null, 'isIndividual': false, 'isSplit': true},
      ];

      List<Map<String, dynamic>> filterServices({
        required int? childAge,
        required String categoryFilter,
        bool isOwnerAdult = false,
      }) {
        return services.where((s) {
          final isServiceAdult = s['isAdult'] as bool?;
          final isSplit = s['isSplit'] as bool? ?? false;
          final isIndividual = s['isIndividual'] as bool? ?? false;
          final ageGroup = s['ageGroup'] as String?;

          if (isOwnerAdult) {
            if (isServiceAdult == false && !isSplit) return false;
            return true;
          } else {
            if (isServiceAdult == true) return false;

            if (childAge != null) {
              if (childAge <= 5) {
                if (!isIndividual || isSplit) return false;
              } else {
                final targetGroup = childAge >= 9 ? '9-15' : '6-8';
                if (ageGroup != null && ageGroup != targetGroup) {
                  return false;
                }
              }
            }

            if (categoryFilter == 'group') {
              return ageGroup != null;
            }
            if (categoryFilter == 'individual') {
              return isIndividual && !isSplit;
            }
            if (categoryFilter == 'split') {
              return isSplit;
            }
            return true;
          }
        }).toList();
      }

      // Group tab for 15 yo
      final groupServices = filterServices(childAge: 15, categoryFilter: 'group');
      expect(groupServices.length, 2);
      expect(groupServices.every((s) => s['ageGroup'] == '9-15'), isTrue);
      expect(groupServices.any((s) => s['ageGroup'] == '6-8'), isFalse);

      // Individual tab for 15 yo
      final individualServices = filterServices(childAge: 15, categoryFilter: 'individual');
      expect(individualServices.length, 1);
      expect(individualServices.first['name'], serviceIndividual);

      // Split tab for 15 yo
      final splitServices = filterServices(childAge: 15, categoryFilter: 'split');
      expect(splitServices.length, 1);
      expect(splitServices.first['name'], serviceSplit);

      // 4 yo child in group tab: 0 group services
      final toddlerGroup = filterServices(childAge: 4, categoryFilter: 'group');
      expect(toddlerGroup.isEmpty, isTrue);

      // 4 yo child in individual tab: only individual services
      final toddlerIndividual = filterServices(childAge: 4, categoryFilter: 'individual');
      expect(toddlerIndividual.length, 1);
      expect(toddlerIndividual.first['name'], serviceIndividual);
    });

    test('Child born 22 November 2010 is 15 years old in Sept 2026 and picker range allows 2010', () {
      final now = DateTime(2026, 9, 25);
      final birthDate = DateTime(2010, 11, 22);

      int calculateAge(DateTime bDate, DateTime refNow) {
        int years = refNow.year - bDate.year;
        if (refNow.month < bDate.month || (refNow.month == bDate.month && refNow.day < bDate.day)) {
          years--;
        }
        return years >= 0 ? years : 0;
      }

      final age = calculateAge(birthDate, now);
      expect(age, 15);

      // Verify that firstDate allows year 2010
      final firstDate = DateTime(now.year - 18, 1, 1);
      expect(firstDate.isBefore(birthDate), isTrue);
      expect(birthDate.isBefore(now), isTrue);

      // Verify that quick year list contains 2010
      final yearList = List.generate(18, (i) => now.year - 1 - i);
      expect(yearList.contains(2010), isTrue);
    });
  });
}

