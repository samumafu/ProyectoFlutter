import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/features/passenger/controllers/passenger_controller.dart';
import 'package:tu_flota/features/passenger/widgets/passenger_trip_card.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';

class PassengerSearchTripsScreen extends ConsumerStatefulWidget {
  const PassengerSearchTripsScreen({super.key});

  @override
  ConsumerState<PassengerSearchTripsScreen> createState() => _PassengerSearchTripsScreenState();
}

class _PassengerSearchTripsScreenState extends ConsumerState<PassengerSearchTripsScreen> {
  final _originCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(passengerControllerProvider.notifier).loadAllTrips());
    Future.microtask(() => ref.read(passengerControllerProvider.notifier).loadMyReservations());
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  void _search() {
    ref
        .read(passengerControllerProvider.notifier)
        .searchTrips(origin: _originCtrl.text, destination: _destinationCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passengerControllerProvider);
    final trips = state.trips;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.passengerDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.refresh,
            onPressed: () => ref.read(passengerControllerProvider.notifier).loadAllTrips(),
          ),
          IconButton(
            icon: const Icon(Icons.event_seat),
            tooltip: AppStrings.activeReservations,
            onPressed: () {
              final reservations = ref.read(passengerControllerProvider).myReservations.where((r) => r.status == 'confirmed').toList();
              showModalBottomSheet(
                context: context,
                builder: (_) => ListView(
                  padding: const EdgeInsets.all(12),
                  children: reservations.isEmpty
                      ? [const ListTile(title: Text(AppStrings.noActiveReservations))]
                      : reservations
                          .map((r) => ListTile(
                                leading: const Icon(Icons.event_seat),
                                title: Text('Trip: ${r.tripId}'),
                                subtitle: Text('${AppStrings.seats}: ${r.seatsReserved} | ${AppStrings.total}: ${r.totalPrice} | ${AppStrings.status}: ${r.status}'),
                              ))
                          .toList(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.signOut,
            onPressed: () async {
              await SupabaseService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 420;
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (isNarrow)
                    Column(
                      children: [
                        TextField(
                          controller: _originCtrl,
                          decoration: const InputDecoration(labelText: AppStrings.origin),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _destinationCtrl,
                          decoration: const InputDecoration(labelText: AppStrings.destination),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(onPressed: _search, child: const Text(AppStrings.search)),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _originCtrl,
                            decoration: const InputDecoration(labelText: AppStrings.origin),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _destinationCtrl,
                            decoration: const InputDecoration(labelText: AppStrings.destination),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _search, child: const Text(AppStrings.search)),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (state.isLoading) const LinearProgressIndicator(),
                  Expanded(
                    child: trips.isEmpty
                        ? const Center(child: Text(AppStrings.noTrips))
                        : ListView.builder(
                            itemCount: trips.length,
                            itemBuilder: (ctx, i) {
                              final CompanySchedule s = trips[i];
                              return PassengerTripCard(
                                schedule: s,
                                onOpen: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/passenger/trip/detail',
                                    arguments: s,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}