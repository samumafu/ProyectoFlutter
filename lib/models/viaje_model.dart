enum ViajeStatus { programado, enCurso, completado, cancelado }

class ViajeModel {
  final String id;
  final String rutaId;
  final String empresaId;
  final String vehiculoId;
  final String? conductorId;
  final DateTime fechaSalida;
  final DateTime horaSalida;
  final DateTime? horaLlegadaEstimada;
  final DateTime? horaSalidaReal;
  final DateTime? horaLlegadaReal;
  final double precio;
  final int cuposDisponibles;
  final int cuposOcupados;
  final ViajeStatus estado;
  final String? observaciones;
  final String? motivoCancelacion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ViajeModel({
    required this.id,
    required this.rutaId,
    required this.empresaId,
    required this.vehiculoId,
    this.conductorId,
    required this.fechaSalida,
    required this.horaSalida,
    this.horaLlegadaEstimada,
    this.horaSalidaReal,
    this.horaLlegadaReal,
    required this.precio,
    required this.cuposDisponibles,
    this.cuposOcupados = 0,
    this.estado = ViajeStatus.programado,
    this.observaciones,
    this.motivoCancelacion,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isProgramado => estado == ViajeStatus.programado;
  bool get isEnCurso => estado == ViajeStatus.enCurso;
  bool get isCompletado => estado == ViajeStatus.completado;
  bool get isCancelado => estado == ViajeStatus.cancelado;
  bool get hasAvailableSeats => cuposDisponibles > cuposOcupados;
  int get cuposLibres => cuposDisponibles - cuposOcupados;

  DateTime get fechaHoraSalida => DateTime(
    fechaSalida.year,
    fechaSalida.month,
    fechaSalida.day,
    horaSalida.hour,
    horaSalida.minute,
  );

  factory ViajeModel.fromJson(Map<String, dynamic> json) {
    return ViajeModel(
      id: json['id'] as String,
      rutaId: json['ruta_id'] as String,
      empresaId: json['empresa_id'] as String,
      vehiculoId: json['vehiculo_id'] as String,
      conductorId: json['conductor_id'] as String?,
      fechaSalida: DateTime.parse(json['fecha_salida']),
      horaSalida: DateTime.parse('1970-01-01 ${json['hora_salida']}'),
      horaLlegadaEstimada: json['hora_llegada_estimada'] != null
          ? DateTime.parse('1970-01-01 ${json['hora_llegada_estimada']}')
          : null,
      horaSalidaReal: json['hora_salida_real'] != null
          ? DateTime.parse(json['hora_salida_real'])
          : null,
      horaLlegadaReal: json['hora_llegada_real'] != null
          ? DateTime.parse(json['hora_llegada_real'])
          : null,
      precio: (json['precio'] as num).toDouble(),
      cuposDisponibles: json['cupos_disponibles'] as int,
      cuposOcupados: json['cupos_ocupados'] as int? ?? 0,
      estado: ViajeStatus.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => ViajeStatus.programado,
      ),
      observaciones: json['observaciones'] as String?,
      motivoCancelacion: json['motivo_cancelacion'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ruta_id': rutaId,
      'empresa_id': empresaId,
      'vehiculo_id': vehiculoId,
      'conductor_id': conductorId,
      'fecha_salida': fechaSalida.toIso8601String().split('T')[0],
      'hora_salida': '${horaSalida.hour.toString().padLeft(2, '0')}:${horaSalida.minute.toString().padLeft(2, '0')}:00',
      'hora_llegada_estimada': horaLlegadaEstimada != null
          ? '${horaLlegadaEstimada!.hour.toString().padLeft(2, '0')}:${horaLlegadaEstimada!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'hora_salida_real': horaSalidaReal?.toIso8601String(),
      'hora_llegada_real': horaLlegadaReal?.toIso8601String(),
      'precio': precio,
      'cupos_disponibles': cuposDisponibles,
      'cupos_ocupados': cuposOcupados,
      'estado': estado.name,
      'observaciones': observaciones,
      'motivo_cancelacion': motivoCancelacion,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ViajeModel copyWith({
    String? id,
    String? rutaId,
    String? empresaId,
    String? vehiculoId,
    String? conductorId,
    DateTime? fechaSalida,
    DateTime? horaSalida,
    DateTime? horaLlegadaEstimada,
    DateTime? horaSalidaReal,
    DateTime? horaLlegadaReal,
    double? precio,
    int? cuposDisponibles,
    int? cuposOcupados,
    ViajeStatus? estado,
    String? observaciones,
    String? motivoCancelacion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ViajeModel(
      id: id ?? this.id,
      rutaId: rutaId ?? this.rutaId,
      empresaId: empresaId ?? this.empresaId,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      conductorId: conductorId ?? this.conductorId,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      horaSalida: horaSalida ?? this.horaSalida,
      horaLlegadaEstimada: horaLlegadaEstimada ?? this.horaLlegadaEstimada,
      horaSalidaReal: horaSalidaReal ?? this.horaSalidaReal,
      horaLlegadaReal: horaLlegadaReal ?? this.horaLlegadaReal,
      precio: precio ?? this.precio,
      cuposDisponibles: cuposDisponibles ?? this.cuposDisponibles,
      cuposOcupados: cuposOcupados ?? this.cuposOcupados,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      motivoCancelacion: motivoCancelacion ?? this.motivoCancelacion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ViajeModel &&
        other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}