import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/schedule_model.dart';
import '../../models/vehicle_model.dart';
import '../../data/routes_data.dart';
import '../../data/popular_routes_manager.dart';
import '../../features/passenger/screens/route_map_screen.dart';
import '../../services/route_tracing_service.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../controllers/auth_controller.dart';
import '../../features/auth/screens/login_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Schedule schedule;
  final int passengers;

  const SeatSelectionScreen({
    Key? key,
    required this.schedule,
    required this.passengers,
  }) : super(key: key);

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<String> selectedSeats = [];
  PickupPoint? selectedPickupPoint;
  
  @override
  Widget build(BuildContext context) {
    final totalPrice = selectedSeats.length * widget.schedule.price;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Asientos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Información del viaje
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.schedule.route.origin} → ${widget.schedule.route.destination}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.schedule.vehicle.brand} ${widget.schedule.vehicle.model} - ${widget.schedule.vehicle.vehicleClass.name}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(widget.schedule.departureTime),
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Selecciona ${widget.passengers} asiento(s)',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Leyenda
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.green, 'Disponible'),
                _buildLegendItem(Colors.blue, 'Seleccionado'),
                _buildLegendItem(Colors.red, 'Ocupado'),
              ],
            ),
          ),
          
          // Mapa de asientos
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildSeatMap(),
            ),
          ),
          
          // Información de selección y botón de continuar
          Container(
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Asientos seleccionados: ${selectedSeats.length}/${widget.passengers}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${NumberFormat('#,###').format(totalPrice)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Selección de punto de recogida
                if (selectedSeats.length == widget.passengers) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.indigo.shade600, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Punto de recogida',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (selectedPickupPoint != null) ...[
                          Text(
                            selectedPickupPoint!.name,
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            selectedPickupPoint!.description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'Selecciona un punto de recogida en el mapa',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _selectPickupPoint,
                            icon: const Icon(Icons.map),
                            label: Text(selectedPickupPoint != null ? 'Cambiar punto' : 'Seleccionar punto'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.indigo,
                              side: const BorderSide(color: Colors.indigo),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: selectedSeats.length == widget.passengers && selectedPickupPoint != null
                        ? _proceedToBooking
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _getButtonText(),
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
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildSeatMap() {
    final seatLayout = widget.schedule.vehicle.seatLayout;
    
    return Column(
      children: [
        // Conductor
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drive_eta, size: 16),
                    SizedBox(width: 4),
                    Text('Conductor'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Asientos
        ...seatLayout.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final row = entry.value;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.asMap().entries.map((seatEntry) {
                final colIndex = seatEntry.key;
                final seatId = seatEntry.value;
                
                if (seatId == null) {
                  // Espacio vacío (pasillo)
                  return const SizedBox(width: 40);
                }
                
                final isAvailable = widget.schedule.availableSeats.contains(seatId);
                final isSelected = selectedSeats.contains(seatId);
                final isOccupied = widget.schedule.reservedSeats.contains(seatId);
                
                Color seatColor;
                if (isSelected) {
                  seatColor = Colors.blue;
                } else if (isOccupied) {
                  seatColor = Colors.red;
                } else if (isAvailable) {
                  seatColor = Colors.green;
                } else {
                  // Asiento no disponible por otras razones
                  seatColor = Colors.grey;
                }
                
                return GestureDetector(
                  onTap: isAvailable ? () => _toggleSeat(seatId) : null,
                  child: Container(
                    width: 35,
                    height: 35,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: seatColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        seatId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _toggleSeat(String seatId) {
    setState(() {
      if (selectedSeats.contains(seatId)) {
        selectedSeats.remove(seatId);
      } else {
        if (selectedSeats.length < widget.passengers) {
          selectedSeats.add(seatId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Solo puedes seleccionar ${widget.passengers} asiento(s)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  void _proceedToBooking() {
    // Por ahora mostrar confirmación, luego implementar sistema de reserva
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Reserva'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ruta: ${widget.schedule.route.origin} → ${widget.schedule.route.destination}'),
              Text('Fecha: ${DateFormat('dd/MM/yyyy').format(widget.schedule.departureTime)}'),
              Text('Hora: ${DateFormat('HH:mm').format(widget.schedule.departureTime)}'),
              Text('Asientos: ${selectedSeats.join(', ')}'),
              if (selectedPickupPoint != null)
                Text('Punto de recogida: ${selectedPickupPoint!.name}'),
              Text('Total: \$${NumberFormat('#,###').format(selectedSeats.length * widget.schedule.price)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmBooking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  String _getButtonText() {
    if (selectedSeats.length < widget.passengers) {
      return 'Selecciona ${widget.passengers - selectedSeats.length} asiento(s) más';
    } else if (selectedPickupPoint == null) {
      return 'Selecciona punto de recogida';
    } else {
      return 'Continuar con la Reserva';
    }
  }

  void _selectPickupPoint() async {
    final result = await Navigator.push<PickupPoint>(
      context,
      MaterialPageRoute(
        builder: (context) => RouteMapScreen(
          origin: widget.schedule.route.origin,
          destination: widget.schedule.route.destination,
          onPickupPointSelected: (point) {
            setState(() {
              selectedPickupPoint = point;
            });
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        selectedPickupPoint = result;
      });
    }
  }

  void _confirmBooking() async {
    // Verificar autenticación antes de proceder
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUser = authController.currentUser;
    
    if (currentUser == null) {
      // Usuario no autenticado, redirigir al login
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      
      // Si el usuario se autenticó exitosamente, intentar la reserva nuevamente
      if (result == true) {
        _confirmBooking();
      }
      return;
    }

    // Crear la reserva
    final booking = Booking(
      id: BookingService.generateBookingId(),
      origin: widget.schedule.route.origin,
      destination: widget.schedule.route.destination,
      departureDate: widget.schedule.departureTime,
      departureTime: DateFormat('HH:mm').format(widget.schedule.departureTime),
      selectedSeats: selectedSeats,
      totalPrice: selectedSeats.length * widget.schedule.price,
      pickupPointName: selectedPickupPoint?.name ?? 'No especificado',
      pickupPointDescription: selectedPickupPoint?.description ?? 'No especificado',
      pickupPointCoordinates: selectedPickupPoint?.coordinates ?? 
          RoutesData.getDestinationCoordinates(widget.schedule.route.origin)!,
      bookingDate: DateTime.now(),
    );

    // Guardar la reserva en el historial
    await BookingService.saveBooking(booking);
    
    // Registrar la reserva en el sistema de rutas populares
    PopularRoutesManager.recordBooking(
      widget.schedule.route.origin, 
      widget.schedule.route.destination
    );
    
    // Mostrar mensaje de éxito y regresar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Reserva confirmada y guardada en el historial!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Regresar a la pantalla anterior
    Navigator.pop(context);
  }
}