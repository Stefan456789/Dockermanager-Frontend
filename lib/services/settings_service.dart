import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _commandPrefixKey = 'commandPrefix';
  static const String _showExitedKey = 'showExited';
  static const String _maxLogLengthKey = 'maxLogLength';

  late SharedPreferences _prefs;
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

  String get commandPrefix => _prefs.getString(_commandPrefixKey) ?? '';
  bool get showExited => _prefs.getBool(_showExitedKey) ?? true;
  int get maxLogLength => _prefs.getInt(_maxLogLengthKey) ?? 100;

  Future<void> setCommandPrefix(String prefix) async {
    await _prefs.setString(_commandPrefixKey, prefix);
  }

  Future<void> setShowExited(bool show) async {
    await _prefs.setBool(_showExitedKey, show);
  }

  Future<void> setMaxLogLength(int length) async {
    await _prefs.setInt(_maxLogLengthKey, length);
  }
}
