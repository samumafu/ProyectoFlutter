import '../models/driver_model.dart';

class DriversData {
  static List<Driver> getAllDrivers() {
    return [
      Driver(
        id: 'driver_001',
        name: 'Carlos',
        lastName: 'Rodríguez',
        phoneNumber: '+57 312 456 7890',
        emergencyPhone: '+57 312 456 7891',
        licenseNumber: 'C2-123456789',
        licenseExpiry: DateTime(2025, 12, 31),
        rating: 4.8,
        totalTrips: 1250,
        photoUrl: 'assets/images/drivers/carlos_rodriguez.jpg',
        yearsExperience: 8,
        languages: ['Español', 'Inglés'],
      ),
      Driver(
        id: 'driver_002',
        name: 'María',
        lastName: 'González',
        phoneNumber: '+57 315 789 1234',
        emergencyPhone: '+57 315 789 1235',
        licenseNumber: 'C2-987654321',
        licenseExpiry: DateTime(2026, 6, 15),
        rating: 4.9,
        totalTrips: 980,
        photoUrl: 'assets/images/drivers/maria_gonzalez.jpg',
        yearsExperience: 6,
        languages: ['Español'],
      ),
      Driver(
        id: 'driver_003',
        name: 'José',
        lastName: 'Martínez',
        phoneNumber: '+57 318 234 5678',
        emergencyPhone: '+57 318 234 5679',
        licenseNumber: 'C2-456789123',
        licenseExpiry: DateTime(2025, 9, 20),
        rating: 4.7,
        totalTrips: 1450,
        photoUrl: 'assets/images/drivers/jose_martinez.jpg',
        yearsExperience: 12,
        languages: ['Español', 'Quechua'],
      ),
      Driver(
        id: 'driver_004',
        name: 'Ana',
        lastName: 'López',
        phoneNumber: '+57 320 567 8901',
        emergencyPhone: '+57 320 567 8902',
        licenseNumber: 'C2-789123456',
        licenseExpiry: DateTime(2026, 3, 10),
        rating: 4.6,
        totalTrips: 750,
        photoUrl: 'assets/images/drivers/ana_lopez.jpg',
        yearsExperience: 5,
        languages: ['Español'],
      ),
      Driver(
        id: 'driver_005',
        name: 'Luis',
        lastName: 'Hernández',
        phoneNumber: '+57 314 890 1234',
        emergencyPhone: '+57 314 890 1235',
        licenseNumber: 'C2-234567890',
        licenseExpiry: DateTime(2025, 11, 5),
        rating: 4.9,
        totalTrips: 1680,
        photoUrl: 'assets/images/drivers/luis_hernandez.jpg',
        yearsExperience: 15,
        languages: ['Español', 'Inglés'],
      ),
      Driver(
        id: 'driver_006',
        name: 'Patricia',
        lastName: 'Ramírez',
        phoneNumber: '+57 317 345 6789',
        emergencyPhone: '+57 317 345 6790',
        licenseNumber: 'C2-567890123',
        licenseExpiry: DateTime(2026, 8, 25),
        rating: 4.8,
        totalTrips: 920,
        photoUrl: 'assets/images/drivers/patricia_ramirez.jpg',
        yearsExperience: 7,
        languages: ['Español'],
      ),
      Driver(
        id: 'driver_007',
        name: 'Roberto',
        lastName: 'Silva',
        phoneNumber: '+57 319 678 9012',
        emergencyPhone: '+57 319 678 9013',
        licenseNumber: 'C2-890123457',
        licenseExpiry: DateTime(2025, 7, 18),
        rating: 4.5,
        totalTrips: 1100,
        photoUrl: 'assets/images/drivers/roberto_silva.jpg',
        yearsExperience: 9,
        languages: ['Español'],
      ),
      Driver(
        id: 'driver_008',
        name: 'Carmen',
        lastName: 'Torres',
        phoneNumber: '+57 316 901 2345',
        emergencyPhone: '+57 316 901 2346',
        licenseNumber: 'C2-345678901',
        licenseExpiry: DateTime(2026, 4, 12),
        rating: 4.7,
        totalTrips: 850,
        photoUrl: 'assets/images/drivers/carmen_torres.jpg',
        yearsExperience: 6,
        languages: ['Español', 'Inglés'],
      ),
      Driver(
        id: 'driver_009',
        name: 'Miguel',
        lastName: 'Vargas',
        phoneNumber: '+57 313 012 3456',
        emergencyPhone: '+57 313 012 3457',
        licenseNumber: 'C2-678901234',
        licenseExpiry: DateTime(2025, 10, 30),
        rating: 4.8,
        totalTrips: 1320,
        photoUrl: 'assets/images/drivers/miguel_vargas.jpg',
        yearsExperience: 11,
        languages: ['Español'],
      ),
      Driver(
        id: 'driver_010',
        name: 'Sandra',
        lastName: 'Morales',
        phoneNumber: '+57 321 123 4567',
        emergencyPhone: '+57 321 123 4568',
        licenseNumber: 'C2-901234568',
        licenseExpiry: DateTime(2026, 1, 22),
        rating: 4.9,
        totalTrips: 1050,
        photoUrl: 'assets/images/drivers/sandra_morales.jpg',
        yearsExperience: 8,
        languages: ['Español', 'Portugués'],
      ),
      Driver(
        id: 'driver_011',
        name: 'Fernando',
        lastName: 'Jiménez',
        phoneNumber: '+57 322 234 5678',
        emergencyPhone: '+57 322 234 5679',
        licenseNumber: 'C2-012345679',
        licenseExpiry: DateTime(2025, 5, 14),
        rating: 4.6,
        totalTrips: 1180,
        photoUrl: 'assets/images/drivers/fernando_jimenez.jpg',
        yearsExperience: 10,
        languages: ['Español'],
      ),
      Driver(
        id: 'driver_012',
        name: 'Gloria',
        lastName: 'Castillo',
        phoneNumber: '+57 323 345 6789',
        emergencyPhone: '+57 323 345 6790',
        licenseNumber: 'C2-123456780',
        licenseExpiry: DateTime(2026, 2, 8),
        rating: 4.7,
        totalTrips: 890,
        photoUrl: 'assets/images/drivers/gloria_castillo.jpg',
        yearsExperience: 7,
        languages: ['Español'],
      ),
      Driver(
        id: 'driver_013',
        name: 'Andrés',
        lastName: 'Peña',
        phoneNumber: '+57 324 456 7890',
        emergencyPhone: '+57 324 456 7891',
        licenseNumber: 'C2-234567891',
        licenseExpiry: DateTime(2025, 8, 3),
        rating: 4.8,
        totalTrips: 1400,
        photoUrl: 'assets/images/drivers/andres_pena.jpg',
        yearsExperience: 13,
        languages: ['Español', 'Inglés'],
      ),
      Driver(
        id: 'driver_014',
        name: 'Beatriz',
        lastName: 'Ruiz',
        phoneNumber: '+57 325 567 8901',
        emergencyPhone: '+57 325 567 8902',
        licenseNumber: 'C2-345678902',
        licenseExpiry: DateTime(2026, 9, 17),
        rating: 4.5,
        totalTrips: 720,
        photoUrl: 'assets/images/drivers/beatriz_ruiz.jpg',
        yearsExperience: 4,
        languages: ['Español'],
      ),
      Driver(
        id: 'driver_015',
        name: 'Diego',
        lastName: 'Mendoza',
        phoneNumber: '+57 326 678 9012',
        emergencyPhone: '+57 326 678 9013',
        licenseNumber: 'C2-456789013',
        licenseExpiry: DateTime(2025, 12, 1),
        rating: 4.9,
        totalTrips: 1560,
        photoUrl: 'assets/images/drivers/diego_mendoza.jpg',
        yearsExperience: 14,
        languages: ['Español', 'Inglés', 'Francés'],
      ),
    ];
  }

  /// Obtiene un conductor por ID
  static Driver? getDriverById(String id) {
    try {
      return getAllDrivers().firstWhere((driver) => driver.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene conductores por calificación mínima
  static List<Driver> getDriversByMinRating(double minRating) {
    return getAllDrivers()
        .where((driver) => driver.rating >= minRating)
        .toList();
  }

  /// Obtiene conductores con licencia vigente
  static List<Driver> getDriversWithValidLicense() {
    final now = DateTime.now();
    return getAllDrivers()
        .where((driver) => driver.licenseExpiry.isAfter(now))
        .toList();
  }

  /// Obtiene conductores por años de experiencia mínima
  static List<Driver> getDriversByMinExperience(int minYears) {
    return getAllDrivers()
        .where((driver) => driver.yearsExperience >= minYears)
        .toList();
  }

  /// Obtiene conductores que hablan un idioma específico
  static List<Driver> getDriversByLanguage(String language) {
    return getAllDrivers()
        .where((driver) => driver.languages.contains(language))
        .toList();
  }

  /// Obtiene conductores disponibles (simulación)
  static List<Driver> getAvailableDrivers() {
    // En una implementación real, esto consultaría la disponibilidad en tiempo real
    // Por ahora, devolvemos conductores con licencia vigente y buena calificación
    return getDriversWithValidLicense()
        .where((driver) => driver.rating >= 4.5)
        .toList();
  }

  /// Obtiene los mejores conductores (top rated)
  static List<Driver> getTopRatedDrivers({int limit = 10}) {
    final drivers = getAllDrivers();
    drivers.sort((a, b) => b.rating.compareTo(a.rating));
    return drivers.take(limit).toList();
  }

  /// Obtiene conductores más experimentados
  static List<Driver> getMostExperiencedDrivers({int limit = 10}) {
    final drivers = getAllDrivers();
    drivers.sort((a, b) => b.yearsExperience.compareTo(a.yearsExperience));
    return drivers.take(limit).toList();
  }
}