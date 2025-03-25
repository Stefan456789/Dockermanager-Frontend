import 'package:flutter/material.dart';
import 'package:docker_manager/models/container_info.dart';

class ContainerActions extends StatelessWidget {
  final ContainerInfo container;
  final bool isPerformingAction;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;

  const ContainerActions({
    super.key,
    required this.container,
    required this.isPerformingAction,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: isPerformingAction || container.state == 'running'
                ? null
                : onStart,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          ),
          ElevatedButton.icon(
            onPressed: isPerformingAction || container.state != 'running'
                ? null
                : onStop,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
          ),
          ElevatedButton.icon(
            onPressed: isPerformingAction || container.state != 'running'
                ? null
                : onRestart,
            icon: const Icon(Icons.refresh),
            label: const Text('Restart'),
          ),
        ],
      ),
    );
  }
}
