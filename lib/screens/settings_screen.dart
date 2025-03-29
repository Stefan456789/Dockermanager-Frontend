import 'package:flutter/material.dart';
import 'package:docker_manager/services/settings_service.dart';
import 'package:docker_manager/screens/user_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsScreen({super.key, required this.settingsService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _prefixController;
  late TextEditingController _maxLogLengthController;
  late TextEditingController _baseUrlController;
  late TextEditingController _wsUrlController;
  late bool _showExited;

  @override
  void initState() {
    super.initState();
    _prefixController = TextEditingController(text: widget.settingsService.commandPrefix);
    _maxLogLengthController = TextEditingController(text: widget.settingsService.maxLogLength.toString());
    _baseUrlController = TextEditingController(text: widget.settingsService.baseUrl);
    _wsUrlController = TextEditingController(text: widget.settingsService.wsUrl);
    _showExited = widget.settingsService.showExited;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _prefixController,
              decoration: const InputDecoration(
                labelText: 'Command Prefix',
                helperText: 'Prefix added to all Docker commands \n(e.g., rcon-cli, sudo). PS: Don\'t forget the space!',
              ),
              onChanged: (value) => widget.settingsService.setCommandPrefix(value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _maxLogLengthController,
              decoration: const InputDecoration(
                labelText: 'Max Log Length',
                helperText: 'Maximum length of log messages (<1 is unlimited)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final length = int.tryParse(value) ?? 100;
                widget.settingsService.setMaxLogLength(length);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                helperText: 'Base URL for the Docker API',
              ),
              onChanged: (value) => widget.settingsService.setBaseUrl(value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _wsUrlController,
              decoration: const InputDecoration(
                labelText: 'WebSocket URL',
                helperText: 'WebSocket URL for container logs',
              ),
              onChanged: (value) => widget.settingsService.setWsUrl(value),
            ),
          ),
          SwitchListTile(
            title: const Text('Show Exited Containers'),
            subtitle: const Text('Display containers that are not running'),
            value: _showExited,
            onChanged: (bool value) {
              setState(() {
                _showExited = value;
                widget.settingsService.setShowExited(value);
              });
            },
          ),
          ListTile(
            title: const Text('User Management'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _maxLogLengthController.dispose();
    _baseUrlController.dispose();
    _wsUrlController.dispose();
    super.dispose();
  }
}
