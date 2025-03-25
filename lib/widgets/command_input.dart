import 'package:flutter/material.dart';

class CommandInput extends StatelessWidget {
  final TextEditingController commandController;
  final bool isConnected;
  final bool isFullscreen;
  final VoidCallback onSend;

  const CommandInput({
    super.key,
    required this.commandController,
    required this.isConnected,
    required this.isFullscreen,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isFullscreen ? Colors.black : Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: isFullscreen
                ? Colors.grey.shade800
                : Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '\$ ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: isFullscreen
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: TextField(
              controller: commandController,
              decoration: InputDecoration(
                hintText: 'Enter command...',
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: isFullscreen ? Colors.grey : null),
              ),
              style: TextStyle(
                fontFamily: 'monospace',
                color: isFullscreen ? Colors.white : null,
              ),
              textInputAction: TextInputAction.send,
              enabled: isConnected,
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: isFullscreen ? Colors.white : null,
            ),
            onPressed: isConnected ? onSend : null,
            tooltip: 'Send command',
          ),
        ],
      ),
    );
  }
}
