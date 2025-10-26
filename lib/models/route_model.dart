import 'package:latlong2/latlong.dart';

class TransportRoute {
  final String id;
  final String origin;
  final String destination;
  final LatLng originCoordinates;
  final LatLng destinationCoordinates;
  final double distance; // en kilómetros
  final int estimatedDuration; // en minutos
  final double basePrice;
  final List<String> intermediateStops;

  const TransportRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.originCoordinates,
    required this.destinationCoordinates,
    required this.distance,
    required this.estimatedDuration,
    required this.basePrice,
    this.intermediateStops = const [],
  });

  factory TransportRoute.fromJson(Map<String, dynamic> json) {
    return TransportRoute(
      id: json['id'],
      origin: json['origin'],
      destination: json['destination'],
      originCoordinates: LatLng(
        json['originCoordinates']['lat'],
        json['originCoordinates']['lng'],
      ),
      destinationCoordinates: LatLng(
        json['destinationCoordinates']['lat'],
        json['destinationCoordinates']['lng'],
      ),
      distance: json['distance'].toDouble(),
      estimatedDuration: json['estimatedDuration'],
      basePrice: json['basePrice'].toDouble(),
      intermediateStops: List<String>.from(json['intermediateStops'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'originCoordinates': {
        'lat': originCoordinates.latitude,
        'lng': originCoordinates.longitude,
      },
      'destinationCoordinates': {
        'lat': destinationCoordinates.latitude,
        'lng': destinationCoordinates.longitude,
      },
      'distance': distance,
      'estimatedDuration': estimatedDuration,
      'basePrice': basePrice,
      'intermediateStops': intermediateStops,
    };
  }
}