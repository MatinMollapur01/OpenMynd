import 'package:flutter/material.dart';
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
      version: 7, // Increase this to 7
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
      completedDate TEXT // New field
    )
    ''');

    await db.execute('''
    CREATE TABLE habits(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      icon INTEGER NOT NULL,
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
      nextDueTime TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE streaks(
      date TEXT PRIMARY KEY,
      streak_count INTEGER NOT NULL
    )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      // Add the new columns to the 'habits' table
      await _addColumnIfNotExists(db, 'habits', 'isCompletedToday', 'INTEGER');
      await _addColumnIfNotExists(db, 'habits', 'lastCompletionTime', 'TEXT');
      await _addColumnIfNotExists(db, 'habits', 'nextDueTime', 'TEXT');
    }
    if (oldVersion < 6) {
      // Create the streaks table if it doesn't exist
      await db.execute('''
      CREATE TABLE IF NOT EXISTS streaks(
        date TEXT PRIMARY KEY,
        streak_count INTEGER NOT NULL
      )
      ''');
    }
    if (oldVersion < 7) {
      // Add the new column to the 'tasks' table
      await _addColumnIfNotExists(db, 'tasks', 'completedDate', 'TEXT');
    }
  }

  Future<void> _addColumnIfNotExists(Database db, String tableName, String columnName, String columnType) async {
    final result = await db.rawQuery('PRAGMA table_info($tableName)');
    final columnExists = result.any((column) => column['name'] == columnName);
    if (!columnExists) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
    }
  }

  // Task CRUD operations
  Future<int> createTask(Task task) async {
    final db = await instance.database;
    final result = await db.insert('tasks', _taskToMap(task));
    print("Task inserted with id: $result");
    return result;
  }

  Future<Task?> readTask(String id) async {
    final db = await instance.database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return _taskFromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> readAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', where: 'isCompleted = ?', whereArgs: [0]);
    return result.map((map) => _taskFromMap(map)).toList();
  }

  Future<List<Task>> readCompletedTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', where: 'isCompleted = ?', whereArgs: [1]);
    return result.map((map) => _taskFromMap(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return await db.update('tasks', _taskToMap(task), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<int> deleteTask(String id) async {
    final db = await instance.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Habit CRUD operations
  Future<int> createHabit(Habit habit) async {
    final db = await instance.database;
    return await db.insert('habits', _habitToMap(habit));
  }

  Future<Habit?> readHabit(String id) async {
    final db = await instance.database;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return _habitFromMap(maps.first);
    }
    return null;
  }

  Future<List<Habit>> readAllHabits() async {
    final db = await instance.database;
    final result = await db.query('habits');
    return result.map((map) => _habitFromMap(map)).toList();
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await instance.database;
    return await db.update(
      'habits',
      _habitToMap(habit),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(String id) async {
    final db = await instance.database;
    return await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Helper methods for Task
  Map<String, dynamic> _taskToMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'dueDate': task.dueDate?.toIso8601String(),
      'priority': task.priority,
      'category': task.category,
      'tags': task.tags.join(','),
      'isCompleted': task.isCompleted ? 1 : 0,
      'completedDate': task.completedDate?.toIso8601String(), // New field
    };
  }

  Task _taskFromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      priority: map['priority'],
      category: map['category'],
      tags: (map['tags'] as String?)?.split(',') ?? [],
      isCompleted: map['isCompleted'] == 1,
      completedDate: map['completedDate'] != null ? DateTime.parse(map['completedDate']) : null, // New field
    );
  }

  // Helper methods for Habit
  Map<String, dynamic> _habitToMap(Habit habit) {
    return {
      'id': habit.id,
      'title': habit.title,
      'description': habit.description,
      'icon': habit.icon.codePoint,
      'color': habit.color.value,
      'category': habit.category,
      'frequency': habit.frequency.index,
      'completionStatus': habit.completionStatus.join(','),
      'createdAt': habit.createdAt.toIso8601String(),
      'notes': habit.notes.join('|'),
      'reminderTime': habit.reminderTime != null ? '${habit.reminderTime!.hour.toString().padLeft(2, '0')}:${habit.reminderTime!.minute.toString().padLeft(2, '0')}' : null,
      'customDays': habit.customDays?.join(','),
      'isCompletedToday': habit.isCompletedToday ? 1 : 0,
      'lastCompletionTime': habit.lastCompletionTime?.toIso8601String(),
      'nextDueTime': habit.nextDueTime?.toIso8601String(),
    };
  }

  Habit _habitFromMap(Map<String, dynamic> map) {
    TimeOfDay? reminderTime;
    if (map['reminderTime'] != null) {
      try {
        reminderTime = _parseTimeOfDay(map['reminderTime']);
      } catch (e) {
        print("Error parsing reminderTime: ${map['reminderTime']}");
        // Set reminderTime to null if parsing fails
      }
    }

    return Habit(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      color: Color(map['color']),
      category: map['category'],
      frequency: HabitFrequency.values[map['frequency']],
      completionStatus: (map['completionStatus'] as String).split(',').map((e) => e == 'true').toList(),
      createdAt: DateTime.parse(map['createdAt']),
      notes: (map['notes'] as String).split('|'),
      reminderTime: reminderTime,
      customDays: map['customDays'] != null ? (map['customDays'] as String).split(',').map((e) => int.parse(e)).toList() : null,
      isCompletedToday: map['isCompletedToday'] == 1,
      lastCompletionTime: map['lastCompletionTime'] != null ? DateTime.parse(map['lastCompletionTime']) : null,
      nextDueTime: map['nextDueTime'] != null ? DateTime.parse(map['nextDueTime']) : null,
    );
  }

  static TimeOfDay? _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      print("Error parsing TimeOfDay: $time");
      return null;
    }
  }

  // Add a search method
  Future<List<Task>> searchTasks(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return result.map((map) => _taskFromMap(map)).toList();
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