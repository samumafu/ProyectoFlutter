import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/passenger/controllers/passenger_controller.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/core/services/supabase_service.dart';

import 'package:latlong2/latlong.dart';
import 'package:tu_flota/core/constants/route_coordinates.dart';
import 'package:intl/intl.dart';

// Style Definitions
const Color _primaryColor = Color(0xFF1E88E5);
const Color _accentColor = Color(0xFF00C853);
const Color _reservedColor = Color(0xFFC62828);
const Color _selectedColor = Color(0xFF43A047);
const Color _warningColor = Color(0xFFF9A825);
const Color _availableColor = Color(0xFFE3F2FD);

// Data structure for top destinations
class TopDestination {
  final String city;
  final String imageUrl;
  TopDestination(this.city, this.imageUrl);
}

class PassengerTripDetailScreen extends ConsumerStatefulWidget {
  final Object? schedule;
  const PassengerTripDetailScreen({super.key, this.schedule});

  @override
  ConsumerState<PassengerTripDetailScreen> createState() => _PassengerTripDetailScreenState();
}

class _PassengerTripDetailScreenState extends ConsumerState<PassengerTripDetailScreen> {
  late final CompanySchedule _schedule;
  
  // Seat selection variables
  final Set<int> _selectedSeats = {};
  final List<int> _mockReservedSeats = [3, 4, 10, 11]; // Mock reserved seats
  
  // State: User selected pickup point
  LatLng? _pickupPoint; 
  
  // Mock data for top destinations (URLs from previous context)
  final List<TopDestination> _topDestinations = [
    TopDestination('Pasto', 'https://iemghgzismoncmirtkyy.supabase.co/storage/v1/object/public/destinos/Pasto.webp'), 
    TopDestination('Cali', 'https://picsum.photos/id/10/200/150'), 
    TopDestination('Medellín', 'https://picsum.photos/id/25/200/150'), 
    TopDestination('Bogotá', 'https://picsum.photos/id/50/200/150'), 
  ];

  // Helper to format time (handles String or DateTime)
  String _formatTime(dynamic timeValue) {
    DateTime date;
    
    if (timeValue is DateTime) {
      date = timeValue;
    } else if (timeValue is String) {
      try {
        // Try to parse the full ISO 8601 string
        date = DateTime.parse(timeValue);
      } catch (e) {
        // If it fails (e.g., only "17:30:00"), assume time and add a base date
        try {
           date = DateTime.parse('2000-01-01T$timeValue');
        } catch (_) {
           return timeValue; // Return the string unparsed if everything fails
        }
      }
    } else {
      return 'N/A'; // If it's neither String nor DateTime
    }
    
    // Format the resulting DateTime object to HH:mm
    return DateFormat('HH:mm').format(date);
  }

  @override
  void initState() {
    super.initState();
    _schedule = widget.schedule as CompanySchedule;
  }
  
  // --- Pickup Point Selection Logic ---
  Future<void> _navigateToMapAndSelectPickup() async {
    final LatLng originCoords = getCoordinates(_schedule.origin);
    final LatLng destinationCoords = getCoordinates(_schedule.destination);

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
  
  // --- Reservation Logic ---
  Future<void> _reserve() async {
    final seats = _selectedSeats.length;
    
    if (seats == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona al menos un puesto.')));
      }
      return;
    }
    
    // Step 1: Check if pickup point has been selected
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


    // Step 2: Process the reservation (only reached if _pickupPoint != null)
    try {
      // NOTE: You need to pass the pickup location data here when you implement the service function.
      // For now, only passing seats as in the original code:
      await ref.read(passengerControllerProvider.notifier).reserveSeats(schedule: _schedule, seats: seats);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.success} - Puestos: ${_selectedSeats.join(', ')}'), backgroundColor: _accentColor));
      
      // Navigate back to the dashboard/home
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
        final available = _schedule.availableSeats;
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
    final totalPrice = _schedule.price * _selectedSeats.length;
    final totalSeats = _schedule.totalSeats; 
    
    // Dynamic text for the main button
    final buttonText = _pickupPoint == null 
        ? 'SELECCIONAR PUNTO DE RECOGIDA' 
        : 'RESERVAR ${_selectedSeats.length} PUESTO(S) | \$${totalPrice.toStringAsFixed(2)}';
    
    // Dynamic color for the main button
    final buttonColor = _pickupPoint == null ? _warningColor : _accentColor;
    
    // Dynamic action for the main button
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
            final pickupDisplayWidget = _buildPickupDisplay(context);
            final topDestinationsWidget = _buildTopDestinations(context);
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: Column(
                          children: [
                            tripDetailsWidget,
                            const SizedBox(height: 20),
                            pickupDisplayWidget,
                            const SizedBox(height: 20),
                            topDestinationsWidget, // Added for wide screens
                          ],
                        )),
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
                          // ⬅️ Resolución de conflicto: Mantener el widget de detalles y el padding para pantallas estrechas.
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: tripDetailsWidget),
                          
                          // Mostrar el punto de recogida seleccionado
                          pickupDisplayWidget,
                          
                          const SizedBox(height: 20),
                          topDestinationsWidget, // Added for narrow screens
                          const SizedBox(height: 20),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
          // Reservation is enabled only if seats are selected OR if we are in the pickup selection step
          onPressed: (_selectedSeats.isNotEmpty || _pickupPoint == null) ? buttonAction : null, 
          // Use dynamic text and color
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
  
  // --- NEW WIDGET: Top Destinations with Images ---
  Widget _buildTopDestinations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Destinos Más Buscados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: _primaryColor),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150, // Height for the horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _topDestinations.length,
            itemBuilder: (context, index) {
              final destination = _topDestinations[index];
              return Padding(
                padding: EdgeInsets.only(right: index == _topDestinations.length - 1 ? 0 : 12),
                child: _buildDestinationCard(destination.city, destination.imageUrl),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildDestinationCard(String city, String imageUrl) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported, color: Colors.black38),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      color: _primaryColor,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              city,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Widget to display the selected pickup point
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

  // Widget for trip details
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
                    '${_schedule.origin} → ${_schedule.destination}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            // Time formatting applied here
            _detailRow(Icons.schedule, 'Hora de Salida', _formatTime(_schedule.departureTime)),
            _detailRow(Icons.access_time, 'Hora de Llegada', _formatTime(_schedule.arrivalTime)),
            _detailRow(Icons.directions_bus, 'Tipo de Vehículo', _schedule.vehicleType ?? 'N/A'),
            _detailRow(Icons.badge, 'Placa del Vehículo', _schedule.vehicleId ?? 'N/A'),
            _detailRow(Icons.person_pin, 'Nombre del Conductor', 'N/A'), 
            const Divider(height: 25),
            _detailRow(Icons.money, 'Precio por Puesto', '\$${_schedule.price.toStringAsFixed(2)}'),
            _detailRow(Icons.event_seat, 'Puestos Disponibles / Total', '${_schedule.availableSeats} / $totalSeats'),
          ],
        ),
      ),
    );
  }
  
  // Reusable detail row widget
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

  // Graphical seat selection widget
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
        // Driver cabin
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
        
        // Seats layout
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
                    final seatNumber = rowIndex * seatsPerRow + colIndex + 1;
                    
                    if (seatNumber > totalSeats) {
                      return const SizedBox.shrink(); // Hide extra seats
                    }

                    final isReserved = _mockReservedSeats.contains(seatNumber);
                    final isSelected = _selectedSeats.contains(seatNumber);
                    
                    Color seatColor;
                    if (isReserved) {
                      seatColor = _reservedColor;
                    } else if (isSelected) {
                      seatColor = _selectedColor;
                    } else {
                      seatColor = _availableColor;
                    }

                    return GestureDetector(
                      onTap: () => _toggleSeat(seatNumber),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: EdgeInsets.only(left: colIndex == 1 ? 20 : 0), // Aisle
                        decoration: BoxDecoration(
                          color: seatColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isReserved ? Colors.white : _primaryColor.withOpacity(0.5)),
                          boxShadow: [
                            if (isSelected) BoxShadow(color: _selectedColor.withOpacity(0.5), blurRadius: 4),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          seatNumber.toString(),
                          style: TextStyle(
                            color: isReserved ? Colors.white : (isSelected ? Colors.white : _primaryColor),
                            fontWeight: FontWeight.bold,
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
        
        // Legend
        _buildSeatLegend(),
      ],
    );
  }
  
  // Seat Legend Widget
  Widget _buildSeatLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendItem(_availableColor, 'Disponible'),
        _legendItem(_reservedColor, 'Reservado'),
        _legendItem(_selectedColor, 'Seleccionado'),
      ],
    );
  }
  
  // Reusable Legend Item
  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: _primaryColor.withOpacity(0.5)),
          ),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}