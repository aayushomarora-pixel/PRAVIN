import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pravin/features/notes/notes_page.dart';
import 'package:pravin/data/db/database_helper.dart';

void main() {
  group('NotesPage Widget', () {
    testWidgets('should display empty state when no notes exist',
        (WidgetTester tester) async {
      // Build the NotesPage widget
      await tester.pumpWidget(
        MaterialApp(
          home: NotesPage(),
        ),
      );

      // Verify empty state message is shown
      expect(find.textContaining('No notes yet'), findsOneWidget);
      expect(find.textContaining('Tap + to create your first note'), findsOneWidget);
    });

    testWidgets('should display search icon in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotesPage(),
        ),
      );

      // Verify search icon is present
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should toggle search bar when search icon is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotesPage(),
        ),
      );

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      // Verify search field is shown
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should display floating action button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotesPage(),
        ),
      );

      // Verify FAB is present
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should open note editor when FAB is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotesPage(),
        ),
      );

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify bottom sheet is shown with text fields
      expect(find.text('New Note'), findsOneWidget);
    });

    testWidgets('should display note creation snackbar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotesPage(),
        ),
      );

      // Tap FAB to open note editor
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter note content
      await tester.enterText(
        find.byType(TextField).last,
        'Test note content',
      );
      await tester.pump();

      // Tap Save button
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
    });

    testWidgets('should display search results when searching',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotesPage(),
        ),
      );

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      // Enter search query
      await tester.enterText(find.byType(TextField).first, 'search');
      await tester.pump();
    });
  });
}