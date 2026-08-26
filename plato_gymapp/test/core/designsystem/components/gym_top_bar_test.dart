import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_bar.dart';

void main() {
  group('GymTopBar', () {
    testWidgets('renders title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: GymTopBar(
              title: 'Test Title',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: GymTopBar(
              title: 'Test Title',
              subtitle: 'Test Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('triggers onBackClick when back button is tapped', (WidgetTester tester) async {
      bool isBackClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: GymTopBar(
              title: 'Test Title',
              onBackClick: () {
                isBackClicked = true;
              },
            ),
          ),
        ),
      );

      final backButton = find.byType(IconButton);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(isBackClicked, isTrue);
    });
  });
}
