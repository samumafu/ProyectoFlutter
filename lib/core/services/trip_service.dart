import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';

typedef OnScheduleInsert = void Function(CompanySchedule schedule);
typedef OnScheduleUpdate = void Function(CompanySchedule schedule);
typedef OnScheduleDelete = void Function(int id);

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

  Future<CompanySchedule?> getScheduleById(int id) async {
    final data = await client
        .from('company_schedules')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : CompanySchedule.fromMap(data);
  }

  Future<CompanySchedule> createSchedule(CompanySchedule schedule) async {
    final inserted = await client
        .from('company_schedules')
        .insert(schedule.toMap())
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
    return CompanySchedule.fromMap(updated ?? schedule.toMap());
  }

  Future<void> deleteSchedule(int id) async {
    await client.from('company_schedules').delete().eq('id', id);
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
          if (oldRow != null) onDelete(oldRow['id'] as int);
        },
      );
    channel.subscribe();
    return channel;
  }
}