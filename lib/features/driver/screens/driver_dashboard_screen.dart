import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/core/services/company_service.dart';
import 'package:tu_flota/core/services/trip_service.dart';
import 'package:tu_flota/features/driver/models/driver_model.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  Driver? _driver;
  bool _loading = true;
  List<CompanySchedule> _assigned = const [];
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDriver);
  }

  Future<void> _loadDriver() async {
    final client = ref.read(supabaseProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _driver = null;
        _loading = false;
      });
      return;
    }
    final svc = CompanyService(client);
    final d = await svc.getDriverByUserId(userId);
    List<CompanySchedule> assigned = const [];
    if (d != null) {
      assigned = await TripService(client).listAssignedSchedulesForDriver(d.id);
    }
    if (mounted) {
      setState(() {
        _driver = d;
        _loading = false;
        _assigned = assigned;
      });
    }
  }

  Future<void> _updateStatus(String scheduleId, String status) async {
    setState(() => _updating = true);
    final client = ref.read(supabaseProvider);
    await TripService(client).updateAssignmentStatus(scheduleId: scheduleId, status: status);
    if (_driver != null) {
      final assigned = await TripService(client).listAssignedSchedulesForDriver(_driver!.id);
      if (mounted) setState(() => _assigned = assigned);
    }
    if (mounted) setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.driverDashboard),
        actions: [
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _driver == null
              ? const Center(child: Text(AppStrings.featureComingSoon))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _driver!.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.directions_car),
                                  const SizedBox(width: 8),
                                  Text(_driver!.autoModel ?? AppStrings.vehicleModel),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.color_lens),
                                  const SizedBox(width: 8),
                                  Text(_driver!.autoColor ?? AppStrings.vehicleColor),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.confirmation_number),
                                  const SizedBox(width: 8),
                                  Text(_driver!.autoPlate ?? AppStrings.plate),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(AppStrings.assignedTrips, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _assigned.isEmpty
                            ? const Center(child: Text(AppStrings.noActiveTripsFound))
                            : ListView.separated(
                                itemCount: _assigned.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final s = _assigned[index];
                                  final statusLabel = s.assignmentStatus == 'accepted'
                                      ? AppStrings.accepted
                                      : s.assignmentStatus == 'rejected'
                                          ? AppStrings.rejected
                                          : AppStrings.pending;
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${s.origin} → ${s.destination}', style: theme.textTheme.bodyLarge),
                                          const SizedBox(height: 4),
                                          Text('Dep: ${s.departureTime} | Arr: ${s.arrivalTime}'),
                                          const SizedBox(height: 4),
                                          Text('${AppStrings.availableSeats}: ${s.availableSeats} / ${s.totalSeats}'),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Chip(label: Text(statusLabel)),
                                              const Spacer(),
                                              if (s.assignmentStatus == 'pending') ...[
                                                TextButton(
                                                  onPressed: _updating ? null : () => _updateStatus(s.id, 'accepted'),
                                                  child: const Text(AppStrings.accept),
                                                ),
                                                const SizedBox(width: 8),
                                                TextButton(
                                                  onPressed: _updating ? null : () => _updateStatus(s.id, 'rejected'),
                                                  child: const Text(AppStrings.reject),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}