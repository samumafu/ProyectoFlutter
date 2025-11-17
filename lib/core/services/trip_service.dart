import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';

typedef OnScheduleInsert = void Function(CompanySchedule schedule);
typedef OnScheduleUpdate = void Function(CompanySchedule schedule);
typedef OnScheduleDelete = void Function(String id);

class TripService {
  final SupabaseClient client;
  TripService(this.client);

  Future<List<CompanySchedule>> listSchedulesByCompany(String companyId) async {
    final data = await client
        .from('company_schedules')
        .select()
        .eq('company_id', companyId)
        .order('departure_time');
    return (data as List<dynamic>)
        .map((e) => CompanySchedule.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CompanySchedule>> listAssignedSchedulesForDriver(String driverId) async {
    final data = await client
        .from('company_schedules')
        .select()
        .eq('assigned_driver_id', driverId)
        .order('departure_time');
    return (data as List<dynamic>)
        .map((e) => CompanySchedule.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<CompanySchedule?> getScheduleById(String id) async {
    final data = await client
        .from('company_schedules')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : CompanySchedule.fromMap(data);
  }

  Future<CompanySchedule> createSchedule(CompanySchedule schedule) async {
    // Do not send 'id' on insert; let DB assign it
    final insertMap = Map<String, dynamic>.from(schedule.toMap())..remove('id');
    final inserted = await client
        .from('company_schedules')
        .insert(insertMap)
        .select()
        .maybeSingle();
    return CompanySchedule.fromMap(inserted!);
  }

  Future<CompanySchedule> updateSchedule(CompanySchedule schedule) async {
    final updated = await client
        .from('company_schedules')
        .update(schedule.toMap())
        .eq('id', schedule.id)
        .select()
        .maybeSingle();
    if (updated == null) {
      throw Exception('Update schedule failed');
    }
    return CompanySchedule.fromMap(updated);
  }

  Future<void> assignScheduleToDriver({required String scheduleId, required String driverId}) async {
    await client
        .from('company_schedules')
        .update({'assigned_driver_id': driverId, 'assignment_status': 'pending'})
        .eq('id', scheduleId);
  }

  Future<void> updateAssignmentStatus({required String scheduleId, required String status}) async {
    await client
        .from('company_schedules')
        .update({'assignment_status': status})
        .eq('id', scheduleId);
  }

  Future<void> deleteSchedule(String id) async {
    await client.from('company_schedules').delete().eq('id', id);
  }

  Future<int> decrementAvailableSeats(String scheduleId, int seatsToSubtract) async {
    final current = await getScheduleById(scheduleId);
    if (current == null) {
      throw Exception('Schedule not found');
    }
    final int newAvailable = (current.availableSeats - seatsToSubtract) < 0
        ? 0
        : current.availableSeats - seatsToSubtract;
    final updated = await client
        .from('company_schedules')
        .update({'available_seats': newAvailable})
        .eq('id', scheduleId)
        .select()
        .maybeSingle();
    if (updated == null) {
      throw Exception('Failed to update available seats');
    }
    return newAvailable;
  }

  // Realtime subscription for company_schedules
  RealtimeChannel subscribeSchedules({
    required OnScheduleInsert onInsert,
    required OnScheduleUpdate onUpdate,
    required OnScheduleDelete onDelete,
  }) {
    final channel = client.channel('public:company_schedules')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'company_schedules',
        callback: (payload) {
          final row = payload.newRecord;
          if (row != null) onInsert(CompanySchedule.fromMap(row));
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'company_schedules',
        callback: (payload) {
          final row = payload.newRecord;
          if (row != null) onUpdate(CompanySchedule.fromMap(row));
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'company_schedules',
        callback: (payload) {
          final oldRow = payload.oldRecord;
          if (oldRow != null) onDelete(oldRow['id'] as String);
      },
      );
    channel.subscribe();
    return channel;
  }
}