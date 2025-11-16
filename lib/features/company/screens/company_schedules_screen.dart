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
    await notifier.loadAuthAndCompany();

    final state = ref.read(companyControllerProvider);
    if (state.company == null) {
      final supabase = ref.read(supabaseProvider);
      final companies = await supabase.from('companies').select();

      if (mounted && companies is List && companies.isNotEmpty) {
        if (companies.length == 1) {
           // Auto-select if only one company is available
          final company = Company.fromMap(companies.first as Map<String, dynamic>);
          notifier.setCompany(company);
        } else {
          // Show selection dialog for multiple companies
          _showCompanySelectionDialog(companies);
        }
      }
    }
    // Load schedules after company is set or confirmed
    await notifier.loadSchedules();
  }

  void _showCompanySelectionDialog(List<dynamic> companies) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select your Company', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 320,
            height: 240,
            child: ListView(
              shrinkWrap: true,
              children: companies.map<Widget>((e) {
                final companyMap = e as Map<String, dynamic>;
                final name = companyMap['name']?.toString() ?? 'Company';
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.business_outlined, color: _primaryColor),
                    title: Text(name),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      final company = Company.fromMap(companyMap);
                      ref.read(companyControllerProvider.notifier).setCompany(company);
                      Navigator.of(ctx).pop();
                      ref.read(companyControllerProvider.notifier).loadSchedules();
                    },
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
        elevation: 1,
        title: Text(
          AppStrings.companySchedules, 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold, 
            color: Colors.black87
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primaryColor,
        foregroundColor: _cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => Navigator.pushNamed(context, '/company/trip/create'),
        label: const Text('New Trip', style: TextStyle(fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.add),
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
                        child: Text(
                          'Error loading schedules: ${state.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  
                  if (state.schedules.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.departure_board_outlined, size: 80, color: Colors.black26),
                          SizedBox(height: 16),
                          Text(
                            'No active trips found.',
                            style: TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                          Text(
                            'Tap the "+" button to create a new schedule.',
                            style: TextStyle(fontSize: 14, color: Colors.black45),
                          ),
                        ],
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

  // --- Helper Methods for Modals ---

  Future<void> _showDeleteConfirmation(BuildContext context, CompanyController notifier, String scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this trip schedule? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await notifier.deleteSchedule(scheduleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.scheduleDeleted)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, child) {
          final reservations = ref.watch(companyControllerProvider).reservationsBySchedule[scheduleId] ?? [];
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Reservations for Trip',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: reservations.isEmpty
                      ? const Center(child: Text(AppStrings.noReservations, style: TextStyle(color: Colors.black54)))
                      : ListView(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          children: reservations
                              .map((r) => ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _primaryColor.withOpacity(0.1),
                                      child: const Icon(Icons.person, color: _primaryColor, size: 20),
                                    ),
                                    title: Text('${AppStrings.passenger}: ${r.passengerId}'),
                                    subtitle: Text(
                                        '${AppStrings.seats}: ${r.seatsReserved} | ${AppStrings.total}: \$${r.totalPrice.toStringAsFixed(2)} | ${AppStrings.status}: ${r.status}'),
                                  ))
                              .toList(),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.forum_outlined, color: _primaryColor),
                      title: const Text(AppStrings.chat, style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: msgs.isEmpty
                          ? const Center(child: Text(AppStrings.noMessages, style: TextStyle(color: Colors.black54)))
                          : ListView.builder(
                              reverse: true, 
                              padding: const EdgeInsets.all(12),
                              itemCount: msgs.length,
                              itemBuilder: (context, i) {
                                final m = msgs[i];
                                final isCompany = m.senderId.startsWith('co_'); 
                                
                                // Esto ahora funciona porque ChatMessage tiene 'createdAt'
                                final timeString = m.createdAt != null
                                    ? m.createdAt!.toLocal().toString().substring(11, 16)
                                    : 'Time';

                                return Align(
                                  alignment: isCompany ? Alignment.centerLeft : Alignment.centerRight,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(10),
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                    decoration: BoxDecoration(
                                      color: isCompany ? _primaryColor.withOpacity(0.8) : Colors.grey.shade300,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(isCompany ? 12 : 12),
                                        topRight: Radius.circular(isCompany ? 12 : 12),
                                        bottomLeft: Radius.circular(isCompany ? 0 : 12),
                                        bottomRight: Radius.circular(isCompany ? 12 : 0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isCompany ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          m.message,
                                          style: TextStyle(color: isCompany ? Colors.white : Colors.black87),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${m.senderId} - $timeString',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: isCompany ? Colors.white70 : Colors.black54,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textCtrl,
                              decoration: InputDecoration(
                                labelText: AppStrings.message,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: () async {
                                final txt = textCtrl.text.trim();
                                if (txt.isEmpty) return;
                                await ref
                                    .read(companyControllerProvider.notifier)
                                    .sendMessage(tripId: tripId, text: txt);
                                textCtrl.clear();
                              },
                              tooltip: AppStrings.send,
                            ),
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
      // Clean up the realtime subscription when chat is closed
      notifier.unsubscribeTripMessages(tripId);
    });
  }
}