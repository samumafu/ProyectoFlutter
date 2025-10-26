import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../data/constants/narino_destinations.dart';

class MapSelectionScreen extends StatefulWidget {
  final String title;
  final LatLng? initialPosition;
  final bool showNarinoDestinations;

  const MapSelectionScreen({
    Key? key,
    required this.title,
    this.initialPosition,
    this.showNarinoDestinations = true,
  }) : super(key: key);

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedPosition;
  String _selectedAddress = '';
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  // Coordenadas del centro de Nariño, Colombia
  static const LatLng _narinoCenter = LatLng(1.2136, -77.2811);

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition ?? _narinoCenter;
    if (_selectedPosition != null) {
      _getAddressFromCoordinates(_selectedPosition!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedPosition != null)
            IconButton(
              onPressed: _confirmSelection,
              icon: const Icon(Icons.check),
              tooltip: 'Confirmar selección',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_searchResults.isNotEmpty) _buildSearchResults(),
          Expanded(
            child: Stack(
              children: [
                _buildMap(),
                _buildLocationInfo(),
                _buildMyLocationButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar ubicación en Nariño...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults.clear();
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: _searchLocation,
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      color: Colors.white,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return ListTile(
            leading: const Icon(Icons.location_on, color: Colors.indigo),
            title: Text(result['name']),
            subtitle: Text(result['region'] ?? ''),
            onTap: () => _selectSearchResult(result),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _selectedPosition ?? _narinoCenter,
        initialZoom: 10.0,
        minZoom: 8.0,
        maxZoom: 18.0,
        onTap: (tapPosition, point) => _onMapTap(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.proyecto_tu_flota',
        ),
        if (widget.showNarinoDestinations) _buildNarinoMarkersLayer(),
        if (_selectedPosition != null) _buildSelectedMarkerLayer(),
      ],
    );
  }

  Widget _buildNarinoMarkersLayer() {
    final destinations = NarinoDestinations.municipalities;
    
    return MarkerLayer(
      markers: destinations.map((destination) {
        // Coordenadas aproximadas para algunos municipios de Nariño
        final coordinates = _getDestinationCoordinates(destination);
        if (coordinates == null) return null;
        
        return Marker(
          point: coordinates,
          width: 30,
          height: 30,
          child: GestureDetector(
            onTap: () => _selectDestination(destination, coordinates),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.location_city,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        );
      }).where((marker) => marker != null).cast<Marker>().toList(),
    );
  }

  Widget _buildSelectedMarkerLayer() {
    return MarkerLayer(
      markers: [
        Marker(
          point: _selectedPosition!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    if (_selectedPosition == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ubicación seleccionada:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedAddress.isNotEmpty ? _selectedAddress : 'Cargando dirección...',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}, '
                'Lng: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: Colors.indigo,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _selectedPosition = point;
    });
    _getAddressFromCoordinates(point);
  }

  void _searchLocation(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    final destinations = NarinoDestinations.searchDestinations(query);
    setState(() {
      _searchResults = destinations.map((dest) => {
        'name': dest,
        'region': NarinoDestinations.getRegionForDestination(dest),
        'coordinates': _getDestinationCoordinates(dest),
      }).toList();
    });
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final coordinates = result['coordinates'] as LatLng?;
    if (coordinates != null) {
      setState(() {
        _selectedPosition = coordinates;
        _selectedAddress = result['name'];
        _searchResults.clear();
      });
      _searchController.clear();
      _mapController.move(coordinates, 14.0);
    }
  }

  void _selectDestination(String destination, LatLng coordinates) {
    setState(() {
      _selectedPosition = coordinates;
      _selectedAddress = destination;
    });
    _mapController.move(coordinates, 14.0);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      Position position = await Geolocator.getCurrentPosition();
      final currentLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedPosition = currentLocation;
      });

      _mapController.move(currentLocation, 15.0);
      _getAddressFromCoordinates(currentLocation);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _selectedAddress = [
            placemark.street,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country,
          ].where((element) => element != null && element.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Dirección no disponible';
      });
    }
  }

  void _confirmSelection() {
    if (_selectedPosition != null) {
      Navigator.pop(context, {
        'position': _selectedPosition,
        'address': _selectedAddress,
      });
    }
  }

  LatLng? _getDestinationCoordinates(String destination) {
    // Coordenadas aproximadas de algunos municipios de Nariño
    final coordinates = {
      'Pasto': const LatLng(1.2136, -77.2811),
      'Ipiales': const LatLng(0.8317, -77.6439),
      'Tumaco': const LatLng(1.8014, -78.7642),
      'Túquerres': const LatLng(1.0864, -77.6175),
      'Barbacoas': const LatLng(1.6667, -78.1500),
      'La Unión': const LatLng(1.6000, -77.1333),
      'Samaniego': const LatLng(1.3333, -77.5833),
      'Sandona': const LatLng(1.2833, -77.4667),
      'Consacá': const LatLng(1.2167, -77.5167),
      'Yacuanquer': const LatLng(1.1333, -77.4167),
      'Tangua': const LatLng(1.0333, -77.7500),
      'Funes': const LatLng(1.0167, -77.7167),
      'Guachucal': const LatLng(0.9833, -77.7667),
      'Cumbal': const LatLng(0.9167, -77.8000),
      'Ricaurte': const LatLng(1.2167, -78.1833),
    };

    return coordinates[destination];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}