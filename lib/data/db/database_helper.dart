import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/task_model.dart';
import '../models/note_model.dart';

/// Database helper class that manages the SQLite database
/// for PRAVIN tasks and notes storage
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'pravin.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        priority TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        reminder_enabled INTEGER,
        reminder_time TEXT,
        completed_at TEXT,
        folder TEXT,
        tags TEXT,
        recurrence TEXT,
        estimated_time TEXT,
        location TEXT,
        attachments TEXT,
        color TEXT,
        is_favorite INTEGER,
        is_archived INTEGER
      )
    ''');

    // Create notes table
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        folder TEXT,
        tags TEXT,
        is_favorite INTEGER,
        is_archived INTEGER,
        color TEXT,
        attachments TEXT,
        last_modified_by TEXT,
        last_modified_at TEXT,
        version INTEGER
      )
    ''');

    // Create index for faster searches
    await db.execute('CREATE INDEX idx_tasks_title ON tasks(title)');
    await db.execute('CREATE INDEX idx_notes_title ON notes(title)');
  }

  // Task CRUD operations

  Future<int> insertTask(TaskModel task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<TaskModel?> getTask(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TaskModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<TaskModel>> getAllTasks({String? status}) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (status != null) {
      where = 'status = ?';
      whereArgs = [status];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'due_date ASC',
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  Future<int> updateTask(TaskModel task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Note CRUD operations

  Future<int> insertNote(NoteModel note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<NoteModel?> getNote(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return NoteModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<NoteModel>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]));
  }

  Future<int> updateNote(NoteModel note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search operations

  Future<List<TaskModel>> searchTasks(String query) async {
    final db = await database;
    final String searchQuery = '%$query%';
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: [searchQuery, searchQuery],
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    final db = await database;
    final String searchQuery = '%$query%';
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: [searchQuery, searchQuery],
    );
    return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]));
  }

  // Database management

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}