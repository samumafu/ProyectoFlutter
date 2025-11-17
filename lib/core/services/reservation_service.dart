// 📝 lib/core/services/reservation_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/features/passenger/models/reservation_model.dart'; 
import 'package:tu_flota/features/passenger/models/reservation_history_dto.dart'; 

class ReservationService {
  final SupabaseClient client;
  ReservationService(this.client);

  Future<List<Reservation>> listReservationsForSchedule(String scheduleId) async {
    final data = await client
        .from('reservations')
        .select()
        .eq('trip_id', scheduleId);
    return (data as List<dynamic>)
        .map((e) => Reservation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // 🛑 CORRECCIÓN CLAVE: Ordenar por 'created_at' descendente
  Future<List<ReservationHistory>> listReservationsByPassenger(String passengerId) async {
    final data = await client
        .from('reservations')
        .select('''
          *, 
          company_schedules(
            origin, 
            destination, 
            departure_time, 
            arrival_time, 
            companies(name) 
          ) 
        ''')
        .eq('passenger_id', passengerId)
        .order('created_at', ascending: false); // ⬅️ Cambiado de 'id' a 'created_at'

    return (data as List<dynamic>)
        .map((e) => ReservationHistory.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Reservation> createReservation({
    required String tripId,
    required String passengerId,
    required int seats,
    required double totalPrice,
  }) async {
    final inserted = await client
        .from('reservations')
        .insert({
          'trip_id': tripId,
          'passenger_id': passengerId,
          'seats_reserved': seats,
          'total_price': totalPrice,
          'status': 'confirmed',
        })
        .select()
        .maybeSingle();
    return Reservation.fromMap(inserted!);
  }

  Future<Reservation> cancelReservation(String reservationId) async {
    final updated = await client
        .from('reservations')
        .update({'status': 'cancelled'})
        .eq('id', reservationId)
        .select()
        .maybeSingle();
    return Reservation.fromMap(updated!);
  }
}