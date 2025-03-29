import 'package:docker_manager/screens/container_list_screen.dart';
import 'package:docker_manager/screens/login_screen.dart';
import 'package:docker_manager/services/auth_service.dart';
import 'package:docker_manager/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await SettingsService().init();
  // Enable debugPaintSizeEnabled for visual debugging
  // Uncomment the line below to see widget boundaries
  // debugPaintSizeEnabled = true;

  runApp(
    const MyApp()
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SettingsService _settingsService = SettingsService();
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = _settingsService.themeMode;
    _settingsService.addListener(_updateTheme);
  }

  void _updateTheme() {
    setState(() {
      _themeMode = _settingsService.themeMode;
    });
  }

  @override
  void dispose() {
    _settingsService.removeListener(_updateTheme);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Docker Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      themeMode: _themeMode,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authService.addListener(_authServiceListener);
  }

  @override
  void dispose() {
    // Remove the listener when widget is disposed
    _authService.removeListener(_authServiceListener);
    debugPrint('AuthWrapper disposed');
    super.dispose();
  }

  // Separate method for the listener to be able to remove it in dispose
  void _authServiceListener() {
    if (mounted) {
      setState(() {
        _isAuthenticated = _authService.isAuthenticated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _authService.init(),
      builder: (context, snapshot) {
        // Show loading indicator while initializing
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Handle initialization errors
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error initializing: ${snapshot.error}'),
            ),
          );
        }

        return _isAuthenticated 
            ? const ContainerListScreen()
            : const LoginScreen();
      },
    );
  }
}
