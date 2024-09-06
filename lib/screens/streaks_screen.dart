import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openmynd/l10n/app_localizations.dart';

class StreaksScreen extends StatefulWidget {
  const StreaksScreen({super.key});

  @override
  StreaksScreenState createState() => StreaksScreenState();
}

class StreaksScreenState extends State<StreaksScreen> {
  int _streakCount = 0;
  List<Habit> _habits = [];
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _initializeStreakCount();
    _loadStreakData();
  }

  Future<void> _initializeStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('streakCount')) {
      await prefs.setInt('streakCount', 0);
    }
  }

  Future<void> _loadStreakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streakCount = prefs.getInt('streakCount') ?? 0;
      final habits = await _databaseService.readAllHabits();

      setState(() {
        _streakCount = streakCount;
        _habits = habits;
      });
    } catch (e) {
      print("Error loading streak data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load streak data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.streaks),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStreakData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.local_fire_department, size: 80, color: Colors.orange),
              Text(
                '$_streakCount',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              Text(
                localizations.dayStreak,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              ..._habits.map((habit) => _buildHabitCard(habit)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completionDates = <DateTime, bool>{};

    for (int i = 0; i <= today.difference(habit.createdAt).inDays; i++) {
      final date = habit.createdAt.add(Duration(days: i));
      completionDates[date] = habit.isCompletedOnDay(date);
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: habit.color,
                  child: Icon(habit.icon, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(habit.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ...completionDates.entries.map((entry) {
              final date = entry.key;
              final isCompleted = entry.value;
              return Row(
                children: [
                  Text('${date.month}/${date.day}/${date.year}'),
                  const SizedBox(width: 8),
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.cancel,
                    color: isCompleted ? Colors.green : Colors.red,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}