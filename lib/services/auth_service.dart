import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:docker_manager/models/user_model.dart';
import 'package:docker_manager/models/container_info.dart';
import 'package:docker_manager/services/settings_service.dart';
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

  static final AuthService _singleton = AuthService._internal();
  
  factory AuthService() {
    return _singleton;
  }
  
  AuthService._internal(){
    _dio.options.baseUrl = SettingsService().baseUrl;
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

  Future<List<UserDetails>> getUsers() async {
    try {
      final response = await _dio.get(
        '/auth/users',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      return (response.data['users'] as List)
          .map((user) => UserDetails.fromJson(user))
          .toList();
    } catch (e) {
      debugPrint('Error getting users: $e');
      throw Exception('Failed to get users');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _dio.delete(
        '/auth/users/$userId',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
    } catch (e) {
      debugPrint('Error deleting user: $e');
      throw Exception('Failed to delete user');
    }
  }

  Future<void> updateUserPermissions(String userId, List<UserPermission> permissions) async {
    try {
      await _dio.post(
        '/auth/users/$userId/permissions',
        data: {
          'permissions': permissions
              .map((p) => p.id)
              .toList(),
        },
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
    } catch (e) {
      debugPrint('Error updating permissions: $e');
      throw Exception('Failed to update permissions');
    }
  }

  Future<List<UserPermission>> getAllPermissions() async {
    try {
      final response = await _dio.get(
        '/auth/all-permissions',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      return (response.data['permissions'] as List)
          .map((perm) => UserPermission.fromJson(perm))
          .toList();
    } catch (e) {
      debugPrint('Error getting permissions: $e');
      throw Exception('Failed to get permissions');
    }
  }

  Future<List<ContainerInfo>> getContainers() async {
    try {
      final response = await _dio.get(
        '/auth/containers',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      return (response.data['containers'] as List)
          .map((container) => ContainerInfo.fromJson(container))
          .toList();
    } catch (e) {
      debugPrint('Error getting containers: $e');
      throw Exception('Failed to get containers');
    }
  }

  Future<List<UserPermission>> getContainerPermissions() async {
    try {
      final response = await _dio.get(
        '/auth/container-permissions',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      return (response.data['permissions'] as List)
          .map((perm) => UserPermission.fromJson(perm))
          .toList();
    } catch (e) {
      debugPrint('Error getting container permissions: $e');
      throw Exception('Failed to get container permissions');
    }
  }

  Future<List<UserDetails>> getUsersPermissionsForContainer(String containerId) async {
    try {
      final response = await _dio.get(
        '/auth/containers/$containerId/users-permissions',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      return (response.data['users'] as List)
          .map((user) => UserDetails.fromJson(user))
          .toList();
    } catch (e) {
      debugPrint('Error getting users permissions for container: $e');
      throw Exception('Failed to get users permissions for container');
    }
  }

  Future<List<UserPermission>> getCurrentUserContainerPermissions(String containerId) async {
    try {
      final response = await _dio.get(
        '/auth/containers/$containerId/users-permissions',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      // Find current user in the response
      final users = response.data['users'] as List;
      try {
        final currentUserData = users.firstWhere(
          (user) => user['id'] == _currentUser?.id,
        );
        return (currentUserData['permissions'] as List)
            .map((perm) => UserPermission.fromJson(perm))
            .toList();
      } catch (e) {
        // Current user not found in the list
        return [];
      }
    } catch (e) {
      debugPrint('Error getting current user container permissions: $e');
      throw Exception('Failed to get current user container permissions');
    }
  }

  Future<void> updateUserContainerPermissions(String containerId, String userId, List<UserPermission> permissions) async {
    try {
      await _dio.post(
        '/auth/containers/$containerId/users/$userId/permissions',
        data: {
          'permissions': permissions
              .map((p) => p.id)
              .toList(),
        },
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
    } catch (e) {
      debugPrint('Error updating container permissions: $e');
      throw Exception('Failed to update container permissions');
    }
  }
}
