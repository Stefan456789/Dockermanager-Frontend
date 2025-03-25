import 'package:flutter/material.dart';
import 'package:docker_manager/models/container_info.dart';
import 'package:docker_manager/services/docker_api_service.dart';
import 'package:docker_manager/screens/container_detail_screen.dart';

class ContainerListScreen extends StatefulWidget {
  const ContainerListScreen({super.key});

  @override
  State<ContainerListScreen> createState() => _ContainerListScreenState();
}

class _ContainerListScreenState extends State<ContainerListScreen> {
  final DockerApiService _apiService = DockerApiService();
  List<ContainerInfo> _containers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContainers();
  }

  Future<void> _fetchContainers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final containers = await _apiService.getContainers();
      setState(() {
        _containers = containers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch containers: $e';
        _isLoading = false;
      });
    }
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
        ],
      ),
      body: _buildBody(),
    );
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
