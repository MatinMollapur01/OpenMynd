import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveData(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getData(String key) {
    return _prefs.getString(key);
  }

  // Add more storage-related methods as needed
}