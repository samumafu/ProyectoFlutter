import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PopularRoutesManager {
  static const String _popularRoutesKey = 'popular_routes_data';
  static const String _routeCountsKey = 'route_booking_counts';
  
  // Rutas populares iniciales por defecto
  static const List<Map<String, String>> _defaultPopularRoutes = [
    {'origin': 'Pasto', 'destination': 'Ipiales'},
    {'origin': 'Pasto', 'destination': 'Túquerres'},
    {'origin': 'Pasto', 'destination': 'Tumaco'},
    {'origin': 'Ipiales', 'destination': 'Pasto'},
    {'origin': 'Túquerres', 'destination': 'Pasto'},
    {'origin': 'Tumaco', 'destination': 'Pasto'},
    {'origin': 'Pasto', 'destination': 'Tangua'},
    {'origin': 'Tangua', 'destination': 'Pasto'},
  ];
  
  /// Obtiene las rutas populares actuales
  static Future<List<Map<String, String>>> getPopularRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routesJson = prefs.getString(_popularRoutesKey);
      
      if (routesJson != null) {
        final List<dynamic> routesList = json.decode(routesJson);
        return routesList.cast<Map<String, dynamic>>()
            .map((route) => Map<String, String>.from(route))
            .toList();
      }
    } catch (e) {
      print('Error loading popular routes: $e');
    }
    
    // Si no hay datos guardados, usar rutas por defecto
    await _savePopularRoutes(_defaultPopularRoutes);
    return List.from(_defaultPopularRoutes);
  }
  
  /// Registra una nueva reserva y actualiza las rutas populares
  static Future<void> recordBooking(String origin, String destination) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Obtener conteos actuales
      final countsJson = prefs.getString(_routeCountsKey);
      Map<String, int> routeCounts = {};
      
      if (countsJson != null) {
        final Map<String, dynamic> counts = json.decode(countsJson);
        routeCounts = counts.map((key, value) => MapEntry(key, value as int));
      }
      
      // Incrementar contador para esta ruta
      final routeKey = '${origin}_to_$destination';
      routeCounts[routeKey] = (routeCounts[routeKey] ?? 0) + 1;
      
      // Guardar conteos actualizados
      await prefs.setString(_routeCountsKey, json.encode(routeCounts));
      
      // Actualizar rutas populares
      await _updatePopularRoutes(routeCounts);
      
    } catch (e) {
      print('Error recording booking: $e');
    }
  }
  
  /// Actualiza la lista de rutas populares basada en los conteos
  static Future<void> _updatePopularRoutes(Map<String, int> routeCounts) async {
    try {
      // Convertir conteos a lista de rutas con sus frecuencias
      List<MapEntry<String, int>> sortedRoutes = routeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Tomar las top 10 rutas más populares
      List<Map<String, String>> popularRoutes = [];
      
      for (var entry in sortedRoutes.take(10)) {
        final parts = entry.key.split('_to_');
        if (parts.length == 2) {
          popularRoutes.add({
            'origin': parts[0],
            'destination': parts[1],
          });
        }
      }
      
      // Si hay menos de 8 rutas populares, completar con rutas por defecto
      if (popularRoutes.length < 8) {
        for (var defaultRoute in _defaultPopularRoutes) {
          if (!popularRoutes.any((route) => 
              route['origin'] == defaultRoute['origin'] && 
              route['destination'] == defaultRoute['destination'])) {
            popularRoutes.add(defaultRoute);
            if (popularRoutes.length >= 8) break;
          }
        }
      }
      
      await _savePopularRoutes(popularRoutes);
      
    } catch (e) {
      print('Error updating popular routes: $e');
    }
  }
  
  /// Guarda las rutas populares en SharedPreferences
  static Future<void> _savePopularRoutes(List<Map<String, String>> routes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_popularRoutesKey, json.encode(routes));
    } catch (e) {
      print('Error saving popular routes: $e');
    }
  }
  
  /// Obtiene estadísticas de reservas por ruta
  static Future<Map<String, int>> getRouteStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final countsJson = prefs.getString(_routeCountsKey);
      
      if (countsJson != null) {
        final Map<String, dynamic> counts = json.decode(countsJson);
        return counts.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      print('Error loading route statistics: $e');
    }
    
    return {};
  }
  
  /// Reinicia las estadísticas (útil para testing o administración)
  static Future<void> resetStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_routeCountsKey);
      await prefs.remove(_popularRoutesKey);
    } catch (e) {
      print('Error resetting statistics: $e');
    }
  }
  
  /// Obtiene las rutas más populares formateadas para mostrar en UI
  static Future<List<String>> getFormattedPopularRoutes() async {
    final routes = await getPopularRoutes();
    return routes.map((route) => '${route['origin']} → ${route['destination']}').toList();
  }
  
  /// Verifica si una ruta específica está en las populares
  static Future<bool> isPopularRoute(String origin, String destination) async {
    final routes = await getPopularRoutes();
    return routes.any((route) => 
        route['origin'] == origin && route['destination'] == destination);
  }
}