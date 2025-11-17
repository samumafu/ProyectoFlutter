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
    // Los datos del viaje (origin, destination) vienen anidados bajo 'company_schedules'
    final scheduleData = map['company_schedules'] as Map<String, dynamic>;

    return ReservationHistory(
      id: map['id'].toString(),
      tripId: map['trip_id'] as String,
      seatsReserved: map['seats_reserved'] as int,
      totalPrice: map['total_price'] as double,
      status: map['status'] as String,
      
      // Mapeo de campos del JOIN anidado:
      origin: scheduleData['origin'] as String,
      destination: scheduleData['destination'] as String,
      
      // Campos opcionales (null safety)
      pickupLatitude: map['pickup_latitude'] as double?,
      pickupLongitude: map['pickup_longitude'] as double?,
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