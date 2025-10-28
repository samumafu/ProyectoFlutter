import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';
import '../../../services/route_tracing_service.dart';
import '../../../data/routes_data.dart';

class DriverTrackingScreen extends StatefulWidget {
  final String tripId;
  final String driverName;
  final String driverPhone;
  final String vehiclePlate;
  final String vehicleModel;
  final LatLng origin;
  final LatLng destination;
  final String estimatedArrival;
  final String? originName;
  final String? destinationName;

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
    this.originName,
    this.destinationName,
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
      // Usar nombres proporcionados o obtener nombres desde las coordenadas
      String originName = widget.originName ?? _getCityNameFromCoords(widget.origin) ?? 'Origen';
      String destinationName = widget.destinationName ?? _getCityNameFromCoords(widget.destination) ?? 'Destino';
      
      print('Cargando ruta real de OpenStreetMap: $originName -> $destinationName');
      
      // Obtener ruta real de OpenStreetMap (sin fallbacks simulados)
      _routePoints = await RouteTracingService.traceRoute(originName, destinationName);
      
      if (_routePoints.isNotEmpty && _routePoints.length > 2) {
        print('Ruta real de OpenStreetMap cargada con ${_routePoints.length} puntos');
        setState(() {
          // Inicializar la posición del conductor en el primer punto de la ruta
          _driverLocation = _routePoints[0];
          _currentRouteIndex = 0;
        });
        
        // Centrar el mapa en la ruta completa después de un pequeño delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _centerMapOnRoute();
        });
      } else {
        throw Exception('Ruta vacía o insuficiente');
      }
    } catch (e) {
      print('Error cargando ruta real de OpenStreetMap: $e');
      
      // Mostrar error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando ruta: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      // Usar coordenadas básicas como último recurso
      setState(() {
        _routePoints = [widget.origin, widget.destination];
        _driverLocation = widget.origin;
        _currentRouteIndex = 0;
      });
    }
  }

  /// Genera una ruta de respaldo más realista
  /// NOTA: Este es solo un fallback de emergencia - se usa OpenStreetMap cuando está disponible
  List<LatLng> _generateEnhancedFallbackRoute(LatLng start, LatLng end) {
    List<LatLng> route = [start];
    
    // Calcular distancia total
    final totalDistance = _calculateDistance(start, end);
    
    // Número de puntos basado en la distancia (más puntos para rutas más largas)
    int numPoints = (totalDistance / 3).ceil().clamp(10, 40);
    
    // Generar puntos intermedios con curvas realistas
    for (int i = 1; i < numPoints; i++) {
      double t = i / numPoints;
      
      // Interpolación básica
      double lat = start.latitude + (end.latitude - start.latitude) * t;
      double lng = start.longitude + (end.longitude - start.longitude) * t;
      
      // Agregar variaciones para simular carreteras reales
      double latVariation = 0.003 * sin(t * pi * 3) * (t * (1 - t));
      double lngVariation = 0.002 * cos(t * pi * 2.5) * (t * (1 - t));
      
      // Variación adicional basada en la topografía estimada
      if (totalDistance > 100) { // Ruta larga, más curvas
        latVariation += 0.002 * sin(t * pi * 5) * (t * (1 - t));
        lngVariation += 0.0015 * cos(t * pi * 4) * (t * (1 - t));
      }
      
      route.add(LatLng(lat + latVariation, lng + lngVariation));
    }
    
    route.add(end);
    return route;
  }

  String? _getCityNameFromCoords(LatLng coords) {
    // Usar RoutesData para obtener coordenadas dinámicamente
    final cities = [
      'Pasto', 'Ipiales', 'Tumaco', 'Túquerres', 'Tangua', 'Popayán',
      'La Unión', 'Samaniego', 'Sandona', 'Consacá', 'Yacuanquer',
      'Chachagüí', 'Nariño', 'Ospina', 'Francisco Pizarro', 'Ricaurte',
      'Barbacoas', 'Magüí', 'Roberto Payán', 'Mallama', 'Piedrancha',
      'Santacruz', 'Providencia', 'Buesaco', 'Funes', 'Guachucal',
      'Cumbal', 'Aldana', 'Córdoba', 'Potosí', 'Gualmatán',
      'Contadero', 'Iles', 'Carlosama', 'Colón', 'San Pedro de Cartago',
      'La Florida', 'Imués', 'Cuaspud', 'Pupiales', 'Ancuyá',
      'Linares', 'Los Andes', 'Policarpa', 'Cumbitara', 'Leiva',
      'El Rosario', 'El Tambo', 'Arboleda', 'Belén', 'San Bernardo',
      'Albán', 'San Pablo', 'La Tola', 'El Charco', 'Mosquera',
      'Olaya Herrera', 'Santa Bárbara'
    ];
    
    // Encontrar la ciudad más cercana
    String? closestCity;
    double minDistance = double.infinity;
    
    for (final city in cities) {
      final cityCoords = RoutesData.getDestinationCoordinates(city);
      if (cityCoords != null) {
        final distance = _calculateDistance(coords, cityCoords);
        if (distance < minDistance) {
          minDistance = distance;
          closestCity = city;
        }
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
      if (_routePoints.isNotEmpty && _routePoints.length > 2) {
        // Mover el conductor a lo largo de la ruta real de OpenStreetMap
        final random = Random();
        final progressIncrement = 0.015 + random.nextDouble() * 0.025; // Movimiento más realista
        _progress = (_progress + progressIncrement).clamp(0.0, 1.0);
        
        // Calcular el índice en la ruta basado en el progreso
        final targetIndex = (_progress * (_routePoints.length - 1)).round();
        
        if (targetIndex < _routePoints.length) {
          _currentRouteIndex = targetIndex;
          _driverLocation = _routePoints[_currentRouteIndex];
        }
      } else {
        // Solo si no hay ruta real disponible (caso extremo)
        final random = Random();
        final progressIncrement = 0.02 + random.nextDouble() * 0.03;
        _progress = (_progress + progressIncrement).clamp(0.0, 1.0);
        
        // Movimiento lineal básico
        final lat = widget.origin.latitude + 
            (widget.destination.latitude - widget.origin.latitude) * _progress;
        final lng = widget.origin.longitude + 
            (widget.destination.longitude - widget.origin.longitude) * _progress;
        _driverLocation = LatLng(lat, lng);
      }
      
      // Actualizar estado del viaje basado en el progreso real
      if (_progress >= 0.95) {
        _tripStatus = 'Llegando';
        _estimatedTime = '1-2 min';
      } else if (_progress >= 0.8) {
        _tripStatus = 'Muy cerca';
        _estimatedTime = '3-5 min';
      } else if (_progress >= 0.6) {
        _tripStatus = 'Cerca';
        _estimatedTime = '8-12 min';
      } else {
        _tripStatus = 'En camino';
        // Calcular tiempo estimado basado en distancia restante
        final remainingDistance = _calculateDistance(_driverLocation, widget.destination);
        final estimatedMinutes = (remainingDistance / 0.8).round(); // Asumiendo 48 km/h promedio
        _estimatedTime = '${estimatedMinutes} min';
      }
    });
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

    // Agregar padding a los límites
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    // Centrar el mapa
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    
    // Calcular zoom apropiado basado en la distancia
    final distance = _calculateDistance(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    double zoom = 10.0;
    
    if (distance < 50) {
      zoom = 12.0;
    } else if (distance < 100) {
      zoom = 11.0;
    } else if (distance < 200) {
      zoom = 10.0;
    } else {
      zoom = 9.0;
    }
    
    _mapController.move(center, zoom);
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
        
        // Línea de ruta mejorada con mejor visualización
        PolylineLayer(
          polylines: [
            if (_routePoints.isNotEmpty && _routePoints.length > 2) ...[
              // Ruta completa en gris claro (más gruesa para mejor visibilidad)
              Polyline(
                points: _routePoints,
                strokeWidth: 8.0,
                color: Colors.grey.withOpacity(0.3),
              ),
              // Borde de la ruta completa para mejor definición
              Polyline(
                points: _routePoints,
                strokeWidth: 6.0,
                color: Colors.grey.withOpacity(0.6),
              ),
              if (_currentRouteIndex > 0)
                // Ruta recorrida en azul vibrante
                Polyline(
                  points: _routePoints.sublist(0, _currentRouteIndex + 1),
                  strokeWidth: 6.0,
                  color: Colors.indigo.withOpacity(0.9),
                ),
              if (_currentRouteIndex > 0)
                // Borde de la ruta recorrida para mejor visibilidad
                Polyline(
                  points: _routePoints.sublist(0, _currentRouteIndex + 1),
                  strokeWidth: 4.0,
                  color: Colors.indigo,
                ),
            ],
            if (_routePoints.isEmpty || _routePoints.length <= 2) ...[
              // Fallback a línea recta si no hay ruta cargada (con mejor estilo)
              Polyline(
                points: [widget.origin, _driverLocation, widget.destination],
                strokeWidth: 6.0,
                color: Colors.grey.withOpacity(0.4),
              ),
              Polyline(
                points: [widget.origin, _driverLocation],
                strokeWidth: 4.0,
                color: Colors.indigo.withOpacity(0.8),
              ),
            ],
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