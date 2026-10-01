/// AI planning service for PRAVIN
/// Generates intelligent daily schedules based on tasks, notes, and calendar events
/// Uses Kimi K3 API for intelligent task prioritization and scheduling suggestions
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:pravin/data/repositories/task_repository.dart';
import 'package:pravin/data/repositories/note_repository.dart';
import 'package:pravin/core/services/kimi_api_service.dart';
import 'package:pravin/data/models/task_model.dart';
import 'package:pravin/data/models/note_model.dart';
import 'package:pravin/core/services/google_auth_service.dart';
import 'package:pravin/core/services/google_calendar_service.dart';

class PlanningService {
  final TaskRepository _taskRepo;
  final NoteRepository _noteRepo;
  final KimiApiService _kimiService;
  final GoogleAuthService _authService;
  final GoogleCalendarService _calendarService;

  PlanningService({
    TaskRepository? taskRepo,
    NoteRepository? noteRepo,
    KimiApiService? kimiService,
    GoogleAuthService? authService,
    GoogleCalendarService? calendarService,
  }) : _taskRepo = taskRepo ?? TaskRepository(),
       _noteRepo = noteRepo ?? NoteRepository(),
       _kimiService = kimiService ?? KimiApiService(apiKey: ''),
       _authService = authService ?? GoogleAuthService(),
       _calendarService = calendarService ?? GoogleCalendarService();

  /// Generate intelligent daily plan based on available tasks and schedule
  /// Returns detailed daily schedule with time allocations
  Future<List<PlannedTask>> generateDailyPlan() async {
    try {
      // Collect all available data
      final tasks = await _taskRepo.getAllTasks();
      final notes = await _noteRepo.getAllNotes();
      final calendarEvents = _authService.isSignedIn ? await _calendarService.getUpcomingEvents(maxResults: 5) : [];

      // Create context for AI planning
      final context = _createPlanningContext(tasks, notes, calendarEvents);

      // Generate schedule using AI
      final plan = await _generateAISchedule(context);

      // Assign to local storage
      return await _assignPlanToLocalTasks(plan);
    } catch (e) {
      throw Exception('Failed to generate daily plan: ${e}');
    }
  }

  /// Create structured context for AI planning
  String _createPlanningContext(List<TaskModel> tasks, List<NoteModel> notes, List<dynamic> calendarEvents) {
    final buffer = StringBuffer();

    buffer.write('Current date: Today\n');
    buffer.write('Active tasks: ${tasks.length}\n');
    for (final task in tasks.where((t) => t.status != 'completed')) {
      buffer.write('- ${task.title} (Priority: ${task.priority}, Due: ${task.dueDate})\n');
    }

    buffer.write('\nRecent notes: ${notes.length}\n');
    for (final note in notes.where((n) => !n.isArchived).take(3)) {
      final title = note.title ?? 'Untitled';
      final preview = note.content.length > 50
          ? '${note.content.substring(0, 50)}...'
          : note.content;
      buffer.write('- $title: $preview\n');
    }

    buffer.write('\nCalendar events: ${calendarEvents.length}\n');
    for (final event in calendarEvents.take(3)) {
      final title = event.summary ?? 'Untitled';
      final startTime = event.start?.dateTime?.hour.toString().padLeft(2, '0');
      buffer.write('- $title (${startTime}:00:${startTime}:00)\n');
    }

    return buffer.toString();
  }

  /// Generate AI-powered schedule using Kimi K3
  Future<List<PlannedTask>> _generateAISchedule(String context) async {
    try {
      final prompt = _createPlanningPrompt(context);
      final response = await _kimiService.generateResponse(
        prompt,
        [], // No conversation history for planning
      );

      // Parse AI response into structured tasks
      return _parsePlanResponse(response);
    } catch (e) {
      // Fallback to simple heuristic when AI fails
      return _generateHeuristicSchedule();
    }
  }

  /// Create prompt for AI planning
  String _createPlanningPrompt(String context) {
    return '''Generate a structured daily schedule based on the following context:
$context

Provide recommendations in this format:
1. TIME_BLOCK: [startTime]-[endTime]: [task description]
2. BREAK_BLOCK: [startTime]-[endTime]: [break/rest]
3. MEAL_BLOCK: [startTime]-[endTime]: [meal/activity]

Focus on:
- High priority tasks first
- Realistic time allocations
- Breaks and buffer time
- Important appointments/meals
- Work-life balance

Return exactly 5 time blocks covering 9 AM - 6 PM (weekday hours).''';
  }

  /// Parse AI response into structured planned tasks
  List<PlannedTask> _parsePlanResponse(String response) {
    final lines = response.split('\n');
    final plannedTasks = <PlannedTask>[];

    for (final line in lines) {
      if (line.trim().isEmpty || !line.contains(':')) continue;

      final match = RegExp(r'(\w+)_BLOCK:\s*(\d{1,2}:\d{2})-(\d{1,2}:\d{2}):\s*(.*)').firstMatch(line);
      if (match != null) {
        final type = match.group(1)!;
        final startTime = match.group(2)!;
        final endTime = match.group(3)!;
        final description = match.group(4)!;

        if (type == 'TASK' && description.contains(':')) {
          final colonIndex = description.indexOf(':');
          final taskTitle = description.substring(0, colonIndex).trim();
          final taskNotes = description.substring(colonIndex + 1).trim();

          plannedTasks.add(PlannedTask(
            title: taskTitle,
            startTime: startTime,
            endTime: endTime,
            description: taskNotes,
            priority: _inferPriority(taskTitle, taskNotes),
          ));
        } else if (type == 'BREAK') {
          plannedTasks.add(PlannedTask(
            title: 'Break/Review',
            startTime: startTime,
            endTime: endTime,
            description: 'Rest, stretch, or quick review',
            priority: 'medium',
          ));
        } else if (type == 'MEAL') {
          plannedTasks.add(PlannedTask(
            title: description,
            startTime: startTime,
            endTime: endTime,
            description: 'Meal and rest',
            priority: 'low',
          ));
        }
      }
    }

    // Ensure we have exactly 5 blocks
    if (plannedTasks.length != 5) {
      plannedTasks.clear();
      plannedTasks.addAll(_generateHeuristicSchedule());
    }

    return plannedTasks;
  }

  /// Generate heuristic fallback schedule when AI fails
  List<PlannedTask> _generateHeuristicSchedule() {
    final baseTime = DateTime.now();
    final startTime = DateTime(baseTime.year, baseTime.month, baseTime.day, 9, 0);

    final tasks = [
      PlannedTask(
        title: 'Morning setup and planning',
        startTime: '09:00',
        endTime: '09:30',
        description: 'Review calendar, prioritize tasks',
        priority: 'high',
      ),
      PlannedTask(
        title: 'Deep work session 1',
        startTime: '09:30',
        endTime: '11:30',
        description: 'High priority project work',
        priority: 'high',
      ),
      PlannedTask(
        title: 'Lunch break',
        startTime: '11:30',
        endTime: '12:30',
        description: 'Eat, rest, step away from work',
        priority: 'low',
      ),
      PlannedTask(
        title: 'Deep work session 2',
        startTime: '12:30',
        endTime: '14:30',
        description: 'Continue important tasks',
        priority: 'high',
      ),
      PlannedTask(
        title: 'Wrap up and planning',
        startTime: '14:30',
        endTime: '16:00',
        description: 'Complete tasks, plan for tomorrow',
        priority: 'medium',
      ),
    ];

    return tasks;
  }

  /// Infer task priority from title and description
  String _inferPriority(String title, String description) {
    final lower = title.toLowerCase() + ' ' + description.toLowerCase();
    if (lower.contains('urgent') || lower.contains('critical') || lower.contains('important') || lower.contains('deadline')) {
      return 'high';
    } else if (lower.contains('review') || lower.contains('plan') || lower.contains('prepare')) {
      return 'medium';
    }
    return 'low';
  }

  /// Assign planned tasks to local storage
  Future<List<PlannedTask>> _assignPlanToLocalTasks(List<PlannedTask> plan) async {
    for (final plannedTask in plan) {
      try {
        final existingTasks = await _taskRepo.getAllTasks();
        final existingTask = existingTasks.firstWhere(
          (t) => t.title.toLowerCase().contains(plannedTask.title.toLowerCase()),
          orElse: () => throw StateError('No matching task'),
        );

        await _taskRepo.updateTask(existingTask.copyWith(
          description: plannedTask.description,
          priority: plannedTask.priority,
        ));
      } catch (_) {
        // Create new task if not found
        final now = DateTime.now().toIso8601String();
        final newTask = TaskModel(
          title: plannedTask.title,
          description: plannedTask.description,
          priority: plannedTask.priority,
          status: 'todo',
          createdAt: now,
          updatedAt: now,
        );

        await _taskRepo.insertTask(newTask);
      }
    }

    return plan;
  }
}

class PlannedTask {
  final String title;
  final String startTime;
  final String endTime;
  final String description;
  final String priority;

  PlannedTask({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.priority,
  });

  /// Calculate duration in minutes
  int get duration {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    return endMinutes - startMinutes;
  }

  /// Get day of week from time (assuming weekday schedule)
  String get day => 'Today';
}