import 'package:flutter/material.dart';
import '../services/ai_travel_service.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class AIRecommendationsWidget extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime? preferredDate;
  final int passengers;

  const AIRecommendationsWidget({
    Key? key,
    required this.origin,
    required this.destination,
    this.preferredDate,
    this.passengers = 1,
  }) : super(key: key);

  @override
  State<AIRecommendationsWidget> createState() => _AIRecommendationsWidgetState();
}

class _AIRecommendationsWidgetState extends State<AIRecommendationsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _recommendations = {};
  Map<String, dynamic> _flexibleSchedules = {};
  Map<String, dynamic> _innovativeSuggestions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAIRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAIRecommendations() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        AITravelService.getTravelRecommendations(
          origin: widget.origin,
          destination: widget.destination,
          preferredDate: widget.preferredDate,
          passengers: widget.passengers,
        ),
        AITravelService.getFlexibleSchedules(
          origin: widget.origin,
          destination: widget.destination,
          baseDate: widget.preferredDate,
        ),
        AITravelService.getInnovativeSuggestions(
          origin: widget.origin,
          destination: widget.destination,
        ),
      ]);

      setState(() {
        _recommendations = results[0];
        _flexibleSchedules = results[1];
        _innovativeSuggestions = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar recomendaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_isLoading) _buildLoadingWidget() else _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recomendaciones IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.origin} → ${widget.destination}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadAIRecommendations,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Generando recomendaciones inteligentes...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.indigo,
          tabs: const [
            Tab(
              icon: Icon(Icons.recommend, size: 20),
              text: 'Recomendaciones',
            ),
            Tab(
              icon: Icon(Icons.schedule, size: 20),
              text: 'Horarios',
            ),
            Tab(
              icon: Icon(Icons.lightbulb, size: 20),
              text: 'Innovador',
            ),
          ],
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRecommendationsTab(),
              _buildFlexibleSchedulesTab(),
              _buildInnovativeSuggestionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Mejores Horarios',
            Icons.access_time,
            _recommendations['bestTimes'] ?? [],
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Duración Estimada',
            Icons.timer,
            [_recommendations['duration'] ?? 'No disponible'],
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Rango de Precios',
            Icons.attach_money,
            [_recommendations['priceRange'] ?? 'No disponible'],
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Consejos de Equipaje',
            Icons.luggage,
            _recommendations['packingTips'] ?? [],
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Atracciones en Destino',
            Icons.place,
            _recommendations['attractions'] ?? [],
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildFlexibleSchedulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Días Más Económicos',
            Icons.calendar_today,
            _flexibleSchedules['cheapestDays'] ?? [],
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Mayor Disponibilidad',
            Icons.event_available,
            _flexibleSchedules['bestAvailability'] ?? [],
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Menos Tráfico',
            Icons.traffic,
            _flexibleSchedules['lessTraffic'] ?? [],
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildAlternativeDatesCard(),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Beneficios de Flexibilidad',
            Icons.trending_up,
            [_flexibleSchedules['flexibilityBenefits'] ?? 'No disponible'],
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildInnovativeSuggestionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Rutas Escénicas',
            Icons.landscape,
            _innovativeSuggestions['scenicRoutes'] ?? [],
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStopsCard(),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Experiencias Locales',
            Icons.local_activity,
            _innovativeSuggestions['localExperiences'] ?? [],
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Recomendaciones Gastronómicas',
            Icons.restaurant,
            _innovativeSuggestions['foodRecommendations'] ?? [],
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Consejos de Presupuesto',
            Icons.savings,
            [_innovativeSuggestions['budgetTips'] ?? 'No disponible'],
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<dynamic> items, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                // Agregar botón de reserva para ciertas recomendaciones
                if (title == 'Rango de Precios' || title == 'Días Más Económicos')
                  ElevatedButton.icon(
                    onPressed: () => _createBookingFromRecommendation(title, items),
                    icon: const Icon(Icons.book_online, size: 16),
                    label: const Text('Reservar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _createBookingFromRecommendation(String recommendationType, List<dynamic> items) async {
    try {
      // Crear una reserva basada en las recomendaciones de IA
      final booking = Booking(
        id: BookingService.generateBookingId(),
        origin: widget.origin,
        destination: widget.destination,
        departureDate: widget.preferredDate ?? DateTime.now().add(const Duration(days: 1)),
        departureTime: '08:00', // Hora por defecto
        selectedSeats: List.generate(widget.passengers, (index) => 'A${index + 1}'),
        totalPrice: _extractPriceFromRecommendation(items),
        pickupPointName: 'Terminal Principal',
        pickupPointDescription: 'Terminal de transporte de ${widget.origin}',
        pickupPointCoordinates: const LatLng(1.2136, -77.2811),
        bookingDate: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Guardar la reserva
      await BookingService.saveBooking(booking);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reserva desde IA Confirmada'),
            content: Text(
              'Has creado una reserva basada en las recomendaciones de IA:\n\n'
              'Ruta: ${widget.origin} → ${widget.destination}\n'
              'Fecha: ${DateFormat('dd/MM/yyyy').format(booking.departureDate)}\n'
              'Pasajeros: ${widget.passengers}\n'
              'Total estimado: \$${booking.totalPrice.toStringAsFixed(0)}\n\n'
              'Tu reserva ha sido guardada en "Mis Viajes".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _extractPriceFromRecommendation(List<dynamic> items) {
    // Intentar extraer un precio de las recomendaciones
    for (var item in items) {
      final text = item.toString().toLowerCase();
      final priceMatch = RegExp(r'\$?(\d+(?:,\d{3})*(?:\.\d{2})?)')
          .firstMatch(text);
      if (priceMatch != null) {
        final priceStr = priceMatch.group(1)?.replaceAll(',', '') ?? '50000';
        return double.tryParse(priceStr) ?? 50000.0;
      }
    }
    // Precio por defecto si no se encuentra ninguno
    return 50000.0;
  }

  Widget _buildAlternativeDatesCard() {
    final alternatives = _flexibleSchedules['alternativeDates'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Fechas Alternativas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...alternatives.map((alt) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alt['date'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          alt['reason'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ahorro: ${alt['savings'] ?? '0%'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsCard() {
    final stops = _innovativeSuggestions['interestingStops'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Paradas Interesantes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...stops.map((stop) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop['place'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.local_activity, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        stop['activity'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        stop['duration'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}