import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/features/passenger/models/reservation_model.dart';
import 'dart:developer';

// Color definitions for a professional look
const Color _primaryColor = Color(0xFF1E88E5); // Primary Blue (Deep Sky)
const Color _accentColor = Color(0xFF00C853); // Accent Green (Emerald)
const Color _secondaryBackgroundColor = Color(0xFFF0F4F8); // Soft background (Light Gray Blue)
const Color _cardBackgroundColor = Colors.white;
const Color _warningColor = Color(0xFFFF9800);

class CompanyDashboardScreen extends ConsumerStatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  ConsumerState<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends ConsumerState<CompanyDashboardScreen> {
  late Future<Map<String, int>> _countsFuture;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(companyControllerProvider.notifier);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await notifier.loadAuthAndCompany();
      await notifier.loadDrivers();
      await notifier.loadSchedules(); 
      
      setState(() {
        _countsFuture = notifier.loadCounts();
      });
    });
    
    _countsFuture = ref.read(companyControllerProvider.notifier).loadCounts();
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
        ),
      ],
    );
  }

  int _calculateTotalReservations(Map<String, List<Reservation>> reservationsBySchedule) {
    final total = reservationsBySchedule.values.fold<int>(0, (previousValue, scheduleReservations) {
      return previousValue + scheduleReservations.length;
    });
    log('DEBUG DASHBOARD: Total reservations from state map: $total');
    return total;
  }

  void _reloadAllData() {
    final notifier = ref.read(companyControllerProvider.notifier);
    setState(() {
      notifier.loadAuthAndCompany();
      notifier.loadDrivers();
      notifier.loadSchedules();
      _countsFuture = notifier.loadCounts(); 
    });
    log('DEBUG DASHBOARD: Data reload triggered.');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _secondaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 4,
        centerTitle: false,
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
            onPressed: state.isLoading ? null : _reloadAllData,
            tooltip: AppStrings.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: _cardBackgroundColor), 
            tooltip: AppStrings.signOut,
            onPressed: () async {
              await SupabaseService().signOut();
              ref.read(companyControllerProvider.notifier).reset();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading && state.company == null
            ? const Center(child: CircularProgressIndicator(color: _primaryColor))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  
                  double cardWidth;
                  if (constraints.maxWidth < 450) {
                    cardWidth = double.infinity;
                  } else if (constraints.maxWidth < 900) {
                    cardWidth = (constraints.maxWidth - 48) / 2;
                  } else {
                    cardWidth = (constraints.maxWidth - 112) / 3;
                  }
                  
                  final padding = EdgeInsets.all(isNarrow ? 16 : 32);

                  final List<_DashboardButton> actionButtons = [
                    _DashboardButton(
                      label: AppStrings.companySchedules,
                      route: '/company/schedules',
                      icon: Icons.calendar_today_rounded,
                      color: _accentColor,
                    ),
                    _DashboardButton(
                      label: AppStrings.drivers,
                      route: '/company/drivers',
                      icon: Icons.person_search_rounded,
                      color: Colors.purple,
                    ),
                    _DashboardButton(
                      label: AppStrings.companyProfile,
                      route: '/company/profile',
                      icon: Icons.business_rounded,
                      color: _primaryColor,
                    ),
                  ];

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: SingleChildScrollView(
                        padding: padding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            if (state.error != null) ...[
                              _ErrorDisplay(error: state.error!),
                              const SizedBox(height: 24),
                            ],

                            _HeroWelcomeBanner(
                              companyName: state.company?.name ?? 'Company',
                              textTheme: textTheme,
                              isNarrow: isNarrow,
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
                              future: _countsFuture,
                              builder: (context, snapshot) {
                                final driversCount = snapshot.data?['drivers'] ?? state.drivers.length;
                                final schedulesCount = snapshot.data?['schedules'] ?? state.schedules.length;
                                final reservationsCount = snapshot.data?['reservations'] ?? _calculateTotalReservations(state.reservationsBySchedule);

                                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                                  return Wrap(
                                    spacing: 24, 
                                    runSpacing: 24, 
                                    children: List.generate(3, (index) => _StatCard.loading(width: cardWidth)),
                                  );
                                }

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
                                      // 🔑 CORRECCIÓN: Añadida la ruta de navegación para que la tarjeta funcione
                                      route: '/company/drivers', 
                                    ),
                                    _StatCard(
                                      title: AppStrings.statSchedules,
                                      value: schedulesCount.toString(),
                                      icon: Icons.calendar_month_rounded,
                                      color: _accentColor,
                                      width: cardWidth,
                                      route: '/company/schedules',
                                    ),
                                    _StatCard(
                                      title: AppStrings.statReservations,
                                      value: reservationsCount.toString(),
                                      icon: Icons.event_seat_rounded,
                                      color: Colors.deepOrangeAccent,
                                      width: cardWidth,
                                      route: '/company/reservations', 
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
                            
                            Wrap(
                              spacing: 20,
                              runSpacing: 16,
                              alignment: isNarrow ? WrapAlignment.center : WrapAlignment.start,
                              children: actionButtons.map((button) {
                                final buttonWidth = isNarrow ? constraints.maxWidth - (padding.horizontal) : 350.0;
                                return SizedBox(
                                  width: buttonWidth,
                                  child: button,
                                );
                              }).toList(),
                            ),

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
// 👑 HERO WELCOME BANNER 
// -------------------------------------------------------------
class _HeroWelcomeBanner extends StatelessWidget {
  final String companyName;
  final TextTheme textTheme;
  final bool isNarrow;
  
  const _HeroWelcomeBanner({
    required this.companyName,
    required this.textTheme,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 24 : 32),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.waving_hand, color: _accentColor, size: isNarrow ? 36 : 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.welcome}, $companyName',
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
                Text(
                  'Manage your fleet, routes, and bookings efficiently.',
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 20),
            const Icon(Icons.departure_board_rounded, color: _primaryColor, size: 60),
          ]
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 📈 MODERN STAT CARD (Interactive y con corrección de tap)
// -------------------------------------------------------------
class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? width;
  final String? route; // 🔑 Este campo es clave para la navegación

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.width,
    this.route,
  });

  factory _StatCard.loading({required double width}) {
    return _StatCard(
      title: 'Loading...',
      value: '---',
      icon: Icons.hourglass_empty,
      color: Colors.grey,
      width: width,
    );
  }

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

  void _onTap() {
    // La navegación debe ocurrir aquí
    if (widget.route != null) {
      Navigator.pushNamed(context, widget.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractable = widget.route != null && widget.title != 'Loading...';

    return MouseRegion( 
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        // 🔑 Añadimos lógica para simular elevación y confirmar el tap en móvil
        onTapDown: (_) => setState(() => _elevation = 12.0),
        onTapUp: (_) => setState(() => _elevation = 6.0),
        onTapCancel: () => setState(() => _elevation = 6.0),
        onTap: isInteractable ? _onTap : null,
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
              // Usamos InkWell solo para el efecto visual de ripple
              onTap: isInteractable ? _onTap : null, 
              borderRadius: BorderRadius.circular(20),
              hoverColor: isInteractable ? widget.color.withOpacity(0.05) : null,
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
                                  fontWeight: widget.value == '---' ? FontWeight.w500 : FontWeight.w900, 
                                  color: widget.color, 
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
                        color: widget.color.withOpacity(0.1), 
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
      ),
    );
  }
}

// -------------------------------------------------------------
// 🚀 MODERN DASHBOARD BUTTON (Animado)
// -------------------------------------------------------------
class _DashboardButton extends StatefulWidget {
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
  State<_DashboardButton> createState() => _DashboardButtonState();
}

class _DashboardButtonState extends State<_DashboardButton> {
  double _elevation = 4.0;
  
  void _onHover(bool isHovering) {
    setState(() {
      _elevation = isHovering ? 10.0 : 4.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _elevation = 10.0),
        onTapUp: (_) => setState(() => _elevation = 4.0),
        onTapCancel: () => setState(() => _elevation = 4.0),
        onTap: () => Navigator.pushNamed(context, widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: double.infinity,
          child: Card(
            color: _cardBackgroundColor,
            elevation: _elevation,
            shadowColor: widget.color.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: widget.color.withOpacity(0.5), width: 1.5),
            ),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, widget.route),
              borderRadius: BorderRadius.circular(16),
              hoverColor: widget.color.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                height: 85, 
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 26), 
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.label,
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
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 🚫 ERROR DISPLAY (Pastilla de Advertencia)
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
        color: _warningColor.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _warningColor.withOpacity(0.6)),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline_rounded, color: _warningColor, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'ATTENTION: An operation failed.',
              style: TextStyle(color: Color(0xFFD35400), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}