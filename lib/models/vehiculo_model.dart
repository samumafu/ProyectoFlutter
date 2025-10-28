enum VehiculoStatus { activo, inactivo, mantenimiento }

enum TipoVehiculo { bus, buseta, microbus, van }

class VehiculoModel {
  final String id;
  final String empresaId;
  final String placa;
  final String marca;
  final String modelo;
  final int anio;
  final TipoVehiculo tipo;
  final int capacidadPasajeros;
  final String numeroInterno;
  final String? color;
  final VehiculoStatus estado;
  final String? soatUrl;
  final DateTime? fechaVencimientoSoat;
  final String? revisionTecnicaUrl;
  final DateTime? fechaVencimientoRevision;
  final String? tarjetaOperacionUrl;
  final DateTime? fechaVencimientoOperacion;
  final String? polizaUrl;
  final DateTime? fechaVencimientoPoliza;
  final String? observaciones;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehiculoModel({
    required this.id,
    required this.empresaId,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.tipo,
    required this.capacidadPasajeros,
    required this.numeroInterno,
    this.color,
    this.estado = VehiculoStatus.activo,
    this.soatUrl,
    this.fechaVencimientoSoat,
    this.revisionTecnicaUrl,
    this.fechaVencimientoRevision,
    this.tarjetaOperacionUrl,
    this.fechaVencimientoOperacion,
    this.polizaUrl,
    this.fechaVencimientoPoliza,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => estado == VehiculoStatus.activo;
  bool get hasValidSoat => 
      fechaVencimientoSoat != null && 
      fechaVencimientoSoat!.isAfter(DateTime.now());
  bool get hasValidRevision => 
      fechaVencimientoRevision != null && 
      fechaVencimientoRevision!.isAfter(DateTime.now());

  String get descripcionCompleta => '$marca $modelo $anio - $placa';

  factory VehiculoModel.fromJson(Map<String, dynamic> json) {
    return VehiculoModel(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String,
      placa: json['placa'] as String,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      anio: json['anio'] as int,
      tipo: TipoVehiculo.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoVehiculo.bus,
      ),
      capacidadPasajeros: json['capacidad_pasajeros'] as int,
      numeroInterno: json['numero_interno'] as String,
      color: json['color'] as String?,
      estado: VehiculoStatus.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => VehiculoStatus.activo,
      ),
      soatUrl: json['soat_url'] as String?,
      fechaVencimientoSoat: json['fecha_vencimiento_soat'] != null
          ? DateTime.parse(json['fecha_vencimiento_soat'])
          : null,
      revisionTecnicaUrl: json['revision_tecnica_url'] as String?,
      fechaVencimientoRevision: json['fecha_vencimiento_revision'] != null
          ? DateTime.parse(json['fecha_vencimiento_revision'])
          : null,
      tarjetaOperacionUrl: json['tarjeta_operacion_url'] as String?,
      fechaVencimientoOperacion: json['fecha_vencimiento_operacion'] != null
          ? DateTime.parse(json['fecha_vencimiento_operacion'])
          : null,
      polizaUrl: json['poliza_url'] as String?,
      fechaVencimientoPoliza: json['fecha_vencimiento_poliza'] != null
          ? DateTime.parse(json['fecha_vencimiento_poliza'])
          : null,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'placa': placa,
      'marca': marca,
      'modelo': modelo,
      'anio': anio,
      'tipo': tipo.name,
      'capacidad_pasajeros': capacidadPasajeros,
      'numero_interno': numeroInterno,
      'color': color,
      'estado': estado.name,
      'soat_url': soatUrl,
      'fecha_vencimiento_soat': fechaVencimientoSoat?.toIso8601String().split('T')[0],
      'revision_tecnica_url': revisionTecnicaUrl,
      'fecha_vencimiento_revision': fechaVencimientoRevision?.toIso8601String().split('T')[0],
      'tarjeta_operacion_url': tarjetaOperacionUrl,
      'fecha_vencimiento_operacion': fechaVencimientoOperacion?.toIso8601String().split('T')[0],
      'poliza_url': polizaUrl,
      'fecha_vencimiento_poliza': fechaVencimientoPoliza?.toIso8601String().split('T')[0],
      'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VehiculoModel copyWith({
    String? id,
    String? empresaId,
    String? placa,
    String? marca,
    String? modelo,
    int? anio,
    TipoVehiculo? tipo,
    int? capacidadPasajeros,
    String? numeroInterno,
    String? color,
    VehiculoStatus? estado,
    String? soatUrl,
    DateTime? fechaVencimientoSoat,
    String? revisionTecnicaUrl,
    DateTime? fechaVencimientoRevision,
    String? tarjetaOperacionUrl,
    DateTime? fechaVencimientoOperacion,
    String? polizaUrl,
    DateTime? fechaVencimientoPoliza,
    String? observaciones,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehiculoModel(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      placa: placa ?? this.placa,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      anio: anio ?? this.anio,
      tipo: tipo ?? this.tipo,
      capacidadPasajeros: capacidadPasajeros ?? this.capacidadPasajeros,
      numeroInterno: numeroInterno ?? this.numeroInterno,
      color: color ?? this.color,
      estado: estado ?? this.estado,
      soatUrl: soatUrl ?? this.soatUrl,
      fechaVencimientoSoat: fechaVencimientoSoat ?? this.fechaVencimientoSoat,
      revisionTecnicaUrl: revisionTecnicaUrl ?? this.revisionTecnicaUrl,
      fechaVencimientoRevision: fechaVencimientoRevision ?? this.fechaVencimientoRevision,
      tarjetaOperacionUrl: tarjetaOperacionUrl ?? this.tarjetaOperacionUrl,
      fechaVencimientoOperacion: fechaVencimientoOperacion ?? this.fechaVencimientoOperacion,
      polizaUrl: polizaUrl ?? this.polizaUrl,
      fechaVencimientoPoliza: fechaVencimientoPoliza ?? this.fechaVencimientoPoliza,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehiculoModel &&
        other.id == id &&
        other.placa == placa;
  }

  @override
  int get hashCode {
    return id.hashCode ^ placa.hashCode;
  }
}