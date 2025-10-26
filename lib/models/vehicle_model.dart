enum VehicleType {
  bus,
  microbus,
  van,
  car,
}

enum VehicleClass {
  economica,
  ejecutiva,
  premium,
}

class Vehicle {
  final String id;
  final String plateNumber;
  final VehicleType type;
  final VehicleClass vehicleClass;
  final String brand;
  final String model;
  final int year;
  final int totalSeats;
  final List<List<String?>> seatLayout; // null = pasillo, string = número de asiento
  final Map<String, String> amenities; // wifi, ac, tv, etc.
  final String imageUrl;

  const Vehicle({
    required this.id,
    required this.plateNumber,
    required this.type,
    required this.vehicleClass,
    required this.brand,
    required this.model,
    required this.year,
    required this.totalSeats,
    required this.seatLayout,
    this.amenities = const {},
    this.imageUrl = '',
  });

  String get typeDisplayName {
    switch (type) {
      case VehicleType.bus:
        return 'Bus';
      case VehicleType.microbus:
        return 'Microbus';
      case VehicleType.van:
        return 'Van';
      case VehicleType.car:
        return 'Automóvil';
    }
  }

  String get classDisplayName {
    switch (vehicleClass) {
      case VehicleClass.economica:
        return 'Económica';
      case VehicleClass.ejecutiva:
        return 'Ejecutiva';
      case VehicleClass.premium:
        return 'Premium';
    }
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      plateNumber: json['plateNumber'],
      type: VehicleType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      vehicleClass: VehicleClass.values.firstWhere(
        (e) => e.toString().split('.').last == json['vehicleClass'],
      ),
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      totalSeats: json['totalSeats'],
      seatLayout: (json['seatLayout'] as List)
          .map((row) => (row as List).cast<String?>())
          .toList(),
      amenities: Map<String, String>.from(json['amenities'] ?? {}),
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'type': type.toString().split('.').last,
      'vehicleClass': vehicleClass.toString().split('.').last,
      'brand': brand,
      'model': model,
      'year': year,
      'totalSeats': totalSeats,
      'seatLayout': seatLayout,
      'amenities': amenities,
      'imageUrl': imageUrl,
    };
  }
}