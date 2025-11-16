import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/core/services/trip_service.dart';
import 'package:tu_flota/core/services/reservation_service.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';

class PassengerState {
  final List<CompanySchedule> trips;
  final List<Reservation> myReservations;
  final bool isLoading;
  final String? error;

  const PassengerState({
    this.trips = const [],
    this.myReservations = const [],
    this.isLoading = false,
    this.error,
  });

  PassengerState copyWith({
    List<CompanySchedule>? trips,
    List<Reservation>? myReservations,
    bool? isLoading,
    String? error,
  }) {
    return PassengerState(
      trips: trips ?? this.trips,
      myReservations: myReservations ?? this.myReservations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

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

  Future<void> loadAllTrips() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // For passenger, list all active schedules across companies
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
      // If no filters provided, load all active trips
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
      // Ensure passenger profile exists and get its id (pasajeros.id)
      final passengerId = await _ensurePassengerId(userId);
      final totalPrice = schedule.price * seats;
      final res = await _reservationService.createReservation(
        tripId: schedule.id,
        passengerId: passengerId,
        seats: seats,
        totalPrice: totalPrice,
      );
      // Decrement available seats for the schedule in DB
      final newAvailable = await _tripService.decrementAvailableSeats(schedule.id, seats);
      // Update local trips list to reflect new availability
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
      // Update my reservations list
      final my = List<Reservation>.from(state.myReservations)..add(res);
      state = state.copyWith(myReservations: my);
      return res;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Do not rethrow; let UI read state.error for feedback
      throw Exception(e.toString());
    }
  }

  Future<void> loadMyReservations() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      final passengerId = await _ensurePassengerId(userId);
      final list = await _reservationService.listReservationsByPassenger(passengerId);
      state = state.copyWith(myReservations: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String> _ensurePassengerId(String userId) async {
    // Try to find existing passenger profile
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
    // Create a passenger profile if missing
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
      final updated = await _reservationService.cancelReservation(reservationId);
      final my = state.myReservations.map((r) => r.id == reservationId ? updated : r).toList();
      state = state.copyWith(myReservations: my);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final passengerControllerProvider = StateNotifierProvider<PassengerController, PassengerState>((ref) {
  return PassengerController(ref);
});