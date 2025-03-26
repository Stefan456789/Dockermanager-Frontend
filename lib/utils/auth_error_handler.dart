import 'package:flutter/material.dart';
import 'package:docker_manager/screens/login_screen.dart';
import 'package:docker_manager/services/auth_service.dart';
import 'package:provider/provider.dart';

class AuthErrorHandler {
  static void handleAuthError(BuildContext context, {String? message}) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Show a snackbar with the error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Authentication error. Please sign in again.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ),
    );
    
    // Sign out the user
    authService.signOut();
    
    // Navigate to login screen
    Future.delayed(const Duration(seconds: 1), () {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }
}
