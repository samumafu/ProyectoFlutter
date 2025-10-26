class Route {
  final String id;
  final String origin;
  final String destination;
  final double distance;
  final String estimatedDuration;
  final List<String> intermediateStops;
  final bool isActive;

  const Route({
    required this.id,
    required this.origin,
    required this.destination,
    required this.distance,
    required this.estimatedDuration,
    required this.intermediateStops,
    required this.isActive,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      distance: (json['distance'] as num).toDouble(),
      estimatedDuration: json['estimated_duration'] as String,
      intermediateStops: List<String>.from(json['intermediate_stops'] ?? []),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'distance': distance,
      'estimated_duration': estimatedDuration,
      'intermediate_stops': intermediateStops,
      'is_active': isActive,
    };
  }
}

class City {
  final String id;
  final String name;
  final String department;
  final double latitude;
  final double longitude;
  final bool isActive;

  const City({
    required this.id,
    required this.name,
    required this.department,
    required this.latitude,
    required this.longitude,
    required this.isActive,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      name: json['name'] as String,
      department: json['department'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
    };
  }

  String get fullName => '$name, $department';
}