import 'package:flutter/material.dart';
import 'dart:async';
import '../models/habit.dart';
import '../services/database_service.dart';
import 'add_edit_habit_screen.dart';
import 'streaks_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  HabitsScreenState createState() => HabitsScreenState();
}

class HabitsScreenState extends State<HabitsScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Habit> _habits = [];
  int _streakCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeStreakCount();
    _loadHabits();
    _loadStreakCount();
    _startTimer();
  }

  Future<void> _initializeStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('streakCount')) {
      await prefs.setInt('streakCount', 0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final nextDay = DateTime(now.year, now.month, now.day + 1);
      if (now.isAfter(nextDay)) {
        _loadHabits();
      }
      setState(() {
        // This will trigger a rebuild of the UI every second
      });
    });
  }

  Future<void> _loadHabits() async {
    final habits = await _databaseService.readAllHabits();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _habits = habits.map((habit) {
        if (habit.lastCompletionTime == null || habit.lastCompletionTime!.isBefore(today)) {
          habit.isCompletedToday = false;
        }
        return habit;
      }).toList();
    });

    // Save the updated habits to the database
    for (final habit in _habits) {
      await _databaseService.updateHabit(habit);
    }

    await _updateStreakCount();
  }

  Future<void> _loadStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _streakCount = prefs.getInt('streakCount') ?? 0;
    });
  }

  Future<void> _updateStreakCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastStreakDate = prefs.getString('lastStreakDate');
      final storedStreakCount = prefs.getInt('streakCount') ?? 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      bool allCompletedToday = _habits.every((habit) => 
        !habit.shouldCompleteToday() || habit.isCompletedToday);

      int newStreakCount = storedStreakCount;
      if (allCompletedToday && _habits.isNotEmpty) {
        if (lastStreakDate == null || DateTime.parse(lastStreakDate).isBefore(today)) {
          newStreakCount = storedStreakCount + 1;
          await prefs.setString('lastStreakDate', today.toIso8601String());
        }
      } else {
        if (lastStreakDate != null && DateTime.parse(lastStreakDate).isAtSameMomentAs(today)) {
          newStreakCount = storedStreakCount - 1;
          await prefs.remove('lastStreakDate');
        }
      }

      // Ensure streak count does not go below zero
      newStreakCount = newStreakCount < 0 ? 0 : newStreakCount;

      await prefs.setInt('streakCount', newStreakCount);
      setState(() {
        _streakCount = newStreakCount;
      });

      // Update the streak count in the database
      await _databaseService.updateStreakCount(newStreakCount, today);
    } catch (e) {
      print("Error updating streak count: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update streak count: $e')),
      );
    }
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _databaseService.deleteHabit(habit.id);
      await NotificationService().cancelHabitReminder(habit.id);
      await _loadHabits(); // Reload habits to reflect changes

      // Check if there are no habits left and adjust the streak count
      if (_habits.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final storedStreakCount = prefs.getInt('streakCount') ?? 0;
        final newStreakCount = storedStreakCount > 0 ? storedStreakCount - 1 : 0;
        await prefs.setInt('streakCount', newStreakCount);
        setState(() {
          _streakCount = newStreakCount;
        });
        await _databaseService.updateStreakCount(newStreakCount, DateTime.now());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StreaksScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('$_streakCount', style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _habits.length,
        itemBuilder: (context, index) {
          final habit = _habits[index];
          return _buildHabitTile(habit);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHabitTile(Habit habit) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: habit.color,
        child: Icon(habit.icon, color: Colors.white),
      ),
      title: Text(habit.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(habit.category),
          if (habit.nextDueTime != null)
            Text('Next due: ${_getTimeUntilNextDue(habit.nextDueTime!)}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          habit.isCompletedToday
              ? Text(_getTimeUntilNextDue(habit.nextDueTime!))
              : Checkbox(
                  value: habit.isCompletedToday,
                  onChanged: (bool? value) {
                    _toggleHabitCompletion(habit);
                  },
                ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteHabit(habit),
          ),
        ],
      ),
      onTap: () => _editHabit(habit),
    );
  }

  String _getTimeUntilNextDue(DateTime nextDueTime) {
    final now = DateTime.now();
    final difference = nextDueTime.difference(now);
    if (difference.isNegative) {
      return '0s';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ${difference.inSeconds % 60}s';
    } else {
      return '${difference.inSeconds}s';
    }
  }

  Future<void> _toggleHabitCompletion(Habit habit) async {
    try {
      if (habit.isCompletedToday) {
        habit.uncompleteHabit();
      } else {
        habit.completeHabit();
      }
      await _databaseService.updateHabit(habit);
      await _loadHabits(); // This will also call _updateStreakCount()
    } catch (e) {
      print("Error toggling habit completion: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update habit: $e')),
      );
    }
  }

  Future<void> _addHabit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditHabitScreen()),
    );
    if (result != null && result is Habit) {
      await _databaseService.createHabit(result);
      if (result.reminderTime != null) {
        await NotificationService().scheduleHabitReminder(result);
      }
      await _loadHabits(); // Reload habits to reflect changes

      // Ensure streak count does not go below zero if this is the first habit
      if (_habits.length == 1) {
        final prefs = await SharedPreferences.getInstance();
        final storedStreakCount = prefs.getInt('streakCount') ?? 0;
        final newStreakCount = storedStreakCount < 0 ? 0 : storedStreakCount;
        await prefs.setInt('streakCount', newStreakCount);
        setState(() {
          _streakCount = newStreakCount;
        });
        await _databaseService.updateStreakCount(newStreakCount, DateTime.now());
      }
    }
  }

  Future<void> _editHabit(Habit habit) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditHabitScreen(habit: habit)),
    );
    if (result != null && result is Habit) {
      await _databaseService.updateHabit(result);
      if (result.reminderTime != null) {
        await NotificationService().scheduleHabitReminder(result);
      } else {
        await NotificationService().cancelHabitReminder(result.id);
      }
      await _loadHabits(); // Reload habits to reflect changes
    }
  }
}