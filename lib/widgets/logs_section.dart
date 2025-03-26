import 'package:flutter/material.dart';

class LogsSection extends StatelessWidget {
  final List<String> logs;
  final ScrollController scrollController;
  final bool isConnected;
  // Existing callbacks
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onGotoEnd;
  // New clear callback
  final VoidCallback? onClear;

  const LogsSection({
    super.key,
    required this.logs,
    required this.scrollController,
    required this.isConnected,
    this.onToggleFullscreen,
    this.onGotoEnd,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Container Logs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(isConnected ? 'Connected' : 'Disconnected'),
                  // Added clear button if callback provided
                  if (onClear != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onClear,
                      tooltip: 'Clear logs',
                    ),
                  // Added fullscreen button if callback provided
                  if (onToggleFullscreen != null)
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      onPressed: onToggleFullscreen,
                      tooltip: 'Fullscreen console',
                    ),
                  // Added goto end button if callback provided
                  if (onGotoEnd != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: onGotoEnd,
                      tooltip: 'Go to end',
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs available',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      Color logColor = Colors.white;
                      if (log.startsWith('>')) {
                        logColor = Colors.cyan;
                      } else if (log.contains('ERROR')) {
                        logColor = Colors.red;
                      } else if (log.contains('Connected to container') ||
                          log.contains('Start successful') ||
                          log.contains('started') ||
                          log.toLowerCase().contains('starting') ||
                          log.contains('Stop successful')) {
                        logColor = Colors.green;
                      } else if (log.contains('stopped') ||
                          log.contains('Disconnected') ||
                          log.toLowerCase().contains('stopping') ||
                          log.contains('shutting down')) {
                        logColor = Colors.orange;
                      }
                      return Text(
                        log,
                        style: TextStyle(
                          color: logColor,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
