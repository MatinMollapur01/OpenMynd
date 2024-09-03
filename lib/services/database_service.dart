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
      version: 4, // Increase this to 4
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
      isCompleted INTEGER NOT NULL
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
      customDays TEXT
    )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the 'tags' column to the 'tasks' table
      await db.execute('ALTER TABLE tasks ADD COLUMN tags TEXT');
    }
    if (oldVersion < 3) {
      // Add the new columns to the 'habits' table
      await _addColumnIfNotExists(db, 'habits', 'icon', 'INTEGER');
      await _addColumnIfNotExists(db, 'habits', 'color', 'INTEGER');
      await _addColumnIfNotExists(db, 'habits', 'category', 'TEXT');
      await _addColumnIfNotExists(db, 'habits', 'completionStatus', 'TEXT');
      await _addColumnIfNotExists(db, 'habits', 'createdAt', 'TEXT');
      await _addColumnIfNotExists(db, 'habits', 'notes', 'TEXT');
      await _addColumnIfNotExists(db, 'habits', 'reminderTime', 'TEXT');
    }
    if (oldVersion < 4) { // Increase the version number
      // Add the new columns for frequency and customDays
      await _addColumnIfNotExists(db, 'habits', 'frequency', 'INTEGER');
      await _addColumnIfNotExists(db, 'habits', 'customDays', 'TEXT');
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
    final result = await db.query('tasks');
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
    return await db.update('habits', _habitToMap(habit), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<int> deleteHabit(String id) async {
    final db = await instance.database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
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
      frequency: map['frequency'] != null ? HabitFrequency.values[map['frequency']] : HabitFrequency.daily,
      completionStatus: (map['completionStatus'] as String).split(',').map((e) => e == 'true').toList(),
      createdAt: DateTime.parse(map['createdAt']),
      notes: (map['notes'] as String).split('|'),
      reminderTime: reminderTime,
      customDays: map['customDays'] != null ? (map['customDays'] as String).split(',').map((e) => int.parse(e)).toList() : null,
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
}