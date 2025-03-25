import 'package:flutter/material.dart';
import 'package:docker_manager/models/container_info.dart';

class ContainerInfoCard extends StatelessWidget {
  final ContainerInfo container;
  const ContainerInfoCard({super.key, required this.container});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color:
                      container.state == 'running' ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${container.status}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('ID: ${container.id}'),
            Text('Image: ${container.image}'),
            Text('Created: ${container.created}'),
            if (container.ports.isNotEmpty)
              Text('Ports: ' +
                  container.ports
                      .map((p) =>
                          '${p.privatePort}${p.publicPort != null ? ':${p.publicPort}' : ''} (${p.type})')
                      .join(', ')),
          ],
        ),
      ),
    );
  }
}
