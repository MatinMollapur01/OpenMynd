import 'package:flutter/material.dart';
import 'package:openmynd/l10n/app_localizations.dart';
import 'todo_screen.dart';
import 'habits_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(String) onLanguageChanged;

  const HomeScreen({Key? key, required this.onThemeChanged, required this.onLanguageChanged}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appTitle),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          const TodoScreen(),
          const HabitsScreen(),
          SettingsScreen(onThemeChanged: widget.onThemeChanged, onLanguageChanged: widget.onLanguageChanged),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'To-Do',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
