import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tu_flota/core/models/user_model.dart';
import 'package:tu_flota/core/services/company_service.dart';
import 'package:tu_flota/core/services/trip_service.dart';
import 'package:tu_flota/core/services/reservation_service.dart';
import 'package:tu_flota/core/services/chat_service.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/features/passenger/models/reservation_model.dart';
import 'package:tu_flota/features/company/models/chat_message_model.dart';

// 1. Importación del modelo Driver (que movimos a su propia carpeta)
import 'package:tu_flota/features/driver/models/driver_model.dart'; 
// 2. Importación de Company (que está en su ruta original)
import 'package:tu_flota/features/company/models/company_model.dart'; 
// 3. Importaciones de modelos que tu controlador usa pero que no estaban listada

import 'package:tu_flota/features/company/models/company_schedule_model.dart';


class CompanyState {
  final UserModel? user;
  final Company? company;
  final List<Driver> drivers; // Ahora encuentra Driver
  final List<CompanySchedule> schedules;
  final Map<String, List<Reservation>> reservationsBySchedule; // Ahora encuentra Reservation
  final Map<String, List<ChatMessage>> messagesByTrip; // Ahora encuentra ChatMessage
  final bool isLoading;
  final String? error;

  const CompanyState({
    this.user,
    this.company,
    this.drivers = const [],
    this.schedules = const [],
    this.reservationsBySchedule = const {},
    this.messagesByTrip = const {},
    this.isLoading = false,
    this.error,
  });

  CompanyState copyWith({
    UserModel? user,
    Company? company,
    List<Driver>? drivers, // Ahora encuentra Driver
    List<CompanySchedule>? schedules,
    Map<String, List<Reservation>>? reservationsBySchedule,
    Map<String, List<ChatMessage>>? messagesByTrip,
    bool? isLoading,
    String? error,
  }) {
    return CompanyState(
      user: user ?? this.user,
      company: company ?? this.company,
      drivers: drivers ?? this.drivers,
      schedules: schedules ?? this.schedules,
      reservationsBySchedule: reservationsBySchedule ?? this.reservationsBySchedule,
      messagesByTrip: messagesByTrip ?? this.messagesByTrip,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CompanyController extends StateNotifier<CompanyState> {
  final Ref ref;
  late final SupabaseClient _client;
  late final CompanyService _companyService;
  late final TripService _tripService;
  late final ReservationService _reservationService;
  late final ChatService _chatService;
  final Map<String, RealtimeChannel> _chatChannels = {};
  RealtimeChannel? _driversChannel;
  RealtimeChannel? _schedulesChannel;

  CompanyController(this.ref) : super(const CompanyState()) {
    _client = ref.read(supabaseProvider);
    _companyService = CompanyService(_client);
    _tripService = TripService(_client);
    _reservationService = ReservationService(_client);
    _chatService = ChatService(_client);
  }

  Future<void> loadAuthAndCompany() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        state = CompanyState(
          user: null,
          company: null,
          drivers: state.drivers,
          schedules: state.schedules,
          reservationsBySchedule: state.reservationsBySchedule,
          messagesByTrip: state.messagesByTrip,
          isLoading: false,
          error: null,
        );
        return;
      }
      final userRow = await _client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      if (userRow == null) {
        state = CompanyState(
          user: null,
          company: null,
          drivers: state.drivers,
          schedules: state.schedules,
          reservationsBySchedule: state.reservationsBySchedule,
          messagesByTrip: state.messagesByTrip,
          isLoading: false,
          error: null,
        );
        return;
      }
      final user = UserModel.fromMap(userRow);
      // Try to associate company by email (case-insensitive)
      Company? company = await _companyService.fetchCompanyByEmail(user.email);
      // Fallback: if no match and there is only ONE company, select it
      if (company == null && user.role == 'empresa') {
        final all = await _companyService.listCompanies();
        if (all.length == 1) {
          company = all.first;
        }
      }
      // Preserve previously selected company if no association was found
      company ??= state.company;
      state = CompanyState(
        user: user,
        company: company,
        drivers: state.drivers,
        schedules: state.schedules,
        reservationsBySchedule: state.reservationsBySchedule,
        messagesByTrip: state.messagesByTrip,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateCompanyProfile(Company company) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final updated = await _companyService.updateCompany(company);
      state = state.copyWith(company: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> uploadLogo(Uint8List bytes, String fileName) async {
    try {
      final companyId = state.company?.id;
      if (companyId == null) return;
      state = state.copyWith(isLoading: true);
      final url = await _companyService.uploadCompanyLogo(
        companyId: companyId,
        bytes: bytes,
        fileName: fileName,
      );
      final updated = state.company?.copyWith(logoUrl: url);
      if (updated != null) {
        state = state.copyWith(company: updated, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadDrivers() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final companyId = state.company?.id;
      if (companyId == null) {
        state = state.copyWith(drivers: const [], isLoading: false);
        return;
      }
      final drivers = await _companyService.listDriversByCompany(companyId);
      state = state.copyWith(drivers: drivers, isLoading: false);
      _subscribeDriversRealtime();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createDriver(Driver driver) async {
    try {
      final cid = state.company?.id;
      if (cid == null) {
        throw Exception('Company is not selected');
      }
      final created = await _companyService.createDriver(
        Driver(
          id: driver.id,
          userId: driver.userId,
          name: driver.name,
          available: driver.available,
          phone: driver.phone,
          autoModel: driver.autoModel,
          autoColor: driver.autoColor,
          autoPlate: driver.autoPlate,
          rating: driver.rating,
          companyId: cid,
        ),
      );
      final updated = [...state.drivers, created];
      state = state.copyWith(drivers: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateDriver(Driver driver) async {
    try {
      final updatedDriver = await _companyService.updateDriver(driver);
      final updated = state.drivers
          .map((d) => d.id == updatedDriver.id ? updatedDriver : d)
          .toList();
      state = state.copyWith(drivers: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteDriver(String id) async {
    try {
      await _companyService.deleteDriver(id);
      state = state.copyWith(
        drivers: state.drivers.where((d) => d.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleDriverAvailability(String id, bool available) async {
    try {
      final updatedDriver =
          await _companyService.toggleDriverAvailability(id, available);
      state = state.copyWith(
        drivers: state.drivers
            .map((d) => d.id == updatedDriver.id ? updatedDriver : d)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadSchedules() async {
    try {
      final companyId = state.company?.id;
      if (companyId == null) return;
      state = state.copyWith(isLoading: true);
      final schedules = await _tripService.listSchedulesByCompany(companyId);
      state = state.copyWith(schedules: schedules, isLoading: false);
      _subscribeSchedulesRealtime();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createSchedule(CompanySchedule schedule) async {
    try {
      // Ensure schedule has the current company id
      final cid = state.company?.id;
      if (cid != null && schedule.companyId != cid) {
        schedule = CompanySchedule(
          id: schedule.id,
          companyId: cid,
          origin: schedule.origin,
          destination: schedule.destination,
          departureTime: schedule.departureTime,
          arrivalTime: schedule.arrivalTime,
          price: schedule.price,
          availableSeats: schedule.availableSeats,
          totalSeats: schedule.totalSeats,
          isActive: schedule.isActive,
          vehicleType: schedule.vehicleType,
          vehicleId: schedule.vehicleId,
          additionalInfo: schedule.additionalInfo,
        );
      }
      final created = await _tripService.createSchedule(schedule);
      state = state.copyWith(schedules: [...state.schedules, created]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Allow manual company selection when association is missing
  void setCompany(Company company) {
    state = state.copyWith(company: company);
  }

  Future<void> updateSchedule(CompanySchedule schedule) async {
    try {
      final updatedSchedule = await _tripService.updateSchedule(schedule);
      state = state.copyWith(
        schedules: state.schedules
            .map((s) => s.id == updatedSchedule.id ? updatedSchedule : s)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _tripService.deleteSchedule(id);
      state = state.copyWith(
        schedules: state.schedules.where((s) => s.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadReservationsForSchedule(String scheduleId) async {
    try {
      final reservations =
          await _reservationService.listReservationsForSchedule(scheduleId);
      final updatedMap = Map<String, List<Reservation>>.from(
          state.reservationsBySchedule);
      updatedMap[scheduleId] = reservations;
      state = state.copyWith(reservationsBySchedule: updatedMap);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMessagesForTrip(String tripId) async {
    try {
      final msgs = await _chatService.listMessages(tripId);
      final updatedMap = Map<String, List<ChatMessage>>.from(state.messagesByTrip);
      updatedMap[tripId] = msgs;
      state = state.copyWith(messagesByTrip: updatedMap);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendMessage({required String tripId, required String text}) async {
    try {
      final senderId = state.user?.id;
      if (senderId == null) return;
      final msg = await _chatService.sendMessage(
        tripId: tripId,
        senderId: senderId,
        message: text,
      );
      final list = <ChatMessage>[...(state.messagesByTrip[tripId] ?? const []), msg];
      final updatedMap = Map<String, List<ChatMessage>>.from(state.messagesByTrip);
      updatedMap[tripId] = list;
      state = state.copyWith(messagesByTrip: updatedMap);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void subscribeTripMessages(String tripId) {
    if (_chatChannels.containsKey(tripId)) return;
    final channel = _chatService.subscribeTripMessages(tripId, (msg) {
      final list = <ChatMessage>[...(state.messagesByTrip[tripId] ?? const []), msg];
      final updatedMap = Map<String, List<ChatMessage>>.from(state.messagesByTrip);
      updatedMap[tripId] = list;
      state = state.copyWith(messagesByTrip: updatedMap);
    });
    _chatChannels[tripId] = channel;
  }

  void unsubscribeTripMessages(String tripId) {
    final channel = _chatChannels.remove(tripId);
    channel?.unsubscribe();
  }

  // Internal realtime subscriptions
  void _subscribeDriversRealtime() {
    _driversChannel?.unsubscribe();
    _driversChannel = _companyService.subscribeDrivers(
      onInsert: (d) {
        final companyId = state.company?.id;
        if (companyId != null && d.companyId == companyId) {
          final updated = [...state.drivers, d];
          state = state.copyWith(drivers: updated);
        }
      },
      onUpdate: (d) {
        final companyId = state.company?.id;
        if (companyId != null && d.companyId == companyId) {
          final updated = state.drivers
              .map((e) => e.id == d.id ? d : e)
              .toList();
          state = state.copyWith(drivers: updated);
        }
      },
      onDelete: (id) {
        final updated = state.drivers.where((e) => e.id != id).toList();
        state = state.copyWith(drivers: updated);
      },
    );
  }

  void _subscribeSchedulesRealtime() {
    _schedulesChannel?.unsubscribe();
    _schedulesChannel = _tripService.subscribeSchedules(
      onInsert: (s) {
        final companyId = state.company?.id;
        if (companyId != null && s.companyId == companyId) {
          final updated = [...state.schedules, s];
          state = state.copyWith(schedules: updated);
        }
      },
      onUpdate: (s) {
        final companyId = state.company?.id;
        if (companyId != null && s.companyId == companyId) {
          final updated = state.schedules
              .map((e) => e.id == s.id ? s : e)
              .toList();
          state = state.copyWith(schedules: updated);
        }
      },
      onDelete: (id) {
        final updated = state.schedules.where((e) => e.id != id).toList();
        state = state.copyWith(schedules: updated);
      },
    );
  }

  // Helpers
  String formatIso(DateTime date, TimeOfDay time) {
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return dt.toIso8601String();
  }

  Future<Map<String, int>> loadCounts() async {
    final companyId = state.company?.id;
    if (companyId == null) {
      return {
        'drivers': state.drivers.length,
        'schedules': state.schedules.length,
        'reservations': state.reservationsBySchedule.values.fold<int>(0, (p, e) => p + e.length),
      };
    }

    // Schedules count filtered by company
    final schedulesRes = await _client
        .from('company_schedules')
        .select('id')
        .eq('company_id', companyId);
    final scheduleIds = (schedulesRes as List?)
            ?.map((e) => (e as Map<String, dynamic>)['id'].toString())
            .toList() ??
        const <String>[];

    // Reservations count filtered to schedules of this company
    List reservationsRes = const [];
    if (scheduleIds.isNotEmpty) {
      final inValues = '(${scheduleIds.map((e) => '"$e"').join(',')})';
      reservationsRes = await _client
          .from('reservations')
          .select('id')
          .filter('trip_id', 'in', inValues);
    }

    final driversRes = await _client
        .from('conductores')
        .select('id')
        .eq('company_id', companyId);
    final driversCount = (driversRes as List).length;

    return {
      'drivers': driversCount,
      'schedules': scheduleIds.length,
      'reservations': (reservationsRes as List).length,
    };
  }

  @override
  void dispose() {
    for (final c in _chatChannels.values) {
      c.unsubscribe();
    }
    _chatChannels.clear();
    _driversChannel?.unsubscribe();
    _driversChannel = null;
    _schedulesChannel?.unsubscribe();
    _schedulesChannel = null;
    super.dispose();
  }

  void reset() {
    for (final c in _chatChannels.values) {
      c.unsubscribe();
    }
    _chatChannels.clear();
    _driversChannel?.unsubscribe();
    _driversChannel = null;
    _schedulesChannel?.unsubscribe();
    _schedulesChannel = null;
    state = const CompanyState();
  }
}

final companyControllerProvider =
    StateNotifierProvider<CompanyController, CompanyState>((ref) {
  return CompanyController(ref);
});