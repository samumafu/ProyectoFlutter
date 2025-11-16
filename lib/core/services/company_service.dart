import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tu_flota/features/company/models/company_model.dart';
import 'package:tu_flota/features/driver/models/driver_model.dart';

typedef OnDriverInsert = void Function(Driver driver);
typedef OnDriverUpdate = void Function(Driver driver);
typedef OnDriverDelete = void Function(String id);

class CompanyService {
  final SupabaseClient client;
  CompanyService(this.client);

  Future<Company?> fetchCompanyById(String companyId) async {
    final data = await client
        .from('companies')
        .select()
        .eq('id', companyId)
        .maybeSingle();
    if (data == null) return null;
    return Company.fromMap(data);
  }

  Future<Company?> fetchCompanyByEmail(String email) async {
    // Primary association by email column
    final byEmail = await client
        .from('companies')
        .select()
        .ilike('email', email)
        .maybeSingle();
    if (byEmail != null) return Company.fromMap(byEmail);

    // Fallback: some datasets store the email in the name field
    final byName = await client
        .from('companies')
        .select()
        .ilike('name', email)
        .maybeSingle();
    if (byName != null) return Company.fromMap(byName);

    return null;
  }

  Future<List<Company>> listCompanies() async {
    final data = await client.from('companies').select();
    return (data as List)
        .map((e) => Company.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Company> updateCompany(Company company) async {
    final updated = await client
        .from('companies')
        .update(company.toMap())
        .eq('id', company.id)
        .select()
        .maybeSingle();
    if (updated == null) {
      throw Exception('Update company failed');
    }
    return Company.fromMap(updated);
  }

  Future<String?> uploadCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = '$companyId/$fileName';
    await client.storage.from('company-logos').uploadBinary(path, bytes,
        fileOptions: const FileOptions(upsert: true));
    final publicUrl = client.storage.from('company-logos').getPublicUrl(path);
    await client
        .from('companies')
        .update({'logo_url': publicUrl})
        .eq('id', companyId);
    return publicUrl;
  }

  // Conductores (Drivers)
  Future<List<Driver>> listDrivers() async {
    final data = await client.from('conductores').select();
    return (data as List<dynamic>)
        .map((e) => Driver.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Driver> createDriver(Driver driver) async {
    final map = driver.toMap();
    map.remove('id');
    final inserted = await client
        .from('conductores')
        .insert(map)
        .select()
        .maybeSingle();
    return Driver.fromMap(inserted!);
  }

  Future<Driver> updateDriver(Driver driver) async {
    final updated = await client
        .from('conductores')
        .update(driver.toMap())
        .eq('id', driver.id)
        .select()
        .maybeSingle();
    if (updated == null) {
      throw Exception('Update driver failed');
    }
    return Driver.fromMap(updated);
  }

  Future<void> deleteDriver(String id) async {
    await client.from('conductores').delete().eq('id', id);
  }

  Future<Driver> toggleDriverAvailability(String id, bool available) async {
    final updated = await client
        .from('conductores')
        .update({'available': available})
        .eq('id', id)
        .select()
        .maybeSingle();
    return Driver.fromMap(updated!);
  }

  // Realtime subscription for drivers table
  RealtimeChannel subscribeDrivers({
    required OnDriverInsert onInsert,
    required OnDriverUpdate onUpdate,
    required OnDriverDelete onDelete,
  }) {
    final channel = client.channel('public:conductores')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'conductores',
        callback: (payload) {
          final row = payload.newRecord;
          if (row != null) onInsert(Driver.fromMap(row));
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'conductores',
        callback: (payload) {
          final row = payload.newRecord;
          if (row != null) onUpdate(Driver.fromMap(row));
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'conductores',
        callback: (payload) {
          final oldRow = payload.oldRecord;
          if (oldRow != null) onDelete(oldRow['id'].toString());
        },
      );
    channel.subscribe();
    return channel;
  }
}