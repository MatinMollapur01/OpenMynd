import 'package:flutter/material.dart';
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

      setState(() {
        _streakCount = streakCount;
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department, size: 80, color: Colors.orange),
              Text(
                '$_streakCount',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              Text(
                localizations.dayStreak,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}