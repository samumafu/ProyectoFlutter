import '../models/schedule_model.dart';
import '../models/route_model.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';
import 'routes_data.dart';
import 'vehicles_data.dart';
import 'drivers_data.dart';

class SchedulesData {
  static List<Schedule> generateSchedulesForDate(DateTime date) {
    List<Schedule> schedules = [];
    final routes = RoutesData.getAllRoutesToPasto();
    final vehicles = VehiclesData.getAllVehicles();
    final drivers = DriversData.getAllDrivers();
    
    // Horarios típicos del día (6:00 AM a 10:00 PM)
    final timeSlots = [
      TimeOfDay(hour: 6, minute: 0),   // 6:00 AM
      TimeOfDay(hour: 7, minute: 30),  // 7:30 AM
      TimeOfDay(hour: 9, minute: 0),   // 9:00 AM
      TimeOfDay(hour: 10, minute: 30), // 10:30 AM
      TimeOfDay(hour: 12, minute: 0),  // 12:00 PM
      TimeOfDay(hour: 1, minute: 30),  // 1:30 PM
      TimeOfDay(hour: 3, minute: 0),   // 3:00 PM
      TimeOfDay(hour: 4, minute: 30),  // 4:30 PM
      TimeOfDay(hour: 6, minute: 0),   // 6:00 PM
      TimeOfDay(hour: 7, minute: 30),  // 7:30 PM
      TimeOfDay(hour: 9, minute: 0),   // 9:00 PM
      TimeOfDay(hour: 10, minute: 30), // 10:30 PM
    ];

    int scheduleId = 1;
    
    for (var route in routes) {
      // Generar entre 3-6 horarios por ruta por día
      final numSchedules = 3 + (route.id.hashCode % 4);
      final selectedTimeSlots = timeSlots.take(numSchedules).toList();
      
      for (int i = 0; i < selectedTimeSlots.length; i++) {
        final timeSlot = selectedTimeSlots[i];
        final vehicle = vehicles[scheduleId % vehicles.length];
        final driver = drivers[scheduleId % drivers.length];
        
        final departureDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          timeSlot.hour,
          timeSlot.minute,
        );
        
        final estimatedArrivalDateTime = departureDateTime.add(
          Duration(minutes: route.estimatedDuration),
        );
        
        final price = _calculatePrice(route, vehicle, timeSlot);
        
        // Generar asientos disponibles y reservados
        final totalSeats = vehicle.totalSeats;
        final reservedCount = scheduleId % 5; // Simular reservas (0-4 asientos)
        final availableSeats = <String>[];
        final reservedSeats = <String>[];
        
        for (int seatNum = 1; seatNum <= totalSeats; seatNum++) {
          final seatId = seatNum.toString().padLeft(2, '0');
          if (seatNum <= reservedCount) {
            reservedSeats.add(seatId);
          } else {
            availableSeats.add(seatId);
          }
        }
        
        schedules.add(Schedule(
          id: 'schedule_${scheduleId.toString().padLeft(3, '0')}',
          route: route,
          vehicle: vehicle,
          driver: driver,
          departureTime: departureDateTime,
          estimatedArrivalTime: estimatedArrivalDateTime,
          price: price,
          availableSeats: availableSeats,
          reservedSeats: reservedSeats,
          status: TripStatus.scheduled,
          additionalInfo: _generateAdditionalInfo(route, vehicle),
        ));
        
        scheduleId++;
      }
    }
    
    return schedules;
  }

  static List<Schedule> generateSchedulesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    List<Schedule> allSchedules = [];
    
    for (DateTime date = startDate;
         date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
         date = date.add(Duration(days: 1))) {
      allSchedules.addAll(generateSchedulesForDate(date));
    }
    
    return allSchedules;
  }

  static double _calculatePrice(
    TransportRoute route,
    Vehicle vehicle,
    TimeOfDay timeSlot,
  ) {
    double basePrice = route.basePrice;
    
    // Ajuste por tipo de vehículo
    switch (vehicle.vehicleClass) {
      case VehicleClass.economica:
        basePrice *= 1.0;
        break;
      case VehicleClass.ejecutiva:
        basePrice *= 1.3;
        break;
      case VehicleClass.premium:
        basePrice *= 1.6;
        break;
    }
    
    // Ajuste por horario (horas pico más caras)
    if ((timeSlot.hour >= 6 && timeSlot.hour <= 9) ||
        (timeSlot.hour >= 17 && timeSlot.hour <= 20)) {
      basePrice *= 1.2; // 20% más caro en horas pico
    }
    
    return basePrice;
  }

  static Map<String, String> _generateAdditionalInfo(
    TransportRoute route,
    Vehicle vehicle,
  ) {
    Map<String, String> info = {};
    
    info['Paradas intermedias'] = route.intermediateStops.length.toString();
    info['Tiempo estimado'] = '${route.estimatedDuration} minutos';
    info['Distancia'] = '${route.distance.toStringAsFixed(1)} km';
    
    if (vehicle.amenities.isNotEmpty) {
      info['Comodidades'] = vehicle.amenities.keys.join(', ');
    }
    
    return info;
  }

  static List<Schedule> searchSchedules({
    required String origin,
    required String destination,
    required DateTime date,
    VehicleType? vehicleType,
    VehicleClass? vehicleClass,
    double? maxPrice,
    int? minAvailableSeats,
  }) {
    final schedules = generateSchedulesForDate(date);
    
    return schedules.where((schedule) {
      // Filtrar por origen y destino
      if (schedule.route.origin != origin || 
          schedule.route.destination != destination) {
        return false;
      }
      
      // Filtrar por tipo de vehículo
      if (vehicleType != null && schedule.vehicle.type != vehicleType) {
        return false;
      }
      
      // Filtrar por clase de vehículo
      if (vehicleClass != null && schedule.vehicle.vehicleClass != vehicleClass) {
        return false;
      }
      
      // Filtrar por precio máximo
      if (maxPrice != null && schedule.price > maxPrice) {
        return false;
      }
      
      // Filtrar por asientos disponibles mínimos
      if (minAvailableSeats != null && 
          schedule.availableSeats.length < minAvailableSeats) {
        return false;
      }
      
      return true;
    }).toList();
  }

  static List<Schedule> getSchedulesByRoute(String routeId, DateTime date) {
    final schedules = generateSchedulesForDate(date);
    return schedules.where((s) => s.route.id == routeId).toList();
  }

  static List<Schedule> getSchedulesByDriver(String driverId, DateTime date) {
    final schedules = generateSchedulesForDate(date);
    return schedules.where((s) => s.driver.id == driverId).toList();
  }

  static List<Schedule> getSchedulesByVehicle(String vehicleId, DateTime date) {
    final schedules = generateSchedulesForDate(date);
    return schedules.where((s) => s.vehicle.id == vehicleId).toList();
  }

  static Schedule? getScheduleById(String scheduleId) {
    // Para este ejemplo, generamos horarios para hoy
    final schedules = generateSchedulesForDate(DateTime.now());
    try {
      return schedules.firstWhere((s) => s.id == scheduleId);
    } catch (e) {
      return null;
    }
  }
}

class TimeOfDay {
  final int hour;
  final int minute;
  
  const TimeOfDay({required this.hour, required this.minute});
}