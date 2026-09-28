import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/admin/presentation/add_client_sheet.dart';

void main() {
  testWidgets('Test AddClientSheet full layout and rendering', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AddClientSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final err = tester.takeException();
    if (err != null) {
      print('FOUND EXCEPTION IN PUMP: $err');
    }
    expect(err, isNull);

    final titleFinder = find.text('Новий Клієнт');
    print('Title found: ${titleFinder.evaluate().length}');
    
    // Check render box sizes
    final sheetFinder = find.byType(AddClientSheet);
    final renderBox = tester.renderObject(sheetFinder) as RenderBox;
    print('Sheet size: ${renderBox.size}');

    final textFieldFinders = find.byType(TextField);
    print('Found text fields: ${textFieldFinders.evaluate().length}');
    for (final tf in textFieldFinders.evaluate()) {
      final rb = tf.renderObject as RenderBox;
      print('TextField size: ${rb.size}');
    }

    // Tap "+ Додати дитину (учня)" button
    final addChildBtn = find.text('+ Додати дитину (учня)');
    expect(addChildBtn, findsOneWidget);
    await tester.tap(addChildBtn);
    await tester.pumpAndSettle();

    expect(find.text('Учень #1'), findsOneWidget);
    expect(find.text('Юний плавець'), findsOneWidget);
    expect(find.text('Видалити'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5)); // 3 client fields + 2 child fields

    // Tap "Видалити" button
    await tester.tap(find.text('Видалити'));
    await tester.pumpAndSettle();
    expect(find.text('Учень #1'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(3));
  });
}
