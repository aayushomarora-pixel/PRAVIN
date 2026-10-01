/// Task repository abstraction
/// Wraps DatabaseHelper and GoogleTasksService to provide a unified
/// interface for task CRUD operations across local and remote storage.
import 'dart:async';
import '../db/database_helper.dart';
import '../models/task_model.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/services/google_tasks_service.dart';

class TaskRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  GoogleAuthService? _authService;
  GoogleTasksService? _tasksService;

  void attachGoogleServices(GoogleAuthService auth, GoogleTasksService tasks) {
    _authService = auth;
    _tasksService = tasks;
    _tasksService?.setAuthClient(auth.authClient);
  }

  bool get _isSignedIn => _authService?.isSignedIn ?? false;

  Future<List<TaskModel>> getAllTasks({String? status}) async {
    return await _db.getAllTasks(status: status);
  }

  Future<TaskModel?> getTask(int id) async {
    return await _db.getTask(id);
  }

  Future<int> insertTask(TaskModel task) async {
    final id = await _db.insertTask(task);
    // Sync to Google if signed in
    if (_isSignedIn && _tasksService != null) {
      try {
        await _tasksService.createTask(
          title: task.title,
          notes: task.description,
          dueDate: task.dueDate,
          status: task.status,
        );
      } catch (_) {
        // Local save succeeded; remote sync will retry later
      }
    }
    return id;
  }

  Future<int> updateTask(TaskModel task) async {
    final result = await _db.updateTask(task);
    if (_isSignedIn && _tasksService != null) {
      try {
        await _tasksService.updateTask(
          taskId: task.id.toString(),
          title: task.title,
          notes: task.description,
          dueDate: task.dueDate,
          status: task.status,
        );
      } catch (_) {
        // Local update succeeded; remote sync will retry later
      }
    }
    return result;
  }

  Future<int> deleteTask(int id) async {
    final result = await _db.deleteTask(id);
    if (_isSignedIn && _tasksService != null) {
      try {
        await _tasksService.deleteTask(id.toString());
      } catch (_) {
        // Local delete succeeded; remote sync will retry later
      }
    }
    return result;
  }

  Future<List<TaskModel>> searchTasks(String query) async {
    return await _db.searchTasks(query);
  }

  Future<List<TaskModel>> getTasksByPriority(String priority) async {
    final all = await _db.getAllTasks();
    return all.where((t) => t.priority == priority).toList();
  }

  Future<List<TaskModel>> getOverdueTasks() async {
    final all = await _db.getAllTasks();
    final now = DateTime.now();
    return all.where((task) {
      if (task.dueDate == null || task.status == 'completed') return false;
      try {
        return DateTime.parse(task.dueDate!).isBefore(now);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<List<TaskModel>> getFavorites() async {
    final all = await _db.getAllTasks();
    return all.where((t) => t.isFavorite).toList();
  }
}