import 'package:flutter/material.dart';
import 'package:docker_manager/models/container_info.dart';
import 'package:docker_manager/services/docker_api_service.dart';
import 'package:docker_manager/services/settings_service.dart';
import 'package:docker_manager/screens/container_detail_screen.dart';
import 'package:docker_manager/screens/settings_screen.dart';

class ContainerListScreen extends StatefulWidget {
  const ContainerListScreen({super.key});

  @override
  State<ContainerListScreen> createState() => _ContainerListScreenState();
}

class _ContainerListScreenState extends State<ContainerListScreen> {
  final DockerApiService _apiService = DockerApiService();
  late final SettingsService _settingsService;
  List<ContainerInfo> _containers = [];
  bool _isLoading = true;
  String? _error;
  
  late String _username = "Anonymous";
  late String _email = "";
  late String _userProfileImage = "https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y";

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _fetchContainers();
    initUser();
  }

  Future<void> _initializeSettings() async {
    _settingsService = SettingsService();
  }

  void initUser() {
    _username = _apiService.authService.currentUser?.name ?? _username;
    _email = _apiService.authService.currentUser?.email ?? _email;
    _userProfileImage = _apiService.authService.currentUser?.picture ?? _userProfileImage;
  }

  Future<void> _fetchContainers() async {
    try {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final containers = await _apiService.getContainers();
      
      if (!mounted) return;
      
      setState(() {
        _containers = containers.where((container) {
          return _settingsService.showExited || container.state == 'running';
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = 'Failed to fetch containers: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up any resources or listeners here if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Docker Containers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchContainers,
            tooltip: 'Refresh container list',
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(_username),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'signout',
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(_userProfileImage),
                backgroundColor: Colors.grey[300],
                child: _userProfileImage.isEmpty
                  ? const Icon(Icons.person, size: 20, color: Colors.white)
                  : null,
              ),
            ),
          ),
          const SizedBox(width: 8), // Add some spacing
        ],
      ),
      body: _buildBody(),
    );
  }
  
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        // Show profile info or navigate to profile screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged in as $_username ($_email)'))
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsScreen(settingsService: _settingsService),
          ),
        ).then((_) => _fetchContainers());
        break;
      case 'signout':
        _apiService.authService.signOut();
        break;
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchContainers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_containers.isEmpty) {
      return const Center(child: Text('No containers found'));
    }

    return RefreshIndicator(
      onRefresh: _fetchContainers,
      child: ListView.builder(
        itemCount: _containers.length,
        itemBuilder: (context, index) {
          final container = _containers[index];
          return _buildContainerItem(container);
        },
      ),
    );
  }

  Widget _buildContainerItem(ContainerInfo container) {
    Color stateColor = Colors.grey;
    if (container.state == 'running') {
      stateColor = Colors.green;
    } else if (container.state == 'exited') {
      stateColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.dns, color: stateColor),
        title: Text(container.name),
        subtitle: Text('${container.image}\n${container.status}'),
        isThreeLine: true,
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContainerDetailScreen(container: container),
            ),
          ).then((_) => _fetchContainers()); // Refresh after returning
        },
      ),
    );
  }
}
