import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/popular_routes_manager.dart';
import '../../../data/routes_data.dart';
import '../../../models/reserva_model.dart';
import '../../../controllers/auth_controller.dart';
import '../../auth/screens/login_screen.dart';
import 'seat_selection_screen.dart';
import 'chat_screen.dart';
import 'driver_tracking_screen.dart';
import '../../../services/reserva_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  int _selectedPassengers = 1;
  List<String> _selectedSeats = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Ticket'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(ticket: widget.ticket),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat con conductor',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTicketHeader(),
                  const SizedBox(height: 24),
                  _buildRouteDetails(),
                  const SizedBox(height: 24),
                  _buildBusDetails(),
                  const SizedBox(height: 24),
                  _buildAmenities(),
                  const SizedBox(height: 24),
                  _buildPassengerSelection(),
                  const SizedBox(height: 24),
                  _buildPriceBreakdown(),
                  if (!widget.ticket.isDirectRoute) ...[
                    const SizedBox(height: 24),
                    _buildStopsInfo(),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTicketHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.indigo[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.indigo,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ticket.companyName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.ticket.busType,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber[600],
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.ticket.rating}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ' (${widget.ticket.reviewCount} reseñas)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.ticket.formattedPrice,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    Text(
                      'por persona',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetails() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles del Viaje',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salida',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.ticket.departureTimeFormatted,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.ticket.origin,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(widget.ticket.departureTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.ticket.isDirectRoute
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.ticket.isDirectRoute
                            ? 'Directo'
                            : '${widget.ticket.stops.length} paradas',
                        style: TextStyle(
                          color: widget.ticket.isDirectRoute
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.ticket.duration,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Llegada',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.ticket.arrivalTimeFormatted,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.ticket.destination,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(widget.ticket.arrivalTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusDetails() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Bus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Tipo de Bus',
                    widget.ticket.busType,
                    Icons.directions_bus,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Asientos Disponibles',
                    '${widget.ticket.availableSeats}/${widget.ticket.totalSeats}',
                    Icons.event_seat,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.indigo,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Servicios Incluidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.ticket.amenities.map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.indigo[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAmenityIcon(amenity),
                        color: Colors.indigo,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        amenity,
                        style: TextStyle(
                          color: Colors.indigo[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'aire acondicionado':
        return Icons.ac_unit;
      case 'baño':
        return Icons.wc;
      case 'tv':
        return Icons.tv;
      case 'snacks':
        return Icons.fastfood;
      case 'asientos reclinables':
        return Icons.airline_seat_recline_normal;
      case 'mantas':
        return Icons.bed;
      default:
        return Icons.check_circle;
    }
  }

  Widget _buildPassengerSelection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Número de Pasajeros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Pasajeros:'),
                const Spacer(),
                IconButton(
                  onPressed: _selectedPassengers > 1
                      ? () => setState(() => _selectedPassengers--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_selectedPassengers',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _selectedPassengers < widget.ticket.availableSeats
                      ? () => setState(() => _selectedPassengers++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final subtotal = widget.ticket.price * _selectedPassengers;
    final taxes = subtotal * 0.19; // IVA 19%
    final total = subtotal + taxes;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Precios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Ticket x $_selectedPassengers'),
                const Spacer(),
                Text(
                  NumberFormat.currency(locale: 'es_CO', symbol: '\$').format(subtotal),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('IVA (19%)'),
                const Spacer(),
                Text(
                  NumberFormat.currency(locale: 'es_CO', symbol: '\$').format(taxes),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  NumberFormat.currency(locale: 'es_CO', symbol: '\$').format(total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paradas Intermedias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.ticket.stops.map((stop) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.orange[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      stop,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total para $_selectedPassengers pasajero${_selectedPassengers != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'es_CO', symbol: '\$')
                        .format((widget.ticket.price * _selectedPassengers) * 1.19),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedPassengers <= widget.ticket.availableSeats
                    ? _proceedToBooking
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Reservar ($_selectedPassengers ${_selectedPassengers == 1 ? 'pasajero' : 'pasajeros'})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToBooking() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
          ticket: widget.ticket,
          passengerCount: _selectedPassengers,
        ),
      ),
    );
    
    if (result != null) {
      _showBookingConfirmation(result);
    }
  }

  void _showBookingConfirmation(Map<String, dynamic> bookingData) {
    final selectedSeats = bookingData['selectedSeats'] as List<int>;
    final totalPrice = bookingData['totalPrice'] as double;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket: ${widget.ticket.companyName}'),
            Text('Ruta: ${widget.ticket.origin} → ${widget.ticket.destination}'),
            Text('Fecha: ${DateFormat('dd MMM yyyy').format(widget.ticket.departureTime)}'),
            Text('Hora: ${widget.ticket.departureTimeFormatted}'),
            Text('Asientos: ${selectedSeats.join(', ')}'),
            Text('Pasajeros: $_selectedPassengers'),
            const SizedBox(height: 8),
            Text(
              'Total: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$').format(totalPrice)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmBooking(selectedSeats, totalPrice);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _confirmBooking(List<int> selectedSeats, double totalPrice) async {
    try {
      // Obtener el usuario actual del AuthController
      final authController = Provider.of<AuthController>(context, listen: false);
      final currentUser = authController.user;
      final userProfile = authController.userProfile;
      
      if (currentUser == null) {
        // Usuario no autenticado, redirigir al login
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        
        // Si el usuario se autenticó exitosamente, intentar la reserva nuevamente
        if (result == true) {
          _confirmBooking(selectedSeats, totalPrice);
        }
        return;
      }

      // Crear reserva usando ReservaService (Supabase)
      final reservaService = ReservaService();
      
      final reserva = await reservaService.crearReserva(
        ReservaModel(
          id: '', // Se generará automáticamente
          viajeId: widget.ticket.id,
          usuarioId: currentUser.id, // ID real del usuario autenticado
          empresaId: widget.ticket.companyId ?? 'default_company',
          nombrePasajero: userProfile?.email.split('@')[0] ?? 'Pasajero',
          telefonoPasajero: '0000000000', // Campo por defecto hasta implementar perfil completo
          numeroAsientos: _selectedPassengers,
          asientosSeleccionados: selectedSeats.map((s) => s.toString()).toList(),
          precioTotal: totalPrice,
          precioFinal: totalPrice,
          estado: ReservaStatus.pendiente,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      // Registrar la reserva en el sistema de rutas populares
      PopularRoutesManager.recordBooking(widget.ticket.origin, widget.ticket.destination);
      
      _showBookingSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la reserva: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBookingSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('¡Reserva Exitosa!'),
          ],
        ),
        content: const Text(
          'Tu reserva ha sido confirmada. Recibirás un correo electrónico con los detalles de tu viaje.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Volver al Inicio'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openDriverTracking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Seguir Conductor'),
          ),
        ],
      ),
    );
  }

  void _openDriverTracking() {
    // Obtener coordenadas reales basadas en el origen y destino del ticket
    final originCoords = RoutesData.getDestinationCoordinates(widget.ticket.origin);
    final destinationCoords = RoutesData.getDestinationCoordinates(widget.ticket.destination);
    
    // Usar coordenadas por defecto si no se encuentran las específicas
    final defaultOrigin = originCoords ?? const LatLng(1.2136, -77.2811); // Pasto por defecto
    final defaultDestination = destinationCoords ?? const LatLng(0.8317, -77.6439); // Ipiales por defecto
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverTrackingScreen(
          tripId: widget.ticket.id,
          driverName: 'Carlos Rodríguez',
          driverPhone: '+57 300 123 4567',
          vehiclePlate: 'ABC-123',
          vehicleModel: 'Mercedes Sprinter 2020',
          origin: defaultOrigin,
          destination: defaultDestination,
          estimatedArrival: '15-20 min',
          originCityName: widget.ticket.origin,
          destinationCityName: widget.ticket.destination,
        ),
      ),
    );
  }
}