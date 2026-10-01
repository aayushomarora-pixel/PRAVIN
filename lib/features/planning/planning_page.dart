import 'package:flutter/material.dart';
import 'package:pravin/data/db/database_helper.dart';
import 'package:pravin/data/models/task_model.dart';
import 'package:pravin/core/services/google_auth_service.dart';
import 'package:pravin/core/services/google_calendar_service.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

/// Daily planning page that generates a schedule
/// Phase 6: Integrates tasks, calendar, and AI planning
class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final GoogleAuthService _authService = GoogleAuthService();
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  List<TaskModel> _todoTasks = [];
  List<TaskModel> _inProgressTasks = [];
  List<TaskModel> _completedTasks = [];
  List<calendar.Event> _todayEvents = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String? _planError;

  @override
  void initState() {
    super.initState();
    _authService.onCurrentUserChanged.listen((account) {
      if (mounted && account != null) {
        _loadTasks();
      }
    });
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final allTasks = await _db.getAllTasks(status: 'todo');
      final inProgress = await _db.getAllTasks(status: 'in_progress');
      final completed = await _db.getAllTasks(status: 'completed');

      setState(() {
        _todoTasks = allTasks;
        _inProgressTasks = inProgress;
        _completedTasks = completed.where((t) => t.completedAt != null).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load tasks: $e');
    }
  }

  Future<void> _loadCalendarEvents() async {
    if (!_authService.isSignedIn) return;

    try {
      final events = await _calendarService.getUpcomingEvents(
        maxResults: 20,
      );
      setState(() {
        _todayEvents = events ?? [];
      });
    } catch (e) {
      // Handle gracefully - calendar might not be available
      debugPrint('Calendar load error: $e');
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _planError = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      _loadTasks();
      if (_authService.isSignedIn) {
        await _loadCalendarEvents();
      }
    } catch (e) {
      setState(() {
        _planError = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeTask(TaskModel task) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _db.updateTask(task.copyWith(
        status: 'completed',
        completedAt: now,
        updatedAt: now,
      ));
      _loadTasks();
    } catch (e) {
      _showError('Failed to complete task: $e');
    }
  }

  Future<void> _startTask(TaskModel task) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _db.updateTask(task.copyWith(
        status: 'in_progress',
        updatedAt: now,
      ));
      _loadTasks();
    } catch (e) {
      _showError('Failed to start task: $e');
    }
  }

  Future<void> _signInGoogle() async {
    try {
      final user = await _authService.signIn();
      if (user != null && mounted) {
        await _loadCalendarEvents();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in to Google Calendar')),
        );
      }
    } catch (e) {
      _showError('Sign in failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Planning'),
        actions: [
          if (_authService.isSignedIn)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _generatePlan,
              tooltip: 'Refresh Plan',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _todoTasks.isEmpty && _inProgressTasks.isEmpty
            ? null
            : () {
                showModalBottomSheet(
                  context: context,
                  enableDrag: true,
                  showDragHandle: true,
                  builder: (context) => _buildQuickAddSheet(),
                );
              },
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_planError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading plan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_planError!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generatePlan,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _generatePlan,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildToDoSection(),
          const SizedBox(height: 16),
          _buildInProgressSection(),
          const SizedBox(height: 16),
          _buildCompletedSection(),
          const SizedBox(height: 16),
          _buildCalendarSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 20),
        const SizedBox(width: 8),
        Text(
          'Today\'s Plan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Spacer(),
        if (_todayEvents.isNotEmpty)
          TextButton(
            onPressed: () {
              // Show calendar detail
            },
            child: const Text('View Calendar'),
          ),
      ],
    );
  }

  Widget _buildToDoSection() {
    if (_todoTasks.isEmpty) {
      return const Text(
        'No pending tasks',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'To Do (${_todoTasks.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._todoTasks.take(5).map((task) => _buildTaskListItem(task, false)),
      ],
    );
  }

  Widget _buildInProgressSection() {
    if (_inProgressTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'In Progress (${_inProgressTasks.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ..._inProgressTasks.map((task) => _buildTaskListItem(task, true)),
      ],
    );
  }

  Widget _buildTaskListItem(TaskModel task, bool isInProgress) {
    final hasDueDate = task.dueDate != null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.status == 'completed',
          onChanged: task.status != 'completed' ? (_) => _completeTask(task) : null,
        ),
        trailing: hasDueDate
            ? Icon(
                Icons.schedule,
                color: _isPastDue(task.dueDate!) ? Colors.red : null,
              )
            : null,
        title: Text(task.title),
        subtitle: Text(
          task.description ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _isPastDue(task.dueDate ?? '') ? Colors.red : null,
          ),
        ),
        onTap: () {
          // Mark as in progress or show task details
          if (task.status == 'todo') {
            _startTask(task);
          }
        },
      ),
    );
  }

  bool _isPastDue(String? dueDateStr) {
    if (dueDateStr == null) return false;
    try {
      final dueDate = DateTime.parse(dueDateStr);
      return dueDate.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Widget _buildCompletedSection() {
    if (_completedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completed Today (${_completedTasks.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        ..._completedTasks.take(3).map((task) => ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(
                task.title,
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
              onTap: () {
                // Could show details or remove
              },
            )),
      ],
    );
  }

  Widget _buildCalendarSection() {
    if (_todayEvents.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!_authService.isSignedIn) ...[
                const Icon(Icons.login, color: Colors.blue),
                const SizedBox(width: 4),
                const Text('Sign in to sync Google Calendar'),
              ] else ...[
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 4),
                const Text('Calendar synced'),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (!_authService.isSignedIn)
            ElevatedButton.icon(
              onPressed: _signInGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Schedule (${_todayEvents.length} events)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._todayEvents.take(5).map((event) => Card(
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.blue),
                title: Text(event.summary ?? 'No title'),
                subtitle: Text(_formatEventTime(event)),
              ),
            )),
      ],
    );
  }

  String _formatEventTime(calendar.Event event) {
    final start = event.start?.dateTime ?? event.start?.date;
    if (start == null) return '';

    final end = event.end?.dateTime ?? event.end?.date;

    final startTime = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTime = end != null
        ? '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}'
        : null;

    return endTime != null ? '$startTime - $endTime' : startTime;
  }

  Widget _buildQuickAddSheet() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedPriority = 'medium';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quick Add Task',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Task Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text('Priority'),
          Wrap(
            spacing: 8,
            children: ['high', 'medium', 'low'].map<Widget>((p) {
              return ChoiceChip(
                label: Text(p[0].toUpperCase() + p.substring(1)),
                selected: selectedPriority == p,
                onSelected: (bool selected) {
                  if (selected) {
                    selectedPriority = p;
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final now = DateTime.now().toIso8601String();
                    final newTask = TaskModel(
                      title: title,
                      description: descriptionController.text.isEmpty ? null : descriptionController.text.trim(),
                      priority: selectedPriority,
                      status: 'todo',
                      createdAt: now,
                      updatedAt: now,
                    );

                    try {
                      await _db.insertTask(newTask);
                      _loadTasks();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task added')),
                      );
                    } catch (e) {
                      _showError('Failed to add task: $e');
                    }
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}