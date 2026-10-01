import 'package:flutter/material.dart';
import 'package:googleapis/tasks/v1.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/services/google_tasks_service.dart';

/// Tasks management page with Google Tasks sync (Phase 5)
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final GoogleAuthService _authService = GoogleAuthService();
  final GoogleTasksService _tasksService = GoogleTasksService();
  List<Task> _tasks = [];
  List<TaskList> _taskGroups = [];
  bool _isLoading = false;
  String? _authError;
  String? _selectedListId = 'tasks';

  @override
  void initState() {
    super.initState();
    _authService.onCurrentUserChanged.listen((account) {
      if (mounted) setState(() {});
    });
  }

  bool get _isSignedIn => _authService.isSignedIn;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _authError = null;
    });
    try {
      _taskGroups = await _tasksService.getTaskGroups() ?? [];
      _tasks = await _tasksService.getTasks(listId: _selectedListId) ?? [];
      setState(() {
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
        _tasksService.setAuthClient(_authService.authClient);
        _loadData();
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
      _tasks.clear();
      _taskGroups.clear();
      _authError = null;
    });
  }

  void _onListChanged(String listId) {
    setState(() {
      _selectedListId = listId;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          if (_isSignedIn)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh tasks',
              onPressed: _isLoading ? null : _loadData,
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
              content: Text('Create new task via natural language in chat'),
            ),
          );
        },
        tooltip: 'New Task',
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
            const Icon(Icons.task_alt, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sign in to sync Google Tasks',
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

    if (_isLoading && _tasks.isEmpty && _taskGroups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_taskGroups.isNotEmpty)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: _taskGroups.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildListChip('Default Tasks', 'tasks', _selectedListId == 'tasks');
                }
                final group = _taskGroups[index - 1];
                final groupId = group.id ?? '';
                return _buildListChip(group.title, groupId, _selectedListId == groupId);
              },
            ),
          ),
        Expanded(
          child: _tasks.isEmpty
              ? const Center(
                  child: Text(
                    'No tasks found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final status = task.status ?? 'needsAction';
                    final isCompleted = status == 'completed';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isCompleted ? Colors.grey[50] : null,
                      child: ListTile(
                        leading: Icon(
                          isCompleted ? Icons.check_box : Icons.task_alt,
                          color: isCompleted ? Colors.green : null,
                        ),
                        title: Text(
                          task.title ?? 'No title',
                          style: isCompleted
                              ? const TextStyle(decoration: TextDecoration.lineThrough)
                              : null,
                        ),
                        subtitle: Text(task.notes ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isCompleted ? Icons.refresh : Icons.check_box,
                                color: Colors.blue,
                              ),
                              onPressed: () async {
                                final newStatus = isCompleted ? 'needsAction' : 'completed';
                                final updatedTask = await _tasksService.updateTask(
                                  taskId: task.id!,
                                  status: newStatus,
                                  listId: _selectedListId,
                                );
                                if (updatedTask != null) {
                                  setState(() {
                                    _tasks[index] = updatedTask;
                                  });
                                }
                              },
                              tooltip: isCompleted ? 'Mark as incomplete' : 'Mark as complete',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                if (task.id != null) {
                                  await _tasksService.deleteTask(task.id!, listId: _selectedListId);
                                  setState(() {
                                    _tasks.removeAt(index);
                                  });
                                }
                              },
                              tooltip: 'Delete task',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListChip(String? title, String listId, bool selected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(title ?? ''),
        selected: selected,
        onSelected: (selected) {
          if (selected) _onListChanged(listId);
        },
        selectedColor: Colors.blue[100],
        labelStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}