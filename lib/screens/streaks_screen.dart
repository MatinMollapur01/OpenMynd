import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreaksScreen extends StatefulWidget {
  const StreaksScreen({Key? key}) : super(key: key);

  @override
  StreaksScreenState createState() => StreaksScreenState();
}

class StreaksScreenState extends State<StreaksScreen> {
  int _streakCount = 0;
  Map<DateTime, bool> _completionStatus = {};
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
      final now = DateTime.now();
      Map<DateTime, bool> completionStatus = {};

      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        bool allCompleted = true;
        for (final habit in habits) {
          if (habit.shouldCompleteOnDay(date) && !habit.isCompletedOnDay(date)) {
            allCompleted = false;
            break;
          }
        }
        completionStatus[date] = allCompleted;
      }

      setState(() {
        _streakCount = streakCount;
        _completionStatus = completionStatus;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaks'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStreakData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.local_fire_department, size: 80, color: Colors.orange),
              Text(
                '$_streakCount',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Day Streak',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now(),
                focusedDay: DateTime.now(),
                calendarFormat: CalendarFormat.month,
                calendarStyle: CalendarStyle(
                  weekendTextStyle: const TextStyle(color: Colors.red),
                  holidayTextStyle: const TextStyle(color: Colors.red),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, date, _) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getDateColor(date),
                      ),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: _getDateColor(date) != Colors.transparent
                              ? Colors.white
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDateColor(DateTime date) {
    if (_completionStatus.containsKey(date)) {
      return _completionStatus[date]! ? Colors.green : Colors.red;
    }
    return Colors.transparent;
  }
}