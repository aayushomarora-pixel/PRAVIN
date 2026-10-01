import 'dart:async';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

/// Google Calendar API service
/// Handles two-way sync between PRAVIN and Google Calendar
class GoogleCalendarService {
  static const String calendarId = 'primary';

  AuthClient? _authClient;

  GoogleCalendarService({AuthClient? authClient}) : _authClient = authClient;

  /// Update the authenticated client used by this service
  void setAuthClient(AuthClient? authClient) {
    _authClient = authClient;
  }

  /// Get Google Calendar API instance
  CalendarApi? get _calendarApi {
    if (_authClient == null) return null;
    return CalendarApi(_authClient!);
  }

  /// List upcoming events from Google Calendar
  Future<List<Event>?> getUpcomingEvents({int maxResults = 10}) async {
    final api = _calendarApi;
    if (api == null) return null;

    try {
      final result = await api.events.list(
        calendarId,
        maxResults: maxResults,
        orderBy: 'startTime',
        singleEvents: true,
        timeMin: DateTime.now(),
      );
      return result.items;
    } catch (e) {
      throw Exception('Failed to fetch calendar events: $e');
    }
  }

  /// Create a new event on Google Calendar
  Future<Event?> createEvent({
    required String summary,
    String? description,
    DateTime? start,
    DateTime? end,
    String? location,
  }) async {
    final api = _calendarApi;
    if (api == null) return null;

    try {
      final event = Event()
        ..summary = summary
        ..description = description
        ..location = location;

      if (start != null && end != null) {
        event.start = EventDateTime()..dateTime = start;
        event.end = EventDateTime()..dateTime = end;
      }

      final result = await api.events.insert(event, calendarId);
      return result;
    } catch (e) {
      throw Exception('Failed to create calendar event: $e');
    }
  }

  /// Update an existing event on Google Calendar
  Future<Event?> updateEvent({
    required String eventId,
    String? summary,
    String? description,
    DateTime? start,
    DateTime? end,
    String? location,
  }) async {
    final api = _calendarApi;
    if (api == null) return null;

    try {
      final event = await api.events.get(calendarId, eventId);
      event.summary = summary ?? event.summary;
      event.description = description ?? event.description;
      event.location = location ?? event.location;
      if (start != null && end != null) {
        event.start = EventDateTime()..dateTime = start;
        event.end = EventDateTime()..dateTime = end;
      }

      final result = await api.events.update(event, calendarId, eventId);
      return result;
    } catch (e) {
      throw Exception('Failed to update calendar event: $e');
    }
  }

  /// Delete an event from Google Calendar
  Future<void> deleteEvent(String eventId) async {
    final api = _calendarApi;
    if (api == null) return;

    try {
      await api.events.delete(calendarId, eventId);
    } catch (e) {
      throw Exception('Failed to delete calendar event: $e');
    }
  }
}