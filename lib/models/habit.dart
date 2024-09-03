import 'package:flutter/material.dart';

enum HabitFrequency { daily, weekly, monthly, custom }

class Habit {
  final String id;
  final String title;
  String? description;
  final IconData icon;
  final Color color;
  final String category; // Add this line
  final List<bool> completionStatus;
  final DateTime createdAt;
  List<String> notes;
  TimeOfDay? reminderTime;
  final HabitFrequency frequency;
  final List<int>? customDays; // For custom frequency, store days of the week (1-7)

  Habit({
    required this.id,
    required this.title,
    this.description,
    required this.icon,
    required this.color,
    required this.category, // Add this line
    required this.completionStatus,
    required this.createdAt,
    this.notes = const [],
    this.reminderTime,
    required this.frequency,
    this.customDays,
  });

  int get streak {
    int currentStreak = 0;
    for (int i = completionStatus.length - 1; i >= 0; i--) {
      if (completionStatus[i]) {
        currentStreak++;
      } else {
        break;
      }
    }
    return currentStreak;
  }

  double get completionRate {
    if (completionStatus.isEmpty) return 0;
    return completionStatus.where((status) => status).length / completionStatus.length;
  }

  // Update toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon.codePoint,
      'color': color.value,
      'category': category, // Add this line
      'completionStatus': completionStatus,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'reminderTime': reminderTime != null ? '${reminderTime!.hour}:${reminderTime!.minute}' : null,
      'frequency': frequency.index,
      'customDays': customDays,
    };
  }

  // Update fromJson method
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      category: json['category'], // Add this line
      completionStatus: List<bool>.from(json['completionStatus']),
      createdAt: DateTime.parse(json['createdAt']),
      notes: List<String>.from(json['notes']),
      reminderTime: json['reminderTime'] != null ? _parseTimeOfDay(json['reminderTime']) : null,
      frequency: HabitFrequency.values[json['frequency']],
      customDays: json['customDays'] != null ? List<int>.from(json['customDays']) : null,
    );
  }

  static TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool isCompletedOnDay(DateTime day) {
    final daysSinceCreation = day.difference(createdAt).inDays;
    if (daysSinceCreation < 0 || daysSinceCreation >= completionStatus.length) {
      return false;
    }
    return completionStatus[daysSinceCreation];
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
}