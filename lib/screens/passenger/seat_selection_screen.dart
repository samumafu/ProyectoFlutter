import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/schedule_model.dart';
import '../../models/vehicle_model.dart';

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
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: selectedSeats.length == widget.passengers
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
                      selectedSeats.length == widget.passengers
                          ? 'Continuar con la Reserva'
                          : 'Selecciona ${widget.passengers - selectedSeats.length} asiento(s) más',
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
                final isOccupied = !isAvailable && !isSelected;
                
                Color seatColor;
                if (isSelected) {
                  seatColor = Colors.blue;
                } else if (isOccupied) {
                  seatColor = Colors.red;
                } else {
                  seatColor = Colors.green;
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

  void _confirmBooking() {
    // Mostrar mensaje de éxito y regresar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Reserva confirmada exitosamente!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Regresar a la pantalla anterior
    Navigator.pop(context);
  }
}