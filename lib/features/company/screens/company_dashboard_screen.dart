import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/core/services/supabase_service.dart';

// Color definitions for a professional look
const Color _primaryColor = Color(0xFF1E88E5); // Primary Blue
const Color _secondaryBackgroundColor = Color(0xFFF0F4F8); // Soft background
const Color _cardBackgroundColor = Colors.white;

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyControllerProvider);
    final notifier = ref.read(companyControllerProvider.notifier);

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _secondaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: _cardBackgroundColor,
        elevation: 1, // Subtle shadow
        title: Text(
          AppStrings.companyDashboard,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _primaryColor),
            onPressed: () async {
              await notifier.loadAuthAndCompany();
              await notifier.loadDrivers();
              await notifier.loadSchedules();
            },
            tooltip: AppStrings.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: AppStrings.signOut,
            onPressed: () async {
              await SupabaseService().signOut();
              if (context.mounted) {
                // Use named replacement for cleaner navigation history
                Navigator.pushReplacementNamed(context, '/auth/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: _primaryColor))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080), // Wider content area
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 👋 WELCOME HEADER
                            Text(
                              '${AppStrings.welcome}, ${state.company?.name ?? 'Company'}',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Quick overview of your fleet and operations.',
                              style: textTheme.titleSmall?.copyWith(
                                color: Colors.black54,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // 📊 STAT CARDS (Improved with FutureBuilder)
                            Text(
                              'Key Statistics',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            FutureBuilder<Map<String, int>>(
                              future: notifier.loadCounts(),
                              builder: (context, snapshot) {
                                final driversCount =
                                    snapshot.data?['drivers'] ?? state.drivers.length;
                                final schedulesCount =
                                    snapshot.data?['schedules'] ?? state.schedules.length;
                                final reservationsCount =
                                    snapshot.data?['reservations'] ??
                                        state.reservationsBySchedule.values
                                            .fold<int>(0, (p, e) => p + e.length);

                                return Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  alignment: isNarrow
                                      ? WrapAlignment.center
                                      : WrapAlignment.start,
                                  children: [
                                    _StatCard(
                                      title: AppStrings.statDrivers,
                                      value: driversCount.toString(),
                                      icon: Icons.people_alt_outlined,
                                      color: Colors.blueAccent,
                                    ),
                                    _StatCard(
                                      title: AppStrings.statSchedules,
                                      value: schedulesCount.toString(),
                                      icon: Icons.route_outlined,
                                      color: Colors.teal,
                                    ),
                                    _StatCard(
                                      title: AppStrings.statReservations,
                                      value: reservationsCount.toString(),
                                      icon: Icons.event_seat_outlined,
                                      color: Colors.deepOrangeAccent,
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 40),

                            // ⚡ ACTION BUTTONS
                            Text(
                              'Quick Actions',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            isNarrow
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _DashboardButton(
                                        label: AppStrings.companyProfile,
                                        route: '/company/profile',
                                        icon: Icons.business_outlined,
                                      ),
                                      const SizedBox(height: 16),
                                      _DashboardButton(
                                        label: AppStrings.drivers,
                                        route: '/company/drivers',
                                        icon: Icons.person_outline,
                                      ),
                                      const SizedBox(height: 16),
                                      _DashboardButton(
                                        label: AppStrings.companySchedules,
                                        route: '/company/schedules',
                                        icon: Icons.calendar_month_outlined,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _DashboardButton(
                                          label: AppStrings.companyProfile,
                                          route: '/company/profile',
                                          icon: Icons.business_outlined,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _DashboardButton(
                                          label: AppStrings.drivers,
                                          route: '/company/drivers',
                                          icon: Icons.person_outline,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _DashboardButton(
                                          label: AppStrings.companySchedules,
                                          route: '/company/schedules',
                                          icon: Icons.calendar_month_outlined,
                                        ),
                                      ),
                                    ],
                                  ),

                            // ⚠️ ERROR MESSAGE
                            if (state.error != null) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Error: ${state.error!}',
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 📈 Modern Stat Card
// -------------------------------------------------------------
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // Fixed width for desktop
      child: Card(
        color: _cardBackgroundColor,
        elevation: 6, // Higher elevation to stand out
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // More rounded corners
        ),
        child: InkWell( // Uses InkWell for a nice tap effect
          onTap: () {
            // Optional action when tapping the card
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 🚀 Modern Dashboard Button (Action card style)
// -------------------------------------------------------------
class _DashboardButton extends StatelessWidget {
  final String label;
  final String route;
  final IconData icon;

  const _DashboardButton({
    required this.label,
    required this.route,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _cardBackgroundColor,
      elevation: 4,
      shadowColor: _primaryColor.withOpacity(0.2), // Primary-colored shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black12, width: 0.5),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          height: 80, // Fixed height
          child: Row(
            children: [
              Icon(icon, color: _primaryColor, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}