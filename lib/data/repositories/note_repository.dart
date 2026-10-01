/// Note repository abstraction
/// Wraps DatabaseHelper to provide a unified interface
/// for note CRUD operations.
import 'dart:async';
import '../db/database_helper.dart';
import '../models/note_model.dart';

class NoteRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<NoteModel>> getAllNotes() async {
    return await _db.getAllNotes();
  }

  Future<NoteModel?> getNote(int id) async {
    return await _db.getNote(id);
  }

  Future<int> insertNote(NoteModel note) async {
    return await _db.insertNote(note);
  }

  Future<int> updateNote(NoteModel note) async {
    return await _db.updateNote(note);
  }

  Future<int> deleteNote(int id) async {
    return await _db.deleteNote(id);
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    return await _db.searchNotes(query);
  }

  Future<List<NoteModel>> getFavorites() async {
    final all = await _db.getAllNotes();
    return all.where((n) => n.isFavorite).toList();
  }

  Future<List<NoteModel>> getNotesByTag(String tag) async {
    final all = await _db.getAllNotes();
    return all.where((n) {
      if (n.tags == null) return false;
      return n.tags!.contains(tag);
    }).toList();
  }
}