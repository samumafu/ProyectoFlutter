enum ReservaStatus {
  pendiente,
  confirmada,
  pagada,
  cancelada,
  completada,
}

enum MetodoPago {
  efectivo,
  tarjeta,
  transferencia,
  pse,
}

class ReservaModel {
  final String id;
  final String viajeId;
  final String usuarioId;
  final String empresaId;
  final String nombrePasajero;
  final String telefonoPasajero;
  final String? emailPasajero;
  final String? documentoPasajero;
  final int numeroAsientos;
  final List<String> asientosSeleccionados;
  final double precioTotal;
  final double? descuento;
  final double precioFinal;
  final ReservaStatus estado;
  final MetodoPago? metodoPago;
  final String? codigoReserva;
  final String? observaciones;
  final DateTime? fechaPago;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Información adicional del viaje (para consultas)
  final String? viajeOrigen;
  final String? viajeDestino;
  final DateTime? viajeFechaSalida;
  final DateTime? viajeHoraSalida;
  final double? viajePrecio;

  const ReservaModel({
    required this.id,
    required this.viajeId,
    required this.usuarioId,
    required this.empresaId,
    required this.nombrePasajero,
    required this.telefonoPasajero,
    this.emailPasajero,
    this.documentoPasajero,
    required this.numeroAsientos,
    required this.asientosSeleccionados,
    required this.precioTotal,
    this.descuento,
    required this.precioFinal,
    required this.estado,
    this.metodoPago,
    this.codigoReserva,
    this.observaciones,
    this.fechaPago,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
    this.viajeOrigen,
    this.viajeDestino,
    this.viajeFechaSalida,
    this.viajeHoraSalida,
    this.viajePrecio,
  });

  // Getters
  bool get isPendiente => estado == ReservaStatus.pendiente;
  bool get isConfirmada => estado == ReservaStatus.confirmada;
  bool get isPagada => estado == ReservaStatus.pagada;
  bool get isCancelada => estado == ReservaStatus.cancelada;
  bool get isCompletada => estado == ReservaStatus.completada;
  bool get isActive => estado != ReservaStatus.cancelada;
  bool get requiresPayment => estado == ReservaStatus.confirmada;
  
  String get asientosTexto => asientosSeleccionados.join(', ');
  double get montoDescuento => descuento ?? 0.0;
  double get porcentajeDescuento => precioTotal > 0 ? (montoDescuento / precioTotal) * 100 : 0;

  String get descripcionViaje {
    if (viajeOrigen != null && viajeDestino != null) {
      return '$viajeOrigen - $viajeDestino';
    }
    return 'Viaje ID: $viajeId';
  }

  // Serialización
  factory ReservaModel.fromJson(Map<String, dynamic> json) {
    return ReservaModel(
      id: json['id'] ?? '',
      viajeId: json['viaje_id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      empresaId: json['empresa_id'] ?? '',
      nombrePasajero: json['nombre_pasajero'] ?? '',
      telefonoPasajero: json['telefono_pasajero'] ?? '',
      emailPasajero: json['email_pasajero'],
      documentoPasajero: json['cedula_pasajero'], // Mapear desde cedula_pasajero
      numeroAsientos: 1, // Valor fijo por ahora
      asientosSeleccionados: json['numero_asiento'] != null 
          ? [json['numero_asiento'].toString()]
          : [],
      precioTotal: (json['precio_pagado'] ?? 0).toDouble(),
      descuento: null,
      precioFinal: (json['precio_pagado'] ?? 0).toDouble(),
      estado: ReservaStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['estado'],
        orElse: () => ReservaStatus.pendiente,
      ),
      metodoPago: json['metodo_pago'] != null
          ? MetodoPago.values.firstWhere(
              (e) => e.toString().split('.').last == json['metodo_pago'],
              orElse: () => MetodoPago.efectivo,
            )
          : null,
      codigoReserva: json['codigo_reserva'],
      observaciones: json['observaciones'],
      fechaPago: json['fecha_pago'] != null 
          ? DateTime.parse(json['fecha_pago']) 
          : null,
      transactionId: json['referencia_pago'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      viajeOrigen: json['viaje_origen'],
      viajeDestino: json['viaje_destino'],
      viajeFechaSalida: json['viaje_fecha_salida'] != null 
          ? DateTime.parse(json['viaje_fecha_salida']) 
          : null,
      viajeHoraSalida: json['viaje_hora_salida'] != null 
          ? DateTime.parse('1970-01-01 ${json['viaje_hora_salida']}') 
          : null,
      viajePrecio: json['viaje_precio'] != null 
          ? (json['viaje_precio']).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'viaje_id': viajeId,
      'usuario_id': usuarioId,
      'empresa_id': empresaId,
      'nombre_pasajero': nombrePasajero,
      'telefono_pasajero': telefonoPasajero,
      'email_pasajero': emailPasajero,
      'documento_pasajero': documentoPasajero,
      'numero_asientos': numeroAsientos,
      'asientos_seleccionados': asientosSeleccionados,
      'precio_total': precioTotal,
      'descuento': descuento,
      'precio_final': precioFinal,
      'estado': estado.toString().split('.').last,
      'metodo_pago': metodoPago?.toString().split('.').last,
      'codigo_reserva': codigoReserva,
      'observaciones': observaciones,
      'fecha_pago': fechaPago?.toIso8601String(),
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Método copyWith
  ReservaModel copyWith({
    String? id,
    String? viajeId,
    String? usuarioId,
    String? empresaId,
    String? nombrePasajero,
    String? telefonoPasajero,
    String? emailPasajero,
    String? documentoPasajero,
    int? numeroAsientos,
    List<String>? asientosSeleccionados,
    double? precioTotal,
    double? descuento,
    double? precioFinal,
    ReservaStatus? estado,
    MetodoPago? metodoPago,
    String? codigoReserva,
    String? observaciones,
    DateTime? fechaPago,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? viajeOrigen,
    String? viajeDestino,
    DateTime? viajeFechaSalida,
    DateTime? viajeHoraSalida,
    double? viajePrecio,
  }) {
    return ReservaModel(
      id: id ?? this.id,
      viajeId: viajeId ?? this.viajeId,
      usuarioId: usuarioId ?? this.usuarioId,
      empresaId: empresaId ?? this.empresaId,
      nombrePasajero: nombrePasajero ?? this.nombrePasajero,
      telefonoPasajero: telefonoPasajero ?? this.telefonoPasajero,
      emailPasajero: emailPasajero ?? this.emailPasajero,
      documentoPasajero: documentoPasajero ?? this.documentoPasajero,
      numeroAsientos: numeroAsientos ?? this.numeroAsientos,
      asientosSeleccionados: asientosSeleccionados ?? this.asientosSeleccionados,
      precioTotal: precioTotal ?? this.precioTotal,
      descuento: descuento ?? this.descuento,
      precioFinal: precioFinal ?? this.precioFinal,
      estado: estado ?? this.estado,
      metodoPago: metodoPago ?? this.metodoPago,
      codigoReserva: codigoReserva ?? this.codigoReserva,
      observaciones: observaciones ?? this.observaciones,
      fechaPago: fechaPago ?? this.fechaPago,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viajeOrigen: viajeOrigen ?? this.viajeOrigen,
      viajeDestino: viajeDestino ?? this.viajeDestino,
      viajeFechaSalida: viajeFechaSalida ?? this.viajeFechaSalida,
      viajeHoraSalida: viajeHoraSalida ?? this.viajeHoraSalida,
      viajePrecio: viajePrecio ?? this.viajePrecio,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReservaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ReservaModel(id: $id, nombrePasajero: $nombrePasajero, numeroAsientos: $numeroAsientos, estado: $estado)';
  }
}