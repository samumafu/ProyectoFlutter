enum EmpresaStatus { activa, inactiva, suspendida }

class EmpresaModel {
  final String id;
  final String userId; // Referencia al usuario que registró la empresa
  final String nit;
  final String razonSocial;
  final String nombreComercial;
  final String representanteLegal;
  final String cedulaRepresentante;
  final String direccion;
  final String municipio;
  final String departamento;
  final String telefono;
  final String? email;
  final String? sitioWeb;
  final String? logoUrl;
  final EmpresaStatus estado;
  final String? numeroHabilitacion;
  final DateTime? fechaHabilitacion;
  final DateTime? fechaVencimientoHabilitacion;
  final String? documentoHabilitacionUrl;
  final String? camaraComercioUrl;
  final String? rutUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmpresaModel({
    required this.id,
    required this.userId,
    required this.nit,
    required this.razonSocial,
    required this.nombreComercial,
    required this.representanteLegal,
    required this.cedulaRepresentante,
    required this.direccion,
    required this.municipio,
    this.departamento = 'Nariño',
    required this.telefono,
    this.email,
    this.sitioWeb,
    this.logoUrl,
    this.estado = EmpresaStatus.activa,
    this.numeroHabilitacion,
    this.fechaHabilitacion,
    this.fechaVencimientoHabilitacion,
    this.documentoHabilitacionUrl,
    this.camaraComercioUrl,
    this.rutUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => estado == EmpresaStatus.activa;
  bool get hasValidHabilitacion => 
      fechaVencimientoHabilitacion != null && 
      fechaVencimientoHabilitacion!.isAfter(DateTime.now());

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nit: json['nit'] as String,
      razonSocial: json['razon_social'] as String,
      nombreComercial: json['nombre_comercial'] as String,
      representanteLegal: json['representante_legal'] as String,
      cedulaRepresentante: json['cedula_representante'] as String,
      direccion: json['direccion'] as String,
      municipio: json['municipio'] as String,
      departamento: json['departamento'] as String? ?? 'Nariño',
      telefono: json['telefono'] as String,
      email: json['email'] as String?,
      sitioWeb: json['sitio_web'] as String?,
      logoUrl: json['logo_url'] as String?,
      estado: EmpresaStatus.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EmpresaStatus.activa,
      ),
      numeroHabilitacion: json['numero_habilitacion'] as String?,
      fechaHabilitacion: json['fecha_habilitacion'] != null
          ? DateTime.parse(json['fecha_habilitacion'])
          : null,
      fechaVencimientoHabilitacion: json['fecha_vencimiento_habilitacion'] != null
          ? DateTime.parse(json['fecha_vencimiento_habilitacion'])
          : null,
      documentoHabilitacionUrl: json['documento_habilitacion_url'] as String?,
      camaraComercioUrl: json['camara_comercio_url'] as String?,
      rutUrl: json['rut_url'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nit': nit,
      'razon_social': razonSocial,
      'nombre_comercial': nombreComercial,
      'representante_legal': representanteLegal,
      'cedula_representante': cedulaRepresentante,
      'direccion': direccion,
      'municipio': municipio,
      'departamento': departamento,
      'telefono': telefono,
      'email': email,
      'sitio_web': sitioWeb,
      'logo_url': logoUrl,
      'estado': estado.name,
      'numero_habilitacion': numeroHabilitacion,
      'fecha_habilitacion': fechaHabilitacion?.toIso8601String().split('T')[0],
      'fecha_vencimiento_habilitacion': fechaVencimientoHabilitacion?.toIso8601String().split('T')[0],
      'documento_habilitacion_url': documentoHabilitacionUrl,
      'camara_comercio_url': camaraComercioUrl,
      'rut_url': rutUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EmpresaModel copyWith({
    String? id,
    String? userId,
    String? nit,
    String? razonSocial,
    String? nombreComercial,
    String? representanteLegal,
    String? cedulaRepresentante,
    String? direccion,
    String? municipio,
    String? departamento,
    String? telefono,
    String? email,
    String? sitioWeb,
    String? logoUrl,
    EmpresaStatus? estado,
    String? numeroHabilitacion,
    DateTime? fechaHabilitacion,
    DateTime? fechaVencimientoHabilitacion,
    String? documentoHabilitacionUrl,
    String? camaraComercioUrl,
    String? rutUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmpresaModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nit: nit ?? this.nit,
      razonSocial: razonSocial ?? this.razonSocial,
      nombreComercial: nombreComercial ?? this.nombreComercial,
      representanteLegal: representanteLegal ?? this.representanteLegal,
      cedulaRepresentante: cedulaRepresentante ?? this.cedulaRepresentante,
      direccion: direccion ?? this.direccion,
      municipio: municipio ?? this.municipio,
      departamento: departamento ?? this.departamento,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      sitioWeb: sitioWeb ?? this.sitioWeb,
      logoUrl: logoUrl ?? this.logoUrl,
      estado: estado ?? this.estado,
      numeroHabilitacion: numeroHabilitacion ?? this.numeroHabilitacion,
      fechaHabilitacion: fechaHabilitacion ?? this.fechaHabilitacion,
      fechaVencimientoHabilitacion: fechaVencimientoHabilitacion ?? this.fechaVencimientoHabilitacion,
      documentoHabilitacionUrl: documentoHabilitacionUrl ?? this.documentoHabilitacionUrl,
      camaraComercioUrl: camaraComercioUrl ?? this.camaraComercioUrl,
      rutUrl: rutUrl ?? this.rutUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmpresaModel &&
        other.id == id &&
        other.nit == nit &&
        other.razonSocial == razonSocial;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nit.hashCode ^ razonSocial.hashCode;
  }
}