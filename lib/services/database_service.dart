import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/habit.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('openmynd.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 10, // Increase this to 10
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE tasks(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      dueDate TEXT,
      priority TEXT NOT NULL,
      category TEXT NOT NULL,
      tags TEXT,
      isCompleted INTEGER NOT NULL,
      completedDate TEXT
    )
    ''');

    await _createHabitsTable(db);

    await db.execute('''
    CREATE TABLE streaks(
      date TEXT PRIMARY KEY,
      streak_count INTEGER NOT NULL
    )
    ''');
  }

  Future<void> _createHabitsTable(Database db) async {
    await db.execute('''
    CREATE TABLE habits(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      iconCodePoint INTEGER NOT NULL,
      color INTEGER NOT NULL,
      category TEXT NOT NULL,
      completionStatus TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      notes TEXT,
      reminderTime TEXT,
      frequency INTEGER,
      customDays TEXT,
      isCompletedToday INTEGER NOT NULL,
      lastCompletionTime TEXT,
      nextDueTime TEXT,
      recentCompletions TEXT
    )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 10) {
      // Drop the existing habits table and recreate it
      await db.execute('DROP TABLE IF EXISTS habits');
      await _createHabitsTable(db);
    }
  }

  Future<void> _addColumnIfNotExists(Database db, String tableName, String columnName, String columnType) async {
    final result = await db.rawQuery('PRAGMA table_info($tableName)');
    final columnExists = result.any((column) => column['name'] == columnName);
    if (!columnExists) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
    }
  }

  Future<void> _removeColumnIfExists(Database db, String tableName, String columnName) async {
    final result = await db.rawQuery('PRAGMA table_info($tableName)');
    final columnExists = result.any((column) => column['name'] == columnName);
    if (columnExists) {
      // SQLite does not support dropping columns directly, so we need to recreate the table
      final tempTableName = '${tableName}_temp';
      await db.execute('''
      CREATE TABLE $tempTableName AS SELECT * FROM $tableName WHERE 0
      ''');
      await db.execute('''
      INSERT INTO $tempTableName SELECT * FROM $tableName
      ''');
      await db.execute('''
      DROP TABLE $tableName
      ''');
      await db.execute('''
      ALTER TABLE $tempTableName RENAME TO $tableName
      ''');
    }
  }

  // Task CRUD operations
  Future<int> createTask(Task task) async {
    final db = await instance.database;
    return await db.insert('tasks', task.toJson());
  }

  Future<Task?> readTask(String id) async {
    final db = await instance.database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Task.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Task>> readAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', where: 'isCompleted = ?', whereArgs: [0]);
    return result.map((map) => Task.fromJson(map)).toList();
  }

  Future<List<Task>> readCompletedTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', where: 'isCompleted = ?', whereArgs: [1]);
    return result.map((map) => Task.fromJson(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return await db.update('tasks', task.toJson(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<int> deleteTask(String id) async {
    final db = await instance.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Habit CRUD operations
  Future<int> createHabit(Habit habit) async {
    final db = await instance.database;
    print('Inserting habit: ${habit.toJson()}'); // Add this line for debugging
    return await db.insert('habits', habit.toJson());
  }

  Future<Habit?> readHabit(String id) async {
    final db = await instance.database;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Habit.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Habit>> readAllHabits() async {
    final db = await instance.database;
    final result = await db.query('habits');
    print('Raw habit data: $result'); // Keep this line for debugging
    return result.map((map) {
      var mutableMap = Map<String, dynamic>.from(map);
      if (mutableMap['recentCompletions'] != null) {
        try {
          final decodedCompletions = jsonDecode(mutableMap['recentCompletions'] as String);
          mutableMap['recentCompletions'] = decodedCompletions is Map ? decodedCompletions : {};
        } catch (e) {
          print('Error decoding recentCompletions: $e');
          mutableMap['recentCompletions'] = {};
        }
      } else {
        mutableMap['recentCompletions'] = {};
      }
      return Habit.fromJson(mutableMap);
    }).toList();
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await instance.database;
    final json = habit.toJson();
    json['recentCompletions'] = jsonEncode(habit.recentCompletions.map((key, value) => MapEntry(key.toIso8601String(), value)));
    return await db.update('habits', json, where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<int> deleteHabit(String id) async {
    final db = await instance.database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // Add a search method
  Future<List<Task>> searchTasks(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return result.map((map) => Task.fromJson(map)).toList();
  }

  Future<void> updateStreakCount(int streakCount, DateTime date) async {
    final db = await instance.database;
    await db.insert(
      'streaks',
      {'date': date.toIso8601String(), 'streak_count': streakCount},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getStreakCount() async {
    final db = await instance.database;
    final result = await db.query(
      'streaks',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['streak_count'] as int;
    }
    return 0;
  }
}