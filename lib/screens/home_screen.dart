import 'package:flutter/material.dart';
import 'package:openmynd/l10n/app_localizations.dart';
import 'todo_screen.dart';
import 'habits_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(String) onLanguageChanged;

  const HomeScreen({super.key, required this.onThemeChanged, required this.onLanguageChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          const TodoScreen(),
          const HabitsScreen(),
          SettingsScreen(
            onThemeChanged: widget.onThemeChanged,
            onLanguageChanged: (String languageCode) {
              widget.onLanguageChanged(languageCode);
              setState(() {}); // Trigger a rebuild to update the localized strings
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: localizations.todoTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.track_changes),
            label: localizations.habitsTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: localizations.settingsTab,
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
