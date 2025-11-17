import 'package:flutter/material.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:intl/intl.dart'; 

// --- CONSTANTES DE ESTILO ---
const Color _despegarPrimaryBlue = Color(0xFF0073E6); 
const Color _despegarGreyText = Color(0xFF666666);   
const Color _despegarDarkText = Color(0xFF333333);   
const Color _despegarLightBlue = Color(0xFFE6F3FF);  

class PassengerTripCard extends StatelessWidget {
  final CompanySchedule schedule;
  final VoidCallback onOpen;

  const PassengerTripCard({
    super.key,
    required this.schedule,
    required this.onOpen,
  });

  // 1. Helper para formatear la hora (HH:mm), manejando String o DateTime
  String _formatTime(dynamic timeValue) {
    DateTime date;
    
    if (timeValue is DateTime) {
      date = timeValue;
    } else if (timeValue is String) {
      try {
        date = DateTime.parse(timeValue);
      } catch (e) {
        try {
           date = DateTime.parse('2000-01-01T$timeValue');
        } catch (_) {
           return timeValue.substring(0, timeValue.length >= 5 ? 5 : timeValue.length); 
        }
      }
    } else {
      return 'N/A';
    }
    
    return DateFormat('HH:mm').format(date);
  }

  // 2. Helper para calcular y formatear la duración
  String _calculateDuration() {
    try {
      final DateTime departure = schedule.departureTime is String 
          ? DateTime.parse('2000-01-01T${schedule.departureTime}') 
          : schedule.departureTime as DateTime;
      final DateTime arrival = schedule.arrivalTime is String 
          ? DateTime.parse('2000-01-01T${schedule.arrivalTime}') 
          : schedule.arrivalTime as DateTime;

      final duration = arrival.difference(departure);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. Formateador de precios
    final priceFormatter = NumberFormat.currency(
      locale: 'es_CO', 
      symbol: '\$',
      decimalDigits: 0, 
    );
    final formattedPrice = priceFormatter.format(schedule.price);

    // 🛑 Marcador de Posición para el nombre de la empresa
    // Se usa un nombre genérico en lugar del ID largo.
    const String companyDisplay = 'Tu Flota S.A.S.';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 350; // Usado para ajustes finos

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.zero, 
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- Fila 1: Información de la Empresa y Vuelo ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Icono/Logo de la empresa (simulado)
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _despegarLightBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.directions_bus, size: 20, color: _despegarPrimaryBlue),
                        ),
                        const SizedBox(width: 8),
                        // Nombre de la empresa (marcador de posición)
                        Text(
                          companyDisplay, 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: _despegarDarkText, fontSize: 14),
                        ),
                      ],
                    ),
                    // Tipo de trayecto
                    const Text(
                      'Directo',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                
                const Divider(height: 25),

                // --- Fila 2: Tiempos, Rutas y Duración (Ajustado para responsividad) ---
                Row(
                  children: [
                    // 1. Hora de Salida (IDA)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTime(schedule.departureTime),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _despegarDarkText),
                        ),
                        SizedBox(
                          width: constraints.maxWidth / 3 - 30, // Limita el ancho para evitar desbordamiento
                          child: Text(
                            schedule.origin,
                            style: const TextStyle(color: _despegarGreyText, fontSize: 13),
                            overflow: TextOverflow.ellipsis, // Recorta si es demasiado largo
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 10),

                    // 2. Duración y Flecha
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _calculateDuration(), 
                            style: const TextStyle(color: _despegarGreyText, fontSize: 12),
                          ),
                          const Divider(color: _despegarGreyText),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 10),

                    // 3. Hora de Llegada (VUELTA)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(schedule.arrivalTime),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _despegarDarkText),
                        ),
                        SizedBox(
                          width: constraints.maxWidth / 3 - 30, // Limita el ancho para evitar desbordamiento
                          child: Text(
                            schedule.destination,
                            style: const TextStyle(color: _despegarGreyText, fontSize: 13),
                            overflow: TextOverflow.ellipsis, // Recorta si es demasiado largo
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const Divider(height: 25),

                // --- Fila 3: Precio y Botón de Compra (Ajustado para responsividad) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Precio Final
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Precio Final (1 puesto)',
                          style: TextStyle(color: _despegarGreyText, fontSize: 11),
                        ),
                        Text(
                          formattedPrice,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: isNarrow ? 18 : 22, // Fuente más pequeña en pantallas muy estrechas
                            color: _despegarPrimaryBlue, 
                          ),
                        ),
                      ],
                    ),
                    
                    // Botón de Compra
                    ElevatedButton(
                      onPressed: onOpen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _despegarPrimaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isNarrow ? 'Reservar' : 'Comprar'), // Texto más corto en pantallas muy estrechas
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}