import '../models/vehicle_model.dart';

class VehiclesData {
  static List<Vehicle> getAllVehicles() {
    return [
      // Buses Económicos
      Vehicle(
        id: 'bus_001',
        plateNumber: 'NAR-001',
        brand: 'Mercedes-Benz',
        model: 'Sprinter',
        year: 2020,
        type: VehicleType.bus,
        vehicleClass: VehicleClass.economica,
        totalSeats: 45,
        seatLayout: _generateBusSeatLayout(45),
        amenities: const {
          'aire_acondicionado': 'Aire Acondicionado',
          'musica': 'Sistema de Música',
          'asientos_reclinables': 'Asientos Reclinables'
        },
        imageUrl: 'assets/images/vehicles/bus_economico.jpg',
      ),
      Vehicle(
        id: 'bus_002',
        plateNumber: 'NAR-002',
        brand: 'Chevrolet',
        model: 'NPR',
        year: 2019,
        type: VehicleType.bus,
        vehicleClass: VehicleClass.economica,
        totalSeats: 40,
        seatLayout: _generateBusSeatLayout(40),
        amenities: const {
          'aire_acondicionado': 'Aire Acondicionado',
          'musica': 'Sistema de Música'
        },
        imageUrl: 'assets/images/vehicles/bus_economico2.jpg',
      ),
      
      // Buses Ejecutivos
      Vehicle(
        id: 'bus_003',
        plateNumber: 'NAR-003',
        brand: 'Mercedes-Benz',
        model: 'OH 1628',
        year: 2021,
        type: VehicleType.bus,
        vehicleClass: VehicleClass.ejecutiva,
        totalSeats: 35,
        seatLayout: _generateBusSeatLayout(35),
        amenities: const {
          'aire_acondicionado': 'Aire Acondicionado',
          'wifi': 'WiFi Gratuito',
          'asientos_reclinables': 'Asientos Reclinables',
          'musica': 'Sistema de Música',
          'cargadores_usb': 'Cargadores USB'
        },
        imageUrl: 'assets/images/vehicles/bus_ejecutivo.jpg',
      ),
      Vehicle(
        id: 'bus_004',
        plateNumber: 'NAR-004',
        brand: 'Volvo',
        model: 'B270F',
        year: 2022,
        type: VehicleType.bus,
        vehicleClass: VehicleClass.ejecutiva,
        totalSeats: 38,
        seatLayout: _generateBusSeatLayout(38),
        amenities: const {
          'aire_acondicionado': 'Aire Acondicionado',
          'wifi': 'WiFi Gratuito',
          'asientos_reclinables': 'Asientos Reclinables',
          'musica': 'Sistema de Música',
          'cargadores_usb': 'Cargadores USB',
          'bano': 'Baño a Bordo'
        },
        imageUrl: 'assets/images/vehicles/bus_ejecutivo2.jpg',
      ),
      
      // Buses Premium
      Vehicle(
        id: 'bus_005',
        plateNumber: 'NAR-005',
        brand: 'Scania',
        model: 'K410',
        year: 2023,
        type: VehicleType.bus,
        vehicleClass: VehicleClass.premium,
        totalSeats: 28,
        seatLayout: _generatePremiumBusSeatLayout(28),
        amenities: const {
          'aire_acondicionado': 'Aire Acondicionado',
          'wifi': 'WiFi Gratuito',
          'asientos_cama': 'Asientos Cama',
          'musica': 'Sistema de Música',
          'cargadores_usb': 'Cargadores USB',
          'bano': 'Baño a Bordo',
          'tv_individual': 'TV Individual',
          'servicio_comida': 'Servicio de Comida'
        },
        imageUrl: 'assets/images/vehicles/bus_premium.jpg',
      ),
      
      // Microbuses
      Vehicle(
        id: 'microbus_001',
        plateNumber: 'NAR-101',
        brand: 'Toyota',
        model: 'Hiace',
        year: 2020,
        type: VehicleType.microbus,
        vehicleClass: VehicleClass.economica,
        totalSeats: 15,
        seatLayout: _generateMicrobusSeatLayout(15),
        amenities: const {
          'aire_acondicionado': 'Aire Acondicionado',
          'musica': 'Sistema de Música'
        },
        imageUrl: 'assets/images/vehicles/microbus_economico.jpg',
      ),
      Vehicle(
        id: 'microbus_002',
        plateNumber: 'NAR-102',
        brand: 'Mercedes-Benz',
        model: 'Sprinter',
        year: 2021,
        type: VehicleType.microbus,
        vehicleClass: VehicleClass.ejecutiva,
        totalSeats: 19,
        seatLayout: _generateMicrobusSeatLayout(19),
        amenities: const {
          'aire_acondicionado': 'Aire Acondicionado',
          'wifi': 'WiFi Gratuito',
          'asientos_reclinables': 'Asientos Reclinables',
          'musica': 'Sistema de Música',
          'cargadores_usb': 'Cargadores USB'
        },
        imageUrl: 'assets/images/vehicles/microbus_ejecutivo.jpg',
      ),
      
      // Vans
      Vehicle(
        id: 'van_001',
        plateNumber: 'NAR-201',
        brand: 'Chevrolet',
        model: 'Express',
        year: 2019,
        type: VehicleType.van,
        vehicleClass: VehicleClass.economica,
        totalSeats: 12,
        seatLayout: _generateVanSeatLayout(12),
        amenities: const {
          'aire_acondicionado': 'Aire Acondicionado',
          'musica': 'Sistema de Música'
        },
        imageUrl: 'assets/images/vehicles/van_economica.jpg',
      ),
      Vehicle(
        id: 'van_002',
        plateNumber: 'NAR-202',
        brand: 'Ford',
        model: 'Transit',
        year: 2021,
        type: VehicleType.van,
        vehicleClass: VehicleClass.ejecutiva,
        totalSeats: 14,
        seatLayout: _generateVanSeatLayout(14),
        amenities: const {
          'aire_acondicionado': 'Aire Acondicionado',
          'wifi': 'WiFi Gratuito',
          'asientos_reclinables': 'Asientos Reclinables',
          'musica': 'Sistema de Música',
          'cargadores_usb': 'Cargadores USB'
        },
        imageUrl: 'assets/images/vehicles/van_ejecutiva.jpg',
      ),
      
      // Carros
      Vehicle(
        id: 'car_001',
        plateNumber: 'NAR-301',
        brand: 'Toyota',
        model: 'Prado',
        year: 2020,
        type: VehicleType.car,
        vehicleClass: VehicleClass.ejecutiva,
        totalSeats: 7,
        seatLayout: _generateCarSeatLayout(7),
        amenities: const {
          'aire_acondicionado': 'Aire Acondicionado',
          'wifi': 'WiFi Gratuito',
          'asientos_cuero': 'Asientos de Cuero',
          'musica': 'Sistema de Música',
          'cargadores_usb': 'Cargadores USB'
        },
        imageUrl: 'assets/images/vehicles/car_ejecutivo.jpg',
      ),
      Vehicle(
        id: 'car_002',
        plateNumber: 'NAR-302',
        brand: 'Chevrolet',
        model: 'Tahoe',
        year: 2022,
        type: VehicleType.car,
        vehicleClass: VehicleClass.premium,
        totalSeats: 8,
        seatLayout: _generateCarSeatLayout(8),
        amenities: const {
          'aire_acondicionado': 'Aire Acondicionado',
          'wifi': 'WiFi Gratuito',
          'asientos_cuero': 'Asientos de Cuero',
          'musica': 'Sistema de Música',
          'cargadores_usb': 'Cargadores USB',
          'tv': 'Televisión',
          'minibar': 'Minibar'
        },
        imageUrl: 'assets/images/vehicles/car_premium.jpg',
      ),
    ];
  }

  /// Genera layout de asientos para buses (2-2 configuración)
  static List<List<String?>> _generateBusSeatLayout(int totalSeats) {
    final layout = <List<String?>>[];
    int seatNumber = 1;
    
    for (int row = 0; row < (totalSeats / 4).ceil(); row++) {
      final rowSeats = <String?>[];
      
      // Lado izquierdo (2 asientos)
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      
      // Pasillo
      rowSeats.add(null);
      
      // Lado derecho (2 asientos)
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      
      layout.add(rowSeats);
    }
    
    return layout;
  }

  /// Genera layout de asientos para buses premium (2-1 configuración)
  static List<List<String?>> _generatePremiumBusSeatLayout(int totalSeats) {
    final layout = <List<String?>>[];
    int seatNumber = 1;
    
    for (int row = 0; row < (totalSeats / 3).ceil(); row++) {
      final rowSeats = <String?>[];
      
      // Lado izquierdo (2 asientos)
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      
      // Pasillo
      rowSeats.add(null);
      
      // Lado derecho (1 asiento)
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      
      layout.add(rowSeats);
    }
    
    return layout;
  }

  /// Genera layout de asientos para microbuses (2-1 configuración)
  static List<List<String?>> _generateMicrobusSeatLayout(int totalSeats) {
    final layout = <List<String?>>[];
    int seatNumber = 1;
    
    for (int row = 0; row < (totalSeats / 3).ceil(); row++) {
      final rowSeats = <String?>[];
      
      // Lado izquierdo (2 asientos)
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      
      // Pasillo
      rowSeats.add(null);
      
      // Lado derecho (1 asiento)
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      
      layout.add(rowSeats);
    }
    
    return layout;
  }

  /// Genera layout de asientos para vans (2-1 configuración)
  static List<List<String?>> _generateVanSeatLayout(int totalSeats) {
    final layout = <List<String?>>[];
    int seatNumber = 1;
    
    for (int row = 0; row < (totalSeats / 3).ceil(); row++) {
      final rowSeats = <String?>[];
      
      // Lado izquierdo (2 asientos)
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      
      // Pasillo
      rowSeats.add(null);
      
      // Lado derecho (1 asiento)
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      
      layout.add(rowSeats);
    }
    
    return layout;
  }

  /// Genera layout de asientos para carros (configuración variable)
  static List<List<String?>> _generateCarSeatLayout(int totalSeats) {
    final layout = <List<String?>>[];
    int seatNumber = 1;
    
    // Primera fila: conductor + copiloto
    layout.add(['C', '1']);
    seatNumber = 2;
    
    // Filas restantes: 2-3 configuración dependiendo del total
    for (int row = 1; row < (totalSeats / 2).ceil(); row++) {
      final rowSeats = <String?>[];
      
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      if (seatNumber <= totalSeats) {
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      if (totalSeats > 6 && seatNumber <= totalSeats) {
        rowSeats.add(null); // Pasillo
        rowSeats.add(seatNumber.toString());
        seatNumber++;
      }
      
      layout.add(rowSeats);
    }
    
    return layout;
  }

  /// Obtiene vehículos por tipo
  static List<Vehicle> getVehiclesByType(VehicleType type) {
    return getAllVehicles().where((vehicle) => vehicle.type == type).toList();
  }

  /// Obtiene vehículos por clase
  static List<Vehicle> getVehiclesByClass(VehicleClass vehicleClass) {
    return getAllVehicles().where((vehicle) => vehicle.vehicleClass == vehicleClass).toList();
  }

  /// Obtiene un vehículo por ID
  static Vehicle? getVehicleById(String id) {
    try {
      return getAllVehicles().firstWhere((vehicle) => vehicle.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene vehículos disponibles para una ruta específica
  static List<Vehicle> getAvailableVehiclesForRoute(String routeId) {
    // En una implementación real, esto consultaría la base de datos
    // Por ahora, devolvemos todos los vehículos
    return getAllVehicles();
  }
}