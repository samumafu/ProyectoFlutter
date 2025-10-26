import 'package:latlong2/latlong.dart';

class Booking {
  final String id;
  final String origin;
  final String destination;
  final DateTime departureDate;
  final String departureTime;
  final List<String> selectedSeats;
  final double totalPrice;
  final String pickupPointName;
  final String pickupPointDescription;
  final LatLng pickupPointCoordinates;
  final DateTime bookingDate;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.departureTime,
    required this.selectedSeats,
    required this.totalPrice,
    required this.pickupPointName,
    required this.pickupPointDescription,
    required this.pickupPointCoordinates,
    required this.bookingDate,
    this.status = BookingStatus.confirmed,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'departureDate': departureDate.toIso8601String(),
      'departureTime': departureTime,
      'selectedSeats': selectedSeats,
      'totalPrice': totalPrice,
      'pickupPointName': pickupPointName,
      'pickupPointDescription': pickupPointDescription,
      'pickupPointLatitude': pickupPointCoordinates.latitude,
      'pickupPointLongitude': pickupPointCoordinates.longitude,
      'bookingDate': bookingDate.toIso8601String(),
      'status': status.toString(),
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      origin: json['origin'],
      destination: json['destination'],
      departureDate: DateTime.parse(json['departureDate']),
      departureTime: json['departureTime'],
      selectedSeats: List<String>.from(json['selectedSeats']),
      totalPrice: json['totalPrice'].toDouble(),
      pickupPointName: json['pickupPointName'],
      pickupPointDescription: json['pickupPointDescription'],
      pickupPointCoordinates: LatLng(
        json['pickupPointLatitude'],
        json['pickupPointLongitude'],
      ),
      bookingDate: DateTime.parse(json['bookingDate']),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  String get formattedDepartureDate {
    return '${departureDate.day}/${departureDate.month}/${departureDate.year}';
  }

  String get seatsText {
    if (selectedSeats.length == 1) {
      return 'Asiento ${selectedSeats.first}';
    } else {
      return 'Asientos ${selectedSeats.join(', ')}';
    }
  }
}

enum BookingStatus {
  confirmed,
  cancelled,
  completed,
}