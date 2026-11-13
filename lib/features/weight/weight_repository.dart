import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'goal.dart';
import 'weight_entry.dart';

abstract class WeightRepository {
  Future<void> addEntry(WeightEntry e);        // Create
  Future<List<WeightEntry>> getAllEntries();   // Read (plus récent d'abord)
  Future<void> updateEntry(WeightEntry e);     // Update
  Future<void> deleteEntry(String id);         // Delete

  Future<Goal?> getGoal();
  Future<void> saveGoal(Goal g);
}

class SqliteWeightRepository implements WeightRepository {
  Database? _db;
  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'weight.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE weights(
            id TEXT PRIMARY KEY,
            weightKg REAL NOT NULL,
            waistCm REAL,
            note TEXT,
            date INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE goal(
            id INTEGER PRIMARY KEY,
            type TEXT NOT NULL,
            startWeightKg REAL NOT NULL,
            targetWeightKg REAL NOT NULL,
            targetDate INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<void> addEntry(WeightEntry e) async {
    final db = await _database;
    await db.insert('weights', e.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<WeightEntry>> getAllEntries() async {
    final db = await _database;
    final rows = await db.query('weights', orderBy: 'date DESC');
    return rows.map(WeightEntry.fromMap).toList();
  }

  @override
  Future<void> updateEntry(WeightEntry e) async {
    final db = await _database;
    await db.update('weights', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final db = await _database;
    await db.delete('weights', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Goal?> getGoal() async {
    final db = await _database;
    final rows = await db.query('goal', where: 'id = 1');
    return rows.isEmpty ? null : Goal.fromMap(rows.first);
  }

  @override
  Future<void> saveGoal(Goal g) async {
    final db = await _database;
    await db.insert('goal', g.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}