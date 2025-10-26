import 'package:flutter/material.dart';
import '../../../data/models/ticket_model.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Ticket ticket;
  final int passengerCount;

  const SeatSelectionScreen({
    super.key,
    required this.ticket,
    required this.passengerCount,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<int> selectedSeats = [];
  late List<SeatStatus> seatStatuses;
  
  @override
  void initState() {
    super.initState();
    _initializeSeats();
  }

  void _initializeSeats() {
    // Inicializar estados de asientos (simulado)
    seatStatuses = List.generate(widget.ticket.totalSeats, (index) {
      // Simular algunos asientos ocupados
      if ([2, 5, 8, 12, 15, 18, 23, 27, 31, 35].contains(index + 1)) {
        return SeatStatus.occupied;
      }
      return SeatStatus.available;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pricePerSeat = widget.ticket.price;
    final totalPrice = selectedSeats.length * pricePerSeat;

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
                  '${widget.ticket.origin} → ${widget.ticket.destination}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.ticket.companyName} - ${widget.ticket.busType}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Selecciona ${widget.passengerCount} asiento(s)',
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
              child: Column(
                children: [
                  // Indicador del frente del bus
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'FRENTE DEL BUS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  // Asientos
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _buildSeatMap(),
                  ),
                ],
              ),
            ),
          ),
          
          // Resumen y botón de continuar
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
                if (selectedSeats.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Asientos seleccionados: ${selectedSeats.map((s) => s.toString()).join(', ')}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${selectedSeats.length} x \$${pricePerSeat.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '\$${totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedSeats.length == widget.passengerCount
                        ? () => _proceedToBooking()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      selectedSeats.length == widget.passengerCount
                          ? 'Continuar con la Reserva'
                          : 'Selecciona ${widget.passengerCount - selectedSeats.length} asiento(s) más',
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSeatMap() {
    // Configuración para bus de 40 asientos (2-2 configuración)
    const seatsPerRow = 4;
    const aislePosition = 2; // Posición del pasillo
    
    List<Widget> rows = [];
    
    for (int row = 0; row < (widget.ticket.totalSeats / seatsPerRow).ceil(); row++) {
      List<Widget> seatsInRow = [];
      
      for (int col = 0; col < seatsPerRow; col++) {
        int seatNumber = row * seatsPerRow + col + 1;
        
        if (seatNumber <= widget.ticket.totalSeats) {
          seatsInRow.add(_buildSeat(seatNumber));
        } else {
          seatsInRow.add(const SizedBox(width: 40, height: 40));
        }
        
        // Agregar espacio para el pasillo
        if (col == aislePosition - 1) {
          seatsInRow.add(const SizedBox(width: 20));
        } else if (col < seatsPerRow - 1) {
          seatsInRow.add(const SizedBox(width: 8));
        }
      }
      
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: seatsInRow,
          ),
        ),
      );
    }
    
    return Column(children: rows);
  }

  Widget _buildSeat(int seatNumber) {
    final status = seatStatuses[seatNumber - 1];
    final isSelected = selectedSeats.contains(seatNumber);
    
    Color seatColor;
    IconData seatIcon = Icons.event_seat;
    
    switch (status) {
      case SeatStatus.occupied:
        seatColor = Colors.red;
        break;
      case SeatStatus.available:
        seatColor = isSelected ? Colors.blue : Colors.green;
        break;
    }
    
    return GestureDetector(
      onTap: status == SeatStatus.available ? () => _toggleSeat(seatNumber) : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade800 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              seatIcon,
              color: Colors.white,
              size: 16,
            ),
            Text(
              seatNumber.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSeat(int seatNumber) {
    setState(() {
      if (selectedSeats.contains(seatNumber)) {
        selectedSeats.remove(seatNumber);
      } else {
        if (selectedSeats.length < widget.passengerCount) {
          selectedSeats.add(seatNumber);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Solo puedes seleccionar ${widget.passengerCount} asiento(s)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  void _proceedToBooking() {
    // Navegar a la pantalla de confirmación de reserva
    Navigator.pop(context, {
      'selectedSeats': selectedSeats,
      'totalPrice': selectedSeats.length * widget.ticket.price,
    });
  }
}

enum SeatStatus {
  available,
  occupied,
}