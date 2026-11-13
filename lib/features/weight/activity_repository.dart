import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'activity_log.dart';

abstract class ActivityRepository {
  Future<void> add(ActivityLog a); // Create
  Future<List<ActivityLog>> getRange(DateTime start, DateTime end); // Read
  Future<void> update(ActivityLog a); // Update
  Future<void> delete(String id); // Delete
}

class SqliteActivityRepository implements ActivityRepository {
  Database? _db;
  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'activity.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE activities(
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          intensity TEXT NOT NULL,
          durationMin INTEGER NOT NULL,
          kcal REAL NOT NULL,
          note TEXT,
          date INTEGER NOT NULL
        )
      '''),
    );
  }

  @override
  Future<void> add(ActivityLog a) async {
    final db = await _database;
    await db.insert('activities', a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<ActivityLog>> getRange(DateTime start, DateTime end) async {
    final db = await _database;
    final rows = await db.query(
      'activities',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date ASC',
    );
    return rows.map(ActivityLog.fromMap).toList();
  }

  @override
  Future<void> update(ActivityLog a) async {
    final db = await _database;
    await db.update('activities', a.toMap(),
        where: 'id = ?', whereArgs: [a.id]);
  }

  @override
  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }
}