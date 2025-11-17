// lib/features/passenger/models/reservation_model.dart

import 'dart:convert';

class Reservation {
  final String id;
  final String tripId;
  final String passengerId;
  final int seatsReserved;
  final double totalPrice;
  final String status;
  // 🟢 Campos de Recogida guardados en la tabla 'reservations'
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
    this.pickupLatitude,
    this.pickupLongitude,
    this.boarded,
    this.boardedAt,
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    double? _asDoubleNullable(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return Reservation(
      id: map['id'] as String? ?? '',
      tripId: map['trip_id'] as String? ?? '',
      passengerId: map['passenger_id'] as String? ?? '',
      seatsReserved: (map['seats_reserved'] as num?)?.toInt() ?? 0,
      totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'unknown',
      // Mapeo de los nuevos campos de recogida
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
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'boarded': boarded,
      'boarded_at': boardedAt,
    };
  }
}