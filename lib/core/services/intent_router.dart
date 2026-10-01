import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/env.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/planning_repository.dart';
import '../../data/models/task_model.dart';
import '../../data/models/note_model.dart';
import 'kimi_api_service.dart';

/// Routes user input to the appropriate handler based on intent classification
/// This is the core "prompt engineering" piece that classifies natural language
/// and extracts structured fields for PRAVIN's features.
class IntentRouter {
  final KimiApiService _apiService;
  final TaskRepository _taskRepo;
  final NoteRepository _noteRepo;
  final PlanningRepository _planningRepo;
  final ValueChanged<IntentClassification>? onClassification;
  final ValueChanged<String>? onResponse;

  IntentRouter({
    String? apiKey,
    String? model,
    this.onClassification,
    this.onResponse,
    TaskRepository? taskRepo,
    NoteRepository? noteRepo,
    PlanningRepository? planningRepo,
  }) : _apiService = KimiApiService(
          apiKey: apiKey ?? Env.kimiApiKey,
          model: model ?? Env.kimiModel,
        ),
        _taskRepo = taskRepo ?? TaskRepository(),
        _noteRepo = noteRepo ?? NoteRepository(),
        _planningRepo = planningRepo ?? PlanningRepository();

  /// Process user input and route to the appropriate handler
  Future<void> processInput({
    required String input,
    required BuildContext context,
    String? conversationHistory,
  }) async {
    if (!Env.hasRequiredKeys) {
      _showError(
        context,
        'Kimi API key not configured. Add KIMI_API_KEY to .env file.',
      );
      return;
    }

    final classification = await _classifyInput(input);

    if (onClassification != null) {
      onClassification!(classification);
    }

    // Route based on intent
    switch (classification.intent) {
      case 'task':
        await _handleTaskInput(input, classification, context);
      case 'calendar':
        await _handleCalendarInput(input, classification, context);
      case 'note':
        await _handleNoteInput(input, classification, context);
      case 'planning':
        await _handlePlanningInput(input, classification, context);
      case 'general':
      default:
        await _handleGeneralQa(input, context, conversationHistory);
    }
  }

  /// Classify the user input using Kimi K3
  Future<IntentClassification> _classifyInput(String input) async {
    try {
      return await _apiService.classifyIntent(input);
    } catch (e) {
      // Fallback to simple keyword matching on API failure
      return _fallbackClassification(input);
    }
  }

  /// Fallback classification using keyword matching when API is unavailable
  IntentClassification _fallbackClassification(String input) {
    final lowerInput = input.toLowerCase();

    // Task keywords
    if (lowerInput.contains('task') ||
        lowerInput.contains('todo') ||
        lowerInput.contains('reminder')) {
      return IntentClassification(
        intent: 'task',
        confidence: 'medium',
        extractedFields: {'title': input},
      );
    }

    // Calendar keywords
    if (lowerInput.contains('event') ||
        lowerInput.contains('meeting') ||
        lowerInput.contains('schedule') ||
        lowerInput.contains('calendar')) {
      return IntentClassification(
        intent: 'calendar',
        confidence: 'medium',
        extractedFields: {'title': input},
      );
    }

    // Note keywords
    if (lowerInput.contains('note')) {
      return IntentClassification(
        intent: 'note',
        confidence: 'medium',
        extractedFields: {'title': input},
      );
    }

    // Planning keywords
    if (lowerInput.contains('plan') || lowerInput.contains('schedule my day')) {
      return IntentClassification(
        intent: 'planning',
        confidence: 'high',
        extractedFields: {},
      );
    }

    // Default to general Q&A
    return IntentClassification(
      intent: 'general',
      confidence: 'low',
      extractedFields: {},
    );
  }

  /// Handle task-related input
  Future<void> _handleTaskInput(
    String input,
    IntentClassification classification,
    BuildContext context,
  ) async {
    final fields = classification.extractedFields;
    final snackBar = SnackBar(
      content: Text('Task: "${fields['title'] ?? input}"'),
      action: SnackBarAction(
        label: 'Create',
        onPressed: () async {
          final taskTitle = fields['title'] ?? input;
          final now = DateTime.now().toIso8601String();
          final task = TaskModel(
            title: taskTitle,
            description: input,
            priority: 'medium',
            status: 'todo',
            createdAt: now,
            updatedAt: now,
          );

          try {
            await _taskRepo.insertTask(task);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task created successfully')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create task: ${e}')),
            );
          }
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Handle calendar-related input
  Future<void> _handleCalendarInput(
    String input,
    IntentClassification classification,
    BuildContext context,
  ) async {
    final fields = classification.extractedFields;
    final snackBar = SnackBar(
      content: Text('Calendar: "${fields['title'] ?? input}"'),
      action: SnackBarAction(
        label: 'Create',
        onPressed: () async {
          final eventTitle = fields['title'] ?? input;
          // Note: Calendar integration requires Google Auth
          // The GoogleCalendarService needs to be attached first
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${eventTitle}" - Sign in to Google Calendar to create'),
              action: SnackBarAction(
                label: 'Sign In',
                onPressed: () {
                  // Trigger Google sign in via HomeScreen
                  Navigator.pushNamed(context, '/calendar');
                },
              ),
            ),
          );
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Handle note-related input
  Future<void> _handleNoteInput(
    String input,
    IntentClassification classification,
    BuildContext context,
  ) async {
    final fields = classification.extractedFields;
    final snackBar = SnackBar(
      content: Text('Note: "${fields['title'] ?? input}"'),
      action: SnackBarAction(
        label: 'Save',
        onPressed: () async {
          final noteTitle = fields['title'] ?? input;
          final now = DateTime.now().toIso8601String();
          final note = NoteModel(
            title: noteTitle,
            content: input,
            createdAt: now,
            updatedAt: now,
            isFavorite: false,
            isArchived: false,
            version: 1,
          );

          try {
            await _noteRepo.insertNote(note);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note saved successfully')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save note: ${e}')),
            );
          }
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Handle planning input
  Future<void> _handlePlanningInput(
    String input,
    IntentClassification classification,
    BuildContext context,
  ) async {
    final snackBar = const SnackBar(
      content: Text('Generating daily plan...'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // Generate AI-powered daily plan using PlanningRepository
    try {
      final plannedTasks = await _planningRepo.getTodaysTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily plan generated with ${plannedTasks.length} tasks!'),
          action: SnackBarAction(
            label: 'Review',
            onPressed: () {
              Navigator.pushNamed(context, '/planning');
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate plan: ${e}')),
      );
    }
  }

  /// Handle general Q&A input
  Future<void> _handleGeneralQa(
    String input,
    BuildContext context,
    String? conversationHistory,
  ) async {
    try {
      List<Map<String, String>> history = [];

      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        final dynamic decoded = json.decode(conversationHistory);
        if (decoded is List<dynamic>) {
          history = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => Map<String, String>.from(e))
              .toList();
        }
      }

      final response = await _apiService.generateResponse(input, history);

      if (onResponse != null) {
        onResponse!(response);
      }

      // Show response in chat UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI: $response')),
      );
    } catch (e) {
      _showError(context, 'Error getting response: ${e.toString()}');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}