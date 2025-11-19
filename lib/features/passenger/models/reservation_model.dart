// lib/features/passenger/models/reservation_model.dart

import 'dart:convert';

class Reservation {
  final String id;
  final String tripId;
  final String passengerId;
  final int seatsReserved;
  final double totalPrice;
  
  // 1. 🟢 CAMPOS DE ESTADO (Para Compañía/Pasajero)
  // Utilizamos 'status' como tu campo principal, pero incluimos los booleanos 
  // para facilitar la lógica de la UI (como el StatusChip en la pantalla de reservas).
  final String status; // 'confirmed', 'pending', 'cancelled'
  final DateTime? createdAt;
  
  // Asumimos que la lógica de la UI del StatusChip puede derivarse de 'status'.
  // Si necesitas 'isConfirmed' / 'isCancelled' directo, añádelos y mapea.
  // Por ahora, usaremos 'status' para derivar esto.

  // 2. 🟡 CAMPOS DE RECOGIDA (Para Driver/Tracking)
  final double? pickupLatitude; 
  final double? pickupLongitude;
  final bool? boarded;
  final String? boardedAt;

  const Reservation({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.seatsReserved,
    required this.totalPrice,
    required this.status,
    this.createdAt, // Añadido
    this.pickupLatitude,
    this.pickupLongitude,
    this.boarded,
    this.boardedAt,
  });
  
  // 🔑 Getters Derivados para compatibilidad con la lógica del StatusChip
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  // Si necesitas un campo 'is_confirmed'/'is_cancelled' en Supabase, 
  // debes mapearlo en fromMap/toMap. Si solo usas 'status', esto es suficiente.


  factory Reservation.fromMap(Map<String, dynamic> map) {
    double? _asDoubleNullable(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    // Mapeo de la fecha de creación desde Supabase
    DateTime? parsedCreatedAt;
    if (map['created_at'] != null && map['created_at'] is String) {
      parsedCreatedAt = DateTime.tryParse(map['created_at']);
    }
    
    return Reservation(
      id: map['id'] as String? ?? '',
      tripId: map['trip_id'] as String? ?? '',
      passengerId: map['passenger_id'] as String? ?? '',
      seatsReserved: (map['seats_reserved'] as num?)?.toInt() ?? 0,
      totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pending', // Default a 'pending'
      
      // Mapeo del campo de fecha
      createdAt: parsedCreatedAt, 
      
      // Mapeo de los campos de recogida
      pickupLatitude: _asDoubleNullable(map['pickup_latitude']),
      pickupLongitude: _asDoubleNullable(map['pickup_longitude']),
      boarded: map['boarded'] as bool?,
      boardedAt: map['boarded_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'passenger_id': passengerId,
      'seats_reserved': seatsReserved,
      'total_price': totalPrice,
      'status': status,
      // 'created_at' no se incluye aquí, se genera automáticamente.
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'boarded': boarded,
      'boarded_at': boardedAt,
    };
  }
}