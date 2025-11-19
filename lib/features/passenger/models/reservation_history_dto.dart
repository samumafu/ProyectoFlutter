// 📝 lib/features/passenger/models/reservation_history_dto.dart

class ReservationHistory {
  final String id;
  final String tripId;
  final String origin;
  final String destination;
  final int seatsReserved;
  final double totalPrice;
  final String status;
  final double? pickupLatitude;
  final double? pickupLongitude;

  ReservationHistory({
    required this.id,
    required this.tripId,
    required this.origin,
    required this.destination,
    required this.seatsReserved,
    required this.totalPrice,
    required this.status,
    this.pickupLatitude,
    this.pickupLongitude,
  });

  // 🟢 CORRECCIÓN 1: Implementación del factory fromMap
  // Maneja el resultado del JOIN: 'reservations' + 'company_schedules'
  factory ReservationHistory.fromMap(Map<String, dynamic> map) {
    // Helpers to normalize numeric values coming from Supabase
    int _asInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double _asDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    double? _asDoubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    // Trip data from the joined table may arrive as Map or null
    final dynamic sched = map['company_schedules'];
    final Map<String, dynamic> scheduleData =
        sched is Map<String, dynamic>
            ? sched
            : (sched is Map ? sched.cast<String, dynamic>() : <String, dynamic>{});

    return ReservationHistory(
      id: map['id'].toString(),
      tripId: (map['trip_id'] ?? map['schedule_id']).toString(),
      seatsReserved: _asInt(map['seats_reserved']),
      totalPrice: _asDouble(map['total_price']),
      status: (map['status'] ?? '').toString(),

      // Joined fields
      origin: (scheduleData['origin'] ?? '').toString(),
      destination: (scheduleData['destination'] ?? '').toString(),

      // Optional pickup coordinates
      pickupLatitude: _asDoubleOrNull(map['pickup_latitude']),
      pickupLongitude: _asDoubleOrNull(map['pickup_longitude']),
    );
  }

  // 🟢 CORRECCIÓN 2: Implementación del método copyWith (Necesario para el Controller)
  ReservationHistory copyWith({
    String? id,
    String? tripId,
    String? origin,
    String? destination,
    int? seatsReserved,
    double? totalPrice,
    String? status, // Campo clave a actualizar
    double? pickupLatitude,
    double? pickupLongitude,
  }) {
    return ReservationHistory(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      seatsReserved: seatsReserved ?? this.seatsReserved,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
    );
  }
}