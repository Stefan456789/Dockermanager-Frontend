import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:docker_manager/models/container_info.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:docker_manager/services/auth_service.dart';
import 'package:docker_manager/services/settings_service.dart';

class DockerApiService {
  final Dio _dio = Dio();
  final String baseUrl;
  final String wsUrl;
  final AuthService authService = AuthService();
  final SettingsService settingsService = SettingsService();

  DockerApiService()
      : baseUrl = SettingsService().baseUrl,
        wsUrl = SettingsService().wsUrl {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    // Add auth token to all requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (authService.token != null) {
          options.headers['Authorization'] = 'Bearer ${authService.token}';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        debugPrint('Error occurred at ${error.requestOptions.path}: ${error.message}');
        
        // Handle different error status codes
        if (error.response?.statusCode == 401) {
          // Check if token is still valid, might have expired
          final isValid = await authService.verifyToken();
          if (!isValid) {
            // Token is invalid, user needs to login again
            debugPrint('Authentication error: Token invalid or expired');
          }
        } else if (error.response?.statusCode == 403) {
          // Permission denied - log the error
          debugPrint('Permission denied: You do not have access to this resource');
          // The error will be handled by the calling method
        }
        return handler.next(error);
      },
    ));
  }

  Future<List<ContainerInfo>> getContainers() async {
    try {
      final response = await _dio.get('/containers');
      return (response.data as List)
          .map((json) => ContainerInfo.fromJson(json))
          .toList();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        debugPrint('Permission denied: Unable to access container list');
        // Return empty list instead of rethrowing
        return [];
      }
      debugPrint('Error getting containers: $e');
      rethrow;
    }
  }

  Future<ContainerInfo> getContainerDetails(String id) async {
    try {
      final response = await _dio.get('/containers/$id');
      return ContainerInfo.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        debugPrint('Permission denied: Unable to access container details');
      }
      debugPrint('Error getting container details: $e');
      rethrow;
    }
  }

  Future<void> startContainer(String id) async {
    try {
      await _dio.post('/containers/$id/start');
    } catch (e) {
      debugPrint('Error starting container: $e');
      rethrow;
    }
  }

  Future<void> stopContainer(String id) async {
    try {
      await _dio.post('/containers/$id/stop');
    } catch (e) {
      debugPrint('Error stopping container: $e');
      rethrow;
    }
  }

  Future<void> restartContainer(String id) async {
    try {
      await _dio.post('/containers/$id/restart');
    } catch (e) {
      debugPrint('Error restarting container: $e');
      rethrow;
    }
  }

  Future<WebSocketChannel?> getContainerLogsStream(String id) async {
    // Ensure token is added to WebSocket connection
    final token = authService.token;
    if (token == null) {
      throw Exception('Authentication required');
    }
    
    final url = '$wsUrl/logs?containerId=$id&token=$token';
    try {
      return WebSocketChannel.connect(Uri.parse(url));
    } catch (e) {
      debugPrint('Error connecting to WebSocket: $e');
      return null;
    }
  }

  // Send command to container via WebSocket
  void sendCommand(WebSocketChannel channel, String command) {
    final commandJson = jsonEncode({
      'type': 'command',
      'containerId':
          command.split(' ').first, // Extract container ID if included
      'command': command,
    });
    channel.sink.add(commandJson);
  }
}
