import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/passenger/controllers/passenger_controller.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/core/services/supabase_service.dart';

import 'package:latlong2/latlong.dart';
import 'package:tu_flota/core/constants/route_coordinates.dart';
import 'package:intl/intl.dart'; // Importación necesaria para DateFormat

// Definiciones de estilo
const Color _primaryColor = Color(0xFF1E88E5);
const Color _accentColor = Color(0xFF00C853);
const Color _reservedColor = Color(0xFFC62828);
const Color _selectedColor = Color(0xFF43A047);
const Color _warningColor = Color(0xFFF9A825); 
const Color _availableColor = Color(0xFFE3F2FD);

class PassengerTripDetailScreen extends ConsumerStatefulWidget {
  final Object? schedule;
  const PassengerTripDetailScreen({super.key, this.schedule});

  @override
  ConsumerState<PassengerTripDetailScreen> createState() => _PassengerTripDetailScreenState();
}

class _PassengerTripDetailScreenState extends ConsumerState<PassengerTripDetailScreen> {
  late final CompanySchedule _s;
  
  // Variables para la selección de puestos
  final Set<int> _selectedSeats = {};
  final List<int> _mockReservedSeats = [3, 4, 10, 11]; 
  
  // Estado: Punto de recogida seleccionado por el usuario
  LatLng? _pickupPoint; 

  // 🟢 HELPER ACTUALIZADO: Para formatear la hora, manejando String o DateTime
  String _formatTime(dynamic timeValue) {
    DateTime date;
    
    if (timeValue is DateTime) {
      date = timeValue;
    } else if (timeValue is String) {
      try {
        // Intenta parsear el string como un DateTime completo (ISO 8601)
        date = DateTime.parse(timeValue);
      } catch (e) {
        // Si falla (ej: solo es "17:30:00"), añade una fecha base para parsear solo el tiempo
        try {
           // Asume que la cadena es solo 'HH:mm:ss' o 'HH:mm' y añade una fecha.
           date = DateTime.parse('2000-01-01T$timeValue');
        } catch (_) {
           return timeValue; // Devuelve el string sin parsear si todo falla
        }
      }
    } else {
      return 'N/A'; // Si no es ni String ni DateTime
    }
    
    // Formatear el objeto DateTime resultante a HH:mm
    return DateFormat('HH:mm').format(date);
  }

  @override
  void initState() {
    super.initState();
    _s = widget.schedule as CompanySchedule;
  }
  
  // --- LÓGICA DE SELECCIÓN DE PUNTO DE RECOGIDA ---
  Future<void> _navigateToMapAndSelectPickup() async {
    final LatLng originCoords = getCoordinates(_s.origin);
    final LatLng destinationCoords = getCoordinates(_s.destination);

    final LatLng? selectedPickup = await Navigator.pushNamed(
      context, 
      '/passenger/map/route',
      arguments: {
        'origin': originCoords,
        'destination': destinationCoords,
      },
    ) as LatLng?;

    if (selectedPickup != null) {
      setState(() {
        _pickupPoint = selectedPickup;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Punto de recogida seleccionado. Ahora puedes reservar.'),
            backgroundColor: _accentColor,
            duration: Duration(milliseconds: 2000),
          ),
        );
      }
    }
  }
  
  // --- LÓGICA DE RESERVA MODIFICADA ---
  Future<void> _reserve() async {
    final seats = _selectedSeats.length;
    
    if (seats == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona al menos un puesto.')));
      }
      return;
    }
    
    // PASO 1: Verificar si el punto de recogida ha sido seleccionado
    if (_pickupPoint == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Importante! Debes seleccionar un punto de recogida antes de reservar.'),
            backgroundColor: _warningColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
      await _navigateToMapAndSelectPickup();
      return;
    }


    // PASO 2: Procesar la reserva (solo se llega aquí si _pickupPoint != null)
    try {
      await ref.read(passengerControllerProvider.notifier).reserveSeats(schedule: _s, seats: seats);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.success} - Puestos: ${_selectedSeats.join(', ')}'), backgroundColor: _accentColor));
      
      // Navegación de vuelta al dashboard/home
      Navigator.pop(context);
      
    } catch (_) {
      if (!mounted) return;
      final err = ref.read(passengerControllerProvider).error ?? AppStrings.actionFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: _reservedColor));
      final client = ref.read(supabaseProvider);
      if (client.auth.currentUser == null) {
        Navigator.pushNamed(context, '/auth/login');
      }
    }
  }
  
  void _toggleSeat(int seatNumber) {
    if (_mockReservedSeats.contains(seatNumber)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este puesto ya está reservado.'),
            backgroundColor: _reservedColor,
            duration: Duration(milliseconds: 1000),
          ),
        );
      }
      return; 
    }
    
    setState(() {
      if (_selectedSeats.contains(seatNumber)) {
        _selectedSeats.remove(seatNumber);
      } else {
        final available = _s.availableSeats;
        if (_selectedSeats.length >= available) {
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Solo quedan $available asientos disponibles.'),
                  backgroundColor: _reservedColor,
                  duration: const Duration(milliseconds: 1500),
                ),
              );
            }
            return;
        }
        
        _selectedSeats.add(seatNumber);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final totalPrice = _s.price * _selectedSeats.length;
    final totalSeats = _s.totalSeats; 
    
    // Texto dinámico para el botón principal
    final buttonText = _pickupPoint == null 
        ? 'SELECCIONAR PUNTO DE RECOGIDA' 
        : 'RESERVAR ${_selectedSeats.length} PUESTO(S) | \$${totalPrice.toStringAsFixed(2)}';
    
    // Color dinámico para el botón principal
    final buttonColor = _pickupPoint == null ? _warningColor : _accentColor;
    
    // Acción dinámica para el botón principal
    final VoidCallback buttonAction = _pickupPoint == null ? _navigateToMapAndSelectPickup : _reserve;


    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(AppStrings.tripDetail),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = 900.0;
            final isWide = constraints.maxWidth > maxContentWidth;
            final horizontalPadding = isWide ? (constraints.maxWidth - maxContentWidth) / 2 : 16.0;
            
            final seatSelectionWidget = _buildSeatSelection(context, totalSeats);
            final tripDetailsWidget = _buildTripDetails(context, totalSeats);
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: tripDetailsWidget),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                          child: seatSelectionWidget
                        )),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          tripDetailsWidget,
                          // Mostrar el punto de recogida seleccionado
                          if (_pickupPoint != null) 
                            _buildPickupDisplay(context),
                          
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                            child: seatSelectionWidget
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          // La reserva solo se activa si hay puestos seleccionados O si se está en el paso de seleccionar el punto de recogida
          onPressed: (_selectedSeats.isNotEmpty || _pickupPoint == null) ? buttonAction : null, 
          // Usar el texto y color dinámicos
          icon: Icon(_pickupPoint == null ? Icons.map : Icons.check_circle_outline),
          label: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
  
  // Widget para mostrar el punto de recogida seleccionado
  Widget _buildPickupDisplay(BuildContext context) {
    if (_pickupPoint == null) return const SizedBox.shrink();
    return Card(
      color: Colors.lightGreen.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _accentColor, width: 1.5)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: _accentColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Punto de Recogida Seleccionado:', style: TextStyle(fontWeight: FontWeight.bold, color: _accentColor)),
                  Text(
                    'Lat: ${_pickupPoint!.latitude.toStringAsFixed(4)}, Lng: ${_pickupPoint!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: _primaryColor),
              onPressed: _navigateToMapAndSelectPickup,
              tooltip: 'Cambiar punto de recogida',
            ),
          ],
        ),
      ),
    );
  }

  // Widget para los detalles del viaje
  Widget _buildTripDetails(BuildContext context, int totalSeats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: _primaryColor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_s.origin} → ${_s.destination}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            // CORRECCIÓN APLICADA AQUÍ: Se usa _formatTime para las horas
            _detailRow(Icons.schedule, 'Hora de Salida', _formatTime(_s.departureTime)),
            _detailRow(Icons.access_time, 'Hora de Llegada', _formatTime(_s.arrivalTime)),
            _detailRow(Icons.directions_bus, 'Tipo de Vehículo', _s.vehicleType ?? 'N/A'),
            _detailRow(Icons.badge, 'Placa del Vehículo', _s.vehicleId ?? 'N/A'),
            _detailRow(Icons.person_pin, 'Nombre del Conductor', 'N/A'), 
            const Divider(height: 25),
            _detailRow(Icons.money, 'Precio por Puesto', '\$${_s.price.toStringAsFixed(2)}'),
            _detailRow(Icons.event_seat, 'Puestos Disponibles / Total', '${_s.availableSeats} / $totalSeats'),
          ],
        ),
      ),
    );
  }
  
  // Fila de detalle reutilizable
  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryColor.withOpacity(0.8), size: 20),
          const SizedBox(width: 10),
          Text('$title:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(width: 5),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  // Widget de selección gráfica de asientos
  Widget _buildSeatSelection(BuildContext context, int totalSeats) {
    const int seatsPerRow = 4; 
    final int totalRows = (totalSeats / seatsPerRow).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Selecciona tus puestos (${_selectedSeats.length})', 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: _primaryColor)
        ),
        const SizedBox(height: 20),
        // Cabina del conductor
        Container(
          height: 30,
          width: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Conductor', style: TextStyle(fontSize: 10)),
        ),
        const SizedBox(height: 10),
        
        // Asientos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(totalRows, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(seatsPerRow, (colIndex) {
                    final seatNumber = (rowIndex * seatsPerRow) + colIndex + 1;
                    if (seatNumber > totalSeats) return const SizedBox.shrink();

                    final isReserved = _mockReservedSeats.contains(seatNumber);
                    final isSelected = _selectedSeats.contains(seatNumber);

                    Color bgColor;
                    if (isReserved) {
                      bgColor = _reservedColor;
                    } else if (isSelected) {
                      bgColor = _selectedColor;
                    } else {
                      bgColor = _availableColor;
                    }

                    return InkWell(
                      onTap: () => _toggleSeat(seatNumber),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? _primaryColor : Colors.grey.shade400, width: isSelected ? 2 : 1),
                        ),
                        child: Center(
                            child: Text(
                              seatNumber.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: isReserved || isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        // Leyenda
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(_availableColor, 'Disponible'),
        _legendItem(_selectedColor, 'Seleccionado'),
        _legendItem(_reservedColor, 'Reservado'),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}