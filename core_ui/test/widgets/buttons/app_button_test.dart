import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppButton shows a loader and ignores taps while loading', (
    WidgetTester tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Buy',
            onPressed: () => pressed = true,
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Buy'), findsNothing);

    await tester.tap(find.byType(AppButton));
    expect(pressed, isFalse);
  });
}
