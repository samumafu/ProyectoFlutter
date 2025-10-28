import 'dart:convert';
import 'dart:math';
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
      // PRIORIDAD 1: Intentar obtener ruta real de APIs de mapas
      final realRoute = await _getRealRoute(originCoords, destinationCoords);
      if (realRoute.isNotEmpty) {
        // Guardar en cache para uso futuro
        await _saveRouteToCache(cacheKey, realRoute);
        print('✅ Ruta REAL obtenida de API de mapas: $origin -> $destination (${realRoute.length} puntos)');
        return realRoute;
      }
    } catch (e) {
      print('❌ Error obteniendo ruta real de APIs: $e');
    }

    // PRIORIDAD 2: Usar método de respaldo con paradas intermedias reales
    print('🔄 Usando método de respaldo con paradas intermedias...');
    final fallbackRoute = _getFallbackRoute(origin, destination, originCoords, destinationCoords);
    if (fallbackRoute.isNotEmpty) {
      // También guardar el fallback en cache
      await _saveRouteToCache(cacheKey, fallbackRoute);
      print('⚠️ Ruta de respaldo generada: $origin -> $destination (${fallbackRoute.length} puntos)');
    }
    return fallbackRoute;
  }

  /// Obtiene una ruta real usando OpenStreetMap routing APIs
  static Future<List<LatLng>> _getRealRoute(LatLng start, LatLng end) async {
    // Usar exclusivamente APIs basadas en OpenStreetMap
    final osmRoutingServices = [
      () => _getOSRMRoute(start, end),
      () => _getMapboxRoute(start, end),
      () => _getOpenRouteServiceRoute(start, end),
    ];
    
    for (final service in osmRoutingServices) {
      try {
        final route = await service();
        if (route.isNotEmpty && route.length > 2) {
          print('Ruta real obtenida con ${route.length} puntos');
          return route;
        }
      } catch (e) {
        print('Error en servicio routing: $e');
        continue;
      }
    }
    
    // Si todos los servicios fallan, usar el método de respaldo con paradas intermedias
    print('APIs de routing no disponibles, usando método de respaldo con paradas intermedias');
    throw Exception('No se pudo obtener ruta real de ningún servicio');
  }

  /// Obtiene ruta usando OSRM API
  static Future<List<LatLng>> _getOSRMRoute(LatLng start, LatLng end) async {
    final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson&steps=true&alternatives=false');
    
    print('Consultando OSRM API: $url');
    
    final response = await http.get(url).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw Exception('Timeout en OSRM API');
      },
    );
    
    print('Respuesta OSRM - Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        if (route['geometry'] != null && route['geometry']['coordinates'] != null) {
          final coordinates = route['geometry']['coordinates'] as List;
          
          print('Ruta OSRM obtenida con ${coordinates.length} puntos');
          
          final routePoints = coordinates.map<LatLng>((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
          
          return _optimizeRoute(routePoints);
        }
      }
    } else {
      print('Error OSRM: ${response.statusCode} - ${response.body}');
    }
    
    throw Exception('OSRM API falló con status ${response.statusCode}');
  }

  /// Obtiene ruta usando OpenRouteService API (gratuita)
  static Future<List<LatLng>> _getOpenRouteServiceRoute(LatLng start, LatLng end) async {
    final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car?start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}');
    
    print('Consultando OpenRouteService API: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
      },
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Timeout en OpenRouteService API');
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['features'] != null && data['features'].isNotEmpty) {
        final feature = data['features'][0];
        if (feature['geometry'] != null && feature['geometry']['coordinates'] != null) {
          final coordinates = feature['geometry']['coordinates'] as List;
          
          print('Coordenadas OpenRouteService encontradas: ${coordinates.length} puntos');
          
          final routePoints = coordinates.map<LatLng>((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
          
          return _optimizeRoute(routePoints);
        }
      }
    }
    
    throw Exception('OpenRouteService API falló');
  }

  /// Obtiene ruta usando Mapbox API (requiere token pero tiene versión gratuita)
  static Future<List<LatLng>> _getMapboxRoute(LatLng start, LatLng end) async {
    // Token público de Mapbox para desarrollo (reemplazar con tu propio token en producción)
    const mapboxToken = 'pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw';
    
    final url = Uri.parse('https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&steps=true&access_token=$mapboxToken');
    
    print('Consultando Mapbox Directions API: $url');
    
    final response = await http.get(url).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw Exception('Timeout en Mapbox API');
      },
    );
    
    print('Respuesta Mapbox - Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        if (route['geometry'] != null && route['geometry']['coordinates'] != null) {
          final coordinates = route['geometry']['coordinates'] as List;
          
          print('Ruta Mapbox obtenida con ${coordinates.length} puntos');
          
          final routePoints = coordinates.map<LatLng>((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
          
          return _optimizeRoute(routePoints);
        }
      }
    } else {
      print('Error Mapbox: ${response.statusCode} - ${response.body}');
    }
    
    throw Exception('Mapbox API falló con status ${response.statusCode}');
  }

  /// Servidor alternativo de OSRM en caso de que el principal falle
  static Future<List<LatLng>> _getRealRouteAlternative(LatLng start, LatLng end) async {
    try {
      // Usar servidor alternativo de OSRM
      final url = Uri.parse('https://routing.openstreetmap.de/routed-car/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');
      
      print('Consultando OSRM alternativo: $url');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception('Timeout en OSRM alternativo');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          if (route['geometry'] != null && route['geometry']['coordinates'] != null) {
            final coordinates = route['geometry']['coordinates'] as List;
            
            final routePoints = coordinates.map<LatLng>((coord) {
              return LatLng(coord[1].toDouble(), coord[0].toDouble());
            }).toList();
            
            final optimizedRoute = _optimizeRoute(routePoints);
            print('Ruta alternativa obtenida con ${optimizedRoute.length} puntos');
            return optimizedRoute;
          }
        }
      }
    } catch (e) {
      print('Error en OSRM alternativo: $e');
    }
    
    return [];
  }

  /// Optimiza la ruta reduciendo puntos redundantes para mejor rendimiento
  static List<LatLng> _optimizeRoute(List<LatLng> route) {
    if (route.length <= 50) return route;
    
    List<LatLng> optimized = [route.first];
    
    // Usar algoritmo de Douglas-Peucker simplificado
    double tolerance = 0.001; // ~100m de tolerancia
    
    for (int i = 1; i < route.length - 1; i++) {
      final prev = optimized.last;
      final current = route[i];
      final next = route[i + 1];
      
      // Calcular si el punto actual es significativo
      if (_isSignificantPoint(prev, current, next, tolerance)) {
        optimized.add(current);
      }
    }
    
    optimized.add(route.last);
    return optimized;
  }

  /// Determina si un punto es significativo en la ruta
  static bool _isSignificantPoint(LatLng prev, LatLng current, LatLng next, double tolerance) {
    // Calcular la distancia perpendicular del punto actual a la línea prev-next
    final distance = _perpendicularDistance(current, prev, next);
    return distance > tolerance;
  }

  /// Calcula la distancia perpendicular de un punto a una línea
  static double _perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final A = point.latitude - lineStart.latitude;
    final B = point.longitude - lineStart.longitude;
    final C = lineEnd.latitude - lineStart.latitude;
    final D = lineEnd.longitude - lineStart.longitude;
    
    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    if (lenSq == 0) return _distance.as(LengthUnit.Kilometer, point, lineStart);
    
    final param = dot / lenSq;
    
    LatLng projection;
    if (param < 0) {
      projection = lineStart;
    } else if (param > 1) {
      projection = lineEnd;
    } else {
      projection = LatLng(
        lineStart.latitude + param * C,
        lineStart.longitude + param * D,
      );
    }
    
    return _distance.as(LengthUnit.Kilometer, point, projection);
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

  /// Genera una ruta realista de emergencia cuando los servicios OSM no están disponibles
  static List<LatLng> _generateRealisticEmergencyRoute(LatLng start, LatLng end) {
    List<LatLng> route = [start];
    
    // Calcular distancia total
    final distance = _distance.as(LengthUnit.Kilometer, start, end);
    
    // Número de puntos basado en la distancia (más puntos para rutas más largas)
    int numPoints = (distance / 2).ceil().clamp(15, 60); // Un punto cada 2km aproximadamente
    
    // Generar puntos intermedios con curvas realistas que simulan carreteras
    for (int i = 1; i < numPoints; i++) {
      double t = i / numPoints;
      
      // Interpolación básica
      double lat = start.latitude + (end.latitude - start.latitude) * t;
      double lng = start.longitude + (end.longitude - start.longitude) * t;
      
      // Agregar variaciones para simular carreteras reales de Colombia
      // Variación principal basada en topografía montañosa típica de Nariño
      double latVariation = 0.004 * sin(t * pi * 3.5) * (t * (1 - t)) * 2;
      double lngVariation = 0.003 * cos(t * pi * 2.8) * (t * (1 - t)) * 2;
      
      // Variación secundaria para curvas más naturales
      if (distance > 50) { // Ruta larga, más curvas
        latVariation += 0.002 * sin(t * pi * 6) * (t * (1 - t));
        lngVariation += 0.0015 * cos(t * pi * 5) * (t * (1 - t));
      }
      
      // Variación terciaria para evitar líneas rectas
      latVariation += 0.001 * sin(t * pi * 8) * (t * (1 - t));
      lngVariation += 0.001 * cos(t * pi * 7) * (t * (1 - t));
      
      route.add(LatLng(lat + latVariation, lng + lngVariation));
    }
    
    route.add(end);
    
    print('Ruta realista de emergencia generada con ${route.length} puntos');
    return route;
  }

  /// Crea una ruta realista entre dos puntos usando algoritmos de interpolación
  static List<LatLng> _createRealisticPath(LatLng start, LatLng end) {
    
    // Calcular la distancia y dirección
    final distance = _distance.as(LengthUnit.Kilometer, start, end);
    final bearing = _distance.bearing(start, end);
    
    // Número de puntos intermedios basado en la distancia (más puntos para rutas más largas)
    int numPoints = (distance / 2).ceil().clamp(8, 50); // Un punto cada 2km aproximadamente
    
    // Determinar el tipo de ruta basado en las coordenadas
    final routeType = _determineRouteType(start, end);
    
    // Agregar puntos de control para crear curvas más realistas
    final controlPoints = _generateControlPoints(start, end, routeType);
    
    // Generar ruta usando spline cúbico para suavidad
    final splinePoints = _generateSplineRoute(start, end, controlPoints, numPoints);
    
    return splinePoints;
  }

  /// Genera puntos de control para crear rutas más realistas
  static List<LatLng> _generateControlPoints(LatLng start, LatLng end, String routeType) {
    List<LatLng> controlPoints = [];
    
    // Calcular punto medio
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    
    // Agregar desviaciones basadas en el tipo de ruta
    switch (routeType) {
      case 'coastal':
        // Rutas costeras: siguen la línea de costa
        controlPoints.add(LatLng(midLat + 0.02, midLng - 0.015));
        controlPoints.add(LatLng(midLat - 0.01, midLng + 0.02));
        break;
        
      case 'mountain':
        // Rutas de montaña: zigzag por la topografía
        controlPoints.add(LatLng(midLat + 0.015, midLng + 0.01));
        controlPoints.add(LatLng(midLat - 0.008, midLng - 0.012));
        controlPoints.add(LatLng(midLat + 0.005, midLng + 0.008));
        break;
        
      case 'valley':
        // Rutas de valle: curvas suaves
        controlPoints.add(LatLng(midLat + 0.008, midLng - 0.005));
        break;
    }
    
    return controlPoints;
  }

  /// Genera una ruta suave usando interpolación spline
  static List<LatLng> _generateSplineRoute(LatLng start, LatLng end, List<LatLng> controlPoints, int numPoints) {
    List<LatLng> allPoints = [start, ...controlPoints, end];
    List<LatLng> splinePoints = [];
    
    for (int i = 0; i <= numPoints; i++) {
      double t = i / numPoints;
      LatLng point = _interpolateSpline(allPoints, t);
      splinePoints.add(point);
    }
    
    return splinePoints;
  }

  /// Interpolación spline cúbico para rutas suaves
  static LatLng _interpolateSpline(List<LatLng> points, double t) {
    if (points.length < 2) return points.first;
    if (points.length == 2) {
      // Interpolación lineal simple
      final lat = points[0].latitude + (points[1].latitude - points[0].latitude) * t;
      final lng = points[0].longitude + (points[1].longitude - points[0].longitude) * t;
      return LatLng(lat, lng);
    }
    
    // Para múltiples puntos, usar interpolación de Bézier
    return _bezierInterpolation(points, t);
  }

  /// Interpolación de Bézier para curvas suaves
  static LatLng _bezierInterpolation(List<LatLng> points, double t) {
    List<LatLng> tempPoints = List.from(points);
    
    while (tempPoints.length > 1) {
      List<LatLng> newPoints = [];
      for (int i = 0; i < tempPoints.length - 1; i++) {
        final lat = tempPoints[i].latitude + (tempPoints[i + 1].latitude - tempPoints[i].latitude) * t;
        final lng = tempPoints[i].longitude + (tempPoints[i + 1].longitude - tempPoints[i].longitude) * t;
        newPoints.add(LatLng(lat, lng));
      }
      tempPoints = newPoints;
    }
    
    return tempPoints.first;
  }

  /// Determina el tipo de ruta basado en las coordenadas de inicio y fin
  static String _determineRouteType(LatLng start, LatLng end) {
    // Coordenadas aproximadas de regiones importantes
    final pacifico = LatLng(1.8, -78.8); // Tumaco
    final andina = LatLng(1.2, -77.3);   // Pasto
    final frontera = LatLng(0.8, -77.6); // Ipiales
    
    final startToPacifico = _distance.as(LengthUnit.Kilometer, start, pacifico);
    final startToAndina = _distance.as(LengthUnit.Kilometer, start, andina);
    final startToFrontera = _distance.as(LengthUnit.Kilometer, start, frontera);
    
    final endToPacifico = _distance.as(LengthUnit.Kilometer, end, pacifico);
    final endToAndina = _distance.as(LengthUnit.Kilometer, end, andina);
    final endToFrontera = _distance.as(LengthUnit.Kilometer, end, frontera);
    
    // Ruta hacia la costa (más curvas por la topografía)
    if (startToPacifico < 100 || endToPacifico < 100) {
      return 'coastal';
    }
    // Ruta de montaña (curvas por la topografía andina)
    else if ((startToAndina < 50 && endToFrontera < 50) || (startToFrontera < 50 && endToAndina < 50)) {
      return 'mountain';
    }
    // Ruta de valle (más directa)
    else {
      return 'valley';
    }
  }

  /// Obtiene variaciones específicas para cada tipo de ruta
  static Map<String, double> _getRouteVariations(String routeType, double fraction, int pointIndex, int totalPoints) {
    double latVariation = 0.0;
    double lngVariation = 0.0;
    
    switch (routeType) {
      case 'coastal':
        // Rutas costeras: más curvas y desviaciones
        latVariation = 0.004 * sin(fraction * pi * 3) * (fraction * (1 - fraction));
        lngVariation = 0.003 * cos(fraction * pi * 2.5) * (fraction * (1 - fraction));
        break;
        
      case 'mountain':
        // Rutas de montaña: curvas serpenteantes
        latVariation = 0.003 * sin(fraction * pi * 4) * (fraction * (1 - fraction));
        lngVariation = 0.002 * cos(fraction * pi * 3) * (fraction * (1 - fraction));
        // Agregar variación adicional para simular zigzag de montaña
        if (pointIndex % 3 == 0) {
          latVariation += 0.001 * (pointIndex % 2 == 0 ? 1 : -1);
        }
        break;
        
      case 'valley':
        // Rutas de valle: más directas pero con algunas curvas suaves
        latVariation = 0.002 * sin(fraction * pi * 2) * (fraction * (1 - fraction));
        lngVariation = 0.0015 * cos(fraction * pi * 1.5) * (fraction * (1 - fraction));
        break;
    }
    
    return {'lat': latVariation, 'lng': lngVariation};
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
    
    // Definir puntos de interés específicos por municipio
    final municipalityPlaces = _getMunicipalitySpecificPlaces(municipality);
    
    for (int i = 0; i < municipalityPlaces.length; i++) {
      final place = municipalityPlaces[i];
      final offset = place['offset'] as List<double>;
      
      nearbyPoints.add(PickupPoint(
        id: '${municipality.toLowerCase()}_${i + 1}',
        name: place['name'] as String,
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

  /// Obtiene lugares específicos para cada municipio
  static List<Map<String, dynamic>> _getMunicipalitySpecificPlaces(String municipality) {
    final places = {
      'Pasto': [
        {'name': 'Centro Histórico', 'offset': [0.002, 0.002]},
        {'name': 'Plaza de Nariño', 'offset': [0.001, -0.001]},
        {'name': 'Universidad de Nariño', 'offset': [-0.003, 0.004]},
        {'name': 'Terminal de Transportes', 'offset': [0.005, -0.003]},
        {'name': 'Centro Comercial Unicentro', 'offset': [-0.002, 0.003]},
        {'name': 'Aeropuerto Antonio Nariño', 'offset': [0.008, -0.005]},
        {'name': 'Parque Infantil', 'offset': [-0.001, 0.001]},
        {'name': 'Hospital Departamental', 'offset': [0.003, 0.002]},
        {'name': 'Estadio Libertad', 'offset': [-0.004, -0.002]},
        {'name': 'Bombona', 'offset': [0.006, 0.004]},
      ],
      'Ipiales': [
        {'name': 'Santuario Las Lajas', 'offset': [0.015, -0.010]},
        {'name': 'Centro de Ipiales', 'offset': [0.001, 0.001]},
        {'name': 'Frontera con Ecuador', 'offset': [-0.005, -0.008]},
        {'name': 'Plaza Principal', 'offset': [0.002, -0.001]},
        {'name': 'Terminal de Transportes', 'offset': [0.003, 0.002]},
        {'name': 'Mercado Municipal', 'offset': [-0.002, 0.003]},
        {'name': 'Parque Central', 'offset': [0.001, -0.002]},
        {'name': 'Hospital San Vicente', 'offset': [0.004, 0.001]},
      ],
      'Túquerres': [
        {'name': 'Centro de Túquerres', 'offset': [0.001, 0.001]},
        {'name': 'Plaza de Bolívar', 'offset': [0.002, -0.001]},
        {'name': 'Terminal de Transportes', 'offset': [0.003, 0.002]},
        {'name': 'Parque Principal', 'offset': [-0.001, 0.002]},
        {'name': 'Iglesia San Bartolomé', 'offset': [0.001, -0.001]},
        {'name': 'Estación de Policía', 'offset': [0.002, 0.003]},
      ],
      'Tumaco': [
        {'name': 'Puerto de Tumaco', 'offset': [0.002, -0.005]},
        {'name': 'Centro de Tumaco', 'offset': [0.001, 0.001]},
        {'name': 'Playa El Morro', 'offset': [0.008, -0.003]},
        {'name': 'Terminal Marítimo', 'offset': [0.003, -0.004]},
        {'name': 'Mercado Público', 'offset': [-0.001, 0.002]},
        {'name': 'Hospital San Andrés', 'offset': [0.004, 0.003]},
        {'name': 'Aeropuerto La Florida', 'offset': [0.010, 0.008]},
      ],
    };

    // Lugares genéricos para municipios no especificados
    final genericPlaces = [
      {'name': 'Centro', 'offset': [0.002, 0.002]},
      {'name': 'Plaza Principal', 'offset': [0.001, -0.001]},
      {'name': 'Parque Central', 'offset': [-0.001, 0.001]},
      {'name': 'Terminal de Transportes', 'offset': [0.003, -0.002]},
      {'name': 'Iglesia Principal', 'offset': [0.001, 0.002]},
      {'name': 'Alcaldía Municipal', 'offset': [-0.002, -0.001]},
    ];

    return places[municipality] ?? genericPlaces;
  }

  /// Calcula la distancia total de la ruta
  static double calculateRouteDistance(List<LatLng> routePoints) {
    if (routePoints.length < 2) return 0.0;
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

  // Try GraphHopper API (OpenStreetMap based)
  static Future<List<LatLng>> _getGraphHopperRoute(LatLng start, LatLng end) async {
    try {
      final url = 'https://graphhopper.com/api/1/route'
          '?point=${start.latitude},${start.longitude}'
          '&point=${end.latitude},${end.longitude}'
          '&vehicle=car'
          '&locale=es'
          '&key=YOUR_GRAPHHOPPER_API_KEY'; // Replace with your API key
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['paths'] != null && data['paths'].isNotEmpty) {
          final points = data['paths'][0]['points'];
          return _decodePolyline(points);
        }
      }
    } catch (e) {
      print('GraphHopper API error: $e');
    }
    
    throw Exception('GraphHopper route not available');
  }

  // Decode polyline points
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
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