import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'habit_detail_screen.dart';

class CategoryHabitsScreen extends StatefulWidget {
  final String category;
  final List<Habit> habits;

  const CategoryHabitsScreen({super.key, required this.category, required this.habits});

  @override
  CategoryHabitsScreenState createState() => CategoryHabitsScreenState();
}

class CategoryHabitsScreenState extends State<CategoryHabitsScreen> {
  late List<Habit> _habits;
  final DatabaseService _databaseService = DatabaseService.instance;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _habits = widget.habits;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: ListView.builder(
        itemCount: _habits.length,
        itemBuilder: (context, index) {
          return _buildHabitTile(_habits[index]);
        },
      ),
    );
  }

  Widget _buildHabitTile(Habit habit) {
    return ListTile(
      leading: Icon(habit.icon, color: habit.color),
      title: Text(habit.title),
      subtitle: Text('Streak: ${habit.streak} days'),
      trailing: Checkbox(
        value: habit.completionStatus.isNotEmpty ? habit.completionStatus.last : false,
        onChanged: (bool? value) {
          _toggleHabitCompletion(habit);
        },
      ),
      onTap: () => _editHabit(habit),
    );
  }

  void _toggleHabitCompletion(Habit habit) async {
    final updatedHabit = Habit(
      id: habit.id,
      title: habit.title,
      description: habit.description,
      icon: habit.icon,
      color: habit.color,
      category: habit.category,
      frequency: habit.frequency,
      completionStatus: [...habit.completionStatus, true],
      createdAt: habit.createdAt,
      notes: habit.notes,
      reminderTime: habit.reminderTime,
    );
    try {
      await _databaseService.updateHabit(updatedHabit);
      setState(() {
        _habits[_habits.indexWhere((h) => h.id == habit.id)] = updatedHabit;
      });
    } catch (e) {
      print("Error updating habit completion: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update habit completion: $e')),
      );
    }
  }

  void _editHabit(Habit habit) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HabitDetailScreen(habit: habit)),
    );
    if (result != null && result is Habit) {
      try {
        await _databaseService.updateHabit(result);
        if (result.reminderTime != null) {
          await _notificationService.scheduleHabitReminder(result);
        } else {
          await _notificationService.cancelHabitReminder(result.id);
        }
        setState(() {
          _habits[_habits.indexWhere((h) => h.id == habit.id)] = result;
        });
      } catch (e) {
        print("Error updating habit: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update habit: $e')),
        );
      }
    }
  }
}