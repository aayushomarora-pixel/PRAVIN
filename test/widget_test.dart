// This is a basic Flutter widget test.
// It tests that the Flutter app loads correctly.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pravin/main.dart';
import 'package:pravin/data/models/note_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pravin/navigation/app_router.dart';

void main() {
  testWidgets('App loads and displays PRAVIN title', (WidgetTester tester) async {
    // Load environment variables (needed for IntentRouter)
    await dotenv.load(fileName: ".env");
    initRouter();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const PravinApp());

    // Verify that our app bar shows PRAVIN title.
    expect(find.text('PRAVIN'), findsOneWidget);
  });
}