import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/core/services/company_service.dart';
import 'package:tu_flota/core/services/trip_service.dart';
import 'package:tu_flota/core/services/reservation_service.dart';
import 'package:tu_flota/features/driver/models/driver_model.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/features/passenger/models/reservation_model.dart';
import 'package:tu_flota/core/services/chat_service.dart';
import 'package:tu_flota/features/company/models/chat_message_model.dart';
import 'package:tu_flota/core/constants/route_coordinates.dart';
import 'package:latlong2/latlong.dart';
import 'package:tu_flota/core/services/chat_service.dart';
import 'package:tu_flota/core/constants/route_coordinates.dart';
import 'package:latlong2/latlong.dart';

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
  final Map<String, List<Reservation>> _resBySchedule = {};
  final Map<String, RealtimeChannel> _resChannels = {};
  final Map<String, List<ChatMessage>> _msgsByTrip = {};
  final Map<String, RealtimeChannel> _chatChannels = {};
  final Map<String, String> _passengerEmailById = {};
  int _finishedCount = 0;
  int _transportedSeats = 0;

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
    if (d != null) {
      await _loadHistoryMetrics(d.id);
    }
  }

  Future<void> _loadHistoryMetrics(String driverId) async {
    final client = ref.read(supabaseProvider);
    final finished = await TripService(client)
        .client
        .from('company_schedules')
        .select('id')
        .eq('assigned_driver_id', driverId)
        .eq('driver_trip_status', 'finished');
    final finishedIds = (finished as List).map((e) => e['id'].toString()).toList();
    int seats = 0;
    for (final sid in finishedIds) {
      final res = await ReservationService(client).listReservationsForSchedule(sid);
      seats += res.fold<int>(0, (p, r) => p + r.seatsReserved);
    }
    if (mounted) {
      setState(() {
        _finishedCount = finishedIds.length;
        _transportedSeats = seats;
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

  Future<void> _startTrip(String scheduleId) async {
    setState(() => _updating = true);
    final client = ref.read(supabaseProvider);
    await TripService(client).startTrip(scheduleId: scheduleId);
    if (_driver != null) {
      final assigned = await TripService(client).listAssignedSchedulesForDriver(_driver!.id);
      if (mounted) setState(() => _assigned = assigned);
    }
    if (mounted) setState(() => _updating = false);
  }

  Future<void> _finishTrip(String scheduleId) async {
    setState(() => _updating = true);
    final client = ref.read(supabaseProvider);
    await TripService(client).finishTrip(scheduleId: scheduleId);
    if (_driver != null) {
      final assigned = await TripService(client).listAssignedSchedulesForDriver(_driver!.id);
      if (mounted) setState(() => _assigned = assigned);
    }
    if (mounted) setState(() => _updating = false);
  }

  void _openEditProfile() {
    final nameCtrl = TextEditingController(text: _driver?.name ?? '');
    final phoneCtrl = TextEditingController(text: _driver?.phone ?? '');
    final modelCtrl = TextEditingController(text: _driver?.autoModel ?? '');
    final colorCtrl = TextEditingController(text: _driver?.autoColor ?? '');
    final plateCtrl = TextEditingController(text: _driver?.autoPlate ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: AppStrings.driver)),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: AppStrings.phone)),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: AppStrings.vehicleModel)),
              TextField(controller: colorCtrl, decoration: const InputDecoration(labelText: AppStrings.vehicleColor)),
              TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: AppStrings.plate)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      if (_driver == null) return;
                      final client = ref.read(supabaseProvider);
                      final updated = await CompanyService(client).updateDriver(Driver(
                        id: _driver!.id,
                        userId: _driver!.userId,
                        name: nameCtrl.text.trim().isEmpty ? _driver!.name : nameCtrl.text.trim(),
                        available: _driver!.available,
                        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                        autoModel: modelCtrl.text.trim().isEmpty ? null : modelCtrl.text.trim(),
                        autoColor: colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
                        autoPlate: plateCtrl.text.trim().isEmpty ? null : plateCtrl.text.trim(),
                        rating: _driver!.rating,
                        companyId: _driver!.companyId,
                      ));
                      setState(() => _driver = updated);
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text(AppStrings.save),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadPassengers(String scheduleId) async {
    final client = ref.read(supabaseProvider);
    final res = await ReservationService(client).listReservationsForSchedule(scheduleId);
    if (mounted) {
      setState(() {
        _resBySchedule[scheduleId] = res;
      });
    }
    final pids = res.map((r) => r.passengerId).toSet().toList();
    final emails = await ReservationService(client).getPassengerEmailsByIds(pids);
    if (mounted) setState(() => _passengerEmailById.addAll(emails));
    if (!_resChannels.containsKey(scheduleId)) {
      final ch = ReservationService(client).subscribeReservationsForTrip(
        tripId: scheduleId,
        onInsert: (r) {
          final list = <Reservation>[...( _resBySchedule[scheduleId] ?? const []), r];
          setState(() => _resBySchedule[scheduleId] = list);
        },
        onUpdate: (r) {
          final list = (_resBySchedule[scheduleId] ?? const [])
              .map((e) => e.id == r.id ? r : e)
              .toList();
          setState(() => _resBySchedule[scheduleId] = list);
        },
        onDelete: (id) {
          final list = (_resBySchedule[scheduleId] ?? const [])
              .where((e) => e.id != id)
              .toList();
          setState(() => _resBySchedule[scheduleId] = list);
        },
      );
      _resChannels[scheduleId] = ch;
    }
  }

  Future<void> _toggleBoarded(Reservation r) async {
    final client = ref.read(supabaseProvider);
    final updated = await ReservationService(client).updateBoarded(r.id, !(r.boarded == true));
    final sid = updated.tripId;
    final list = (_resBySchedule[sid] ?? const [])
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    if (mounted) setState(() => _resBySchedule[sid] = list);
  }

  void _openRoute(CompanySchedule s) {
    final origin = getCoordinates(s.origin);
    final dest = getCoordinates(s.destination);
    Navigator.pushNamed(context, '/passenger/map/route', arguments: {'origin': origin, 'destination': dest});
  }

  void _openChat(String tripId) {
    final client = ref.read(supabaseProvider);
    if (!_chatChannels.containsKey(tripId)) {
      final ch = ChatService(client).subscribeTripMessages(tripId, (msg) {
        final list = <ChatMessage>[...( _msgsByTrip[tripId] ?? const []), msg];
        setState(() => _msgsByTrip[tripId] = list);
      });
      _chatChannels[tripId] = ch;
    }
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final messages = _msgsByTrip[tripId] ?? const [];
        final controller = TextEditingController();
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text(AppStrings.noMessages))
                    : ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (_, i) => ListTile(
                          title: Text(messages[i].message),
                        ),
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: AppStrings.message),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final userId = client.auth.currentUser?.id;
                      final text = controller.text.trim();
                      if (userId != null && text.isNotEmpty) {
                        await ChatService(client).sendMessage(tripId: tripId, senderId: userId, message: text);
                        controller.clear();
                      }
                    },
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
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
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(AppStrings.available),
                                  const Spacer(),
                                  Switch(
                                    value: _driver!.available,
                                    onChanged: (v) async {
                                      setState(() => _driver = Driver(
                                        id: _driver!.id,
                                        userId: _driver!.userId,
                                        name: _driver!.name,
                                        available: v,
                                        phone: _driver!.phone,
                                        autoModel: _driver!.autoModel,
                                        autoColor: _driver!.autoColor,
                                        autoPlate: _driver!.autoPlate,
                                        rating: _driver!.rating,
                                        companyId: _driver!.companyId,
                                      ));
                                      final client = ref.read(supabaseProvider);
                                      await CompanyService(client).toggleDriverAvailability(_driver!.id, v);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _openEditProfile(),
                                    icon: const Icon(Icons.edit),
                                    label: const Text(AppStrings.editProfile),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(AppStrings.assignedTrips, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Text('Finished Trips', style: theme.textTheme.bodyMedium), const SizedBox(height:4), Text('$_finishedCount')])))),
                          const SizedBox(width: 8),
                          Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Text('Passengers Transported', style: theme.textTheme.bodyMedium), const SizedBox(height:4), Text('$_transportedSeats')])))),
                        ],
                      ),
                      Expanded(
                        child: _assigned.isEmpty
                            ? const Center(child: Text(AppStrings.noActiveTripsFound))
                            : ListView.separated(
                                itemCount: _assigned.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final s = _assigned[index];
                                  final statusLabel = s.driverTripStatus == 'in_progress'
                                      ? AppStrings.inProgress
                                      : s.driverTripStatus == 'finished'
                                          ? AppStrings.finished
                                          : s.assignmentStatus == 'accepted'
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
                                              ] else if (s.assignmentStatus == 'accepted' && s.driverTripStatus != 'in_progress' && s.driverTripStatus != 'finished') ...[
                                                TextButton(
                                                  onPressed: _updating ? null : () => _startTrip(s.id),
                                                  child: const Text(AppStrings.startTrip),
                                                ),
                                              ] else if (s.driverTripStatus == 'in_progress') ...[
                                                TextButton(
                                                  onPressed: _updating ? null : () => _finishTrip(s.id),
                                                  child: const Text(AppStrings.finishTrip),
                                                ),
                                              ],
                                              OutlinedButton.icon(
                                                onPressed: () => _openRoute(s),
                                                icon: const Icon(Icons.map_outlined),
                                                label: const Text('View Route'),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton.icon(
                                                onPressed: () => _openChat(s.id),
                                                icon: const Icon(Icons.chat_bubble_outline),
                                                label: const Text(AppStrings.chat),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton(
                                              onPressed: () => _loadPassengers(s.id),
                                              child: const Text('View Passengers'),
                                            ),
                                          ),
                                          if (_resBySchedule[s.id] != null) ...[
                                            const SizedBox(height: 4),
                                            Text('${AppStrings.passenger}: ${_resBySchedule[s.id]!.length}'),
                                            const SizedBox(height: 6),
                                           ..._resBySchedule[s.id]!.map((r) => Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.person_outline, size: 18),
                                                      const SizedBox(width: 6),
                                                      Expanded(child: Text(_passengerEmailById[r.passengerId] ?? r.passengerId)),
                                                      Text('${AppStrings.seats}: ${r.seatsReserved}'),
                                                      const SizedBox(width: 8),
                                                      Text(r.status),
                                                      const SizedBox(width: 8),
                                                      if (r.pickupLatitude != null && r.pickupLongitude != null)
                                                        Text('(${r.pickupLatitude}, ${r.pickupLongitude})'),
                                                      const SizedBox(width: 8),
                                                      TextButton(
                                                        onPressed: () => _toggleBoarded(r),
                                                        child: Text(r.boarded == true ? 'Set Not Boarded' : 'Set Boarded'),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                          ],
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