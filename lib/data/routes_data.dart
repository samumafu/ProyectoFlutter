import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import 'constants/narino_destinations.dart';

class RoutesData {
  // Coordenadas de Pasto (destino principal)
  static const LatLng pastoCoordinates = LatLng(1.2136, -77.2811);
  
  static List<TransportRoute> getAllRoutesToPasto() {
    final List<TransportRoute> routes = [];
    
    // Generar rutas desde cada municipio hacia Pasto
    for (int i = 0; i < NarinoDestinations.municipalities.length; i++) {
      final municipality = NarinoDestinations.municipalities[i];
      
      // No crear ruta desde Pasto hacia Pasto
      if (municipality.toLowerCase() == 'pasto') continue;
      
      final originCoords = _getDestinationCoordinates(municipality);
      if (originCoords == null) continue;
      
      final route = TransportRoute(
        id: 'route_${municipality.toLowerCase().replaceAll(' ', '_')}_to_pasto',
        origin: municipality,
        destination: 'Pasto',
        originCoordinates: originCoords,
        destinationCoordinates: pastoCoordinates,
        distance: _calculateDistance(originCoords, pastoCoordinates),
        estimatedDuration: _calculateDuration(originCoords, pastoCoordinates),
        basePrice: _calculatePrice(originCoords, pastoCoordinates),
        intermediateStops: _getIntermediateStops(municipality),
      );
      
      routes.add(route);
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
  
  static List<String> _getIntermediateStops(String origin) {
    // Paradas intermedias comunes según la ubicación
    final Map<String, List<String>> intermediateStopsMap = {
      'Tumaco': ['Barbacoas', 'Ricaurte'],
      'Ipiales': ['Aldana', 'Pupiales'],
      'Túquerres': ['Sapuyes', 'Guachucal'],
      'Samaniego': ['Linares', 'Los Andes'],
      'La Unión': ['San Bernardo', 'Colón'],
      'Barbacoas': ['Ricaurte'],
      'Ricaurte': ['Tumaco'],
      'Magüí': ['Barbacoas'],
      'Roberto Payán': ['Barbacoas'],
      'Mosquera': ['El Rosario'],
      'El Rosario': ['Leiva'],
      'Leiva': ['El Rosario'],
      'Policarpa': ['Leiva'],
      'Cumbitara': ['Los Andes'],
      'Los Andes': ['Samaniego'],
      'Sotomayor': ['Los Andes'],
      'Linares': ['Samaniego'],
      'San Pablo': ['La Unión'],
      'Belén': ['San Pablo'],
      'San Bernardo': ['La Unión'],
      'Colón': ['La Unión'],
      'Santiago': ['Colón'],
      'La Tola': ['Tumaco'],
      'Francisco Pizarro': ['Tumaco'],
      'Olaya Herrera': ['Tumaco'],
      'Santa Bárbara': ['Tumaco'],
      'Iscuandé': ['Tumaco'],
      'El Tambo': ['Tumaco'],
      'Aldana': ['Ipiales'],
      'Pupiales': ['Ipiales'],
      'Gualmatán': ['Ipiales'],
      'Contadero': ['Ipiales'],
      'Córdoba': ['Ipiales'],
      'Potosí': ['Ipiales'],
      'Cuaspud': ['Ipiales'],
      'Carlosama': ['Ipiales'],
      'Guachucal': ['Túquerres'],
      'Sapuyes': ['Túquerres'],
      'Iles': ['Túquerres'],
      'Mallama': ['Túquerres'],
      'Ricaurte': ['Túquerres'],
      'Santacruz': ['Túquerres'],
      'Providencia': ['Túquerres'],
      'Ancuyá': ['Samaniego'],
      'Consacá': ['Sandona'],
      'Sandona': ['Consacá'],
      'Yacuanquer': ['Sandona'],
      'Tangua': ['Yacuanquer'],
      'Funes': ['Tangua'],
      'Imués': ['Funes'],
      'Ospina': ['Imués'],
      'Aldana': ['Ospina'],
      'Puerres': ['Aldana'],
      'Córdoba': ['Puerres'],
      'Potosí': ['Córdoba'],
      'Cuaspud': ['Potosí'],
      'Carlosama': ['Cuaspud'],
      'Buesaco': ['Chachagüí'],
      'Chachagüí': ['Nariño'],
      'Nariño': ['La Florida'],
      'La Florida': ['Sandoná'],
      'Sandoná': ['Consacá'],
      'Arboleda': ['Sandoná'],
      'Albán': ['Arboleda'],
    };
    
    return intermediateStopsMap[origin] ?? [];
  }
  
  static TransportRoute? getRouteById(String routeId) {
    try {
      return getAllRoutesToPasto().firstWhere((route) => route.id == routeId);
    } catch (e) {
      return null;
    }
  }
  
  static List<TransportRoute> getRoutesByOrigin(String origin) {
    return getAllRoutesToPasto()
        .where((route) => route.origin.toLowerCase() == origin.toLowerCase())
        .toList();
  }
  
  static List<TransportRoute> searchRoutes(String origin, String destination) {
    return getAllRoutesToPasto()
        .where((route) => 
            route.origin.toLowerCase().contains(origin.toLowerCase()) &&
            route.destination.toLowerCase().contains(destination.toLowerCase()))
        .toList();
  }
  
  static LatLng? _getDestinationCoordinates(String destination) {
    // Coordenadas aproximadas de algunos municipios de Nariño
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
}