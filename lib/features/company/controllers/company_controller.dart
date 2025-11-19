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
import 'package:tu_flota/features/driver/models/driver_model.dart'; 
import 'package:tu_flota/features/company/models/company_model.dart'; 
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'dart:developer'; // Importar para usar la función log()


class CompanyState {
  final UserModel? user;
  final Company? company;
  final List<Driver> drivers; 
  final List<CompanySchedule> schedules;
  final Map<String, List<Reservation>> reservationsBySchedule; 
  final Map<String, List<ChatMessage>> messagesByTrip; 
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

  // --- LÓGICA DE AUTENTICACIÓN Y PERFIL DE COMPAÑÍA ---

  Future<void> loadAuthAndCompany() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        log('AUTH DEBUG: No authenticated user found.');
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
        log('AUTH DEBUG: User row not found for UID: ${authUser.id}');
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
      log('AUTH DEBUG: Company loaded: ${company?.name ?? 'N/A'} (ID: ${company?.id ?? 'N/A'})');
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
      log('ERROR: loadAuthAndCompany failed: $e');
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

  void setCompany(Company company) {
    state = state.copyWith(company: company);
  }

  // --- LÓGICA DE CONDUCTORES (DRIVERS) ---

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

  // --- LÓGICA DE HORARIOS (SCHEDULES) Y RESERVAS ---

  Future<void> loadSchedules() async {
    try {
      final companyId = state.company?.id;
      if (companyId == null) {
        log('DEBUG SCHEDULES: Cannot load schedules. Company ID is null.');
        return;
      }
      state = state.copyWith(isLoading: true);
      
      // 1. Cargar Horarios
      final schedules = await _tripService.listSchedulesByCompany(companyId);
      
      // ** LOG DE HORARIOS **
      log('DEBUG SCHEDULES: Loaded ${schedules.length} schedules from service.');
      
      // 2. Actualizar estado con horarios
      state = state.copyWith(schedules: schedules, isLoading: false);

      // 3. PASO CLAVE: Cargar todas las reservas
      await _loadAllReservations();
      
      _subscribeSchedulesRealtime();
    } catch (e) {
      log('ERROR: loadSchedules failed: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // MÉTODO AGREGADO: Carga todas las reservas de la compañía de forma masiva
  Future<void> _loadAllReservations() async {
    final scheduleIds = state.schedules.map((s) => s.id).toList();
    
    // ** LOG DE RESERVAS **
    log('DEBUG RESERVATIONS: Starting load for ${scheduleIds.length} trip IDs.');
    
    if (scheduleIds.isEmpty) {
        state = state.copyWith(reservationsBySchedule: {});
        log('DEBUG RESERVATIONS: No schedule IDs, exiting load.');
        return;
    }

    // Cargar todas las reservas en paralelo
    final results = await Future.wait(
      scheduleIds.map((id) => _reservationService.listReservationsForSchedule(id))
    );

    // Reconstruir el mapa de reservas
    final updatedMap = <String, List<Reservation>>{};
    int totalReservations = 0;
    for (int i = 0; i < scheduleIds.length; i++) {
        updatedMap[scheduleIds[i]] = results[i];
        totalReservations += results[i].length;
    }

    // ** LOG FINAL DE RESERVAS **
    log('DEBUG RESERVATIONS: Finished loading. Total reservations found: $totalReservations');

    // Actualizar estado con todas las reservas
    state = state.copyWith(reservationsBySchedule: updatedMap);
  }

  Future<void> createSchedule(CompanySchedule schedule) async {
    // ... (código sin cambios)
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

  Future<void> updateSchedule(CompanySchedule schedule) async {
    // ... (código sin cambios)
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
    // ... (código sin cambios)
    try {
      await _tripService.deleteSchedule(id);
      state = state.copyWith(
        schedules: state.schedules.where((s) => s.id != id).toList(),
        // Opcional: Limpiar las reservas asociadas al horario eliminado
        reservationsBySchedule: Map.from(state.reservationsBySchedule)..remove(id),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Este método solo carga las reservas para un *único* horario,
  Future<void> loadReservationsForSchedule(String scheduleId) async {
    // ... (código sin cambios)
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

  // --- LÓGICA DE CHAT ---
  // ... (métodos de chat sin cambios)

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


  // --- SUSCRIPCIONES EN TIEMPO REAL (REALTIME) ---
  // ... (métodos de suscripción sin cambios)

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
          // Opcional: Limpiar las reservas asociadas al horario eliminado
        state = state.copyWith(
          schedules: updated,
          reservationsBySchedule: Map.from(state.reservationsBySchedule)..remove(id),
        );
      },
    );
  }

  // --- AYUDAS Y CONTADORES ---

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

    // Drivers count filtered by company
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

  // --- DISPOSE Y RESET ---

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