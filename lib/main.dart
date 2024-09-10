import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
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
  final ValueNotifier<Locale> _localeNotifier = ValueNotifier(const Locale('en'));

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      _localeNotifier.value = Locale(prefs.getString('language') ?? 'en');
    });
  }

  void _onThemeChanged(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  void _onLanguageChanged(String languageCode) {
    _localeNotifier.value = Locale(languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: _localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'OpenMynd',
          theme: ThemeData(
            fontFamily: 'Kavivanar', // Set the default font family to Kavivanar
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
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('fa'),
            Locale('tr'),
            Locale('az'),
            Locale('ar'),
            Locale('ru'),
            Locale('zh'),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: HomeScreen(onThemeChanged: _onThemeChanged, onLanguageChanged: _onLanguageChanged),
        );
      },
    );
  }
}
