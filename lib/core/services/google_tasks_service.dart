import 'package:googleapis/tasks/v1.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

/// Google Tasks API service
/// Handles two-way sync between PRAVIN and Google Tasks
class GoogleTasksService {
  static const String defaultListId = 'tasks';

  AuthClient? _authClient;

  GoogleTasksService({AuthClient? authClient}) : _authClient = authClient;

  /// Update the authenticated client used by this service
  void setAuthClient(AuthClient? authClient) {
    _authClient = authClient;
  }

  /// Get Google Tasks API instance
  TasksApi? get _tasksApi {
    if (_authClient == null) return null;
    return TasksApi(_authClient!);
  }

  /// List task groups (folders)
  Future<List<TaskList>?> getTaskGroups() async {
    final api = _tasksApi;
    if (api == null) return null;

    try {
      final result = await api.tasklists.list();
      return result.items;
    } catch (e) {
      throw Exception('Failed to fetch task groups: $e');
    }
  }

  /// List tasks from a task list
  Future<List<Task>?> getTasks({String? listId}) async {
    final api = _tasksApi;
    if (api == null) return null;

    try {
      final result = await api.tasks.list(listId ?? defaultListId);
      return result.items;
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  /// Create a new task
  Future<Task?> createTask({
    required String title,
    String? notes,
    String? dueDate,
    String? status,
    String? listId,
  }) async {
    final api = _tasksApi;
    if (api == null) return null;

    try {
      final task = Task()
        ..title = title
        ..notes = notes
        ..due = dueDate;

      if (status != null) {
        task.status = status;
      }

      final result = await api.tasks.insert(task, listId ?? defaultListId);
      return result;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update a task
  Future<Task?> updateTask({
    required String taskId,
    String? title,
    String? notes,
    String? dueDate,
    String? status,
    String? listId,
  }) async {
    final api = _tasksApi;
    if (api == null) return null;

    try {
      final task = await api.tasks.get(listId ?? defaultListId, taskId);
      task.title = title ?? task.title;
      task.notes = notes ?? task.notes;
      if (dueDate != null) {
        task.due = dueDate;
      }
      if (status != null) {
        task.status = status;
      }

      final result = await api.tasks.update(task, listId ?? defaultListId, taskId);
      return result;
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Mark a task as completed
  Future<void> completeTask(String taskId, {String? listId}) async {
    final api = _tasksApi;
    if (api == null) return;

    try {
      await api.tasks.update(Task()..status = 'completed', listId ?? defaultListId, taskId);
    } catch (e) {
      throw Exception('Failed to complete task: $e');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId, {String? listId}) async {
    final api = _tasksApi;
    if (api == null) return;

    try {
      await api.tasks.delete(listId ?? defaultListId, taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Move a task to another task list
  Future<Task?> moveTask({
    required String taskId,
    required String sourceListId,
    required String destinationListId,
  }) async {
    final api = _tasksApi;
    if (api == null) return null;

    try {
      final task = await api.tasks.get(sourceListId, taskId);
      final result = await api.tasks.insert(task, destinationListId);
      await api.tasks.delete(sourceListId, taskId);
      return result;
    } catch (e) {
      throw Exception('Failed to move task: $e');
    }
  }
}