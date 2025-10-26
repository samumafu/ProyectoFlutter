import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/ticket_model.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Datos de ejemplo para el historial de reservas
  final List<Booking> _upcomingBookings = [
    Booking(
      id: 'BK001',
      ticketId: 'TK001',
      userId: 'user123',
      passengerCount: 2,
      totalPrice: 120000,
      bookingDate: DateTime.now().subtract(const Duration(days: 2)),
      status: BookingStatus.confirmed,
      seatNumbers: ['A12', 'A13'],
      ticket: Ticket(
        id: 'TK001',
        routeId: 'route_001',
        companyId: 'comp_001',
        companyName: 'Expreso Bolivariano',
        companyLogo: '',
        origin: 'Bogotá',
        destination: 'Medellín',
        departureTime: DateTime.now().subtract(const Duration(days: 5)),
        arrivalTime: DateTime.now().subtract(const Duration(days: 5, hours: -8)),
        price: 85000,
        availableSeats: 0,
        totalSeats: 40,
        busType: 'Ejecutivo',
        amenities: ['WiFi', 'Aire Acondicionado', 'Baño'],
        rating: 4.5,
        reviewCount: 234,
        duration: '8h 30m',
        isDirectRoute: true,
        stops: [],
      ),
    ),
    Booking(
      id: 'BK002',
      ticketId: 'TK002',
      userId: 'user123',
      passengerCount: 1,
      totalPrice: 45000,
      bookingDate: DateTime.now().subtract(const Duration(days: 1)),
      status: BookingStatus.confirmed,
      seatNumbers: ['B08'],
      ticket: Ticket(
        id: 'TK002',
        routeId: 'route_002',
        companyId: 'comp_002',
        companyName: 'Copetran',
        companyLogo: '',
        origin: 'Cali',
        destination: 'Cartagena',
        departureTime: DateTime.now().subtract(const Duration(days: 15)),
        arrivalTime: DateTime.now().subtract(const Duration(days: 15, hours: -10)),
        price: 120000,
        availableSeats: 0,
        totalSeats: 45,
        busType: 'VIP',
        amenities: ['WiFi', 'Aire Acondicionado', 'Baño', 'Entretenimiento'],
        rating: 4.7,
        reviewCount: 189,
        duration: '10h 15m',
        isDirectRoute: false,
        stops: ['Buga', 'Pereira'],
      ),
    ),
  ];

  final List<Booking> _pastBookings = [
    Booking(
      id: 'BK003',
      ticketId: 'TK003',
      userId: 'user123',
      passengerCount: 1,
      totalPrice: 35000,
      bookingDate: DateTime.now().subtract(const Duration(days: 15)),
      status: BookingStatus.completed,
      seatNumbers: ['C05'],
      ticket: Ticket(
        id: 'TK003',
        routeId: 'route_003',
        companyId: 'comp_003',
        companyName: 'Flota Magdalena',
        companyLogo: '',
        origin: 'Medellín',
        destination: 'Bogotá',
        departureTime: DateTime.now().subtract(const Duration(days: 30)),
        arrivalTime: DateTime.now().subtract(const Duration(days: 30, hours: -9)),
        price: 75000,
        availableSeats: 0,
        totalSeats: 38,
        busType: 'Ejecutivo',
        amenities: ['WiFi', 'Aire Acondicionado'],
        rating: 4.2,
        reviewCount: 156,
        duration: '9h 00m',
        isDirectRoute: true,
        stops: [],
      ),
    ),
    Booking(
      id: 'BK004',
      ticketId: 'TK004',
      userId: 'user123',
      passengerCount: 2,
      totalPrice: 90000,
      bookingDate: DateTime.now().subtract(const Duration(days: 30)),
      status: BookingStatus.cancelled,
      seatNumbers: ['A01', 'A02'],
      ticket: Ticket(
        id: 'TK004',
        routeId: 'route_004',
        companyId: 'comp_004',
        companyName: 'Brasilia',
        companyLogo: '',
        origin: 'Barranquilla',
        destination: 'Santa Marta',
        departureTime: DateTime.now().subtract(const Duration(days: 45)),
        arrivalTime: DateTime.now().subtract(const Duration(days: 45, hours: -2)),
        price: 35000,
        availableSeats: 0,
        totalSeats: 42,
        busType: 'Corriente',
        amenities: ['Aire Acondicionado'],
        rating: 3.8,
        reviewCount: 98,
        duration: '2h 30m',
        isDirectRoute: true,
        stops: [],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Próximos Viajes'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingBookings(),
          _buildPastBookings(),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    if (_upcomingBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available,
        title: 'No tienes viajes próximos',
        subtitle: 'Busca y reserva tu próximo viaje',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _upcomingBookings.length,
      itemBuilder: (context, index) {
        final booking = _upcomingBookings[index];
        return _buildBookingCard(booking, isUpcoming: true);
      },
    );
  }

  Widget _buildPastBookings() {
    if (_pastBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No tienes historial de viajes',
        subtitle: 'Tus viajes anteriores aparecerán aquí',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pastBookings.length,
      itemBuilder: (context, index) {
        final booking = _pastBookings[index];
        return _buildBookingCard(booking, isUpcoming: false);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, {required bool isUpcoming}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildBookingHeader(booking),
          _buildRouteInfo(booking.ticket),
          _buildBookingDetails(booking),
          if (isUpcoming) _buildUpcomingActions(booking),
        ],
      ),
    );
  }

  Widget _buildBookingHeader(Booking booking) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (booking.status) {
      case BookingStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Confirmado';
        statusIcon = Icons.check_circle;
        break;
      case BookingStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        statusIcon = Icons.schedule;
        break;
      case BookingStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelado';
        statusIcon = Icons.cancel;
        break;
      case BookingStatus.completed:
        statusColor = Colors.blue;
        statusText = 'Completado';
        statusIcon = Icons.done_all;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reserva #${booking.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Reservado el ${DateFormat('dd/MM/yyyy').format(booking.bookingDate)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(Ticket ticket) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.origin,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ticket.departureTimeFormatted,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(
                Icons.arrow_forward,
                color: Colors.indigo,
                size: 24,
              ),
              Text(
                ticket.duration,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ticket.destination,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ticket.arrivalTimeFormatted,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.business, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(booking.ticket.companyName),
              const Spacer(),
              Icon(Icons.airline_seat_recline_normal, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text('${booking.passengerCount} ${booking.passengerCount == 1 ? 'pasajero' : 'pasajeros'}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event_seat, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text('Asientos: ${booking.seatNumbers.join(', ')}'),
              const Spacer(),
              Text(
                '\$${booking.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingActions(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showBookingDetails(booking),
              icon: const Icon(Icons.info_outline),
              label: const Text('Ver Detalles'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _cancelBooking(booking),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Detalles de la Reserva',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('Código de Reserva', booking.id),
                      _buildDetailItem('Fecha de Reserva', 
                        DateFormat('dd/MM/yyyy HH:mm').format(booking.bookingDate)),
                      _buildDetailItem('Empresa', booking.ticket.companyName),
                      _buildDetailItem('Tipo de Bus', booking.ticket.busType),
                      _buildDetailItem('Ruta', '${booking.ticket.origin} → ${booking.ticket.destination}'),
                      _buildDetailItem('Fecha de Viaje', 
                        DateFormat('EEEE, dd MMMM yyyy', 'es').format(booking.ticket.departureTime)),
                      _buildDetailItem('Hora de Salida', booking.ticket.departureTimeFormatted),
                      _buildDetailItem('Hora de Llegada', booking.ticket.arrivalTimeFormatted),
                      _buildDetailItem('Asientos', booking.seatNumbers.join(', ')),
                      _buildDetailItem('Pasajeros', '${booking.passengerCount}'),
                      _buildDetailItem('Total Pagado', '\$${booking.totalPrice.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar esta reserva? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                booking.status = BookingStatus.cancelled;
                _upcomingBookings.remove(booking);
                _pastBookings.insert(0, booking);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reserva cancelada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }
}