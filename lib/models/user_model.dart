enum UserRole { usuario, conductor, empresa, admin }

enum UserStatus { activo, inactivo, suspendido }

class UserModel {
  final String id;
  final String email;
  final UserRole rol;
  final String nombres;
  final String apellidos;
  final String cedula;
  final String? telefono;
  final DateTime? fechaNacimiento;
  final String? direccion;
  final String? municipio;
  final String? departamento;
  final String? fotoPerfilUrl;
  final UserStatus estado;
  final bool emailVerificado;
  final bool telefonoVerificado;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.rol,
    required this.nombres,
    required this.apellidos,
    required this.cedula,
    this.telefono,
    this.fechaNacimiento,
    this.direccion,
    this.municipio,
    this.departamento = 'Nariño',
    this.fotoPerfilUrl,
    this.estado = UserStatus.activo,
    this.emailVerificado = false,
    this.telefonoVerificado = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get nombreCompleto => '$nombres $apellidos';

  bool get isActive => estado == UserStatus.activo;
  bool get isEmpresa => rol == UserRole.empresa;
  bool get isConductor => rol == UserRole.conductor;
  bool get isUsuario => rol == UserRole.usuario;
  bool get isAdmin => rol == UserRole.admin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      rol: UserRole.values.firstWhere(
        (e) => e.name == json['rol'],
        orElse: () => UserRole.usuario,
      ),
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      cedula: json['cedula'] as String,
      telefono: json['telefono'] as String?,
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'])
          : null,
      direccion: json['direccion'] as String?,
      municipio: json['municipio'] as String?,
      departamento: json['departamento'] as String? ?? 'Nariño',
      fotoPerfilUrl: json['foto_perfil_url'] as String?,
      estado: UserStatus.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => UserStatus.activo,
      ),
      emailVerificado: json['email_verificado'] as bool? ?? false,
      telefonoVerificado: json['telefono_verificado'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'rol': rol.name,
      'nombres': nombres,
      'apellidos': apellidos,
      'cedula': cedula,
      'telefono': telefono,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0],
      'direccion': direccion,
      'municipio': municipio,
      'departamento': departamento,
      'foto_perfil_url': fotoPerfilUrl,
      'estado': estado.name,
      'email_verificado': emailVerificado,
      'telefono_verificado': telefonoVerificado,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    UserRole? rol,
    String? nombres,
    String? apellidos,
    String? cedula,
    String? telefono,
    DateTime? fechaNacimiento,
    String? direccion,
    String? municipio,
    String? departamento,
    String? fotoPerfilUrl,
    UserStatus? estado,
    bool? emailVerificado,
    bool? telefonoVerificado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      cedula: cedula ?? this.cedula,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      direccion: direccion ?? this.direccion,
      municipio: municipio ?? this.municipio,
      departamento: departamento ?? this.departamento,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      estado: estado ?? this.estado,
      emailVerificado: emailVerificado ?? this.emailVerificado,
      telefonoVerificado: telefonoVerificado ?? this.telefonoVerificado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.rol == rol &&
        other.nombres == nombres &&
        other.apellidos == apellidos &&
        other.cedula == cedula;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        rol.hashCode ^
        nombres.hashCode ^
        apellidos.hashCode ^
        cedula.hashCode;
  }
}