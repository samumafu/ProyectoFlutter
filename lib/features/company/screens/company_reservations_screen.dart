import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/passenger/models/reservation_model.dart'; // Asegurar el modelo
import 'package:tu_flota/features/company/models/company_schedule_model.dart'; // Necesitamos el Schedule

// Colores definidos para consistencia
const Color _primaryColor = Color(0xFF1E88E5);
const Color _accentColor = Color(0xFF00C853);
const Color _cardBackgroundColor = Colors.white;

class CompanyReservationsScreen extends ConsumerStatefulWidget {
  const CompanyReservationsScreen({super.key});

  @override
  ConsumerState<CompanyReservationsScreen> createState() => _CompanyReservationsScreenState();
}

class _CompanyReservationsScreenState extends ConsumerState<CompanyReservationsScreen> {
  
  @override
  void initState() {
    super.initState();
    // 🔑 PASO CRÍTICO: Asegurar la carga de datos al inicio.
    // loadSchedules() recarga los horarios y todas las reservas.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(companyControllerProvider.notifier).loadSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. ESCUCHAMOS EL ESTADO
    final state = ref.watch(companyControllerProvider);
    
    // 2. OBTENER DATOS Y MAPAS
    // Lista aplanada de todas las reservas
    final allReservations = state.reservationsBySchedule.values
        .expand((list) => list)
        .cast<Reservation>() // Casteamos explícitamente a Reservation
        .toList();

    // Mapeo rápido de horarios (scheduleId -> CompanySchedule)
    final scheduleMap = {
      for (var schedule in state.schedules) schedule.id: schedule
    };

    // 3. PANTALLA DE CARGA
    if (state.isLoading && allReservations.isEmpty) {
      return const Scaffold(
        appBar: _ReservationsAppBar(title: AppStrings.statReservations),
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }
    
    // 4. ESTRUCTURA PRINCIPAL DE LA PANTALLA
    return Scaffold(
      appBar: const _ReservationsAppBar(title: AppStrings.statReservations),
      body: allReservations.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sentiment_dissatisfied_rounded, size: 60, color: Colors.black38),
                    const SizedBox(height: 16),
                    Text(
                      'No current reservations found.', 
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black54)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verify your published schedules.', 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black45)
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allReservations.length,
              itemBuilder: (context, index) {
                final reservation = allReservations[index]; 
                final schedule = scheduleMap[reservation.tripId];

                // Renderizar la tarjeta de reserva con la información de Schedule
                return ReservationCard(
                  reservation: reservation,
                  schedule: schedule,
                  onTap: () {
                    // TODO: Implementar navegación a detalles de la reserva
                    // Por ejemplo: Navigator.pushNamed(context, '/company/reservation_detail', arguments: reservation.id);
                  },
                );
              },
            ),
    );
  }
}

// -------------------------------------------------------------
// 📐 WIDGET DE LA BARRA DE APLICACIÓN
// -------------------------------------------------------------
class _ReservationsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  
  const _ReservationsAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: _cardBackgroundColor,
        ),
      ),
      backgroundColor: _primaryColor,
      iconTheme: const IconThemeData(color: _cardBackgroundColor),
      elevation: 4,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


// -------------------------------------------------------------
// 💳 WIDGET DE TARJETA DE RESERVA (DISEÑO MEJORADO)
// -------------------------------------------------------------
class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final CompanySchedule? schedule;
  final VoidCallback onTap;

  const ReservationCard({
    super.key,
    required this.reservation,
    required this.schedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    
    // Formatear la hora
    final departureTime = schedule?.departureTime != null
        ? schedule!.departureTime.substring(0, 5) // HH:MM
        : 'N/A';
    
    // Formatear la fecha (asumiendo que hay un campo de fecha, si no, usar la fecha de creación)
    final reservationDate = reservation.createdAt != null
        ? reservation.createdAt!.toLocal().toString().substring(0, 10) 
        : 'N/A';

    // Información de la ruta
    final routeInfo = schedule != null 
        ? '${schedule!.origin} to ${schedule!.destination}'
        : 'Route: N/A';

    // Información del pasajero
    final passengerIdShort = reservation.passengerId.substring(0, 8);
    final passengerDisplay = 'Passenger: ID ${passengerIdShort}...';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECCIÓN SUPERIOR: RUTA Y ESTADO ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      routeInfo,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusChip(
                    isConfirmed: reservation.isConfirmed,
                    isCancelled: reservation.isCancelled,
                  ),
                ],
              ),
              const Divider(height: 20, color: Colors.black12),

              // --- SECCIÓN MEDIA: DETALLES DE HORA, ASIENTOS Y PRECIO ---
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.black54, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Time: $departureTime on $reservationDate',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Icono y número de asientos
                  const Icon(Icons.event_seat_rounded, color: Colors.deepOrange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Seats Reserved: ${reservation.seatsReserved}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  const Spacer(),
                  
                  // Icono y precio total
                  const Icon(Icons.attach_money_rounded, color: _accentColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '\$${reservation.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _accentColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // --- SECCIÓN INFERIOR: ID DEL PASAJERO ---
              Row(
                children: [
                  const Icon(Icons.person_rounded, color: Colors.black54, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      passengerDisplay,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 🏷️ CHIP DE ESTADO DE RESERVA
// -------------------------------------------------------------
class _StatusChip extends StatelessWidget {
  final bool isConfirmed;
  final bool isCancelled;

  const _StatusChip({required this.isConfirmed, required this.isCancelled});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    if (isCancelled) {
      color = Colors.red;
      text = 'Canceled';
      icon = Icons.cancel;
    } else if (isConfirmed) {
      color = _accentColor;
      text = 'Confirmed';
      icon = Icons.check_circle;
    } else {
      color = Colors.orange;
      text = 'Pending';
      icon = Icons.pending_actions;
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      avatar: Icon(icon, color: Colors.white, size: 16),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}