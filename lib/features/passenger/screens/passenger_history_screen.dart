import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/features/passenger/controllers/passenger_controller.dart';
// IMPORTACIÓN NECESARIA para LatLng
import 'package:latlong2/latlong.dart'; 
// IMPORTACIÓN DEL DTO (Asumimos que está en este path)
import 'package:tu_flota/features/company/models/company_schedule_model.dart'; 
import 'package:tu_flota/features/passenger/models/reservation_history_dto.dart';

// Definiciones de estilo (Alineadas con el resto de la app - estilo Despegar/Moderno)
const Color _primaryColor = Color(0xFF0073E6); // Azul Moderno
const Color _accentColor = Color(0xFF34A853); // Verde (Confirmado)
const Color _reservedColor = Color(0xFFC62828); // Rojo (Cancelado)
const Color _pendingColor = Color(0xFFFFB300); // Naranja (Pendiente)
const Color _backgroundColor = Color(0xFFF0F2F5); // Fondo más grisáceo/suave
const Color _darkTextColor = Color(0xFF1A1A1A); // Texto muy oscuro

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

  // Lógica de cancelación
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
    // USO DEL DTO CORREGIDO
    final List<ReservationHistory> reservations = state.myReservations.cast<ReservationHistory>();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Historial de Viajes'),
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
          // Centrado para pantallas grandes
          final horizontalPadding = (constraints.maxWidth - _maxContentWidth).clamp(0.0, double.infinity) / 2;
          
          return Column(
            children: [
              // Encabezado Fijo de la Lista
              Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding + 16, 16, horizontalPadding + 16, 0),
                child: _buildHeader(context, constraints.maxWidth),
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
                                // USO DEL DTO CORREGIDO
                                final ReservationHistory r = reservations[i];
                                
                                return ReservationHistoryCard(
                                  reservation: r, // PASAMOS EL OBJETO DE RESERVA/TRAYECTO COMBINADO
                                  statusColor: _getStatusColor(r.status),
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
  Widget _buildHeader(BuildContext context, double screenWidth) {
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
          ],
        ),
      ),
    );
  }
}


// --------------------------------------------------------------------------
// ReservationHistoryCard (CORREGIDO PARA USAR ReservationHistory)
// --------------------------------------------------------------------------

class ReservationHistoryCard extends StatelessWidget {
  // TIPO CORREGIDO: Ahora usa el DTO
  final ReservationHistory reservation; 
  final Color statusColor;
  final VoidCallback? onCancel;

  const ReservationHistoryCard({
    super.key,
    required this.reservation,
    required this.statusColor,
    this.onCancel,
  });

  // Helper para mostrar un detalle específico
  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _primaryColor.withOpacity(0.7), size: 16),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: _darkTextColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Helper para el título del viaje
  Widget _buildTripTitle(BuildContext context, String origin, String destination) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Origen
        Flexible(
          flex: 4,
          child: Text(
            origin,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900, 
              color: _darkTextColor,
              fontSize: 18,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Icono de flecha
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(
            Icons.arrow_right_alt, 
            color: _primaryColor, 
            size: 24
          ),
        ),
        
        // Destino
        Flexible(
          flex: 4,
          child: Text(
            destination,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900, 
              color: _darkTextColor,
              fontSize: 18,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ACCESO SEGURO a las propiedades del DTO
    final String origin = reservation.origin; 
    final String destination = reservation.destination;
    final int seatsReserved = reservation.seatsReserved;
    final double totalPrice = reservation.totalPrice;
    final String status = reservation.status;
    
    // Coordenadas
    final double? lat = reservation.pickupLatitude; 
    final double? lng = reservation.pickupLongitude; 

    // LÓGICA DEL ID CORTO
    final String shortId = reservation.id.length > 8 
        ? reservation.id.substring(0, 8) 
        : reservation.id;
    
    LatLng? pickupPoint;
    if (lat != null && lng != null) {
      pickupPoint = LatLng(lat, lng);
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 1,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
        // Borde superior más sutil
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TÍTULO DEL VIAJE (Origen -> Destino)
            _buildTripTitle(context, origin, destination),

            const Divider(height: 25),

            // 2. DETALLES (Puestos, Total, Estado)
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                // ID CORTO UTILIZADO AQUÍ
                _buildDetailChip(Icons.confirmation_number, 'ID Reserva', shortId),
                _buildDetailChip(Icons.event_seat, 'Puestos', seatsReserved.toString()),
                _buildDetailChip(Icons.payments, 'Total', '\$${totalPrice.toStringAsFixed(2)}'),
              ],
            ),
            
            const SizedBox(height: 15),
            
            // 3. PUNTO DE RECOGIDA Y ESTADO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Detalle del Punto de Recogida
                _buildDetailChip(Icons.pin_drop, 'Recogida', pickupPoint != null ? 'Asignado' : 'Pendiente'),

                // Etiqueta de Estado (Movida aquí para mejor visibilidad)
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
            
            // 4. ACCIONES (Ver Mapa / Cancelar)
            if (onCancel != null || pickupPoint != null) ...[
              const Divider(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Botón para ver el punto en el mapa
                  if (pickupPoint != null)
                    TextButton.icon(
                      onPressed: () {
                        // Navegar a la pantalla de visualización del mapa
                        Navigator.of(context).pushNamed(
                          '/passenger/map/view', 
                          arguments: {
                            'location': pickupPoint, 
                            'title': 'Punto de Recogida',
                          },
                        );
                      },
                      icon: const Icon(Icons.map_outlined, size: 18, color: _primaryColor),
                      label: const Text('Ver Punto en Mapa'),
                    ),

                  const SizedBox(width: 10),

                  // Botón de Cancelar
                  if (onCancel != null)
                    OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('CANCELAR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _reservedColor,
                        side: BorderSide(color: _reservedColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}