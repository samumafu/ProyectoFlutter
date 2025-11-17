import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/features/passenger/models/reservation_model.dart';
import 'package:tu_flota/features/passenger/models/reservation_history_dto.dart';

typedef OnReservationInsert = void Function(Reservation res);
typedef OnReservationUpdate = void Function(Reservation res);
typedef OnReservationDelete = void Function(String id);

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

  // ---------------------------------------------------
  // 🔹 Obtener emails por IDs de pasajeros
  // ---------------------------------------------------
  Future<Map<String, String>> getPassengerEmailsByIds(List<String> passengerIds) async {
    if (passengerIds.isEmpty) return {};

    final idsList = passengerIds.map((e) => "'$e'").join(',');

    final pasajeros = await client
        .from('pasajeros')
        .select('id,user_id')
        .filter('id', 'in', '($idsList)');

    final pList = (pasajeros as List).map((e) => {
          'id': e['id'].toString(),
          'user_id': e['user_id']?.toString(),
        }).toList();

    final userIds = pList
        .map((e) => e['user_id'])
        .where((e) => e != null)
        .cast<String>()
        .toSet()
        .toList();

    if (userIds.isEmpty) return {};

    final uIdsList = userIds.map((e) => "'$e'").join(',');

    final users = await client
        .from('users')
        .select('id,email')
        .filter('id', 'in', '($uIdsList)');

    final uMap = <String, String>{
      for (final u in (users as List)) u['id'].toString(): (u['email']?.toString() ?? '')
    };

    final result = <String, String>{};

    for (final p in pList) {
      final pid = p['id'] as String;
      final uid = p['user_id'] as String?;

      if (uid != null && uMap.containsKey(uid)) {
        result[pid] = uMap[uid] ?? '';
      }
    }

    return result;
  }

  // ---------------------------------------------------
  // 🔹 Suscripción realtime a reservas de un viaje
  // ---------------------------------------------------
  RealtimeChannel subscribeReservationsForTrip({
    required String tripId,
    required OnReservationInsert onInsert,
    required OnReservationUpdate onUpdate,
    required OnReservationDelete onDelete,
  }) {
    final channel = client.channel('public:reservations')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'reservations',
        callback: (payload) {
          final row = payload.newRecord;
          if (row != null && row['trip_id']?.toString() == tripId) {
            onInsert(Reservation.fromMap(row));
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'reservations',
        callback: (payload) {
          final row = payload.newRecord;
          if (row != null && row['trip_id']?.toString() == tripId) {
            onUpdate(Reservation.fromMap(row));
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'reservations',
        callback: (payload) {
          final oldRow = payload.oldRecord;
          if (oldRow != null && oldRow['trip_id']?.toString() == tripId) {
            onDelete(oldRow['id'].toString());
          }
        },
      );

    channel.subscribe();
    return channel;
  }

  // ---------------------------------------------------
  // 🔹 Historial por pasajero (con orden por created_at)
  // ---------------------------------------------------
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
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => ReservationHistory.fromMap(e))
        .toList();
  }

  // ---------------------------------------------------
  // 🔹 Crear reserva
  // ---------------------------------------------------
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

  // ---------------------------------------------------
  // 🔹 Cancelar reserva
  // ---------------------------------------------------
  Future<Reservation> cancelReservation(String reservationId) async {
    final updated = await client
        .from('reservations')
        .update({'status': 'cancelled'})
        .eq('id', reservationId)
        .select()
        .maybeSingle();

    return Reservation.fromMap(updated!);
  }

  // ---------------------------------------------------
  // 🔹 Marcar como abordado
  // ---------------------------------------------------
  Future<Reservation> updateBoarded(String reservationId, bool boarded) async {
    final updated = await client
        .from('reservations')
        .update({
          'boarded': boarded,
          'boarded_at': boarded ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', reservationId)
        .select()
        .maybeSingle();

    return Reservation.fromMap(updated!);
  }
}
