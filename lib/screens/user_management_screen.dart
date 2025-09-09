import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/container_info.dart';
import '../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<ContainerInfo> _containers = [];
  List<UserPermission> _containerPermissions = [];
  Map<String, List<UserDetails>> _containerUsers = {};
  Map<String, List<UserPermission>> _currentUserContainerPermissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final containers = await AuthService().getContainers();
      final permissions = await AuthService().getContainerPermissions();
      setState(() {
        _containers = containers;
        _containerPermissions = permissions;
        debugPrint('Loaded ${containers.length} containers and ${permissions.length} permission types');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUsersForContainer(String containerId) async {
    if (_containerUsers.containsKey(containerId)) return;
    try {
      final users = await AuthService().getUsersPermissionsForContainer(containerId);
      
      // Find current user's permissions
      final currentUser = AuthService().currentUser;
      UserDetails? currentUserData;
      try {
        currentUserData = users.firstWhere(
          (user) => user.id == currentUser?.id,
        );
      } catch (e) {
        currentUserData = null;
      }
      
      setState(() {
        _containerUsers[containerId] = users;
        _currentUserContainerPermissions[containerId] = currentUserData?.permissions ?? [];
        debugPrint('Loaded ${users.length} users for container $containerId');
        debugPrint('Current user permissions: ${_currentUserContainerPermissions[containerId]?.length ?? 0}');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users for container: $e')),
        );
      }
    }
  }

  Future<void> _updateUserContainerPermissions(String containerId, String userId, List<UserPermission> permissions) async {
    try {
      debugPrint('Updating permissions for user $userId on container $containerId: ${permissions.map((p) => p.name).join(', ')}');
      await AuthService().updateUserContainerPermissions(containerId, userId, permissions);
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
              itemCount: _containers.length,
              itemBuilder: (context, index) {
                final container = _containers[index];
                return ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.view_list)),
                  title: Text(container.name),
                  subtitle: Text(container.image),
                  onExpansionChanged: (expanded) {
                    if (expanded && !_containerUsers.containsKey(container.id)) {
                      _loadUsersForContainer(container.id);
                    }
                  },
                  children: !_containerUsers.containsKey(container.id)
                      ? [const Center(child: CircularProgressIndicator())]
                      : _containerUsers[container.id]!.map((user) {
                          return ExpansionTile(
                            leading: user.picture != null
                                ? CircleAvatar(backgroundImage: NetworkImage(user.picture!))
                                : const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(user.name ?? user.email),
                            subtitle: Text(user.email),
                            children: _containerPermissions.isEmpty
                                ? [const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No permissions available'),
                                  )]
                                : _currentUserContainerPermissions[container.id] == null
                                    ? [const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('Loading permissions...'),
                                      )]
                                    : _currentUserContainerPermissions[container.id]!.isEmpty
                                        ? [const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Text('You have no permissions to manage on this container'),
                                          )]
                                        : _containerPermissions
                                            .where((permission) => _currentUserContainerPermissions[container.id]!
                                                .any((p) => p.id == permission.id))
                                            .map((permission) {
                                          final isGranted = user.permissions.any((p) => p.id == permission.id);
                                          return CheckboxListTile(
                                            title: Text(permission.name),
                                            subtitle: Text(permission.description),
                                            value: isGranted,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value ?? false) {
                                                  user.permissions.add(permission);
                                                } else {
                                                  user.permissions.removeWhere((p) => p.id == permission.id);
                                                }
                                              });
                                              _updateUserContainerPermissions(
                                                container.id,
                                                user.id,
                                                user.permissions,
                                              );
                                            },
                                          );
                                        }).toList(),
                          );
                        }).toList(),
                );
              },
            ),
    );
  }
}
