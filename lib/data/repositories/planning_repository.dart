/// Planning repository abstraction
/// Wraps PlanningService to provide planned task operations
import 'dart:async';
import '../models/task_model.dart';
import '../../core/services/planning_service.dart';
import '../../core/services/kimi_api_service.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/services/google_calendar_service.dart';

class PlanningRepository {
  PlanningService? _planningService;

  void attachPlanningService(PlanningService service) {
    _planningService = service;
  }

  /// Generate daily plan using AI
  /// Returns list of tasks with time allocations
  Future<List<TaskModel>> generateDailyPlan() async {
    if (_planningService == null) {
      throw Exception('Planning service not attached');
    }
    return await _planningService.generateDailyPlan();
  }

  /// Get today's planned tasks
  /// Returns tasks that have been scheduled by AI planning
  Future<List<TaskModel>> getTodaysTasks() async {
    if (_planningService == null) {
      throw Exception('Planning service not attached');
    }
    return await _planningService.generateDailyPlan();
  }

  /// Add task to planning queue
  Future<void> addToPlanQueue(String taskTitle, String priority) async {
    final now = DateTime.now().toIso8601String();
    final task = TaskModel(
      title: taskTitle,
      description: 'Planned task from intent classification',
      priority: priority,
      status: 'todo',
      createdAt: now,
      updatedAt: now,
    );

    await _planningService?.assignToPlannedTasks(task);
  }

  /// Get planning statistics
  Future<PlanningStats> getStats() async {
    final tasks = await _planningService?.generateDailyPlan() ?? [];

    final today = DateTime.now();
    final highPriority = tasks.where((t) => t.priority == 'high').length;
    final mediumPriority = tasks.where((t) => t.priority == 'medium').length;
    final lowPriority = tasks.where((t) => t.priority == 'low').length;

    return PlanningStats(
      totalTasks: tasks.length,
      highPriority: highPriority,
      mediumPriority: mediumPriority,
      lowPriority: lowPriority,
    );
  }
}

class PlanningStats {
  final int totalTasks;
  final int highPriority;
  final int mediumPriority;
  final int lowPriority;

  PlanningStats({
    required this.totalTasks,
    required this.highPriority,
    required this.mediumPriority,
    required this.lowPriority,
  });

  /// Get percentage of tasks for a priority level
  double getPercentage(int value, int total) {
    if (total == 0) return 0.0;
    return (value / total) * 100;
  }

  /// Get completion rate (if tracking implemented)
  double get completionRate => 0.0; // Placeholder for future implementation
}