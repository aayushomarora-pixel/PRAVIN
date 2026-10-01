import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import '../../core/services/google_auth_service.dart';
import '../../core/services/google_calendar_service.dart';

/// Calendar view page with Google Calendar sync (Phase 5)
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final GoogleAuthService _authService = GoogleAuthService();
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  List<calendar.Event> _events = [];
  bool _isLoading = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _authService.onCurrentUserChanged.listen((account) {
      if (mounted) setState(() {});
    });
  }

  bool get _isSignedIn => _authService.isSignedIn;

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _authError = null;
    });
    try {
      final events = await _calendarService.getUpcomingEvents(maxResults: 10);
      setState(() {
        _events = events ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _authError = e.toString();
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _authError = null;
    });
    try {
      final user = await _authService.signIn();
      if (user != null && mounted) {
        _calendarService.setAuthClient(_authService.authClient);
        _fetchEvents();
      }
    } catch (e) {
      setState(() {
        _authError = e.toString();
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    setState(() {
      _events.clear();
      _authError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          if (_isSignedIn)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh events',
              onPressed: _isLoading ? null : _fetchEvents,
            ),
          if (_isSignedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: _signOut,
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create event via natural language in chat'),
            ),
          );
        },
        tooltip: 'New Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isSignedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sign in to sync Google Calendar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _signIn,
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
            ),
            if (_authError != null) ...[
              const SizedBox(height: 16),
              Text(
                _authError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    if (_isLoading && _events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_events.isEmpty && !_isLoading) {
      return const Center(
        child: Text(
          'No upcoming events',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        final startTime = event.start?.dateTime ?? event.start?.date;
        final timeStr = startTime != null
            ? '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}'
            : 'All day';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.event),
            title: Text(event.summary ?? 'No title'),
            subtitle: Text(
              '${event.location ?? ""}${event.location != null && startTime != null ? " • " : ""}$timeStr',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                if (event.id != null) {
                  await _calendarService.deleteEvent(event.id!);
                  setState(() {
                    _events.removeAt(index);
                  });
                }
              },
              tooltip: 'Delete event',
            ),
          ),
        );
      },
    );
  }
}
