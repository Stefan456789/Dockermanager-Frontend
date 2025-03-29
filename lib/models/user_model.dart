class UserPermission {
  final int id;
  final String name;
  final String description;
  bool isGranted;

  UserPermission({
    required this.id,
    required this.name,
    required this.description,
    this.isGranted = false,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class UserDetails {
  final String id;
  final String email;
  final String? name;
  final String? picture;
  final List<UserPermission> permissions;

  UserDetails({
    required this.id,
    required this.email,
    this.name,
    this.picture,
    required this.permissions,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      picture: json['picture'],
      permissions: (json['permissions'] as List?)
          ?.map((p) => UserPermission.fromJson(p))
          .toList() ?? [],
    );
  }
}
