import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/passenger/controllers/passenger_controller.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/core/services/supabase_service.dart';

// Definiciones de estilo
const Color _primaryColor = Color(0xFF1E88E5);
const Color _accentColor = Color(0xFF00C853);
const Color _reservedColor = Color(0xFFC62828);
const Color _selectedColor = Color(0xFF43A047);
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
  // Los asientos ocupados deben cargarse del controlador (simulación por ahora)
  final List<int> _mockReservedSeats = [3, 4, 10, 11]; 

  @override
  void initState() {
    super.initState();
    // Aseguramos que el objeto sea el modelo CompanySchedule
    _s = widget.schedule as CompanySchedule;
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
    
    // Lógica para seleccionar/deseleccionar puestos disponibles
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

  Future<void> _reserve() async {
    final seats = _selectedSeats.length;
    
    if (seats == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona al menos un puesto.')));
      }
      return;
    }

    try {
      await ref.read(passengerControllerProvider.notifier).reserveSeats(schedule: _s, seats: seats);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.success} - Puestos: ${_selectedSeats.join(', ')}'), backgroundColor: _accentColor));
      Navigator.pushNamedAndRemoveUntil(context, '/passenger/dashboard', (route) => false);
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

  @override
  Widget build(BuildContext context) {
    final totalPrice = _s.price * _selectedSeats.length;
    final totalSeats = _s.totalSeats; 

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
          onPressed: _reserve,
          icon: const Icon(Icons.check_circle_outline),
          label: Text('RESERVAR ${_selectedSeats.length} PUESTO(S) | \$${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
            _detailRow(Icons.schedule, 'Departure Time', _s.departureTime),
            _detailRow(Icons.access_time, 'Arrival Time', _s.arrivalTime),
            // ✅ USANDO EL CAMPO vehicleType DEL MODELO
            _detailRow(Icons.directions_bus, 'Vehicle Type', _s.vehicleType ?? 'N/A'),
            // ✅ USANDO EL CAMPO vehicleId DEL MODELO (Placa/ID)
            _detailRow(Icons.badge, 'Vehicle ID', _s.vehicleId ?? 'N/A'),
            // 🚨 El nombre del conductor NO existe en el modelo, lo marcamos como no vinculado
            _detailRow(Icons.person_pin, 'Driver Name', 'Not Linked (N/A)'), 
            const Divider(height: 25),
            _detailRow(Icons.money, 'Price per seat', '\$${_s.price.toStringAsFixed(2)}'),
            // ✅ USANDO availableSeats y totalSeats del modelo
            _detailRow(Icons.event_seat, 'Seats / Total', '${_s.availableSeats} / $totalSeats'),
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
    // Definimos 4 asientos por fila (layout común de bus)
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
          child: const Text('Driver', style: TextStyle(fontSize: 10)),
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
                    if (seatNumber > totalSeats) return const SizedBox.shrink(); // Oculta si el asiento excede el total

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