import 'package:flutter/material.dart';

enum HabitFrequency { daily, weekly, monthly, custom }

class Habit {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final HabitFrequency frequency;
  final List<bool> completionStatus;
  final DateTime createdAt;
  final List<String> notes;
  final TimeOfDay? reminderTime;
  final List<int>? customDays;
  bool isCompletedToday;
  DateTime? lastCompletionTime;
  DateTime? nextDueTime;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.frequency,
    required this.completionStatus,
    required this.createdAt,
    this.notes = const [],
    this.reminderTime,
    this.customDays,
    this.isCompletedToday = false,
    this.lastCompletionTime,
    this.nextDueTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon.codePoint,
      'color': color.value,
      'category': category,
      'frequency': frequency.index,
      'completionStatus': completionStatus.map((e) => e ? 1 : 0).join(','), // Convert to comma-separated string
      'createdAt': createdAt.toIso8601String(),
      'notes': notes.join('|'), // Use a separator that's unlikely to be in the notes
      'reminderTime': reminderTime != null ? '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}' : null,
      'customDays': customDays?.join(','),
      'isCompletedToday': isCompletedToday ? 1 : 0,
      'lastCompletionTime': lastCompletionTime?.toIso8601String(),
      'nextDueTime': nextDueTime?.toIso8601String(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      category: json['category'],
      frequency: HabitFrequency.values[json['frequency']],
      completionStatus: json['completionStatus'] != null && json['completionStatus'].isNotEmpty
          ? json['completionStatus'].split(',').map((e) => e == '1').toList().cast<bool>()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      notes: json['notes'] != null && json['notes'].isNotEmpty ? json['notes'].split('|') : [],
      reminderTime: json['reminderTime'] != null ? TimeOfDay.fromDateTime(DateTime.parse('2022-01-01 ${json['reminderTime']}:00')) : null,
      customDays: json['customDays'] != null ? (json['customDays'] as String).split(',').map((e) => int.parse(e)).toList() : null,
      isCompletedToday: json['isCompletedToday'] == 1,
      lastCompletionTime: json['lastCompletionTime'] != null ? DateTime.parse(json['lastCompletionTime']) : null,
      nextDueTime: json['nextDueTime'] != null ? DateTime.parse(json['nextDueTime']) : null,
    );
  }

  bool isOverdue() {
    final now = DateTime.now();
    if (nextDueTime == null) return false;
    return now.isAfter(nextDueTime!);
  }

  DateTime calculateNextDueTime() {
    final now = DateTime.now();
    switch (frequency) {
      case HabitFrequency.daily:
        return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      case HabitFrequency.weekly:
        return DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
      case HabitFrequency.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case HabitFrequency.custom:
        if (customDays != null && customDays!.isNotEmpty) {
          int nextDay = customDays!.firstWhere((day) => day > now.weekday, orElse: () => customDays!.first);
          return DateTime(now.year, now.month, now.day).add(Duration(days: (nextDay - now.weekday + 7) % 7));
        }
        return now;
    }
  }

  bool shouldCompleteToday() {
    final now = DateTime.now();
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return now.weekday == DateTime.monday;
      case HabitFrequency.monthly:
        return now.day == 1;
      case HabitFrequency.custom:
        return customDays?.contains(now.weekday) ?? false;
    }
  }

  void completeHabit() {
    isCompletedToday = true;
    lastCompletionTime = DateTime.now();
    nextDueTime = calculateNextDueTime();
    final index = DateTime.now().difference(createdAt).inDays;
    if (index >= 0 && index < completionStatus.length) {
      completionStatus[index] = true;
    } else if (index >= completionStatus.length) {
      completionStatus.addAll(List.generate(index - completionStatus.length + 1, (_) => false));
      completionStatus[index] = true;
    }
  }

  void uncompleteHabit() {
    isCompletedToday = false;
    lastCompletionTime = null;
    nextDueTime = null;
    final index = DateTime.now().difference(createdAt).inDays;
    if (index >= 0 && index < completionStatus.length) {
      completionStatus[index] = false;
    }
  }

  bool isCompletedOnDay(DateTime date) {
    final index = date.difference(createdAt).inDays;
    if (index < 0 || index >= completionStatus.length) {
      return false;
    }
    return completionStatus[index];
  }
}

// Define a global key for navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
