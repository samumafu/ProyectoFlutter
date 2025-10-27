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
      // Rutas desde Pasto
      Ticket(
        id: '1',
        routeId: 'route1',
        companyId: 'comp1',
        origin: 'Pasto',
        destination: 'Ipiales',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        arrivalTime: DateTime.now().add(const Duration(hours: 4)),
        price: 25000,
        availableSeats: 15,
        totalSeats: 40,
        companyName: 'Expreso Bolivariano',
        companyLogo: 'assets/logos/bolivariano.png',
        busType: 'Ejecutivo',
        amenities: ['WiFi', 'Aire Acondicionado', 'Baño', 'TV'],
        rating: 4.5,
        reviewCount: 234,
        isDirectRoute: true,
        duration: '2h 00m',
        stops: [],
      ),
      Ticket(
        id: '2',
        routeId: 'route2',
        companyId: 'comp2',
        origin: 'Pasto',
        destination: 'Tumaco',
        departureTime: DateTime.now().add(const Duration(hours: 3)),
        arrivalTime: DateTime.now().add(const Duration(hours: 8)),
        price: 45000,
        availableSeats: 8,
        totalSeats: 40,
        companyName: 'Copetran',
        companyLogo: 'assets/logos/copetran.png',
        busType: 'Económico',
        amenities: ['Aire Acondicionado', 'Baño'],
        rating: 4.2,
        reviewCount: 156,
        isDirectRoute: false,
        duration: '5h 00m',
        stops: ['Túquerres'],
      ),
      Ticket(
        id: '3',
        routeId: 'route3',
        companyId: 'comp3',
        origin: 'Pasto',
        destination: 'Túquerres',
        departureTime: DateTime.now().add(const Duration(hours: 1)),
        arrivalTime: DateTime.now().add(const Duration(hours: 2, minutes: 30)),
        price: 18000,
        availableSeats: 20,
        totalSeats: 35,
        companyName: 'Flota Magdalena',
        companyLogo: 'assets/logos/magdalena.png',
        busType: 'Económico',
        amenities: ['Aire Acondicionado'],
        rating: 4.0,
        reviewCount: 89,
        isDirectRoute: true,
        duration: '1h 30m',
        stops: [],
      ),
      // Rutas desde Ipiales
      Ticket(
        id: '4',
        routeId: 'route4',
        companyId: 'comp1',
        origin: 'Ipiales',
        destination: 'Pasto',
        departureTime: DateTime.now().add(const Duration(hours: 4)),
        arrivalTime: DateTime.now().add(const Duration(hours: 6)),
        price: 25000,
        availableSeats: 12,
        totalSeats: 40,
        companyName: 'Expreso Bolivariano',
        companyLogo: 'assets/logos/bolivariano.png',
        busType: 'Ejecutivo',
        amenities: ['WiFi', 'Aire Acondicionado', 'Baño', 'TV'],
        rating: 4.5,
        reviewCount: 234,
        isDirectRoute: true,
        duration: '2h 00m',
        stops: [],
      ),
      Ticket(
        id: '5',
        routeId: 'route5',
        companyId: 'comp4',
        origin: 'Ipiales',
        destination: 'Aldana',
        departureTime: DateTime.now().add(const Duration(hours: 2, minutes: 30)),
        arrivalTime: DateTime.now().add(const Duration(hours: 3, minutes: 15)),
        price: 12000,
        availableSeats: 18,
        totalSeats: 30,
        companyName: 'Transportes Nariño',
        companyLogo: 'assets/logos/narino.png',
        busType: 'Económico',
        amenities: ['Aire Acondicionado'],
        rating: 3.8,
        reviewCount: 67,
        isDirectRoute: true,
        duration: '45m',
        stops: [],
      ),
      // Rutas desde Tumaco
      Ticket(
        id: '6',
        routeId: 'route6',
        companyId: 'comp2',
        origin: 'Tumaco',
        destination: 'Pasto',
        departureTime: DateTime.now().add(const Duration(hours: 5)),
        arrivalTime: DateTime.now().add(const Duration(hours: 10)),
        price: 45000,
        availableSeats: 10,
        totalSeats: 40,
        companyName: 'Copetran',
        companyLogo: 'assets/logos/copetran.png',
        busType: 'Ejecutivo',
        amenities: ['WiFi', 'Aire Acondicionado', 'Baño'],
        rating: 4.3,
        reviewCount: 145,
        isDirectRoute: false,
        duration: '5h 00m',
        stops: ['Túquerres'],
      ),
      // Rutas desde Túquerres
      Ticket(
        id: '7',
        routeId: 'route7',
        companyId: 'comp3',
        origin: 'Túquerres',
        destination: 'Pasto',
        departureTime: DateTime.now().add(const Duration(hours: 6)),
        arrivalTime: DateTime.now().add(const Duration(hours: 7, minutes: 30)),
        price: 18000,
        availableSeats: 25,
        totalSeats: 35,
        companyName: 'Flota Magdalena',
        companyLogo: 'assets/logos/magdalena.png',
        busType: 'Económico',
        amenities: ['Aire Acondicionado'],
        rating: 4.0,
        reviewCount: 89,
        isDirectRoute: true,
        duration: '1h 30m',
        stops: [],
      ),
      Ticket(
        id: '8',
        routeId: 'route8',
        companyId: 'comp4',
        origin: 'Túquerres',
        destination: 'Ipiales',
        departureTime: DateTime.now().add(const Duration(hours: 3, minutes: 45)),
        arrivalTime: DateTime.now().add(const Duration(hours: 4, minutes: 30)),
        price: 15000,
        availableSeats: 14,
        totalSeats: 30,
        companyName: 'Transportes Nariño',
        companyLogo: 'assets/logos/narino.png',
        busType: 'Económico',
        amenities: ['Aire Acondicionado'],
        rating: 3.9,
        reviewCount: 78,
        isDirectRoute: true,
        duration: '45m',
        stops: [],
      ),
      // Rutas adicionales con otros municipios
      Ticket(
        id: '9',
        routeId: 'route9',
        companyId: 'comp5',
        origin: 'Samaniego',
        destination: 'Pasto',
        departureTime: DateTime.now().add(const Duration(hours: 7)),
        arrivalTime: DateTime.now().add(const Duration(hours: 9)),
        price: 22000,
        availableSeats: 16,
        totalSeats: 32,
        companyName: 'Cootransnariño',
        companyLogo: 'assets/logos/cootrans.png',
        busType: 'Económico',
        amenities: ['Aire Acondicionado', 'Baño'],
        rating: 4.1,
        reviewCount: 112,
        isDirectRoute: true,
        duration: '2h 00m',
        stops: [],
      ),
      Ticket(
        id: '10',
        routeId: 'route10',
        companyId: 'comp5',
        origin: 'Pasto',
        destination: 'La Unión',
        departureTime: DateTime.now().add(const Duration(hours: 8)),
        arrivalTime: DateTime.now().add(const Duration(hours: 10, minutes: 30)),
        price: 28000,
        availableSeats: 11,
        totalSeats: 32,
        companyName: 'Cootransnariño',
        companyLogo: 'assets/logos/cootrans.png',
        busType: 'Ejecutivo',
        amenities: ['WiFi', 'Aire Acondicionado', 'Baño'],
        rating: 4.2,
        reviewCount: 95,
        isDirectRoute: true,
        duration: '2h 30m',
        stops: [],
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