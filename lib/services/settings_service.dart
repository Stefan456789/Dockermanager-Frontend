import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService extends ChangeNotifier {
  static const String _commandPrefixKey = 'commandPrefix';
  static const String _showExitedKey = 'showExited';
  static const String _maxLogLengthKey = 'maxLogLength';
  static const String _baseUrlKey = 'baseUrl';
  static const String _wsUrlKey = 'wsUrl';
  static const String _themeModeKey = 'themeMode';

  SharedPreferences? _prefs;
  final Future<void> _prefsFuture;

  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() {
    return _instance;
  }

  SettingsService._internal() : _prefsFuture = Future.value() {
    _create();
  }
  Future<void> _create() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> init() async {
    await _prefsFuture;
  }

  String get commandPrefix => _prefs?.getString(_commandPrefixKey) ?? '';
  bool get showExited => _prefs?.getBool(_showExitedKey) ?? true;
  int get maxLogLength => _prefs?.getInt(_maxLogLengthKey) ?? 100;
  String get baseUrl => _prefs?.getString(_baseUrlKey) ?? dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:3000/api';
  String get wsUrl => _prefs?.getString(_wsUrlKey) ?? dotenv.env['WS_URL'] ?? 'ws://10.0.2.2:3000/api';

  ThemeMode get themeMode {
    final String? themeModeString = _prefs?.getString(_themeModeKey);
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setCommandPrefix(String prefix) async {
    await _prefs?.setString(_commandPrefixKey, prefix);
  }

  Future<void> setShowExited(bool show) async {
    await _prefs?.setBool(_showExitedKey, show);
  }

  Future<void> setMaxLogLength(int length) async {
    await _prefs?.setInt(_maxLogLengthKey, length);
  }

  Future<void> setBaseUrl(String url) async {
    await _prefs?.setString(_baseUrlKey, url);
  }

  Future<void> setWsUrl(String url) async {
    await _prefs?.setString(_wsUrlKey, url);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      default:
        modeString = 'system';
    }
    await _prefs?.setString(_themeModeKey, modeString);
    notifyListeners();
  }
}
