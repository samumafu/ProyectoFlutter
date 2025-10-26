import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/routes_data.dart';

class RouteTracingService {
  static const Distance _distance = Distance();
  
  // Cache para rutas calculadas
  static final Map<String, List<LatLng>> _routeCache = {};
  
  /// Genera una clave única para el cache basada en origen y destino
  static String _getCacheKey(String origin, String destination) {
    return '${origin}_to_$destination';
  }
  
  /// Guarda una ruta en el cache local persistente
  static Future<void> _saveRouteToCache(String cacheKey, List<LatLng> route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routeJson = route.map((point) => '${point.latitude},${point.longitude}').join(';');
      await prefs.setString('route_$cacheKey', routeJson);
      
      // También guardar en cache en memoria
      _routeCache[cacheKey] = route;
    } catch (e) {
      print('Error guardando ruta en cache: $e');
    }
  }
  
  /// Carga una ruta del cache local persistente
  static Future<List<LatLng>?> _loadRouteFromCache(String cacheKey) async {
    try {
      // Primero verificar cache en memoria
      if (_routeCache.containsKey(cacheKey)) {
        return _routeCache[cacheKey];
      }
      
      // Luego verificar cache persistente
      final prefs = await SharedPreferences.getInstance();
      final routeJson = prefs.getString('route_$cacheKey');
      
      if (routeJson != null) {
        final points = routeJson.split(';').map((pointStr) {
          final coords = pointStr.split(',');
          return LatLng(double.parse(coords[0]), double.parse(coords[1]));
        }).toList();
        
        // Guardar en cache en memoria para acceso rápido
        _routeCache[cacheKey] = points;
        return points;
      }
    } catch (e) {
      print('Error cargando ruta del cache: $e');
    }
    
    return null;
  }

  /// Traza una ruta realista entre dos municipios siguiendo las vías principales
  static Future<List<LatLng>> traceRoute(String origin, String destination) async {
    final originCoords = RoutesData.getDestinationCoordinates(origin);
    final destinationCoords = RoutesData.getDestinationCoordinates(destination);
    
    if (originCoords == null || destinationCoords == null) {
      return [];
    }

    // Verificar cache primero
    final cacheKey = _getCacheKey(origin, destination);
    final cachedRoute = await _loadRouteFromCache(cacheKey);
    if (cachedRoute != null) {
      print('Ruta cargada desde cache: $origin -> $destination');
      return cachedRoute;
    }

    try {
      // Intentar obtener ruta real usando OSRM API
      final realRoute = await _getRealRoute(originCoords, destinationCoords);
      if (realRoute.isNotEmpty) {
        // Guardar en cache para uso futuro
        await _saveRouteToCache(cacheKey, realRoute);
        print('Ruta real obtenida de OSRM API y guardada en cache: $origin -> $destination');
        return realRoute;
      }
    } catch (e) {
      print('Error obteniendo ruta real: $e');
    }

    // Fallback: usar el método anterior si la API falla
    final fallbackRoute = _getFallbackRoute(origin, destination, originCoords, destinationCoords);
    if (fallbackRoute.isNotEmpty) {
      // También guardar el fallback en cache
      await _saveRouteToCache(cacheKey, fallbackRoute);
      print('Ruta fallback generada y guardada en cache: $origin -> $destination');
    }
    return fallbackRoute;
  }

  /// Obtiene una ruta real usando OSRM API (gratuita, sin API key)
  static Future<List<LatLng>> _getRealRoute(LatLng start, LatLng end) async {
    try {
      // Usar OSRM API que es completamente gratuita y no requiere API key
      final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');
      
      print('Consultando OSRM API: $url');
      
      final response = await http.get(url);
      
      print('Respuesta OSRM - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Datos recibidos: ${data.toString().substring(0, 200)}...');
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          if (route['geometry'] != null && route['geometry']['coordinates'] != null) {
            final coordinates = route['geometry']['coordinates'] as List;
            
            print('Coordenadas encontradas: ${coordinates.length} puntos');
            
            final routePoints = coordinates.map<LatLng>((coord) {
              return LatLng(coord[1].toDouble(), coord[0].toDouble());
            }).toList();
            
            print('Ruta real obtenida con ${routePoints.length} puntos');
            return routePoints;
          }
        }
      } else {
        print('Error en respuesta OSRM: ${response.body}');
      }
    } catch (e) {
      print('Error en API de rutas OSRM: $e');
    }
    
    return [];
  }

  /// Método de respaldo usando el sistema anterior
  static List<LatLng> _getFallbackRoute(String origin, String destination, LatLng originCoords, LatLng destinationCoords) {
    // Obtener paradas intermedias de la ruta
    final intermediateStops = RoutesData.getIntermediateStops(origin, destination);
    
    List<LatLng> routePoints = [originCoords];
    
    // Agregar coordenadas de paradas intermedias con rutas realistas
    for (String stop in intermediateStops) {
      final stopCoords = RoutesData.getDestinationCoordinates(stop);
      if (stopCoords != null) {
        // Crear una ruta curva más realista entre puntos
        final intermediatePoints = _createRealisticPath(
          routePoints.last, 
          stopCoords
        );
        routePoints.addAll(intermediatePoints);
      }
    }
    
    // Agregar ruta final al destino
    final finalPoints = _createRealisticPath(routePoints.last, destinationCoords);
    routePoints.addAll(finalPoints);
    
    return routePoints;
  }

  /// Crea una ruta más realista entre dos puntos simulando carreteras
  static List<LatLng> _createRealisticPath(LatLng start, LatLng end) {
    List<LatLng> path = [];
    
    // Calcular la distancia y dirección
    final distance = _distance.as(LengthUnit.Kilometer, start, end);
    final bearing = _distance.bearing(start, end);
    
    // Número de puntos intermedios basado en la distancia
    int numPoints = (distance / 5).ceil().clamp(3, 20); // Un punto cada 5km aproximadamente
    
    for (int i = 1; i <= numPoints; i++) {
      double fraction = i / numPoints;
      
      // Interpolación básica con pequeñas variaciones para simular carreteras
      double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      double lng = start.longitude + (end.longitude - start.longitude) * fraction;
      
      // Agregar pequeñas variaciones para simular el trazado de carreteras
      if (i > 1 && i < numPoints) {
        // Variación basada en la topografía simulada
        double variation = 0.002 * (1 - 2 * (i % 2)); // Alternating small variations
        lat += variation * (fraction * (1 - fraction)) * 2; // Curva suave
        lng += variation * 0.5 * (fraction * (1 - fraction)) * 2;
      }
      
      path.add(LatLng(lat, lng));
    }
    
    return path;
  }

  /// Obtiene puntos de recogida potenciales a lo largo de la ruta
  static Future<List<PickupPoint>> getPickupPointsAlongRoute(String origin, String destination) async {
    List<PickupPoint> pickupPoints = [];
    
    // Punto de origen
    final originCoords = RoutesData.getDestinationCoordinates(origin);
    if (originCoords != null) {
      pickupPoints.add(PickupPoint(
        id: 'origin',
        name: 'Terminal de $origin',
        description: 'Terminal principal de $origin',
        coordinates: originCoords,
        municipality: origin,
        isTerminal: true,
      ));
    }
    
    // Puntos intermedios
    final intermediateStops = RoutesData.getIntermediateStops(origin, destination);
    for (int i = 0; i < intermediateStops.length; i++) {
      final stop = intermediateStops[i];
      final stopCoords = RoutesData.getDestinationCoordinates(stop);
      if (stopCoords != null) {
        pickupPoints.add(PickupPoint(
          id: 'stop_$i',
          name: 'Terminal de $stop',
          description: 'Parada en $stop',
          coordinates: stopCoords,
          municipality: stop,
          isTerminal: true,
        ));

        // Agregar puntos adicionales cerca de cada parada
        pickupPoints.addAll(_generateNearbyPickupPoints(stop, stopCoords));
      }
    }
    
    // Agregar puntos adicionales simulados a lo largo de la ruta
    final routePoints = await traceRoute(origin, destination);
    if (routePoints.length > 4) {
      // Agregar algunos puntos de recogida adicionales
      for (int i = 1; i < routePoints.length - 1; i += (routePoints.length ~/ 4)) {
        final point = routePoints[i];
        pickupPoints.add(PickupPoint(
          id: 'pickup_$i',
          name: 'Punto de Recogida ${pickupPoints.length}',
          description: 'Punto de recogida en la vía principal',
          coordinates: point,
          municipality: origin, // Asignar municipio de origen por defecto
          isTerminal: false,
        ));
      }
    }
    
    // Punto de destino
    final destinationCoords = RoutesData.getDestinationCoordinates(destination);
    if (destinationCoords != null) {
      pickupPoints.add(PickupPoint(
        id: 'destination',
        name: 'Terminal de $destination',
        description: 'Terminal de destino en $destination',
        coordinates: destinationCoords,
        municipality: destination,
        isTerminal: true,
      ));
    }

    return pickupPoints;
  }

  /// Genera puntos de recogida adicionales cerca de un municipio
  static List<PickupPoint> _generateNearbyPickupPoints(String municipality, LatLng center) {
    List<PickupPoint> nearbyPoints = [];
    
    // Definir algunos puntos de interés comunes
    final commonPlaces = [
      {'name': 'Centro', 'offset': [0.002, 0.002]},
      {'name': 'Plaza Principal', 'offset': [0.001, -0.001]},
      {'name': 'Parque Central', 'offset': [-0.001, 0.001]},
      {'name': 'Estación de Servicio', 'offset': [0.003, -0.002]},
    ];

    for (int i = 0; i < commonPlaces.length; i++) {
      final place = commonPlaces[i];
      final offset = place['offset'] as List<double>;
      
      nearbyPoints.add(PickupPoint(
        id: '${municipality.toLowerCase()}_${i + 1}',
        name: '${place['name']} - $municipality',
        description: 'Punto de recogida en ${place['name']} de $municipality',
        coordinates: LatLng(
          center.latitude + offset[0],
          center.longitude + offset[1],
        ),
        municipality: municipality,
        isTerminal: false,
      ));
    }

    return nearbyPoints;
  }

  /// Calcula la distancia total de la ruta
  static double calculateRouteDistance(List<LatLng> routePoints) {
    if (routePoints.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistance += _distance.as(LengthUnit.Kilometer, routePoints[i], routePoints[i + 1]);
    }

    return totalDistance;
  }

  /// Encuentra el punto de recogida más cercano a una coordenada dada
  static PickupPoint? findNearestPickupPoint(LatLng location, List<PickupPoint> pickupPoints) {
    if (pickupPoints.isEmpty) return null;

    PickupPoint? nearest;
    double minDistance = double.infinity;

    for (final point in pickupPoints) {
      final distance = _distance.as(LengthUnit.Meter, location, point.coordinates);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = point;
      }
    }

    return nearest;
  }
}

/// Modelo para representar un punto de recogida
class PickupPoint {
  final String id;
  final String name;
  final String description;
  final LatLng coordinates;
  final String municipality;
  final bool isTerminal;

  const PickupPoint({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinates,
    required this.municipality,
    required this.isTerminal,
  });

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickupPoint &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}