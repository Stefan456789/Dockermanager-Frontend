import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class User {
  final String id;
  final String email;
  final String? name;
  final String? picture;

  User({
    required this.id,
    required this.email,
    this.name,
    this.picture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      picture: json['picture'],
    );
  }
}

class AuthService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['GOOGLE_CLIENT_ID'],
    scopes: ['email', 'profile', 'openid'],
  );
  final Dio _dio = Dio();
  User? _currentUser;
  String? _token;
  bool _isInitialized = false;

  AuthService() {
    _dio.options.baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:3000/api';
  }

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null && _token != null;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _loadUserFromPrefs();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
      _isInitialized = true; // Mark as initialized even if there's an error
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('Google user: $googleUser');
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      debugPrint('Google ID token: $idToken');

      if (idToken == null) return false;

      // Verify token with backend
      final response = await _dio.post('/auth/google-signin', data: {
        'token': idToken,
      });

      final userData = response.data['user'];
      final token = response.data['token'];

      _currentUser = User.fromJson(userData);
      _token = token;

      // Save to SharedPreferences
      await _saveToPrefs();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    if (_currentUser == null || _token == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'user',
        jsonEncode({
          'id': _currentUser!.id,
          'email': _currentUser!.email,
          'name': _currentUser!.name,
          'picture': _currentUser!.picture,
        }));
    await prefs.setString('token', _token!);
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final token = prefs.getString('token');

    if (userJson != null && token != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
      _token = token;
      
      // Verify the token on startup
      await verifyToken();
    }
  }

  Future<bool> verifyToken() async {
    if (_token == null) return false;
    
    try {
      final response = await _dio.post('/auth/verify-token', data: {
        'token': _token,
      });
      
      final isValid = response.data['valid'] ?? false;
      
      if (isValid && response.data['user'] != null) {
        // Update user data if needed
        _currentUser = User.fromJson(response.data['user']);
        notifyListeners();
      } else {
        // Clear invalid token
        await signOut();
      }
      
      return isValid;
    } catch (e) {
      debugPrint('Error verifying token: $e');
      await signOut();
      return false;
    }
  }
}
