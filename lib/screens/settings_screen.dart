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
  late bool _showExited;

  @override
  void initState() {
    super.initState();
    _prefixController = TextEditingController(text: widget.settingsService.commandPrefix);
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
                helperText: 'Prefix added to all Docker commands (e.g., sudo)',
              ),
              onChanged: (value) => widget.settingsService.setCommandPrefix(value),
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
    super.dispose();
  }
}
