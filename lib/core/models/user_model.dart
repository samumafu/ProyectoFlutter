class UserModel {
  final String id;
  final String email;
  final String? passwordHash;
  final String role;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.passwordHash,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String?,
      role: map['role'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'role': role,
    };
  }
}