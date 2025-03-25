import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:docker_manager/models/container_info.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:docker_manager/services/auth_service.dart';

class DockerApiService {
  final Dio _dio = Dio();
  final String baseUrl;
  final String wsUrl;
  final AuthService? authService;

  DockerApiService({this.authService})
      : baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:3000/api',
        wsUrl = dotenv.env['WS_URL'] ?? 'ws://10.0.2.2:3000/api' {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);

    // Add auth token to all requests if available
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (authService?.token != null) {
        options.headers['Authorization'] = 'Bearer ${authService!.token}';
      }
      return handler.next(options);
    }));
  }

  Future<List<ContainerInfo>> getContainers() async {
    try {
      final response = await _dio.get('/containers');
      return (response.data as List)
          .map((json) => ContainerInfo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting containers: $e');
      rethrow;
    }
  }

  Future<ContainerInfo> getContainerDetails(String id) async {
    try {
      final response = await _dio.get('/containers/$id');
      return ContainerInfo.fromJson(response.data);
    } catch (e) {
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

  WebSocketChannel getContainerLogsStream(String id) {
    String url = '$wsUrl/logs?containerId=$id';
    if (authService?.token != null) {
      url += '&token=${authService!.token}';
    }
    return WebSocketChannel.connect(Uri.parse(url));
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
