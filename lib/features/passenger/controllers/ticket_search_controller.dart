import 'package:flutter/material.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/models/route_model.dart';

class TicketSearchController extends ChangeNotifier {
  // Estado de búsqueda
  List<Ticket> _allTickets = [];
  List<Ticket> _filteredTickets = [];
  bool _isLoading = false;
  String? _error;

  // Filtros
  TicketFilter _currentFilter = TicketFilter();
  String _sortBy = 'price'; // price, departure, duration, rating

  // Getters
  List<Ticket> get filteredTickets => _filteredTickets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TicketFilter get currentFilter => _currentFilter;
  String get sortBy => _sortBy;

  // Datos de ejemplo
  final List<City> _cities = [
    City(
      id: '1',
      name: 'Bogotá',
      department: 'Cundinamarca',
      latitude: 4.7110,
      longitude: -74.0721,
      isActive: true,
    ),
    City(
      id: '2',
      name: 'Medellín',
      department: 'Antioquia',
      latitude: 6.2442,
      longitude: -75.5812,
      isActive: true,
    ),
    City(
      id: '3',
      name: 'Cali',
      department: 'Valle del Cauca',
      latitude: 3.4516,
      longitude: -76.5320,
      isActive: true,
    ),
    City(
      id: '4',
      name: 'Barranquilla',
      department: 'Atlántico',
      latitude: 10.9639,
      longitude: -74.7964,
      isActive: true,
    ),
    City(
      id: '5',
      name: 'Cartagena',
      department: 'Bolívar',
      latitude: 10.3910,
      longitude: -75.4794,
      isActive: true,
    ),
  ];

  List<City> get cities => _cities;

  // Inicializar datos de ejemplo
  void initializeSampleData() {
    _allTickets = [
      Ticket(
        id: '1',
        routeId: 'route1',
        companyId: 'comp1',
        origin: 'Bogotá',
        destination: 'Medellín',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        arrivalTime: DateTime.now().add(const Duration(hours: 10)),
        price: 85000,
        availableSeats: 15,
        totalSeats: 40,
        companyName: 'Expreso Bolivariano',
        companyLogo: 'assets/logos/bolivariano.png',
        busType: 'Ejecutivo',
        amenities: ['WiFi', 'Aire Acondicionado', 'Baño', 'TV'],
        rating: 4.5,
        reviewCount: 234,
        isDirectRoute: true,
        duration: '8h 00m',
        stops: [],
      ),
      Ticket(
        id: '2',
        routeId: 'route1',
        companyId: 'comp2',
        origin: 'Bogotá',
        destination: 'Medellín',
        departureTime: DateTime.now().add(const Duration(hours: 4)),
        arrivalTime: DateTime.now().add(const Duration(hours: 13)),
        price: 75000,
        availableSeats: 8,
        totalSeats: 40,
        companyName: 'Copetran',
        companyLogo: 'assets/logos/copetran.png',
        busType: 'Económico',
        amenities: ['Aire Acondicionado', 'Baño'],
        rating: 4.2,
        reviewCount: 156,
        isDirectRoute: false,
        duration: '9h 00m',
        stops: ['Girardot'],
      ),
      Ticket(
        id: '3',
        routeId: 'route2',
        companyId: 'comp3',
        origin: 'Bogotá',
        destination: 'Cali',
        departureTime: DateTime.now().add(const Duration(hours: 1)),
        arrivalTime: DateTime.now().add(const Duration(hours: 11)),
        price: 95000,
        availableSeats: 22,
        totalSeats: 45,
        companyName: 'Flota Magdalena',
        companyLogo: 'assets/logos/magdalena.png',
        busType: 'Premium',
        amenities: ['WiFi', 'Aire Acondicionado', 'Baño', 'TV', 'Snacks'],
        rating: 4.7,
        reviewCount: 189,
        isDirectRoute: true,
        duration: '10h 00m',
        stops: [],
      ),
      Ticket(
        id: '4',
        routeId: 'route3',
        companyId: 'comp4',
        origin: 'Medellín',
        destination: 'Cartagena',
        departureTime: DateTime.now().add(const Duration(hours: 6)),
        arrivalTime: DateTime.now().add(const Duration(hours: 19)),
        price: 120000,
        availableSeats: 5,
        totalSeats: 35,
        companyName: 'Brasilia',
        companyLogo: 'assets/logos/brasilia.png',
        busType: 'Ejecutivo',
        amenities: ['WiFi', 'Aire Acondicionado', 'Baño', 'TV', 'Cama'],
        rating: 4.6,
        reviewCount: 298,
        isDirectRoute: true,
        duration: '13h 00m',
        stops: [],
      ),
      Ticket(
        id: '5',
        routeId: 'route4',
        companyId: 'comp5',
        origin: 'Cali',
        destination: 'Barranquilla',
        departureTime: DateTime.now().add(const Duration(hours: 3)),
        arrivalTime: DateTime.now().add(const Duration(hours: 18)),
        price: 110000,
        availableSeats: 12,
        totalSeats: 40,
        companyName: 'Expreso Palmira',
        companyLogo: 'assets/logos/palmira.png',
        busType: 'Ejecutivo',
        amenities: ['WiFi', 'Aire Acondicionado', 'Baño', 'TV'],
        rating: 4.3,
        reviewCount: 167,
        isDirectRoute: false,
        duration: '15h 00m',
        stops: ['Montería'],
      ),
    ];
    _filteredTickets = List.from(_allTickets);
    notifyListeners();
  }

  // Buscar tickets
  Future<void> searchTickets({
    required String origin,
    required String destination,
    required DateTime departureDate,
    DateTime? returnDate,
    required int passengers,
    bool isRoundTrip = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simular llamada a API
      await Future.delayed(const Duration(seconds: 1));

      // Filtrar por origen y destino
      _filteredTickets = _allTickets.where((ticket) {
        return ticket.origin.toLowerCase().contains(origin.toLowerCase()) &&
               ticket.destination.toLowerCase().contains(destination.toLowerCase());
      }).toList();

      // Aplicar filtros adicionales
      _applyFilters();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al buscar tickets: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Aplicar filtros
  void applyFilter(TicketFilter filter) {
    _currentFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<Ticket> filtered = List.from(_allTickets);

    // Filtro por precio
    if (_currentFilter.minPrice != null) {
      filtered = filtered.where((ticket) => ticket.price >= _currentFilter.minPrice!).toList();
    }
    if (_currentFilter.maxPrice != null) {
      filtered = filtered.where((ticket) => ticket.price <= _currentFilter.maxPrice!).toList();
    }

    // Filtro por horario de salida
    if (_currentFilter.departureTimeRange != null) {
      filtered = filtered.where((ticket) {
        final hour = ticket.departureTime.hour;
        switch (_currentFilter.departureTimeRange) {
          case 'morning':
            return hour >= 6 && hour < 12;
          case 'afternoon':
            return hour >= 12 && hour < 18;
          case 'evening':
            return hour >= 18 && hour < 22;
          case 'night':
            return hour >= 22 || hour < 6;
          default:
            return true;
        }
      }).toList();
    }

    // Filtro por compañías
    if (_currentFilter.companies != null && _currentFilter.companies!.isNotEmpty) {
      filtered = filtered.where((ticket) => 
        _currentFilter.companies!.contains(ticket.companyName)
      ).toList();
    }

    // Filtro por rutas directas
    if (_currentFilter.directRouteOnly == true) {
      filtered = filtered.where((ticket) => ticket.isDirectRoute).toList();
    }

    // Filtro por amenidades
    if (_currentFilter.amenities != null && _currentFilter.amenities!.isNotEmpty) {
      filtered = filtered.where((ticket) {
        return _currentFilter.amenities!.every((amenity) => 
          ticket.amenities.contains(amenity)
        );
      }).toList();
    }

    _filteredTickets = filtered;
    _sortTickets();
  }

  // Ordenar tickets
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _sortTickets();
    notifyListeners();
  }

  void _sortTickets() {
    switch (_sortBy) {
      case 'price':
        _filteredTickets.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'departure':
        _filteredTickets.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
      case 'duration':
        // Comparar por duración como string
        _filteredTickets.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 'rating':
        _filteredTickets.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
  }

  // Obtener compañías disponibles
  List<String> getAvailableCompanies() {
    return _allTickets.map((ticket) => ticket.companyName).toSet().toList();
  }

  // Obtener tipos de bus disponibles
  List<String> getAvailableBusTypes() {
    return _allTickets.map((ticket) => ticket.busType).toSet().toList();
  }

  // Obtener amenidades disponibles
  List<String> getAvailableAmenities() {
    final Set<String> amenities = {};
    for (final ticket in _allTickets) {
      amenities.addAll(ticket.amenities);
    }
    return amenities.toList();
  }

  // Limpiar filtros
  void clearFilters() {
    _currentFilter = TicketFilter();
    _filteredTickets = List.from(_allTickets);
    _sortTickets();
    notifyListeners();
  }

  // Obtener rutas populares
  List<Map<String, String>> getPopularRoutes() {
    return [
      {'origin': 'Bogotá', 'destination': 'Medellín'},
      {'origin': 'Bogotá', 'destination': 'Cali'},
      {'origin': 'Medellín', 'destination': 'Cartagena'},
      {'origin': 'Cali', 'destination': 'Barranquilla'},
      {'origin': 'Bogotá', 'destination': 'Cartagena'},
    ];
  }
}