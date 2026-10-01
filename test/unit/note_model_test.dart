import 'package:flutter_test/flutter_test.dart';
import 'package:pravin/data/models/note_model.dart';

void main() {
  group('NoteModel', () {
    test('should create note with default values', () {
      final note = NoteModel(
        title: 'Test Note',
        content: 'Test content',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      );

      expect(note.title, equals('Test Note'));
      expect(note.content, equals('Test content'));
      expect(note.isFavorite, isFalse);
      expect(note.isArchived, isFalse);
      expect(note.version, equals(1));
    });

    test('should convert to map correctly', () {
      final note = NoteModel(
        id: 1,
        title: 'Test Note',
        content: 'Test content',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
        isFavorite: true,
        isArchived: false,
        tags: ['work', 'important'],
      );

      final map = note.toMap();

      expect(map['id'], equals(1));
      expect(map['title'], equals('Test Note'));
      expect(map['content'], equals('Test content'));
      expect(map['is_favorite'], equals(1));
      expect(map['is_archived'], equals(0));
      expect(map['tags'], equals('work,important'));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'title': 'Test Note',
        'content': 'Test content',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
        'is_favorite': 1,
        'is_archived': 0,
        'tags': 'work,important',
        'color': '#FF0000',
        'version': 2,
      };

      final note = NoteModel.fromMap(map);

      expect(note.id, equals(1));
      expect(note.title, equals('Test Note'));
      expect(note.content, equals('Test content'));
      expect(note.isFavorite, isTrue);
      expect(note.isArchived, isFalse);
      expect(note.tags, equals(['work', 'important']));
      expect(note.color, equals('#FF0000'));
      expect(note.version, equals(2));
    });

    test('should handle empty title', () {
      final note = NoteModel(
        title: null,
        content: 'Content',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      );

      expect(note.title, isNull);
    });

    test('should copy with modified fields', () {
      final note = NoteModel(
        title: 'Original',
        content: 'Content',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      );

      final updated = note.copyWith(
        title: 'Updated',
        isFavorite: true,
      );

      expect(updated.title, equals('Updated'));
      expect(updated.isFavorite, isTrue);
      expect(updated.content, equals('Content'));
      expect(updated.createdAt, equals(note.createdAt));
    });

    test('should handle null fields in map', () {
      final map = {
        'id': 1,
        'title': null,
        'content': 'Test content',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
        'is_favorite': 0,
        'is_archived': 0,
        'tags': null,
        'color': null,
        'attachments': null,
        'last_modified_by': null,
        'last_modified_at': null,
        'version': 1,
      };

      final note = NoteModel.fromMap(map);

      expect(note.title, isNull);
      expect(note.tags, isEmpty);
      expect(note.attachments, isEmpty);
    });
  });
}