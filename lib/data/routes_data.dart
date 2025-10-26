import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import 'constants/narino_destinations.dart';

class RoutesData {
  // Coordenadas de municipios principales
  static const Map<String, LatLng> mainCityCoordinates = {
    'Pasto': LatLng(1.2136, -77.2811),
    'Ipiales': LatLng(0.8317, -77.6439),
    'Tumaco': LatLng(1.8014, -78.7642),
    'Túquerres': LatLng(1.0864, -77.6175),
    'Tangua': LatLng(1.0333, -77.7500),
    'Tenagás': LatLng(1.0167, -77.7167), // Coordenadas aproximadas
  };
  
  // Municipios principales con múltiples horarios
  static const List<String> mainCities = [
    'Pasto', 'Ipiales', 'Túquerres', 'Tumaco', 'Tangua', 'Tenagás'
  ];
  
  static List<TransportRoute> getAllRoutes() {
    final List<TransportRoute> routes = [];
    
    // 1. Rutas entre ciudades principales (bidireccionales con múltiples horarios)
    routes.addAll(_generateMainCityRoutes());
    
    // 2. Rutas desde ciudades principales hacia otros municipios
    routes.addAll(_generateRoutesToOtherMunicipalities());
    
    // 3. Rutas desde otros municipios hacia ciudades principales
    routes.addAll(_generateRoutesFromOtherMunicipalities());
    
    return routes;
  }
  
  static List<TransportRoute> _generateMainCityRoutes() {
    final List<TransportRoute> routes = [];
    
    for (int i = 0; i < mainCities.length; i++) {
      for (int j = 0; j < mainCities.length; j++) {
        if (i != j) {
          final origin = mainCities[i];
          final destination = mainCities[j];
          final originCoords = mainCityCoordinates[origin]!;
          final destinationCoords = mainCityCoordinates[destination]!;
          
          final route = TransportRoute(
            id: 'main_${origin.toLowerCase().replaceAll(' ', '_')}_to_${destination.toLowerCase().replaceAll(' ', '_')}',
            origin: origin,
            destination: destination,
            originCoordinates: originCoords,
            destinationCoordinates: destinationCoords,
            distance: _calculateDistance(originCoords, destinationCoords),
            estimatedDuration: _calculateDuration(originCoords, destinationCoords),
            basePrice: _calculatePrice(originCoords, destinationCoords),
            intermediateStops: getIntermediateStops(origin, destination),
          );
          
          routes.add(route);
        }
      }
    }
    
    return routes;
  }
  
  static List<TransportRoute> _generateRoutesToOtherMunicipalities() {
    final List<TransportRoute> routes = [];
    
    for (final mainCity in mainCities) {
      for (final municipality in NarinoDestinations.municipalities) {
        if (!mainCities.contains(municipality)) {
          final originCoords = mainCityCoordinates[mainCity];
          final destinationCoords = getDestinationCoordinates(municipality);
          
          if (originCoords != null && destinationCoords != null) {
            final route = TransportRoute(
              id: 'route_${mainCity.toLowerCase().replaceAll(' ', '_')}_to_${municipality.toLowerCase().replaceAll(' ', '_')}',
              origin: mainCity,
              destination: municipality,
              originCoordinates: originCoords,
              destinationCoordinates: destinationCoords,
              distance: _calculateDistance(originCoords, destinationCoords),
              estimatedDuration: _calculateDuration(originCoords, destinationCoords),
              basePrice: _calculatePrice(originCoords, destinationCoords),
              intermediateStops: getIntermediateStops(mainCity, municipality),
            );
            
            routes.add(route);
          }
        }
      }
    }
    
    return routes;
  }
  
  static List<TransportRoute> _generateRoutesFromOtherMunicipalities() {
    final List<TransportRoute> routes = [];
    
    for (final municipality in NarinoDestinations.municipalities) {
      if (!mainCities.contains(municipality)) {
        for (final mainCity in mainCities) {
          final originCoords = getDestinationCoordinates(municipality);
          final destinationCoords = mainCityCoordinates[mainCity];
          
          if (originCoords != null && destinationCoords != null) {
            final route = TransportRoute(
              id: 'route_${municipality.toLowerCase().replaceAll(' ', '_')}_to_${mainCity.toLowerCase().replaceAll(' ', '_')}',
              origin: municipality,
              destination: mainCity,
              originCoordinates: originCoords,
              destinationCoordinates: destinationCoords,
              distance: _calculateDistance(originCoords, destinationCoords),
              estimatedDuration: _calculateDuration(originCoords, destinationCoords),
              basePrice: _calculatePrice(originCoords, destinationCoords),
              intermediateStops: getIntermediateStops(municipality, mainCity),
            );
            
            routes.add(route);
          }
        }
      }
    }
    
    return routes;
  }

  static double _calculateDistance(LatLng origin, LatLng destination) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, origin, destination);
  }
  
  static int _calculateDuration(LatLng origin, LatLng destination) {
    final distanceKm = _calculateDistance(origin, destination);
    // Estimación: 50 km/h promedio en carreteras de Nariño
    return (distanceKm / 50 * 60).round();
  }
  
  static double _calculatePrice(LatLng origin, LatLng destination) {
    final distanceKm = _calculateDistance(origin, destination);
    // Precio base: $2000 COP por km + tarifa base de $15000
    return 15000 + (distanceKm * 2000);
  }
  
  static List<String> getIntermediateStops(String origin, String destination) {
    // Paradas intermedias basadas en rutas geográficas reales
    final Map<String, Map<String, List<String>>> routeStops = {
      'Pasto': {
        'Ipiales': ['Tangua', 'Funes', 'Guachucal'],
        'Túquerres': ['Tangua', 'Funes'],
        'Tumaco': ['Chachagüí', 'El Tambo', 'Ricaurte', 'Barbacoas'],
        'Tangua': [],
        'Tenagás': ['Tangua'],
      },
      'Ipiales': {
        'Pasto': ['Guachucal', 'Funes', 'Tangua'],
        'Túquerres': ['Guachucal'],
        'Tumaco': ['Pasto', 'Chachagüí', 'El Tambo', 'Ricaurte', 'Barbacoas'],
        'Tangua': ['Guachucal', 'Funes'],
        'Tenagás': ['Guachucal', 'Funes', 'Tangua'],
      },
      'Túquerres': {
        'Pasto': ['Funes', 'Tangua'],
        'Ipiales': ['Guachucal'],
        'Tumaco': ['Pasto', 'Chachagüí', 'El Tambo', 'Ricaurte', 'Barbacoas'],
        'Tangua': ['Funes'],
        'Tenagás': ['Funes', 'Tangua'],
      },
      'Tumaco': {
        'Pasto': ['Barbacoas', 'Ricaurte', 'El Tambo', 'Chachagüí'],
        'Ipiales': ['Barbacoas', 'Ricaurte', 'El Tambo', 'Chachagüí', 'Pasto'],
        'Túquerres': ['Barbacoas', 'Ricaurte', 'El Tambo', 'Chachagüí', 'Pasto'],
        'Tangua': ['Barbacoas', 'Ricaurte', 'El Tambo', 'Chachagüí', 'Pasto'],
        'Tenagás': ['Barbacoas', 'Ricaurte', 'El Tambo', 'Chachagüí', 'Pasto'],
      },
      'Tangua': {
        'Pasto': [],
        'Ipiales': ['Funes', 'Guachucal'],
        'Túquerres': ['Funes'],
        'Tumaco': ['Pasto', 'Chachagüí', 'El Tambo', 'Ricaurte', 'Barbacoas'],
        'Tenagás': [],
      },
      'Tenagás': {
        'Pasto': ['Tangua'],
        'Ipiales': ['Tangua', 'Funes', 'Guachucal'],
        'Túquerres': ['Tangua', 'Funes'],
        'Tumaco': ['Tangua', 'Pasto', 'Chachagüí', 'El Tambo', 'Ricaurte', 'Barbacoas'],
        'Tangua': [],
      },
    };
    
    return routeStops[origin]?[destination] ?? [];
  }
  
  static TransportRoute? getRouteById(String routeId) {
    try {
      return getAllRoutes().firstWhere((route) => route.id == routeId);
    } catch (e) {
      return null;
    }
  }
  
  static List<TransportRoute> getRoutesByOrigin(String origin) {
    return getAllRoutes()
        .where((route) => route.origin.toLowerCase() == origin.toLowerCase())
        .toList();
  }
  
  static List<TransportRoute> searchRoutes(String origin, String destination) {
    return getAllRoutes()
        .where((route) => 
            route.origin.toLowerCase().contains(origin.toLowerCase()) &&
            route.destination.toLowerCase().contains(destination.toLowerCase()))
        .toList();
  }
  
  static LatLng? getDestinationCoordinates(String destination) {
    // Coordenadas aproximadas de municipios de Nariño
    final coordinates = {
      'Pasto': const LatLng(1.2136, -77.2811),
      'Ipiales': const LatLng(0.8317, -77.6439),
      'Tumaco': const LatLng(1.8014, -78.7642),
      'Túquerres': const LatLng(1.0864, -77.6175),
      'Barbacoas': const LatLng(1.6667, -78.1500),
      'La Unión': const LatLng(1.6000, -77.1333),
      'Samaniego': const LatLng(1.3333, -77.5833),
      'Sandoná': const LatLng(1.2833, -77.4667),
      'Consacá': const LatLng(1.2167, -77.5167),
      'Yacuanquer': const LatLng(1.1333, -77.4167),
      'Tangua': const LatLng(1.0333, -77.7500),
      'Tenagás': const LatLng(1.0167, -77.7167),
      'Funes': const LatLng(1.0167, -77.7167),
      'Guachucal': const LatLng(0.9833, -77.7667),
      'Cumbal': const LatLng(0.9167, -77.8000),
      'Ricaurte': const LatLng(1.2167, -78.1833),
      'Aldana': const LatLng(0.8500, -77.6833),
      'Potosí': const LatLng(0.8167, -77.6167),
      'Gualmatán': const LatLng(0.9167, -77.6500),
      'Contadero': const LatLng(0.7833, -77.6833),
      'Córdoba': const LatLng(0.7500, -77.7167),
      'Sapuyes': const LatLng(1.0500, -77.6833),
      'Iles': const LatLng(1.1167, -77.6500),
      'Pupiales': const LatLng(0.8833, -77.6333),
      'Cuaspud': const LatLng(0.7167, -77.7500),
      'Mallama': const LatLng(1.1500, -77.9167),
      'Providencia': const LatLng(1.1833, -77.9500),
      'Leiva': const LatLng(1.8833, -77.9167),
      'Policarpa': const LatLng(1.8500, -77.8833),
      'Cumbitara': const LatLng(1.7167, -78.0833),
      'Los Andes': const LatLng(1.6333, -77.6833),
      'La Cruz': const LatLng(1.5833, -77.1167),
      'Belén': const LatLng(1.1833, -77.0833),
      'San Bernardo': const LatLng(1.5167, -77.0500),
      'Colón': const LatLng(1.4833, -77.2833),
      'San Lorenzo': const LatLng(1.4500, -77.3167),
      'Arboleda': const LatLng(1.3167, -77.0833),
      'Buesaco': const LatLng(1.3833, -77.1667),
      'Chachagüí': const LatLng(1.1833, -77.2833),
      'El Tambo': const LatLng(1.4167, -77.3500),
      'La Florida': const LatLng(1.3000, -77.3667),
      'Nariño': const LatLng(1.2833, -77.3000),
      'Ospina': const LatLng(0.9833, -77.5833),
      'Francisco Pizarro': const LatLng(1.9333, -78.6833),
      'Mosquera': const LatLng(2.5333, -78.4667),
      'El Charco': const LatLng(2.4833, -78.1167),
      'La Tola': const LatLng(2.2167, -78.4333),
      'Olaya Herrera': const LatLng(2.3333, -78.4167),
      'Santa Bárbara': const LatLng(2.0167, -78.1500),
      'Magüí': const LatLng(2.1167, -78.2833),
      'Roberto Payán': const LatLng(1.8500, -78.3500),
      'Ancuyá': const LatLng(1.2833, -77.6167),
      'Linares': const LatLng(1.3500, -77.6500),
      'San Pablo': const LatLng(1.4167, -77.0833),
      'Taminango': const LatLng(1.4500, -77.3333),
      'San Pedro de Cartago': const LatLng(1.5833, -77.0833),
      'El Rosario': const LatLng(1.7333, -77.4833),
      'El Peñol': const LatLng(1.4833, -77.4167),
      'El Tablón de Gómez': const LatLng(1.4000, -77.2167),
      'La Llanada': const LatLng(1.6833, -77.5167),
      'Imués': const LatLng(0.9500, -77.5167),
      'Puerres': const LatLng(0.8000, -77.5833),
      'Santacruz': const LatLng(1.1000, -77.7833),
      'Guaitarilla': const LatLng(1.1667, -77.5833),
      'Albán': const LatLng(1.3667, -77.0500),
    };

    return coordinates[destination];
  }
  
  // Método para obtener rutas hacia Pasto (compatibilidad con código existente)
  static List<TransportRoute> getAllRoutesToPasto() {
    return getAllRoutes()
        .where((route) => route.destination.toLowerCase() == 'pasto')
        .toList();
  }
}