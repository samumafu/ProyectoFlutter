enum UserRole { pasajero, conductor, empresa, admin }

class SimpleUserModel {
  final String id;
  final String email;
  final UserRole role;
  final String passwordHash;
  final DateTime createdAt;

  const SimpleUserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.passwordHash,
    required this.createdAt,
  });

  bool get isEmpresa => role == UserRole.empresa;
  bool get isConductor => role == UserRole.conductor;
  bool get isUsuario => role == UserRole.pasajero;
  bool get isAdmin => role == UserRole.admin;

  factory SimpleUserModel.fromJson(Map<String, dynamic> json) {
    return SimpleUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.pasajero,
      ),
      passwordHash: json['password_hash'] as String,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
    };
  }
}