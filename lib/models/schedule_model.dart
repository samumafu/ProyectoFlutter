import 'route_model.dart';
import 'vehicle_model.dart';
import 'driver_model.dart';

enum TripStatus {
  scheduled,
  boarding,
  inTransit,
  completed,
  cancelled,
  delayed,
}

class Schedule {
  final String id;
  final TransportRoute route;
  final Vehicle vehicle;
  final Driver driver;
  final DateTime departureTime;
  final DateTime estimatedArrivalTime;
  final double price;
  final List<String> availableSeats;
  final List<String> reservedSeats;
  final TripStatus status;
  final Map<String, dynamic> additionalInfo;

  const Schedule({
    required this.id,
    required this.route,
    required this.vehicle,
    required this.driver,
    required this.departureTime,
    required this.estimatedArrivalTime,
    required this.price,
    required this.availableSeats,
    required this.reservedSeats,
    this.status = TripStatus.scheduled,
    this.additionalInfo = const {},
  });

  int get totalSeats => vehicle.totalSeats;
  int get availableSeatsCount => availableSeats.length;
  int get reservedSeatsCount => reservedSeats.length;
  
  bool get hasAvailableSeats => availableSeats.isNotEmpty;
  
  String get statusDisplayName {
    switch (status) {
      case TripStatus.scheduled:
        return 'Programado';
      case TripStatus.boarding:
        return 'Abordando';
      case TripStatus.inTransit:
        return 'En Tránsito';
      case TripStatus.completed:
        return 'Completado';
      case TripStatus.cancelled:
        return 'Cancelado';
      case TripStatus.delayed:
        return 'Retrasado';
    }
  }

  Duration get tripDuration => estimatedArrivalTime.difference(departureTime);

  bool isSeatAvailable(String seatNumber) {
    return availableSeats.contains(seatNumber);
  }

  bool isSeatReserved(String seatNumber) {
    return reservedSeats.contains(seatNumber);
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      route: TransportRoute.fromJson(json['route']),
      vehicle: Vehicle.fromJson(json['vehicle']),
      driver: Driver.fromJson(json['driver']),
      departureTime: DateTime.parse(json['departureTime']),
      estimatedArrivalTime: DateTime.parse(json['estimatedArrivalTime']),
      price: json['price'].toDouble(),
      availableSeats: List<String>.from(json['availableSeats']),
      reservedSeats: List<String>.from(json['reservedSeats']),
      status: TripStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TripStatus.scheduled,
      ),
      additionalInfo: Map<String, dynamic>.from(json['additionalInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route': route.toJson(),
      'vehicle': vehicle.toJson(),
      'driver': driver.toJson(),
      'departureTime': departureTime.toIso8601String(),
      'estimatedArrivalTime': estimatedArrivalTime.toIso8601String(),
      'price': price,
      'availableSeats': availableSeats,
      'reservedSeats': reservedSeats,
      'status': status.toString().split('.').last,
      'additionalInfo': additionalInfo,
    };
  }
}