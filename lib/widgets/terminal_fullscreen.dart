import 'package:flutter/material.dart';
import 'package:docker_manager/widgets/command_input.dart';
import 'package:docker_manager/utils/log_utils.dart';

class TerminalFullscreen extends StatelessWidget {
  final List<String> logs;
  final ScrollController scrollController;
  final TextEditingController commandController;
  final bool isConnected;
  final VoidCallback onSend;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final VoidCallback onRefresh;
  final VoidCallback onGotoEnd;

  const TerminalFullscreen({
    super.key,
    required this.logs,
    required this.scrollController,
    required this.commandController,
    required this.isConnected,
    required this.onSend,
    required this.onBack,
    required this.onClear,
    required this.onRefresh,
    required this.onGotoEnd,
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Console"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
          tooltip: 'Exit fullscreen',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onClear,
            tooltip: 'Clear logs',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward),
            onPressed: onGotoEnd,
            tooltip: 'Go to bottom',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
            tooltip: 'Reload connection',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8),
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
                        return Text(
                          log,
                          style: TextStyle(
                            color: getLogColor(log),
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
            ),
          ),
          CommandInput(
            commandController: commandController,
            isConnected: isConnected,
            isFullscreen: true,
            onSend: onSend,
          ),
        ],
      ),
    );
  }
}
