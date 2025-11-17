// lib/core/services/osrm_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; 

class OsrmService {
  static const String _osrmBaseUrl = 'http://router.project-osrm.org/route/v1/driving/';
  final PolylinePoints polylinePoints = PolylinePoints();

  Future<List<LatLng>> getRoute(LatLng origin, LatLng destination) async {
    // ⚠️ CRÍTICO: OSRM usa longitud,latitud (lon,lat), no lat,lon.
    final coordinates = '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
    
    // El parámetro overview=full asegura que la geometría de la ruta esté completa
    // El parámetro geometries=polyline asegura que la geometría esté comprimida (polyline)
    final url = Uri.parse('$_osrmBaseUrl$coordinates?overview=full&geometries=polyline');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final String encodedPolyline = data['routes'][0]['geometry'];
          
          // ⚠️ Decodificación: OSRM devuelve la polilínea codificada.
          List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(encodedPolyline);
          
          // Mapea los puntos decodificados al formato LatLng que usa flutter_map
          return decodedPoints.map((point) => LatLng(point.latitude, point.longitude)).toList();
        }
      }
    } catch (e) {
      // Si hay error de conexión o JSON, se retorna una lista vacía
      print('Error al obtener la ruta OSRM: $e'); 
    }
    return [];
  }
}