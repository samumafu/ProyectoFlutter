import 'package:flutter/material.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

// Colores consistentes para el diseño
const Color _primaryColor = Color(0xFF1E88E5); // Azul Corporativo
const Color _secondaryColor = Color(0xFF00C853); // Verde (Éxito/Activo)
const Color _warningColor = Color(0xFFFF9800); // Naranja (Baja disponibilidad)
const Color _cardBackgroundColor = Colors.white; // Fondo blanco para la tarjeta

class CompanyTripCard extends StatelessWidget {
  final CompanySchedule schedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewReservations;
  final VoidCallback? onOpenChat;

  const CompanyTripCard({
    super.key,
    required this.schedule,
    this.onEdit,
    this.onDelete,
    this.onViewReservations,
    this.onOpenChat,
  });

  // Helper para mostrar la hora y fecha legiblemente
  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM d, HH:mm').format(dateTime); // Ej: Nov 18, 14:30
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cálculo de disponibilidad y estado
    final available = schedule.availableSeats;
    final total = schedule.totalSeats;
    final isFull = available <= 0;
    final isLow = available > 0 && available <= total * 0.2;

    final availabilityColor = isFull ? Colors.red.shade700 : (isLow ? _warningColor : _secondaryColor);
    final availabilityText = isFull ? 'FULL' : (isLow ? 'LOW ($available)' : 'Seats: $available/$total');
    
    final isActive = schedule.isActive;
    final statusChipColor = isActive ? _secondaryColor.withOpacity(0.1) : Colors.red.withOpacity(0.1);
    final statusTextColor = isActive ? _secondaryColor : Colors.red.shade700;
    final statusText = isActive ? AppStrings.active : 'Inactive';
    final statusIcon = isActive ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Card(
      elevation: 8,
      shadowColor: _primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _primaryColor.withOpacity(0.2), width: 1.5), // Borde sutil azul
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER: ESTADO y PRECIO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chip de Estado (Activo/Inactivo)
                Chip(
                  avatar: Icon(statusIcon, size: 18, color: statusTextColor),
                  label: Text(statusText, style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  backgroundColor: statusChipColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                ),
                // Precio (Destacado)
                Text(
                  '\$${schedule.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _primaryColor, // Precio ahora en azul primario
                  ),
                ),
              ],
            ),

            const Divider(height: 20, thickness: 1, color: Colors.black12),

            // 2. DETALLE DE RUTA Y TIEMPOS (Diseño Estilizado)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicador de Ruta Vertical (Iconos en azul primario)
                Column(
                  children: [
                    Icon(Icons.location_on, color: _primaryColor, size: 24), // Origen en azul
                    Container(
                      height: 40,
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                    Icon(Icons.flag, color: _primaryColor, size: 24), // Destino en azul
                  ],
                ),
                const SizedBox(width: 15),
                // Origen y Destino con Tiempos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Origen
                      Text(
                        schedule.origin,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primaryColor), // Origen en azul primario
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${AppStrings.departure}: ${_formatDateTime(schedule.departureTime)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      // Destino
                      Text(
                        schedule.destination,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primaryColor), // Destino en azul primario
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${AppStrings.arrival}: ${_formatDateTime(schedule.arrivalTime)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 15),

            // 3. DETALLES ADICIONALES (Fila compacta)
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                // Vehículo
                if (schedule.vehicleType != null && schedule.vehicleType!.isNotEmpty)
                  _buildDetailItem(
                    icon: Icons.directions_bus_filled_outlined,
                    label: schedule.vehicleType!,
                    color: Colors.black87,
                  ),
                // Asientos
                _buildDetailItem(
                  icon: Icons.event_seat_outlined,
                  label: availabilityText,
                  color: availabilityColor,
                  isBold: isFull || isLow,
                ),
                // ID de Viaje (Referencia rápida)
                _buildDetailItem(
                  icon: Icons.vpn_key_outlined,
                  label: 'ID: ${schedule.id.substring(0, 8)}',
                  color: Colors.grey.shade600,
                ),
              ],
            ),

            // 4. INFORMACIÓN ADICIONAL (Texto menos prominente)
            if (schedule.additionalInfo != null && jsonEncode(schedule.additionalInfo) != '{}') // Ocultar si está vacío
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  '${AppStrings.info}: ${jsonEncode(schedule.additionalInfo)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 15),

            // 5. ACCIONES (Row de IconButtons con fondo de color sutil)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.people_alt_outlined,
                  label: AppStrings.reservations,
                  onPressed: onViewReservations,
                  color: _secondaryColor,
                  backgroundColor: _secondaryColor.withOpacity(0.1), // Fondo sutil verde
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: AppStrings.chat,
                  onPressed: onOpenChat,
                  color: _primaryColor,
                  backgroundColor: _primaryColor.withOpacity(0.1), // Fondo sutil azul
                ),
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  label: AppStrings.edit,
                  onPressed: onEdit,
                  color: _warningColor,
                  backgroundColor: _warningColor.withOpacity(0.1), // Fondo sutil naranja
                ),
                _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: AppStrings.delete,
                  onPressed: onDelete,
                  color: Colors.red,
                  backgroundColor: Colors.red.withOpacity(0.1), // Fondo sutil rojo
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Helper para Detalles ---
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // --- Widget Helper para Botones de Acción (con nuevo parámetro backgroundColor) ---
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    Color? backgroundColor, // Nuevo parámetro para el fondo
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: label,
        child: Material(
          color: backgroundColor ?? Colors.transparent, // Usar el fondo provisto o transparente
          borderRadius: BorderRadius.circular(10), // Bordes suaves para el fondo
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(6.0), // Padding interno para el IconButton
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}