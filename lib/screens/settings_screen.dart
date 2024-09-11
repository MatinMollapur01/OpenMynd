import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openmynd/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(String) onLanguageChanged;

  const SettingsScreen({super.key, required this.onThemeChanged, required this.onLanguageChanged});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _saveThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> _saveLanguagePreference(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    widget.onLanguageChanged(language); // Notify the app to change the language
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(localizations.appearance, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: Text(localizations.darkMode),
            value: _isDarkMode,
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
              });
              _saveThemePreference(value);
              widget.onThemeChanged(value);
            },
          ),
          ListTile(
            title: Text(localizations.language, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: Text(localizations.selectLanguage),
            subtitle: Text(_selectedLanguage),
            onTap: () async {
              final selectedLanguage = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: Text(localizations.selectLanguage),
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'en');
                        },
                        child: Text(localizations.english),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'fa');
                        },
                        child: Text(localizations.persian),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'tr');
                        },
                        child: Text(localizations.turkish),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'az');
                        },
                        child: Text(localizations.azerbaijani),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'ar');
                        },
                        child: Text(localizations.arabic),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'ru');
                        },
                        child: Text(localizations.russian),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'zh');
                        },
                        child: Text(localizations.chinese),
                      ),
                    ],
                  );
                },
              );
              if (selectedLanguage != null) {
                setState(() {
                  _selectedLanguage = selectedLanguage;
                });
                _saveLanguagePreference(selectedLanguage);
              }
            },
          ),
          const Divider(),
          ListTile(
            title: Text(localizations.myketAppStore, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: Text(localizations.submitUserReview),
            onTap: () => _launchUrl('myket://comment/com.example.open_mynd'),
          ),
          ListTile(
            title: Text(localizations.openAppPageInMyket),
            onTap: () => _launchUrl('myket://details?id=com.example.open_mynd'),
          ),
          ListTile(
            title: Text(localizations.openDeveloperAppsPage),
            onTap: () => _launchUrl('myket://developer/dev-76064'),
          ),
        ],
      ),
    );
  }
}
