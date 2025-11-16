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
import 'package:tu_flota/features/company/models/company_model.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';

class CompanyState {
  final UserModel? user;
  final Company? company;
  final List<Driver> drivers;
  final List<CompanySchedule> schedules;
  final Map<int, List<Reservation>> reservationsBySchedule;
  final Map<int, List<ChatMessage>> messagesByTrip;
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
    List<Driver>? drivers,
    List<CompanySchedule>? schedules,
    Map<int, List<Reservation>>? reservationsBySchedule,
    Map<int, List<ChatMessage>>? messagesByTrip,
    bool? isLoading,
    String? error,
  }) {
    return CompanyState(
      user: user ?? this.user,
      company: company ?? this.company,
      drivers: drivers ?? this.drivers,
      schedules: schedules ?? this.schedules,
      reservationsBySchedule:
          reservationsBySchedule ?? this.reservationsBySchedule,
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
  final Map<int, RealtimeChannel> _chatChannels = {};
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
        state = state.copyWith(isLoading: false);
        return;
      }
      final userRow = await _client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      if (userRow == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final user = UserModel.fromMap(userRow);
      final company = await _companyService.fetchCompanyById(user.id);
      state = state.copyWith(user: user, company: company, isLoading: false);
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
      final drivers = await _companyService.listDrivers();
      state = state.copyWith(drivers: drivers, isLoading: false);
      _subscribeDriversRealtime();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createDriver(Driver driver) async {
    try {
      final created = await _companyService.createDriver(driver);
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

  Future<void> deleteDriver(int id) async {
    try {
      await _companyService.deleteDriver(id);
      state = state.copyWith(
        drivers: state.drivers.where((d) => d.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleDriverAvailability(int id, bool available) async {
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
      final created = await _tripService.createSchedule(schedule);
      state = state.copyWith(schedules: [...state.schedules, created]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
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

  Future<void> deleteSchedule(int id) async {
    try {
      await _tripService.deleteSchedule(id);
      state = state.copyWith(
        schedules: state.schedules.where((s) => s.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadReservationsForSchedule(int scheduleId) async {
    try {
      final reservations =
          await _reservationService.listReservationsForSchedule(scheduleId);
      final updatedMap = Map<int, List<Reservation>>.from(
          state.reservationsBySchedule);
      updatedMap[scheduleId] = reservations;
      state = state.copyWith(reservationsBySchedule: updatedMap);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMessagesForTrip(int tripId) async {
    try {
      final msgs = await _chatService.listMessages(tripId);
      final updatedMap = Map<int, List<ChatMessage>>.from(state.messagesByTrip);
      updatedMap[tripId] = msgs;
      state = state.copyWith(messagesByTrip: updatedMap);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendMessage({required int tripId, required String text}) async {
    try {
      final senderId = state.user?.id;
      if (senderId == null) return;
      final msg = await _chatService.sendMessage(
        tripId: tripId,
        senderId: senderId,
        message: text,
      );
      final list = <ChatMessage>[...(state.messagesByTrip[tripId] ?? const []), msg];
      final updatedMap = Map<int, List<ChatMessage>>.from(state.messagesByTrip);
      updatedMap[tripId] = list;
      state = state.copyWith(messagesByTrip: updatedMap);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void subscribeTripMessages(int tripId) {
    if (_chatChannels.containsKey(tripId)) return;
    final channel = _chatService.subscribeTripMessages(tripId, (msg) {
      final list = <ChatMessage>[...(state.messagesByTrip[tripId] ?? const []), msg];
      final updatedMap = Map<int, List<ChatMessage>>.from(state.messagesByTrip);
      updatedMap[tripId] = list;
      state = state.copyWith(messagesByTrip: updatedMap);
    });
    _chatChannels[tripId] = channel;
  }

  void unsubscribeTripMessages(int tripId) {
    final channel = _chatChannels.remove(tripId);
    channel?.unsubscribe();
  }

  // Internal realtime subscriptions
  void _subscribeDriversRealtime() {
    _driversChannel?.unsubscribe();
    _driversChannel = _companyService.subscribeDrivers(
      onInsert: (d) {
        final updated = [...state.drivers, d];
        state = state.copyWith(drivers: updated);
      },
      onUpdate: (d) {
        final updated = state.drivers
            .map((e) => e.id == d.id ? d : e)
            .toList();
        state = state.copyWith(drivers: updated);
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
        final updated = [...state.schedules, s];
        state = state.copyWith(schedules: updated);
      },
      onUpdate: (s) {
        final updated = state.schedules
            .map((e) => e.id == s.id ? s : e)
            .toList();
        state = state.copyWith(schedules: updated);
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
    // Counts fetched directly from DB for dashboard
    final driversRes = await _client.from('conductores').select('id');
    final schedulesRes = await _client.from('company_schedules').select('id');
    final reservationsRes = await _client.from('reservations').select('id');
    final driversCount = (driversRes as List?)?.length ?? state.drivers.length;
    final schedulesCount = (schedulesRes as List?)?.length ?? state.schedules.length;
    final reservationsCount = (reservationsRes as List?)?.length ??
        state.reservationsBySchedule.values.fold<int>(0, (p, e) => p + e.length);
    return {
      'drivers': driversCount,
      'schedules': schedulesCount,
      'reservations': reservationsCount,
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
}

final companyControllerProvider =
    StateNotifierProvider<CompanyController, CompanyState>((ref) {
  return CompanyController(ref);
});