import 'package:flutter_test/flutter_test.dart';
import 'package:pravin/data/models/task_model.dart';

void main() {
  group('TaskModel', () {
    test('should create task with default values', () {
      final task = TaskModel(
        title: 'Test Task',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      );

      expect(task.title, equals('Test Task'));
      expect(task.status, equals('todo'));
      expect(task.priority, isNull);
      expect(task.isFavorite, isFalse);
      expect(task.isArchived, isFalse);
      expect(task.reminderEnabled, isFalse);
    });

    test('should convert to map correctly', () {
      final task = TaskModel(
        id: 1,
        title: 'Test Task',
        description: 'Description',
        dueDate: '2024-12-31',
        priority: 'high',
        status: 'todo',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
        isFavorite: true,
        isArchived: false,
        reminderEnabled: true,
      );

      final map = task.toMap();

      expect(map['id'], equals(1));
      expect(map['title'], equals('Test Task'));
      expect(map['description'], equals('Description'));
      expect(map['due_date'], equals('2024-12-31'));
      expect(map['priority'], equals('high'));
      expect(map['status'], equals('todo'));
      expect(map['is_favorite'], equals(1));
      expect(map['is_archived'], equals(0));
      expect(map['reminder_enabled'], equals(1));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'title': 'Test Task',
        'description': 'Description',
        'due_date': '2024-12-31',
        'priority': 'high',
        'status': 'todo',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
        'is_favorite': 1,
        'is_archived': 0,
        'reminder_enabled': 1,
        'reminder_time': null,
        'completed_at': null,
        'folder': null,
        'tags': null,
        'recurrence': null,
        'estimated_time': null,
        'location': null,
        'attachments': null,
        'color': null,
      };

      final task = TaskModel.fromMap(map);

      expect(task.id, equals(1));
      expect(task.title, equals('Test Task'));
      expect(task.description, equals('Description'));
      expect(task.dueDate, equals('2024-12-31'));
      expect(task.priority, equals('high'));
      expect(task.status, equals('todo'));
      expect(task.isFavorite, isTrue);
      expect(task.isArchived, isFalse);
      expect(task.reminderEnabled, isTrue);
    });

    test('should handle tags correctly', () {
      final task = TaskModel(
        title: 'Test Task',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
        tags: ['work', 'urgent'],
      );

      final map = task.toMap();
      expect(map['tags'], equals('work,urgent'));

      final restored = TaskModel.fromMap(map);
      expect(restored.tags, equals(['work', 'urgent']));
    });

    test('should copy with modified fields', () {
      final task = TaskModel(
        title: 'Test Task',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      );

      final updated = task.copyWith(
        title: 'Updated Task',
        status: 'completed',
        completedAt: '2024-01-02T00:00:00.000Z',
      );

      expect(updated.title, equals('Updated Task'));
      expect(updated.status, equals('completed'));
      expect(updated.completedAt, equals('2024-01-02T00:00:00.000Z'));
      expect(updated.createdAt, equals(task.createdAt));
    });

    test('should handle null tags', () {
      final task = TaskModel(
        title: 'Test Task',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
        tags: null,
      );

      final map = task.toMap();
      expect(map['tags'], isNull);

      final restored = TaskModel.fromMap(map);
      expect(restored.tags, isEmpty);
    });
  });
}