import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/core/services/supabase_service.dart';

// Color definitions for a professional look
const Color _primaryColor = Color(0xFF1E88E5); // Primary Blue
const Color _accentColor = Color(0xFF00C853); // Accent Green/Teal
const Color _secondaryBackgroundColor = Color(0xFFF0F4F8); // Soft background
const Color _cardBackgroundColor = Colors.white;

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  // Helper para el título de la sección
  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 28),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyControllerProvider);
    final notifier = ref.read(companyControllerProvider.notifier);

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _secondaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor, 
        elevation: 0, 
        centerTitle: true,
        title: Text(
          AppStrings.companyDashboard,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: _cardBackgroundColor, 
          ),
        ),
        iconTheme: const IconThemeData(color: _cardBackgroundColor), 
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _cardBackgroundColor),
            onPressed: state.isLoading ? null : () async {
              await notifier.loadAuthAndCompany();
              await notifier.loadDrivers();
              await notifier.loadSchedules();
            },
            tooltip: AppStrings.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: AppStrings.signOut,
            onPressed: () async {
              await SupabaseService().signOut();
              if (context.mounted) {
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
                  final cardWidth = isNarrow ? double.infinity : (constraints.maxWidth - 48 - 40) / 3;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isNarrow ? 16 : 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 👋 WELCOME HEADER (FIXED RESPONSIVENESS)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Icon(Icons.waving_hand, color: _accentColor, size: 30),
                                const SizedBox(width: 8),
                                Expanded( // Usamos Expanded para evitar el desborde horizontal del nombre
                                  child: Text(
                                    '${AppStrings.welcome}, ${state.company?.name ?? 'Company'}',
                                    // FIX: Usamos titleLarge o headlineSmall en móvil
                                    style: isNarrow
                                        ? textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black87,
                                          )
                                        : textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black87,
                                          ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Quick overview of your fleet and operations.',
                              style: textTheme.titleSmall?.copyWith(
                                color: Colors.black54,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // 📊 STAT CARDS SECTION
                            _buildSectionHeader(
                              context, 
                              title: 'Key Statistics', 
                              icon: Icons.bar_chart_rounded,
                            ),
                            const SizedBox(height: 20),
                            
                            FutureBuilder<Map<String, int>>(
                              future: notifier.loadCounts(),
                              builder: (context, snapshot) {
                                final driversCount = snapshot.data?['drivers'] ?? state.drivers.length;
                                final schedulesCount = snapshot.data?['schedules'] ?? state.schedules.length;
                                final reservationsCount = snapshot.data?['reservations'] ?? state.reservationsBySchedule.values.fold<int>(0, (p, e) => p + e.length);

                                return Wrap(
                                  spacing: 24, 
                                  runSpacing: 24, 
                                  alignment: isNarrow ? WrapAlignment.center : WrapAlignment.start,
                                  children: [
                                    _StatCard(
                                      title: AppStrings.statDrivers,
                                      value: driversCount.toString(),
                                      icon: Icons.people_alt_rounded,
                                      color: Colors.blueAccent,
                                      width: cardWidth,
                                    ),
                                    _StatCard(
                                      title: AppStrings.statSchedules,
                                      value: schedulesCount.toString(),
                                      icon: Icons.calendar_month_rounded,
                                      color: _accentColor,
                                      width: cardWidth,
                                    ),
                                    _StatCard(
                                      title: AppStrings.statReservations,
                                      value: reservationsCount.toString(),
                                      icon: Icons.event_seat_rounded,
                                      color: Colors.deepOrangeAccent,
                                      width: cardWidth,
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 50),

                            // ⚡ ACTION BUTTONS SECTION
                            _buildSectionHeader(
                              context, 
                              title: 'Quick Actions', 
                              icon: Icons.flash_on_rounded,
                            ),
                            const SizedBox(height: 20),
                            
                            isNarrow
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _DashboardButton(
                                        label: AppStrings.companyProfile,
                                        route: '/company/profile',
                                        icon: Icons.business_rounded,
                                        color: _primaryColor,
                                      ),
                                      const SizedBox(height: 16),
                                      _DashboardButton(
                                        label: AppStrings.drivers,
                                        route: '/company/drivers',
                                        icon: Icons.person_search_rounded,
                                        color: Colors.purple,
                                      ),
                                      const SizedBox(height: 16),
                                      // Botón de Horarios/Reservas
                                      _DashboardButton( 
                                        label: AppStrings.companySchedules,
                                        route: '/company/schedules', // Navega a la vista de Horarios
                                        icon: Icons.calendar_today_rounded,
                                        color: _accentColor,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _DashboardButton(
                                          label: AppStrings.companyProfile,
                                          route: '/company/profile',
                                          icon: Icons.business_rounded,
                                          color: _primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: _DashboardButton(
                                          label: AppStrings.drivers,
                                          route: '/company/drivers',
                                          icon: Icons.person_search_rounded,
                                          color: Colors.purple,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: _DashboardButton(
                                          label: AppStrings.companySchedules,
                                          route: '/company/schedules',
                                          icon: Icons.calendar_today_rounded,
                                          color: _accentColor,
                                        ),
                                      ),
                                    ],
                                  ),

                            // ⚠️ ERROR MESSAGE
                            if (state.error != null) ...[
                              const SizedBox(height: 24),
                              _ErrorDisplay(error: state.error!),
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
// 📈 MODERN STAT CARD (Interactive)
// -------------------------------------------------------------
class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? width;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.width,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  double _elevation = 6.0;

  void _onHover(bool isHovering) {
    setState(() {
      _elevation = isHovering ? 12.0 : 6.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion( 
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedContainer( 
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: widget.width == double.infinity ? null : widget.width, 
        constraints: widget.width == null ? const BoxConstraints(minWidth: 280) : null,
        child: Card(
          color: _cardBackgroundColor,
          elevation: _elevation, 
          shadowColor: widget.color.withOpacity(0.3), 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              // Navegar o mostrar detalle del stat si es necesario (ej. a /company/schedules)
              if (widget.title == AppStrings.statSchedules || widget.title == AppStrings.statReservations) {
                  Navigator.pushNamed(context, '/company/schedules');
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.value,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900, 
                                color: Colors.black87,
                                fontSize: 36, 
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(14), 
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 32),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 🚀 MODERN DASHBOARD BUTTON (Action card style)
// -------------------------------------------------------------
class _DashboardButton extends StatelessWidget {
  final String label;
  final String route;
  final IconData icon;
  final Color color;

  const _DashboardButton({
    required this.label,
    required this.route,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _cardBackgroundColor,
      elevation: 4,
      shadowColor: color.withOpacity(0.2), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5), 
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          height: 85, 
          child: Row(
            children: [
              Icon(icon, color: color, size: 30), 
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 🚫 ERROR DISPLAY
// -------------------------------------------------------------
class _ErrorDisplay extends StatelessWidget {
  final String error;

  const _ErrorDisplay({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Operation Failed: $error',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}