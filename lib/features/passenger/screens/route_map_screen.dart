import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// Asegúrate de que esta importación esté disponible
import 'package:latlong2/latlong.dart' as lt; 
import 'package:tu_flota/core/services/osrm_service.dart';

const Color _primaryColor = Color(0xFF1E88E5);
const Color _originColor = Color(0xFF00C853);
const Color _destinationColor = Color(0xFFC62828);
const Color _pickupColor = Color(0xFFFFA000); 

class RouteMapScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;

  const RouteMapScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  String? _error;
  LatLng? _pickupPoint; 
  // Distancia máxima en metros para considerar un tap "cercano" a la línea
  static const double _maxDistanceMeters = 500.0; 

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  // Cargar la ruta usando el servicio OSRM
  Future<void> _loadRoute() async {
    final osrm = OsrmService();
    try {
      final points = await osrm.getRoute(widget.origin, widget.destination);
      
      if (mounted) {
        setState(() {
          _routePoints = points;
          _isLoading = false;
          if (points.isEmpty) {
             _error = 'No se pudo trazar la ruta. Verifica el servicio OSRM y las coordenadas.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error de conexión al servicio de rutas.';
          print('OSRM Error: $e');
        });
      }
    }
  }
  
  // 🟢 NUEVA FUNCIÓN: Encuentra el punto más cercano en la polilínea a un punto dado.
  LatLng? _findNearestPointOnPolyline(LatLng tapPoint, List<LatLng> polyline) {
    final Distance distance = const lt.Distance();
    LatLng? nearestPoint;
    double minDistance = double.infinity;

    // Recorrer todos los segmentos de la ruta
    for (int i = 0; i < polyline.length - 1; i++) {
      final p1 = polyline[i];
      final p2 = polyline[i + 1];

      // Calcular la distancia del tapPoint al segmento p1-p2
      final nearestOnSegment = _getNearestPointOnSegment(tapPoint, p1, p2);
      final distToSegment = distance(tapPoint, nearestOnSegment);

      // Si es el punto más cercano encontrado hasta ahora
      if (distToSegment < minDistance) {
        minDistance = distToSegment;
        nearestPoint = nearestOnSegment;
      }
    }
    
    // Si la distancia mínima es menor que el umbral máximo, lo devolvemos
    if (minDistance <= _maxDistanceMeters && nearestPoint != null) {
      return nearestPoint;
    }
    
    // Si está demasiado lejos, devuelve null
    return null;
  }

  // Helper matemático para encontrar el punto más cercano en un segmento de línea (p1-p2)
  LatLng _getNearestPointOnSegment(LatLng p, LatLng p1, LatLng p2) {
    // Convierte LatLng a coordenadas cartesianas simplificadas (asume distancias cortas)
    // Se usa la librería latlong2 para simplificar la proyección.
    
    // Distancia entre p1 y p2 (Segmento)
    final d2 = const lt.Distance().distance(p1, p2);
    
    // Si la distancia es cero, devuelve p1 (los puntos son el mismo)
    if (d2 == 0.0) return p1;

    // Producto escalar
    final t = ((p.longitude - p1.longitude) * (p2.longitude - p1.longitude) +
               (p.latitude - p1.latitude) * (p2.latitude - p1.latitude)) /
              (d2 * d2);

    // t < 0 significa que el punto más cercano está fuera del segmento (antes de p1)
    if (t < 0) return p1;
    // t > 1 significa que el punto más cercano está fuera del segmento (después de p2)
    if (t > 1) return p2;

    // El punto más cercano está en el segmento
    return LatLng(
      p1.latitude + t * (p2.latitude - p1.latitude),
      p1.longitude + t * (p2.longitude - p1.longitude),
    );
  }


  // 🟢 FUNCIÓN MODIFICADA: Ahora ajusta el punto tocado a la polilínea
  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    if (_routePoints.isEmpty) return;
    
    final LatLng? snappedPoint = _findNearestPointOnPolyline(latlng, _routePoints);

    if (snappedPoint != null) {
      setState(() {
        _pickupPoint = snappedPoint;
      });
      // Mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Punto de recogida ajustado a la ruta: ${snappedPoint.latitude.toStringAsFixed(4)}, ${snappedPoint.longitude.toStringAsFixed(4)}'),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: _pickupColor,
        ),
      );
    } else {
      // Mensaje de advertencia
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El punto de recogida debe estar cerca de la ruta trazada.'),
          duration: Duration(milliseconds: 2000),
          backgroundColor: _destinationColor,
        ),
      );
    }
  }

  // Helper para construir los marcadores
  Marker _buildMarker(LatLng point, Color color, IconData icon) {
    return Marker(
      width: 80.0,
      height: 80.0,
      point: point,
      child: Icon(
        icon,
        color: color,
        size: 40.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter = LatLng(
      (widget.origin.latitude + widget.destination.latitude) / 2,
      (widget.origin.longitude + widget.destination.longitude) / 2,
    );
    
    final List<Marker> markers = [
      _buildMarker(widget.origin, _originColor, Icons.departure_board),
      _buildMarker(widget.destination, _destinationColor, Icons.flag),
    ];

    if (_pickupPoint != null) {
      markers.add(_buildMarker(_pickupPoint!, _pickupColor, Icons.person_pin_circle));
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta del Viaje - Seleccionar Recogida'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null || _routePoints.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.route_outlined, color: Colors.grey, size: 80),
                        const SizedBox(height: 10),
                        Text(
                          _error ?? 'No se pudo trazar la ruta. Verifica los datos.', 
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.black54)
                        ),
                      ],
                    ),
                  ),
                )
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: _routePoints.length < 100 ? 11.0 : 9.0, 
                    onTap: _handleTap, 
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tuflota.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          color: _primaryColor,
                          strokeWidth: 5.0,
                          strokeCap: StrokeCap.round, 
                        ),
                      ],
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _pickupPoint != null
                ? () {
                    // Devuelve la coordenada seleccionada a la pantalla anterior
                    Navigator.pop(context, _pickupPoint); 
                  }
                : null,
            icon: const Icon(Icons.location_on),
            label: Text(_pickupPoint != null ? 'CONFIRMAR PUNTO DE RECOGIDA' : 'TOCA SOBRE LA RUTA PARA SELECCIONAR UN PUNTO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _pickupColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}