import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

// Import pages
import '../features/chat/chat_page.dart';
import '../features/tasks/tasks_page.dart';
import '../features/calendar/calendar_page.dart';
import '../features/notes/notes_page.dart';
import '../features/planning/planning_page.dart';
import '../presentation/screens/home_screen.dart';

late final GoRouter appRouter;

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/chat',
      routes: [
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return HomeScreen(child: child);
          },
          routes: [
            GoRoute(
              path: '/chat',
              name: 'chat',
              builder: (context, state) => const ChatPage(),
            ),
            GoRoute(
              path: '/tasks',
              name: 'tasks',
              builder: (context, state) => const TasksPage(),
            ),
            GoRoute(
              path: '/calendar',
              name: 'calendar',
              builder: (context, state) => const CalendarPage(),
            ),
            GoRoute(
              path: '/notes',
              name: 'notes',
              builder: (context, state) => const NotesPage(),
            ),
            GoRoute(
              path: '/planning',
              name: 'planning',
              builder: (context, state) => const PlanningPage(),
            ),
          ],
        ),
      ],
    );
  }
}

void initRouter() {
  appRouter = AppRouter.createRouter();
}

/// Returns the Kimi K3 API key from .env
String get kimiApiKey => dotenv.env['KIMI_API_KEY'] ?? '';

/// Returns the Google Client ID from .env
String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';