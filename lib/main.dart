import 'package:docker_manager/screens/container_list_screen.dart';
import 'package:docker_manager/screens/login_screen.dart';
import 'package:docker_manager/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  
  runApp(
    // Use ChangeNotifierProvider instead of Provider.value
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      themeMode: ThemeMode.system,
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
  late final Future<void> _initializationFuture;
  
  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _initializationFuture = authService.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
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
        
        // Get the current auth state after initialization is complete
        final authService = Provider.of<AuthService>(context);
        
        // Redirect based on authentication status
        if (authService.isAuthenticated) {
          return const ContainerListScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
