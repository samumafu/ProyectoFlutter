// 📝 lib/features/passenger/controllers/passenger_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/core/services/trip_service.dart';
import 'package:tu_flota/core/services/reservation_service.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/features/passenger/models/reservation_model.dart'; 
import 'package:tu_flota/features/passenger/models/reservation_history_dto.dart';
import 'package:tu_flota/core/data/narino_municipalities.dart'; 

// --------------------------------------------------------------------------
// 1. ESTADO CORREGIDO: Acepta ReservationHistory para el historial
// --------------------------------------------------------------------------
class PassengerState {
  final List<CompanySchedule> trips;
  // 🛑 CAMBIO CLAVE: Cambiado de List<Reservation> a List<ReservationHistory>
  final List<ReservationHistory> myReservations;
  final bool isLoading;
  final String? error;
  final List<String> municipalities; 

  const PassengerState({
    this.trips = const [],
    // Inicialización con el nuevo tipo
    this.myReservations = const [],
    this.isLoading = false,
    this.error,
    this.municipalities = const [], 
  });

  PassengerState copyWith({
    List<CompanySchedule>? trips,
    // 🛑 CAMBIO CLAVE: El copyWith acepta la lista de historial
    List<ReservationHistory>? myReservations,
    bool? isLoading,
    String? error,
    List<String>? municipalities, 
  }) {
    return PassengerState(
      trips: trips ?? this.trips,
      myReservations: myReservations ?? this.myReservations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      municipalities: municipalities ?? this.municipalities, 
    );
  }
}

// --------------------------------------------------------------------------
// 2. CONTROLLER CORREGIDO
// --------------------------------------------------------------------------
class PassengerController extends StateNotifier<PassengerState> {
  final Ref ref;
  late final SupabaseClient _client;
  late final TripService _tripService;
  late final ReservationService _reservationService;

  PassengerController(this.ref) : super(const PassengerState()) {
    _client = ref.read(supabaseProvider);
    _tripService = TripService(_client);
    _reservationService = ReservationService(_client);
  }

  Future<void> loadMunicipalities() async {
    final List<String> loadedMunicipalities = narinoMunicipalities;
    if (state.municipalities.isEmpty && loadedMunicipalities.isNotEmpty) {
      state = state.copyWith(
        municipalities: loadedMunicipalities,
        error: null, 
      );
    }
  }

  Future<void> loadAllTrips() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await _client
          .from('company_schedules')
          .select()
          .eq('is_active', true)
          .order('departure_time');
      final trips = (data as List<dynamic>)
          .map((e) => CompanySchedule.fromMap(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(trips: trips, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> searchTrips({String? origin, String? destination}) async {
    try {
      final o = origin?.trim() ?? '';
      final d = destination?.trim() ?? '';
      if (o.isEmpty && d.isEmpty) {
        await loadAllTrips();
        return;
      }
      state = state.copyWith(isLoading: true, error: null);
      var query = _client.from('company_schedules').select().eq('is_active', true);
      if (o.isNotEmpty) {
        query = query.ilike('origin', '%$o%');
      }
      if (d.isNotEmpty) {
        query = query.ilike('destination', '%$d%');
      }
      final data = await query.order('departure_time');
      final trips = (data as List<dynamic>)
          .map((e) => CompanySchedule.fromMap(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(trips: trips, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Reservation> reserveSeats({
    required CompanySchedule schedule,
    required int seats,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Debes iniciar sesión para reservar');
      }
      final passengerId = await _ensurePassengerId(userId);
      final totalPrice = schedule.price * seats;
      final res = await _reservationService.createReservation(
        tripId: schedule.id,
        passengerId: passengerId,
        seats: seats,
        totalPrice: totalPrice,
      );
      final newAvailable = await _tripService.decrementAvailableSeats(schedule.id, seats);
      
      final updatedTrips = state.trips
          .map((t) => t.id == schedule.id
              ? CompanySchedule(
                  id: t.id,
                  companyId: t.companyId,
                  origin: t.origin,
                  destination: t.destination,
                  departureTime: t.departureTime,
                  arrivalTime: t.arrivalTime,
                  price: t.price,
                  availableSeats: newAvailable,
                  totalSeats: t.totalSeats,
                  vehicleType: t.vehicleType,
                  vehicleId: t.vehicleId,
                  isActive: t.isActive,
                  additionalInfo: t.additionalInfo,
                )
              : t)
          .toList();
      state = state.copyWith(trips: updatedTrips);
      
      // ⚠️ ADVERTENCIA: Esta línea fue la que generó el TypeError antes. 
      // La dejamos así por ahora, pero lo ideal sería no actualizar el estado aquí, 
      // sino recargar el historial después. Si falla, coméntala.
      // final my = List<Reservation>.from(state.myReservations)..add(res);
      // state = state.copyWith(myReservations: my);
      
      return res;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      throw Exception(e.toString());
    }
  }

  Future<void> loadMyReservations() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      final passengerId = await _ensurePassengerId(userId);
      
      // 🛑 CORRECCIÓN DE TIPO (Aunque el servicio necesita ser corregido en el otro archivo)
      // Se asume que el servicio devolverá List<ReservationHistory>
      final list = await _reservationService.listReservationsByPassenger(passengerId);
      
      // Ahora el estado acepta List<ReservationHistory>
      state = state.copyWith(myReservations: list as List<ReservationHistory>); 
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String> _ensurePassengerId(String userId) async {
    final existing = await _client
        .from('pasajeros')
        .select()
        .eq('user_id', userId)
        .limit(1);
    if (existing is List && existing.isNotEmpty) {
      final row = existing.first as Map<String, dynamic>;
      final id = row['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    final name = _client.auth.currentUser?.email ?? 'Passenger';
    final inserted = await _client
        .from('pasajeros')
        .insert({'user_id': userId, 'name': name})
        .select()
        .maybeSingle();
    return inserted!['id'].toString();
  }

  Future<void> cancelMyReservation(String reservationId) async {
    try {
      // 1. Ejecutar la cancelación en DB.
      await _reservationService.cancelReservation(reservationId); 

      // 2. Actualizar la lista local (List<ReservationHistory>):
      final updatedList = state.myReservations.map<ReservationHistory>((r) {
        if (r.id == reservationId) {
            // 🛑 CORRECCIÓN DEL ERROR: Usa copyWith de ReservationHistory para actualizar el status.
            return r.copyWith(status: 'cancelled'); 
        }
        return r;
      }).toList();

      state = state.copyWith(myReservations: updatedList);

    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final passengerControllerProvider = StateNotifierProvider<PassengerController, PassengerState>((ref) {
  return PassengerController(ref);
});