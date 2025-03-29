import 'dart:convert';
import 'package:docker_manager/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:docker_manager/models/container_info.dart';
import 'package:docker_manager/services/docker_api_service.dart';
import 'package:docker_manager/services/websocket_manager.dart';
import 'package:docker_manager/widgets/container_info_card.dart';
import 'package:docker_manager/widgets/container_actions.dart';
import 'package:docker_manager/widgets/logs_section.dart';
import 'package:docker_manager/widgets/command_input.dart';
import 'package:docker_manager/widgets/terminal_fullscreen.dart';

class ContainerDetailScreen extends StatefulWidget {
  final ContainerInfo container;

  const ContainerDetailScreen({super.key, required this.container});

  @override
  State<ContainerDetailScreen> createState() => _ContainerDetailScreenState();
}

class _ContainerDetailScreenState extends State<ContainerDetailScreen> {
  final DockerApiService _apiService = DockerApiService();
  late WebSocketManager _wsManager;
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  bool _isPerformingAction = false;
  final TextEditingController _commandController = TextEditingController();
  bool _isConnected = false;
  late ContainerInfo _currentContainer;
  bool _isFullscreenConsole = false;

  @override
  void initState() {
    super.initState();
    _currentContainer = widget.container;
    _initWebSocket();
    _scrollToBottom();
  }

  void _initWebSocket() {
      if (!mounted) return;
    _wsManager = WebSocketManager(
      containerId: _currentContainer.id,
      apiService: _apiService,
    );
    _wsManager.onMessage = (message) {
      if (!context.mounted) return;
      try {
        final data = jsonDecode(message);
        if (data['type'] == 'logs') {
          setState(() => addToLogs(data['log']));
        } else if (data['type'] == 'commandOutput') {
          setState(() => addToLogs('> ${data['output']}'));
        } else if (data['type'] == 'error') {
          setState(() => addToLogs('ERROR: ${data['message']}'));
        }
      } catch (e) {
        setState(() => addToLogs(message));
      }
      _scrollToBottom();
    };
    _wsManager.onError = (error) {
      if (!context.mounted) return;
      setState(() {
        _isConnected = false;
        addToLogs('ERROR: WebSocket connection error');
      });
      _showReconnectSnackBar();
    };
    _wsManager.onDone = () {
      if (!context.mounted) return;
      setState(() {
        _isConnected = false;
        addToLogs('Disconnected from container logs');
      });
      _showReconnectSnackBar();
    };
    setState(() {
      _isConnected = true;
      addToLogs('Connected to container logs...');
    });
    _wsManager.connect();
  }

  void addToLogs(String log) {
    setState(() {
      _logs.add(log);
      var maxLogLength = SettingsService().maxLogLength;
      if (maxLogLength > 0 && _logs.length > maxLogLength) {
        _logs.removeAt(0);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showReconnectSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Connection lost to logs'),
        action: SnackBarAction(
          label: 'Reconnect',
          onPressed: _reconnectWebSocket,
        ),
      ),
    );
  }

  void _reconnectWebSocket() {
    _wsManager.close();
    _fetchContainerDetails().then((_) {
      _initWebSocket();
    });
  }

  Future<void> _fetchContainerDetails() async {
    try {
      final updated =
          await _apiService.getContainerDetails(_currentContainer.id);
      setState(() {
        _currentContainer = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh container details: $e')),
        );
      }
    }
  }

  void _sendCommand() {
    if (_commandController.text.trim().isEmpty || !_isConnected) {
      setState(() => addToLogs('ERROR: Not connected to container'));
      return;
    }
    final command = SettingsService().commandPrefix + _commandController.text.trim();
    setState(() => addToLogs('> $command'));

    final commandJson = jsonEncode({
      'type': 'command',
      'containerId': widget.container.id,
      'command': command,
    });
    _wsManager.send(commandJson);
    _commandController.clear();
    _scrollToBottom();
  }

  Future<void> _performAction(
    Future<void> Function() action,
    String actionName,
  ) async {
    try {
      setState(() => _isPerformingAction = true);
      await action();
      setState(() => addToLogs('Container $actionName successful'));
      await _fetchContainerDetails();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$actionName successful')));
      }
    } catch (e) {
      setState(() => addToLogs('ERROR: Failed to $actionName container: $e'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $actionName container: $e')),
        );
      }
    } finally {
      setState(() => _isPerformingAction = false);
    }
  }

  @override
  void dispose() {
    _wsManager.close();
    _scrollController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isFullscreenConsole
        ? TerminalFullscreen(
            logs: _logs,
            scrollController: _scrollController,
            commandController: _commandController,
            isConnected: _isConnected,
            onSend: _sendCommand,
            onBack: () {
              setState(() => _isFullscreenConsole = false);
              _scrollToBottom();
            },
            onClear: () {
              setState(() => _logs.clear());
            },
            onRefresh: _reconnectWebSocket,
            onGotoEnd: _scrollToBottom, // new callback for fullscreen
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(_currentContainer.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _reconnectWebSocket,
                  tooltip: 'Reload connection and refresh data',
                ),
              ],
            ),
            body: Column(
              children: [
                ContainerInfoCard(container: _currentContainer),
                ContainerActions(
                  container: _currentContainer,
                  isPerformingAction: _isPerformingAction,
                  onStart: () => _performAction(
                      () => _apiService.startContainer(_currentContainer.id),
                      'Start'),
                  onStop: () => _performAction(
                      () => _apiService.stopContainer(_currentContainer.id),
                      'Stop'),
                  onRestart: () => _performAction(
                      () => _apiService.restartContainer(_currentContainer.id),
                      'Restart'),
                ),
                Expanded(
                  child: LogsSection(
                    logs: _logs,
                    scrollController: _scrollController,
                    isConnected: _isConnected,
                    onClear: () {
                      setState(() => _logs.clear());
                    },
                    onToggleFullscreen: () {
                      setState(() => _isFullscreenConsole = true);
                    },
                    onGotoEnd: _scrollToBottom,
                  ),
                ),
                CommandInput(
                  commandController: _commandController,
                  isConnected: _isConnected,
                  isFullscreen: false,
                  onSend: _sendCommand,
                ),
              ],
            ),
          );
  }
}
