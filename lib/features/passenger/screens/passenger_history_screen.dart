import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/features/passenger/controllers/passenger_controller.dart';
// Asegúrate de importar tu modelo de Reservation si no está implícito
// import 'package:tu_flota/features/company/models/reservation_model.dart'; 

// Definiciones de estilo (Alineadas con el resto de la app - estilo Despegar)
// Usamos tus colores originales pero con nombres más descriptivos para la estética
const Color _primaryColor = Color(0xFF0073E6); // Usando un azul más Despegar/Moderno (reemplazando 0xFF1E88E5)
const Color _accentColor = Color(0xFF34A853); // Verde (Confirmado)
const Color _reservedColor = Color(0xFFC62828); // Rojo (Cancelado)
const Color _pendingColor = Color(0xFFFFB300); // Naranja (Pendiente)
const Color _backgroundColor = Color(0xFFF8F9FA); // Fondo casi blanco
const Color _darkTextColor = Color(0xFF333333); // Texto oscuro

const double _maxContentWidth = 900.0; // Ancho máximo para el centrado

class PassengerHistoryScreen extends ConsumerStatefulWidget {
  const PassengerHistoryScreen({super.key});

  @override
  ConsumerState<PassengerHistoryScreen> createState() => _PassengerHistoryScreenState();
}

class _PassengerHistoryScreenState extends ConsumerState<PassengerHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(passengerControllerProvider.notifier).loadMyReservations());
  }

  // Helper para obtener el color basado en el estado
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return _accentColor;
      case 'cancelled':
        return _reservedColor;
      case 'pending':
        return _pendingColor;
      default:
        return Colors.grey.shade600;
    }
  }

  // ⚠️ Lógica de cancelación
  Future<void> _confirmCancelation(dynamic reservationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Cancelación'),
        content: const Text('¿Estás seguro de que deseas cancelar esta reserva?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sí, Cancelar', style: TextStyle(color: _reservedColor))),
        ],
      ),
    );

    if (confirm == true) {
      // Usamos .toString() para asegurar el tipo si 'r.id' no es String
      await ref.read(passengerControllerProvider.notifier).cancelMyReservation(reservationId.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada exitosamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passengerControllerProvider);
    final reservations = state.myReservations;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Historial de Reservas'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0, 
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(passengerControllerProvider.notifier).loadMyReservations(),
            tooltip: 'Recargar historial',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          // Centrado para pantallas grandes
          final horizontalPadding = (constraints.maxWidth - _maxContentWidth).clamp(0.0, double.infinity) / 2;
          
          return Column(
            children: [
              // Encabezado Fijo de la Lista
              Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding + 16, 16, horizontalPadding + 16, 0),
                child: _buildHeader(context, isNarrow),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: state.isLoading
                      ? _buildLoadingIndicator(context)
                      : reservations.isEmpty
                          ? _buildEmptyState(context)
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 10, bottom: 20, left: 16, right: 16),
                              itemCount: reservations.length,
                              itemBuilder: (ctx, i) {
                                final r = reservations[i];
                                final statusColor = _getStatusColor(r.status);
                                
                                return HistoryCard(
                                  // ⚠️ LÓGICA DE DATOS MANTENIDA: Usa solo tripId y el resto de la reserva
                                  title: 'Reserva para Viaje ID: ${r.tripId}', 
                                  subtitle: 'Puestos: ${r.seatsReserved} • Total: \$${r.totalPrice.toStringAsFixed(2)}',
                                  status: r.status,
                                  statusColor: statusColor,
                                  onCancel: r.status.toLowerCase() == 'confirmed'
                                      ? () => _confirmCancelation(r.id)
                                      : null,
                                );
                              },
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Widget para el estado de carga
  Widget _buildLoadingIndicator(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 10),
          Text('Cargando historial...', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _darkTextColor)),
        ],
      ),
    );
  }

  // Widget para la lista vacía
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 15),
          Text(
            '¡Tu historial está vacío!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: _darkTextColor),
          ),
          const SizedBox(height: 5),
          const Text(
            'Una vez que reserves un viaje, aparecerá aquí.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  // Encabezado de la lista con diseño de tarjeta
  Widget _buildHeader(BuildContext context, bool isNarrow) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.timeline, color: _primaryColor),
            const SizedBox(width: 8),
            Text(
              'Tus Reservas Recientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: _darkTextColor),
            ),
            if (!isNarrow) const Spacer(),
            if (!isNarrow) 
              Text(
                'Estado | Puestos | Total',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}


// --------------------------------------------------------------------------
// 🔥 HistoryCard REDISEÑADA (Estética de Ticket/Responsive)
// --------------------------------------------------------------------------

class HistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final VoidCallback? onCancel;

  const HistoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.onCancel,
  });

  // Helper para mostrar un detalle específico basado en el subtitle.
  // Notar que aquí hacemos un poco de "parsing" del subtitle para dividirlo.
  Widget _buildDetailChip(String iconName, String value) {
    IconData icon;
    String label;

    if (iconName.contains('Puestos')) {
      icon = Icons.event_seat;
      label = 'Puestos';
    } else if (iconName.contains('Total')) {
      icon = Icons.payments;
      label = 'Total';
    } else {
      icon = Icons.info_outline;
      label = 'Info';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _primaryColor.withOpacity(0.7), size: 18),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: _darkTextColor),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    // Patrón de "ticket" con borde superior destacado
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        // El borde superior cambia de color según el estado
        border: Border(top: BorderSide(color: statusColor, width: 6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TÍTULO Y ESTADO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, 
                      color: _darkTextColor,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Etiqueta de Estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 20),

            // 2. DETALLES (Responsive con Wrap)
            // Dividimos el subtitle para mostrarlo como chips
            // Ejemplo: "Puestos: 2 • Total: $50.00" -> ['Puestos: 2', 'Total: $50.00']
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: subtitle.split(' • ').map((detail) {
                final parts = detail.split(': ');
                if (parts.length == 2) {
                  return _buildDetailChip(parts[0].trim(), parts[1].trim());
                }
                return const SizedBox.shrink(); // En caso de que el formato sea inesperado
              }).toList(),
            ),
            
            // 3. ACCIÓN (Cancelar)
            if (onCancel != null) ...[
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('CANCELAR RESERVA'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _reservedColor,
                    side: BorderSide(color: _reservedColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}