import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pravin/features/planning/planning_page.dart';

void main() {
  group('PlanningPage Widget', () {
    testWidgets('should display Today\'s Plan title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlanningPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today\'s Plan'), findsOneWidget);
    });

    testWidgets('should display calendar hint when not signed in',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlanningPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pending tasks'), findsOneWidget);
    });

    testWidgets('should display refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlanningPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should display FAB for adding task',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlanningPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should open quick add sheet when FAB is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlanningPage(),
        ),
      );

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify bottom sheet is shown
      expect(find.text('Quick Add Task'), findsOneWidget);
    });

    testWidgets('should validate empty task title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlanningPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Open quick add sheet
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Try to add task without title
      await tester.tap(find.text('Add'));
      await tester.pump();

      // Should stay on the same screen (validation error)
    });

    testWidgets('should display calendar section', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlanningPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to calendar section
      expect(find.text('Calendar'), findsOneWidget);
    });
  });
}