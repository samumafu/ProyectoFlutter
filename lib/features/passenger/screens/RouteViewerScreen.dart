import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tu_flota/core/services/osrm_service.dart'; // ¡Asegúrate que esta ruta es correcta!

class RouteViewerScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;

  const RouteViewerScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  @override
  State<RouteViewerScreen> createState() => _RouteViewerScreenState();
}

class _RouteViewerScreenState extends State<RouteViewerScreen> {
  List<LatLng> _routePoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  // 1. Cargar la ruta usando el servicio OSRM
  Future<void> _loadRoute() async {
    final osrm = OsrmService();
    final points = await osrm.getRoute(widget.origin, widget.destination);
    
    if (mounted) {
      setState(() {
        _routePoints = points;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. Calcula el centro inicial del mapa
    final LatLng initialCenter = LatLng(
      (widget.origin.latitude + widget.destination.latitude) / 2,
      (widget.origin.longitude + widget.destination.longitude) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta de Viaje Confirmada'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 11.0, 
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tuflota.app',
                ),
                // 3. Dibuja la polilínea de la ruta
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue.shade800,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
                // 4. Marcadores de Origen y Destino
                MarkerLayer(
                  markers: [
                    _buildMarker(widget.origin, Colors.green, Icons.departure_board),
                    _buildMarker(widget.destination, Colors.red, Icons.flag),
                  ],
                ),
              ],
            ),
    );
  }

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
}