import 'package:docker_manager/services/docker_api_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketManager {
  final String containerId;
  final DockerApiService apiService;
  WebSocketChannel? _channel;

  // Callbacks to propagate events.
  void Function(String message)? onMessage;
  void Function(dynamic error)? onError;
  void Function()? onDone;

  WebSocketManager({required this.containerId, required this.apiService});

  Future<void> connect() async {
    _channel = await apiService.getContainerLogsStream(containerId);
    _channel!.stream.listen(
      (message) {
        onMessage?.call(message.toString());
      },
      onError: (error) {
        onError?.call(error);
      },
      onDone: () {
        onDone?.call();
      },
    );
  }

  void send(String message) {
    _channel?.sink.add(message);
  }

  void close() {
    _channel?.sink.close();
  }
}
