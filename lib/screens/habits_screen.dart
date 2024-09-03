import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/habit.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'habit_detail_screen.dart';

enum CalendarSystem { gregorian, jalali, solarHijri }

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  HabitsScreenState createState() => HabitsScreenState();
}

class HabitsScreenState extends State<HabitsScreen> {
  final Logger _logger = Logger();
  List<Habit> _habits = [];
  final DatabaseService _databaseService = DatabaseService.instance;
  final NotificationService _notificationService = NotificationService();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<String, List<Habit>> _categorizedHabits = {};
  CalendarSystem _calendarSystem = CalendarSystem.gregorian;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await _databaseService.readAllHabits();
      if (mounted) {
        setState(() {
          _habits = habits;
          _categorizeHabits();
        });
      }
    } catch (e) {
      _logger.e("Error loading habits: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load habits: $e')),
        );
      }
    }
  }

  void _categorizeHabits() {
    _categorizedHabits.clear();
    for (var habit in _habits) {
      if (!_categorizedHabits.containsKey(habit.category)) {
        _categorizedHabits[habit.category] = [];
      }
      _categorizedHabits[habit.category]!.add(habit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCalendarFormatDropdown(),
          _buildCalendar(),
          Expanded(
            child: ListView.builder(
              itemCount: _categorizedHabits.length,
              itemBuilder: (context, index) {
                String category = _categorizedHabits.keys.elementAt(index);
                return _buildCategorySection(category, _categorizedHabits[category]!);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarFormatDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<CalendarFormat>(
            value: _calendarFormat,
            items: CalendarFormat.values.map((format) {
              return DropdownMenuItem(
                value: format,
                child: Text(format.toString().split('.').last),
              );
            }).toList(),
            onChanged: (CalendarFormat? newFormat) {
              if (newFormat != null) {
                setState(() {
                  _calendarFormat = newFormat;
                });
              }
            },
          ),
          DropdownButton<CalendarSystem>(
            value: _calendarSystem,
            items: CalendarSystem.values.map((system) {
              return DropdownMenuItem(
                value: system,
                child: Text(system.toString().split('.').last),
              );
            }).toList(),
            onChanged: (CalendarSystem? newSystem) {
              if (newSystem != null) {
                setState(() {
                  _calendarSystem = newSystem;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2021, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
      ),
      eventLoader: (day) {
        return _habits.where((habit) {
          return habit.isCompletedOnDay(day);
        }).toList();
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return Center(
            child: Text(
              _formatDayNumber(day),
              style: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }

  String _formatDayNumber(DateTime date) {
    switch (_calendarSystem) {
      case CalendarSystem.gregorian:
        return date.day.toString();
      case CalendarSystem.jalali:
        final jalali = Jalali.fromDateTime(date);
        return jalali.day.toString();
      case CalendarSystem.solarHijri:
        final jalali = Jalali.fromDateTime(date);
        // Convert Jalali to Solar Hijri by adding 622 years
        final solarHijri = jalali.addYears(622);
        return solarHijri.day.toString();
    }
  }

  bool _shouldCompleteOnDay(Habit habit, DateTime day) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return day.weekday == DateTime.monday;
      case HabitFrequency.monthly:
        return day.day == 1;
      case HabitFrequency.custom:
        return habit.customDays?.contains(day.weekday) ?? false;
    }
  }

  Widget _buildCategorySection(String category, List<Habit> habits) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ListTile(
            title: Text(category),
            trailing: Text('${habits.length} habits'),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              final shouldCompleteToday = habit.shouldCompleteToday();
              final isCompletedToday = habit.completionStatus.isNotEmpty && 
                                       habit.completionStatus.last &&
                                       _isCompletedToday(habit);
              return ListTile(
                leading: Icon(habit.icon, color: habit.color),
                title: Text(habit.title),
                subtitle: Text(habit.frequency.toString().split('.').last),
                trailing: shouldCompleteToday
                  ? Checkbox(
                      value: isCompletedToday,
                      onChanged: (bool? value) {
                        _toggleHabitCompletion(habit);
                      },
                    )
                  : null,
                onTap: () => _editHabit(habit),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isCompletedToday(Habit habit) {
    final today = DateTime.now();
    final daysSinceCreation = today.difference(habit.createdAt).inDays;
    return daysSinceCreation < habit.completionStatus.length &&
           habit.completionStatus[daysSinceCreation];
  }

  void _toggleHabitCompletion(Habit habit) async {
    final today = DateTime.now();
    final updatedCompletionStatus = List<bool>.from(habit.completionStatus);
    final daysSinceCreation = today.difference(habit.createdAt).inDays;
    
    while (updatedCompletionStatus.length <= daysSinceCreation) {
      updatedCompletionStatus.add(false);
    }
    
    updatedCompletionStatus[daysSinceCreation] = !updatedCompletionStatus[daysSinceCreation];

    final updatedHabit = Habit(
      id: habit.id,
      title: habit.title,
      icon: habit.icon,
      color: habit.color,
      category: habit.category,
      completionStatus: updatedCompletionStatus,
      createdAt: habit.createdAt,
      frequency: habit.frequency,
      description: habit.description,
      notes: habit.notes,
      reminderTime: habit.reminderTime,
      customDays: habit.customDays,
    );

    try {
      await _databaseService.updateHabit(updatedHabit);
      if (mounted) {
        await _loadHabits();
      }
    } catch (e) {
      print("Error updating habit completion: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update habit completion: $e')),
        );
      }
    }
  }

  void _editHabit(Habit habit) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailScreen(habit: habit),
      ),
    );
    if (result != null) {
      if (result is Habit) {
        try {
          await _databaseService.updateHabit(result);
          if (result.reminderTime != null) {
            await _notificationService.scheduleHabitReminder(result);
          } else {
            await _notificationService.cancelHabitReminder(result.id);
          }
          if (mounted) {
            await _loadHabits();
          }
        } catch (e) {
          _logger.e("Error updating habit: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update habit: $e')),
            );
          }
        }
      } else if (result is Map && result['action'] == 'delete') {
        try {
          await _databaseService.deleteHabit(habit.id);
          await _notificationService.cancelHabitReminder(habit.id);
          if (mounted) {
            await _loadHabits();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Habit deleted successfully')),
            );
          }
        } catch (e) {
          _logger.e("Error deleting habit: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete habit: $e')),
            );
          }
        }
      }
    }
  }

  void _addHabit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HabitDetailScreen()),
    );
    if (result != null && result is Habit) {
      try {
        await _databaseService.createHabit(result);
        if (result.reminderTime != null) {
          await _notificationService.scheduleHabitReminder(result);
        }
        if (mounted) {
          await _loadHabits();
        }
      } catch (e) {
        _logger.e("Error adding habit: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add habit: $e')),
          );
        }
      }
    }
  }
}