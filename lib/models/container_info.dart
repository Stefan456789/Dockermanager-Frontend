class ContainerInfo {
  final String id;
  final String name;
  final String image;
  final String state;
  final String status;
  final List<ContainerPort> ports;
  final String created;
  final bool tty;
  final bool openStdin;

  ContainerInfo({
    required this.id,
    required this.name,
    required this.image,
    required this.state,
    required this.status,
    required this.ports,
    required this.created,
    required this.tty,
    required this.openStdin,
  });

  factory ContainerInfo.fromJson(Map<String, dynamic> json) {
    return ContainerInfo(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      state: json['state'],
      status: json['status'],
      ports: (json['ports'] as List<dynamic>)
          .map((port) => ContainerPort.fromJson(port))
          .toList(),
      created: json['created'],
      tty: json['tty'],
      openStdin: json['openStdin'],
    );
  }
}

class ContainerPort {
  final int privatePort;
  final int? publicPort;
  final String type;

  ContainerPort({
    required this.privatePort,
    this.publicPort,
    required this.type,
  });

  factory ContainerPort.fromJson(Map<String, dynamic> json) {
    return ContainerPort(
      privatePort: json['privatePort'],
      publicPort: json['publicPort'],
      type: json['type'],
    );
  }
}
