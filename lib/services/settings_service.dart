import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _commandPrefixKey = 'commandPrefix';
  static const String _showExitedKey = 'showExited';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  String get commandPrefix => _prefs.getString(_commandPrefixKey) ?? 'sudo';
  bool get showExited => _prefs.getBool(_showExitedKey) ?? true;

  Future<void> setCommandPrefix(String prefix) async {
    await _prefs.setString(_commandPrefixKey, prefix);
  }

  Future<void> setShowExited(bool show) async {
    await _prefs.setBool(_showExitedKey, show);
  }
}
