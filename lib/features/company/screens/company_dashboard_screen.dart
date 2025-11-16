import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/core/services/supabase_service.dart';

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyControllerProvider);
    final notifier = ref.read(companyControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.companyDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await notifier.loadAuthAndCompany();
              await notifier.loadDrivers();
              await notifier.loadSchedules();
            },
            tooltip: AppStrings.refresh,
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
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 480;
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppStrings.welcome}, ${state.company?.name ?? '-'}',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        FutureBuilder<Map<String, int>>(
                          future: notifier.loadCounts(),
                          builder: (context, snapshot) {
                            final driversCount = (snapshot.data?['drivers'] ?? state.drivers.length).toString();
                            final schedulesCount = (snapshot.data?['schedules'] ?? state.schedules.length).toString();
                            final reservationsCount = (snapshot.data?['reservations'] ?? state.reservationsBySchedule.values.fold<int>(0, (p, e) => p + e.length)).toString();
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _StatCard(
                                  title: AppStrings.statDrivers,
                                  value: driversCount,
                                  icon: Icons.person,
                                ),
                                _StatCard(
                                  title: AppStrings.statSchedules,
                                  value: schedulesCount,
                                  icon: Icons.schedule,
                                ),
                                _StatCard(
                                  title: AppStrings.statReservations,
                                  value: reservationsCount,
                                  icon: Icons.event_seat,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        if (isNarrow)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/company/profile'),
                                child: const Text(AppStrings.companyProfile),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text(AppStrings.featureComingSoon)),
                                  );
                                },
                                child: const Text(AppStrings.drivers),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/company/schedules'),
                                child: const Text(AppStrings.companySchedules),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/company/profile'),
                                child: const Text(AppStrings.companyProfile),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text(AppStrings.featureComingSoon)),
                                  );
                                },
                                child: const Text(AppStrings.drivers),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/company/schedules'),
                                child: const Text(AppStrings.companySchedules),
                              ),
                            ],
                          ),
                        if (state.error != null) ...[
                          const SizedBox(height: 16),
                          Text(state.error!, style: const TextStyle(color: Colors.red)),
                        ]
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 180,
        height: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}