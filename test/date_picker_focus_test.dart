import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/utils/date_picker_utils.dart';

void main() {
  testWidgets('text field does not regain focus after the date picker', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: focus),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => DatePickerUtils.pickDate(
                    context: context,
                    initialDate: DateTime(2026, 10, 30),
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2027),
                  ),
                  child: const Text('open'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(focus.hasFocus, isFalse);
  });
}
