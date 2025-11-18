// Archivo: lib/features/company/screens/company_schedules_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/features/company/models/company_model.dart';
import 'package:tu_flota/features/company/widgets/company_trip_card.dart';


// Color definitions for design consistency
const Color _primaryColor = Color(0xFF1E88E5); // Primary Blue
const Color _secondaryColor = Color(0xFF00C853); // Accent Green for success/reservations
const Color _secondaryBackgroundColor = Color(0xFFF0F4F8); // Soft background
const Color _cardBackgroundColor = Colors.white;

class CompanySchedulesScreen extends ConsumerStatefulWidget {
  const CompanySchedulesScreen({super.key});

  @override
  ConsumerState<CompanySchedulesScreen> createState() => _CompanySchedulesScreenState();
}

class _CompanySchedulesScreenState extends ConsumerState<CompanySchedulesScreen> {
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadInitialData());
  }

  // Unified method for data loading and company selection logic
  Future<void> _loadInitialData() async {
    final notifier = ref.read(companyControllerProvider.notifier);
    final current = ref.read(companyControllerProvider);

    // If a company is already selected, just load schedules and return
    if (current.company != null) {
      await notifier.loadSchedules();
      return;
    }

    // Try to load auth and associated company
    await notifier.loadAuthAndCompany();
    final state = ref.read(companyControllerProvider);

    // If still no company, prompt once for selection
    if (state.company == null && mounted) {
      final supabase = ref.read(supabaseProvider);
      final response = await supabase.from('companies').select();

      if (mounted && response is List) {
        final companies = response.whereType<Map<String, dynamic>>().toList();
        if (companies.length == 1) {
          final company = Company.fromMap(companies.first);
          notifier.setCompany(company);
        } else if (companies.length > 1) {
          _showCompanySelectionDialog(companies);
          return; // loadSchedules is called after selection
        }
      }
    }

    // Load schedules when company is set or confirmed
    await notifier.loadSchedules();
  }

  // Diseño mejorado del diálogo de selección de compañía
  void _showCompanySelectionDialog(List<Map<String, dynamic>> companies) {
    showDialog(
      context: context,
      builder: (ctx) {
        final notifier = ref.read(companyControllerProvider.notifier); 

        return AlertDialog(
          backgroundColor: _cardBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            AppStrings.selectYourCompany, 
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              color: _primaryColor
            ),
          ),
          content: SizedBox(
            width: 320,
            height: 240,
            child: ListView(
              shrinkWrap: true,
              children: companies.map<Widget>((companyMap) {
                final name = companyMap['name']?.toString() ?? 'Company';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Material(
                    color: _secondaryBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        final company = Company.fromMap(companyMap);
                        notifier.setCompany(company);
                        notifier.loadSchedules();
                        Navigator.of(ctx).pop(); 
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.apartment_outlined, color: _primaryColor, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.black54, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyControllerProvider);
    final notifier = ref.read(companyControllerProvider.notifier); 

    // Determines the appropriate padding for centering content on large screens
    final double maxContentWidth = 980; 

    return Scaffold(
      backgroundColor: _secondaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: _cardBackgroundColor,
        elevation: 4, // Mayor elevación para sensación de material
        centerTitle: false,
        title: Text(
          AppStrings.companySchedules, 
          style: Theme.of(context).textTheme.headlineSmall?.copyWith( // Fuente más grande
            fontWeight: FontWeight.w800, 
            color: Colors.black87
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primaryColor,
        foregroundColor: _cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bordes más suaves
        onPressed: () => Navigator.pushNamed(context, '/company/trip/create'),
        label: const Text('New Trip', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        icon: const Icon(Icons.add, size: 24),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: _primaryColor))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > maxContentWidth;
                  final horizontalPadding = isWide 
                      ? (constraints.maxWidth - maxContentWidth) / 2 
                      : 16.0;

                  // Show an error/empty state if data is missing or loading failed
                  if (state.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Card(
                          color: Colors.red.shade50,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.red, width: 1)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Error loading schedules: ${state.error}',
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  // Empty State Design Mejorado
                  if (state.schedules.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bus_alert, size: 100, color: _primaryColor.withOpacity(0.5)), // Ícono más llamativo
                            const SizedBox(height: 24),
                            Text(
                              AppStrings.noActiveTripsFound,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              AppStrings.tapPlusToCreate,
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Display the list of schedules
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding.clamp(16, 120),
                      vertical: 20,
                    ),
                    itemCount: state.schedules.length,
                    itemBuilder: (context, index) {
                      final s = state.schedules[index];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: CompanyTripCard(
                          schedule: s,
                          onEdit: () => Navigator.pushNamed(
                            context,
                            '/company/trip/edit',
                            arguments: s,
                          ),
                          // Usar 'notifier' guardado para evitar Bad State en async actions
                          onDelete: () => _showDeleteConfirmation(context, notifier, s.id), 
                          onViewReservations: () => _showReservationsModal(context, notifier, s.id),
                          onOpenChat: () => _showChatModal(context, notifier, s.id),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  // --- Helper Methods for Modals (Diseño Mejorado) ---

  Future<void> _showDeleteConfirmation(BuildContext context, CompanyController notifier, String scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this trip schedule? This action cannot be undone.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await notifier.deleteSchedule(scheduleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.scheduleDeleted),
            backgroundColor: _secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 100, left: 10, right: 10),
          ),
        );
      }
    }
  }

  void _showReservationsModal(BuildContext context, CompanyController notifier, String scheduleId) async {
    await notifier.loadReservationsForSchedule(scheduleId);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // Bordes más suaves
      ),
      builder: (_) => Consumer(
        builder: (context, ref, child) {
          final reservations = ref.watch(companyControllerProvider).reservationsBySchedule[scheduleId] ?? [];
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7, // Altura un poco mayor
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Reservations for Trip',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _primaryColor,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: reservations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_seat_outlined, size: 60, color: Colors.black26),
                              SizedBox(height: 10),
                              Text(AppStrings.noReservations, style: TextStyle(color: Colors.black54, fontSize: 16))
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: reservations.length,
                          padding: const EdgeInsets.only(top: 10, bottom: 20),
                          itemBuilder: (context, index) {
                            final r = reservations[index];
                            final statusColor = r.status == 'confirmed' ? _secondaryColor : Colors.red;
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _primaryColor,
                                child: Text(r.seatsReserved.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(
                                '${AppStrings.passenger}: ${r.passengerId}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${AppStrings.total}: \$${r.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              trailing: Chip(
                                label: Text(r.status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                                backgroundColor: statusColor.withOpacity(0.1),
                                side: BorderSide(color: statusColor),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showChatModal(BuildContext context, CompanyController notifier, String tripId) async {
    await notifier.loadMessagesForTrip(tripId);
    notifier.subscribeTripMessages(tripId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // Bordes más suaves
      ),
      builder: (ctx) {
        final textCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(companyControllerProvider);
              final msgs = state.messagesByTrip[tripId] ?? [];
              
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.8, // Mayor altura para el chat
                child: Column(
                  children: [
                    // Header de Chat Mejorado
                    Container(
                      decoration: const BoxDecoration(
                        color: _cardBackgroundColor,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, color: _primaryColor, size: 28),
                        title: const Text(AppStrings.chat, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        subtitle: const Text('Real-time conversation with passengers', style: TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 28),
                          onPressed: () {
                            notifier.unsubscribeTripMessages(tripId);
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: msgs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.comment_outlined, size: 60, color: Colors.black26),
                                  SizedBox(height: 10),
                                  Text(AppStrings.noMessages, style: TextStyle(color: Colors.black54, fontSize: 16))
                                ],
                              ),
                            )
                          : ListView.builder(
                              reverse: true, 
                              padding: const EdgeInsets.all(12),
                              itemCount: msgs.length,
                              itemBuilder: (context, i) {
                                final m = msgs[i];
                                final isCompany = m.senderId.startsWith('co_'); 
                                
                                final timeString = m.createdAt != null
                                    ? m.createdAt!.toLocal().toString().substring(11, 16)
                                    : 'Time';

                                // Diseño de Burbuja de Chat Mejorado
                                return Align(
                                  alignment: isCompany ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.all(12),
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                    decoration: BoxDecoration(
                                      color: isCompany ? _primaryColor : Colors.grey.shade200,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(isCompany ? 16 : 4), // Esquina inferior propia más pequeña
                                        bottomRight: Radius.circular(isCompany ? 4 : 16), // Esquina inferior propia más pequeña
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Texto del mensaje
                                        Text(
                                          m.message,
                                          style: TextStyle(color: isCompany ? Colors.white : Colors.black87, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        // Info del sender y timestamp
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isCompany ? 'You' : m.senderId.substring(0, 7), // Mostrar ID corto o 'You'
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: isCompany ? Colors.white70 : Colors.black54,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '• $timeString',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: isCompany ? Colors.white70 : Colors.black54,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    
                    // Input de mensaje mejorado
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textCtrl,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: AppStrings.message,
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30), // Borde muy redondeado
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              onSubmitted: (value) async {
                                final txt = textCtrl.text.trim();
                                if (txt.isEmpty) return;
                                await notifier.sendMessage(tripId: tripId, text: txt); 
                                textCtrl.clear();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botón de enviar redondeado
                          FloatingActionButton(
                            mini: true,
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            onPressed: () async {
                              final txt = textCtrl.text.trim();
                              if (txt.isEmpty) return;
                              await notifier.sendMessage(tripId: tripId, text: txt); 
                              textCtrl.clear();
                            },
                            tooltip: AppStrings.send,
                            child: const Icon(Icons.send_rounded),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      // Limpiar la suscripción en 'whenComplete'
      notifier.unsubscribeTripMessages(tripId);
    });
  }
}