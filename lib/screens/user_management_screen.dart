import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserDetails> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await AuthService().getUsers();
      setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await AuthService().deleteUser(userId);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
  }

  Future<void> _updateUserPermissions(String userId, List<UserPermission> permissions) async {
    try {
      await AuthService().updateUserPermissions(userId, permissions);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating permissions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ExpansionTile(
                  leading: user.picture != null
                      ? CircleAvatar(backgroundImage: NetworkImage(user.picture!))
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user.name ?? user.email),
                  subtitle: Text(user.email),
                  children: [
                    ...user.permissions.map((permission) => CheckboxListTile(
                      title: Text(permission.name),
                      subtitle: Text(permission.description),
                      value: permission.isGranted,
                      onChanged: (bool? value) {
                        setState(() => permission.isGranted = value ?? false);
                        _updateUserPermissions(user.id, user.permissions);
                      },
                    )),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Delete User'),
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete User'),
                          content: Text('Are you sure you want to delete ${user.name ?? user.email}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteUser(user.id);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
