import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  await DatabaseService.instance.database; // Initialize the database
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    });
  }

  void _onThemeChanged(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenMynd',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
          surface: _isDarkMode ? const Color(0xFF1C1919) : const Color(0xFFD9D9D9),
        ).copyWith(
          // Override specific colors
          surface: _isDarkMode ? const Color(0xFF1C1919) : const Color(0xFFD9D9D9),
        ),
        scaffoldBackgroundColor: _isDarkMode ? const Color(0xFF1C1919) : const Color(0xFFD9D9D9),
        useMaterial3: true,
      ),
      home: HomeScreen(onThemeChanged: _onThemeChanged),
    );
  }
}
