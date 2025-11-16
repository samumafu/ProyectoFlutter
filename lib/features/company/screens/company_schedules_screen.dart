import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/features/company/models/company_model.dart';
import 'package:tu_flota/features/company/widgets/company_trip_card.dart';

class CompanySchedulesScreen extends ConsumerStatefulWidget {
  const CompanySchedulesScreen({super.key});

  @override
  ConsumerState<CompanySchedulesScreen> createState() => _CompanySchedulesScreenState();
}

class _CompanySchedulesScreenState extends ConsumerState<CompanySchedulesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(companyControllerProvider.notifier).loadAuthAndCompany();
      // If no company is associated, offer a quick selection when there is more than one
      final st = ref.read(companyControllerProvider);
      if (st.company == null) {
        final companies = await ref.read(companyControllerProvider.notifier).ref.read(supabaseProvider)
            .from('companies')
            .select();
        if (mounted && companies is List && companies.isNotEmpty) {
          showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Selecciona tu empresa'),
                content: SizedBox(
                  width: 320,
                  height: 240,
                  child: ListView(
                    children: companies.map<Widget>((e) {
                      final name = (e as Map<String, dynamic>)['name']?.toString() ?? 'Empresa';
                      return ListTile(
                        title: Text(name),
                        onTap: () {
                          final company = Company.fromMap(e as Map<String, dynamic>);
                          ref.read(companyControllerProvider.notifier).setCompany(company);
                          Navigator.of(ctx).pop();
                          ref.read(companyControllerProvider.notifier).loadSchedules();
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        }
      }
      await ref.read(companyControllerProvider.notifier).loadSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.companySchedules),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/company/trip/create'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 480;
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 8 : 16,
                      vertical: isNarrow ? 8 : 16,
                    ),
                    itemCount: state.schedules.length,
                    itemBuilder: (context, index) {
                      final s = state.schedules[index];
                      return CompanyTripCard(
                        schedule: s,
                        onEdit: () => Navigator.pushNamed(
                          context,
                          '/company/trip/edit',
                          arguments: s,
                        ),
                        onDelete: () async {
                          await ref.read(companyControllerProvider.notifier).deleteSchedule(s.id);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text(AppStrings.scheduleDeleted)),
                          );
                        },
                        onViewReservations: () async {
                          await ref.read(companyControllerProvider.notifier).loadReservationsForSchedule(s.id);
                          final reservations = ref.read(companyControllerProvider).reservationsBySchedule[s.id] ?? [];
                          showModalBottomSheet(
                            context: context,
                            builder: (_) => ListView(
                              padding: const EdgeInsets.all(12),
                              children: reservations.isEmpty
                                  ? [const ListTile(title: Text(AppStrings.noReservations))]
                                  : reservations
                                      .map((r) => ListTile(
                                            leading: const Icon(Icons.person),
                                            title: Text('${AppStrings.passenger}: ${r.passengerId}'),
                                            subtitle: Text('${AppStrings.seats}: ${r.seatsReserved} | ${AppStrings.total}: ${r.totalPrice} | ${AppStrings.status}: ${r.status}'),
                                          ))
                                      .toList(),
                            ),
                          );
                        },
                        onOpenChat: () async {
                          await ref.read(companyControllerProvider.notifier).loadMessagesForTrip(s.id);
                          ref.read(companyControllerProvider.notifier).subscribeTripMessages(s.id);
                          // Chat modal
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (ctx) {
                              final textCtrl = TextEditingController();
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                                ),
                                child: Consumer(
                                  builder: (context, ref, _) {
                                    final st = ref.watch(companyControllerProvider);
                                    final msgs = st.messagesByTrip[s.id] ?? [];
                                    return SizedBox(
                                      height: 420,
                                      child: Column(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.chat_bubble_outline),
                                            title: const Text(AppStrings.chat),
                                          ),
                                          const Divider(height: 1),
                                          Expanded(
                                            child: msgs.isEmpty
                                                ? const Center(child: Text(AppStrings.noMessages))
                                                : ListView.builder(
                                                    padding: const EdgeInsets.all(12),
                                                    itemCount: msgs.length,
                                                    itemBuilder: (context, i) {
                                                      final m = msgs[i];
                                                      return Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Container(
                                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                                          padding: const EdgeInsets.all(10),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey.shade200,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(m.message),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                m.senderId,
                                                                style: Theme.of(context).textTheme.bodySmall,
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
                                                    decoration: const InputDecoration(
                                                      labelText: AppStrings.message,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.send),
                                                  onPressed: () async {
                                                    final txt = textCtrl.text.trim();
                                                    if (txt.isEmpty) return;
                                                    await ref
                                                        .read(companyControllerProvider.notifier)
                                                        .sendMessage(tripId: s.id, text: txt);
                                                    textCtrl.clear();
                                                  },
                                                  tooltip: AppStrings.send,
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
                            ref.read(companyControllerProvider.notifier).unsubscribeTripMessages(s.id);
                          });
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}