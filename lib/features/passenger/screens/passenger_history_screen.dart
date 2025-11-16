import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/features/passenger/controllers/passenger_controller.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passengerControllerProvider);
    final reservations = state.myReservations;
    return Scaffold(
      appBar: AppBar(title: const Text('My Reservations')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: reservations.isEmpty
            ? const Center(child: Text('No reservations yet'))
            : ListView.builder(
                itemCount: reservations.length,
                itemBuilder: (ctx, i) {
                  final r = reservations[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_seat),
                      title: Text('Trip #${r.tripId} • Seats: ${r.seatsReserved}'),
                      subtitle: Text('Total: ${r.totalPrice} • Status: ${r.status}'),
                      trailing: r.status == 'confirmed'
                          ? TextButton(
                              onPressed: () async {
                                await ref.read(passengerControllerProvider.notifier).cancelMyReservation(r.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reservation cancelled')),
                                  );
                                }
                              },
                              child: const Text('Cancel'),
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}