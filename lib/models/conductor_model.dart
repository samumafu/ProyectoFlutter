enum ConductorStatus { activo, inactivo, suspendido }

enum ConductorEstado { disponible, enRuta, fueraDeServicio }

class ConductorModel {
  final String id;
  final String userId; // Referencia al usuario
  final String empresaId; // Referencia a la empresa
  final String numeroLicencia;
  final String categoriaLicencia;
  final DateTime fechaVencimientoLicencia;
  final String? experienciaAnios;
  final ConductorStatus estado;
  final ConductorEstado estadoActual;
  final String? licenciaUrl;
  final String? soatUrl;
  final String? revisionTecnicaUrl;
  final String? cedulaUrl;
  final String? certificadoAntecedentesUrl;
  final DateTime? fechaIngreso;
  final String? observaciones;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConductorModel({
    required this.id,
    required this.userId,
    required this.empresaId,
    required this.numeroLicencia,
    required this.categoriaLicencia,
    required this.fechaVencimientoLicencia,
    this.experienciaAnios,
    this.estado = ConductorStatus.activo,
    this.estadoActual = ConductorEstado.disponible,
    this.licenciaUrl,
    this.soatUrl,
    this.revisionTecnicaUrl,
    this.cedulaUrl,
    this.certificadoAntecedentesUrl,
    this.fechaIngreso,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => estado == ConductorStatus.activo;
  bool get isDisponible => estadoActual == ConductorEstado.disponible;
  bool get hasValidLicencia => fechaVencimientoLicencia.isAfter(DateTime.now());

  factory ConductorModel.fromJson(Map<String, dynamic> json) {
    return ConductorModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      empresaId: json['empresa_id'] as String,
      numeroLicencia: json['numero_licencia'] as String,
      categoriaLicencia: json['categoria_licencia'] as String,
      fechaVencimientoLicencia: DateTime.parse(json['fecha_vencimiento_licencia']),
      experienciaAnios: json['experiencia_anios'] as String?,
      estado: ConductorStatus.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => ConductorStatus.activo,
      ),
      estadoActual: ConductorEstado.values.firstWhere(
        (e) => e.name == json['estado_actual'],
        orElse: () => ConductorEstado.disponible,
      ),
      licenciaUrl: json['licencia_url'] as String?,
      soatUrl: json['soat_url'] as String?,
      revisionTecnicaUrl: json['revision_tecnica_url'] as String?,
      cedulaUrl: json['cedula_url'] as String?,
      certificadoAntecedentesUrl: json['certificado_antecedentes_url'] as String?,
      fechaIngreso: json['fecha_ingreso'] != null
          ? DateTime.parse(json['fecha_ingreso'])
          : null,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'empresa_id': empresaId,
      'numero_licencia': numeroLicencia,
      'categoria_licencia': categoriaLicencia,
      'fecha_vencimiento_licencia': fechaVencimientoLicencia.toIso8601String().split('T')[0],
      'experiencia_anios': experienciaAnios,
      'estado': estado.name,
      'estado_actual': estadoActual.name,
      'licencia_url': licenciaUrl,
      'soat_url': soatUrl,
      'revision_tecnica_url': revisionTecnicaUrl,
      'cedula_url': cedulaUrl,
      'certificado_antecedentes_url': certificadoAntecedentesUrl,
      'fecha_ingreso': fechaIngreso?.toIso8601String().split('T')[0],
      'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ConductorModel copyWith({
    String? id,
    String? userId,
    String? empresaId,
    String? numeroLicencia,
    String? categoriaLicencia,
    DateTime? fechaVencimientoLicencia,
    String? experienciaAnios,
    ConductorStatus? estado,
    ConductorEstado? estadoActual,
    String? licenciaUrl,
    String? soatUrl,
    String? revisionTecnicaUrl,
    String? cedulaUrl,
    String? certificadoAntecedentesUrl,
    DateTime? fechaIngreso,
    String? observaciones,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConductorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      empresaId: empresaId ?? this.empresaId,
      numeroLicencia: numeroLicencia ?? this.numeroLicencia,
      categoriaLicencia: categoriaLicencia ?? this.categoriaLicencia,
      fechaVencimientoLicencia: fechaVencimientoLicencia ?? this.fechaVencimientoLicencia,
      experienciaAnios: experienciaAnios ?? this.experienciaAnios,
      estado: estado ?? this.estado,
      estadoActual: estadoActual ?? this.estadoActual,
      licenciaUrl: licenciaUrl ?? this.licenciaUrl,
      soatUrl: soatUrl ?? this.soatUrl,
      revisionTecnicaUrl: revisionTecnicaUrl ?? this.revisionTecnicaUrl,
      cedulaUrl: cedulaUrl ?? this.cedulaUrl,
      certificadoAntecedentesUrl: certificadoAntecedentesUrl ?? this.certificadoAntecedentesUrl,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConductorModel &&
        other.id == id &&
        other.numeroLicencia == numeroLicencia;
  }

  @override
  int get hashCode {
    return id.hashCode ^ numeroLicencia.hashCode;
  }
}