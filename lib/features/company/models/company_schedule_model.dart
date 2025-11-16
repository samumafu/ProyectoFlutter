class CompanySchedule {
  final int id;
  final String companyId;
  final String origin;
  final String destination;
  final String departureTime; // store as ISO/string to match DB
  final String arrivalTime; // store as ISO/string to match DB
  final double price;
  final int availableSeats;
  final int totalSeats;
  final String? vehicleType;
  final int? vehicleId;
  final bool isActive;
  final String? additionalInfo;

  const CompanySchedule({
    required this.id,
    required this.companyId,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.availableSeats,
    required this.totalSeats,
    required this.isActive,
    this.vehicleType,
    this.vehicleId,
    this.additionalInfo,
  });

  factory CompanySchedule.fromMap(Map<String, dynamic> map) {
    return CompanySchedule(
      id: (map['id'] as num).toInt(),
      companyId: map['company_id'] as String,
      origin: map['origin'] as String,
      destination: map['destination'] as String,
      departureTime: map['departure_time'] as String,
      arrivalTime: map['arrival_time'] as String,
      price: (map['price'] as num).toDouble(),
      availableSeats: (map['available_seats'] as num).toInt(),
      totalSeats: (map['total_seats'] as num).toInt(),
      vehicleType: map['vehicle_type'] as String?,
      vehicleId: (map['vehicle_id'] as num?)?.toInt(),
      isActive: (map['is_active'] as bool?) ?? false,
      additionalInfo: map['additional_info'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'origin': origin,
      'destination': destination,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'price': price,
      'available_seats': availableSeats,
      'total_seats': totalSeats,
      'vehicle_type': vehicleType,
      'vehicle_id': vehicleId,
      'is_active': isActive,
      'additional_info': additionalInfo,
    };
  }
}

class Reservation {
  final int id;
  final int tripId;
  final String passengerId;
  final int seatsReserved;
  final double totalPrice;
  final String status;

  const Reservation({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.seatsReserved,
    required this.totalPrice,
    required this.status,
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: (map['id'] as num).toInt(),
      tripId: (map['trip_id'] as num).toInt(),
      passengerId: map['passenger_id'] as String,
      seatsReserved: (map['seats_reserved'] as num).toInt(),
      totalPrice: (map['total_price'] as num).toDouble(),
      status: map['status'] as String,
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
    };
  }
}

class ChatMessage {
  final int id;
  final int tripId;
  final String senderId;
  final String message;

  const ChatMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.message,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: (map['id'] as num).toInt(),
      tripId: (map['trip_id'] as num).toInt(),
      senderId: map['sender_id'] as String,
      message: map['message'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'sender_id': senderId,
      'message': message,
    };
  }
}