import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';
import '../../../services/route_tracing_service.dart';

class DriverTrackingScreen extends StatefulWidget {
  final String tripId;
  final String driverName;
  final String driverPhone;
  final String vehiclePlate;
  final String vehicleModel;
  final LatLng origin;
  final LatLng destination;
  final String estimatedArrival;

  const DriverTrackingScreen({
    Key? key,
    required this.tripId,
    required this.driverName,
    required this.driverPhone,
    required this.vehiclePlate,
    required this.vehicleModel,
    required this.origin,
    required this.destination,
    required this.estimatedArrival,
  }) : super(key: key);

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late LatLng _driverLocation;
  late Timer _locationTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  String _tripStatus = 'En camino';
  double _progress = 0.3;
  String _estimatedTime = '';
  
  // Nueva variable para almacenar la ruta real
  List<LatLng> _routePoints = [];
  int _currentRouteIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeDriverLocation();
    _loadRoute();
    _startLocationUpdates();
    _setupAnimations();
    _estimatedTime = widget.estimatedArrival;
  }

  void _initializeDriverLocation() {
    // Simular ubicación inicial del conductor entre origen y destino
    final lat = widget.origin.latitude + 
        (widget.destination.latitude - widget.origin.latitude) * 0.3;
    final lng = widget.origin.longitude + 
        (widget.destination.longitude - widget.origin.longitude) * 0.3;
    _driverLocation = LatLng(lat, lng);
  }

  Future<void> _loadRoute() async {
    try {
      // Obtener nombres de ciudades desde las coordenadas
      final originName = _getCityNameFromCoords(widget.origin);
      final destinationName = _getCityNameFromCoords(widget.destination);
      
      if (originName != null && destinationName != null) {
        _routePoints = await RouteTracingService.traceRoute(originName, destinationName);
        
        if (_routePoints.isNotEmpty) {
          // Inicializar la posición del conductor en el 30% de la ruta
          _currentRouteIndex = (_routePoints.length * 0.3).round();
          if (_currentRouteIndex < _routePoints.length) {
            _driverLocation = _routePoints[_currentRouteIndex];
          }
          setState(() {});
        }
      }
    } catch (e) {
      print('Error cargando ruta: $e');
      // Fallback a la línea recta si hay error
      _routePoints = [widget.origin, widget.destination];
    }
  }

  String? _getCityNameFromCoords(LatLng coords) {
    // Mapeo de coordenadas conocidas a nombres de ciudades
    const cityCoords = {
      'Pasto': LatLng(1.2136, -77.2811),
      'Ipiales': LatLng(0.8317, -77.6439),
      'Tumaco': LatLng(1.8014, -78.7642),
      'Túquerres': LatLng(1.0864, -77.6175),
      'Tangua': LatLng(1.0333, -77.7500),
      'Popayán': LatLng(2.4448, -76.6147),
    };
    
    // Encontrar la ciudad más cercana
    String? closestCity;
    double minDistance = double.infinity;
    
    for (final entry in cityCoords.entries) {
      final distance = _calculateDistance(coords, entry.value);
      if (distance < minDistance) {
        minDistance = distance;
        closestCity = entry.key;
      }
    }
    
    return minDistance < 50 ? closestCity : null; // 50km de tolerancia
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Radio de la Tierra en km
    final double lat1Rad = point1.latitude * (pi / 180);
    final double lat2Rad = point2.latitude * (pi / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateDriverLocation();
    });
  }

  void _updateDriverLocation() {
    setState(() {
      if (_routePoints.isNotEmpty) {
        // Mover el conductor a lo largo de la ruta real
        final random = Random();
        final progressIncrement = 0.02 + random.nextDouble() * 0.03;
        _progress = (_progress + progressIncrement).clamp(0.0, 1.0);
        
        // Calcular el índice en la ruta basado en el progreso
        final targetIndex = (_progress * (_routePoints.length - 1)).round();
        
        if (targetIndex < _routePoints.length) {
          _currentRouteIndex = targetIndex;
          _driverLocation = _routePoints[_currentRouteIndex];
        }
      } else {
        // Fallback al método anterior si no hay ruta cargada
        final random = Random();
        final progressIncrement = 0.02 + random.nextDouble() * 0.03;
        _progress = (_progress + progressIncrement).clamp(0.0, 1.0);
        
        // Actualizar ubicación del conductor
        final lat = widget.origin.latitude + 
            (widget.destination.latitude - widget.origin.latitude) * _progress;
        final lng = widget.origin.longitude + 
            (widget.destination.longitude - widget.origin.longitude) * _progress;
        _driverLocation = LatLng(lat, lng);
      }
      
      // Actualizar estado del viaje
      if (_progress >= 0.95) {
        _tripStatus = 'Llegando';
        _estimatedTime = '1-2 min';
      } else if (_progress >= 0.7) {
        _tripStatus = 'Cerca';
        _estimatedTime = '5-8 min';
      } else {
        _tripStatus = 'En camino';
      }
    });
  }

  @override
  void dispose() {
    _locationTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento del Conductor'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: _callDriver,
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: _messageDriver,
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del viaje
          _buildTripInfo(),
          
          // Mapa
          Expanded(
            child: _buildMap(),
          ),
          
          // Panel inferior con información del conductor
          _buildDriverPanel(),
        ],
      ),
    );
  }

  Widget _buildTripInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tripStatus,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  Text(
                    'Tiempo estimado: $_estimatedTime',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_progress * 100).toInt()}% completado',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _driverLocation,
        initialZoom: 14.0,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: [
            // Marcador de origen
            Marker(
              point: widget.origin,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            
            // Marcador de destino
            Marker(
              point: widget.destination,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            
            // Marcador del conductor con animación
            Marker(
              point: _driverLocation,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            spreadRadius: 5,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        
        // Línea de ruta
        PolylineLayer(
          polylines: [
            if (_routePoints.isNotEmpty)
              Polyline(
                points: _routePoints,
                strokeWidth: 4.0,
                color: Colors.indigo.withOpacity(0.7),
              )
            else
              // Fallback a línea recta si no hay ruta cargada
              Polyline(
                points: [widget.origin, _driverLocation, widget.destination],
                strokeWidth: 4.0,
                color: Colors.indigo.withOpacity(0.7),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.indigo.shade100,
                child: Text(
                  widget.driverName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.driverName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.vehicleModel} - ${widget.vehiclePlate}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        const Text('4.8'),
                        const SizedBox(width: 8),
                        Text(
                          '(127 viajes)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _callDriver,
                  icon: const Icon(Icons.phone),
                  label: const Text('Llamar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _messageDriver,
                  icon: const Icon(Icons.message),
                  label: const Text('Mensaje'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _callDriver() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Llamar al Conductor'),
        content: Text('¿Deseas llamar a ${widget.driverName}?\n${widget.driverPhone}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí se implementaría la llamada real
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Iniciando llamada...')),
              );
            },
            child: const Text('Llamar'),
          ),
        ],
      ),
    );
  }

  void _messageDriver() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Mensaje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enviar mensaje rápido a ${widget.driverName}:'),
            const SizedBox(height: 16),
            ...['Ya estoy listo', 'Llego en 5 minutos', 'Estoy en el punto de encuentro']
                .map((message) => ListTile(
                      title: Text(message),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Mensaje enviado: $message')),
                        );
                      },
                    )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}