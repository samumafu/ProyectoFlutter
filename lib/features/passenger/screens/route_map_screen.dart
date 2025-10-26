import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/route_tracing_service.dart';
import '../../../data/routes_data.dart';

class RouteMapScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final Function(PickupPoint)? onPickupPointSelected;

  const RouteMapScreen({
    Key? key,
    required this.origin,
    required this.destination,
    this.onPickupPointSelected,
  }) : super(key: key);

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  List<PickupPoint> _pickupPoints = [];
  PickupPoint? _selectedPickupPoint;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  void _loadRouteData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar datos de ruta usando la nueva API
      final routePoints = await RouteTracingService.traceRoute(widget.origin, widget.destination);
      final pickupPoints = await RouteTracingService.getPickupPointsAlongRoute(widget.origin, widget.destination);

      setState(() {
        _routePoints = routePoints;
        _pickupPoints = pickupPoints;
        _isLoading = false;
      });

      // Centrar el mapa en la ruta
      if (_routePoints.isNotEmpty) {
        _centerMapOnRoute();
      }
    } catch (e) {
      print('Error cargando datos de ruta: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _centerMapOnRoute() {
    if (_routePoints.isEmpty) return;

    // Calcular los límites de la ruta
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final point in _routePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    // Centrar el mapa
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 10.0);
  }

  void _selectPickupPoint(PickupPoint point) {
    setState(() {
      _selectedPickupPoint = point;
    });

    if (widget.onPickupPointSelected != null) {
      widget.onPickupPointSelected!(point);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ruta ${widget.origin} - ${widget.destination}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedPickupPoint != null)
            IconButton(
              onPressed: () {
                Navigator.pop(context, _selectedPickupPoint);
              },
              icon: const Icon(Icons.check),
              tooltip: 'Confirmar punto de recogida',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando ruta...'),
                ],
              ),
            )
          : Column(
              children: [
                _buildRouteInfo(),
                Expanded(
                  child: Stack(
                    children: [
                      _buildMap(),
                      _buildPickupPointsList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRouteInfo() {
    if (_routePoints.isEmpty) return const SizedBox.shrink();

    final distance = RouteTracingService.calculateRouteDistance(_routePoints);
    final intermediateStops = RoutesData.getIntermediateStops(widget.origin, widget.destination);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: Colors.indigo[600]),
              const SizedBox(width: 8),
              Text(
                'Distancia: ${distance.toStringAsFixed(1)} km',
                style: TextStyle(
                  color: Colors.indigo[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${_pickupPoints.length} puntos de recogida',
                style: TextStyle(
                  color: Colors.indigo[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (intermediateStops.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Paradas: ${intermediateStops.join(', ')}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _routePoints.isNotEmpty ? _routePoints.first : const LatLng(1.2136, -77.2811),
        initialZoom: 10.0,
        minZoom: 8.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.proyecto_tu_flota',
        ),
        if (_routePoints.length > 1) _buildRouteLayer(),
        _buildPickupPointsLayer(),
      ],
    );
  }

  Widget _buildRouteLayer() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: _routePoints,
          strokeWidth: 4.0,
          color: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildPickupPointsLayer() {
    return MarkerLayer(
      markers: _pickupPoints.map((point) {
        final isSelected = _selectedPickupPoint?.id == point.id;
        final isOrigin = point.id == 'origin';
        
        return Marker(
          point: point.coordinates,
          width: isSelected ? 40 : 30,
          height: isSelected ? 40 : 30,
          child: GestureDetector(
            onTap: () => _selectPickupPoint(point),
            child: Container(
              decoration: BoxDecoration(
                color: isOrigin 
                    ? Colors.green 
                    : isSelected 
                        ? Colors.orange 
                        : point.isTerminal 
                            ? Colors.blue 
                            : Colors.purple,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white, 
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isOrigin 
                    ? Icons.my_location 
                    : point.isTerminal 
                        ? Icons.location_city 
                        : Icons.location_on,
                color: Colors.white,
                size: isSelected ? 20 : 16,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPickupPointsList() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.indigo[600], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Puntos de recogida',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedPickupPoint != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Seleccionado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _pickupPoints.length,
                itemBuilder: (context, index) {
                  final point = _pickupPoints[index];
                  final isSelected = _selectedPickupPoint?.id == point.id;
                  
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: point.id == 'origin' 
                            ? Colors.green 
                            : isSelected 
                                ? Colors.orange 
                                : point.isTerminal 
                                    ? Colors.blue 
                                    : Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        point.id == 'origin' 
                            ? Icons.my_location 
                            : point.isTerminal 
                                ? Icons.location_city 
                                : Icons.location_on,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    title: Text(
                      point.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.orange[700] : null,
                      ),
                    ),
                    subtitle: Text(
                      point.description,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: isSelected,
                    selectedTileColor: Colors.orange[50],
                    onTap: () => _selectPickupPoint(point),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}