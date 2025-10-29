import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/company_model.dart';

class CompanyService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Autenticación de empresa
  static Future<Map<String, dynamic>> signInCompany(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Verificar si es una empresa
        final companyData = await getCompanyByEmail(email);
        if (companyData != null) {
          return {
            'success': true,
            'user': response.user,
            'company': companyData,
            'message': 'Inicio de sesión exitoso'
          };
        } else {
          await _supabase.auth.signOut();
          return {
            'success': false,
            'message': 'Esta cuenta no está registrada como empresa'
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Credenciales incorrectas'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al iniciar sesión: ${e.toString()}'
      };
    }
  }

  // Registro de empresa
  static Future<Map<String, dynamic>> registerCompany({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String nit,
    String description = '',
  }) async {
    try {
      // Crear usuario en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Preparar registro de empresa SIN forzar el id
        final tempCompany = Company(
          id: '', // será generado por la BD
          name: name,
          email: email,
          phone: phone,
          address: address,
          nit: nit,
          description: description,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdCompany = await createCompany(tempCompany);

        if (createdCompany != null) {
          return {
            'success': true,
            'user': response.user,
            'company': createdCompany,
            'message': 'Empresa registrada exitosamente'
          };
        } else {
          // Intentar recuperar empresa existente por NIT o email (duplicado)
          final existingByNit = await getCompanyByNit(nit);
          final existingByEmail = await getCompanyByEmail(email);
          final existingCompany = existingByNit ?? existingByEmail;

          if (existingCompany != null) {
            return {
              'success': true,
              'user': response.user,
              'company': existingCompany,
              'message': 'Empresa ya existente vinculada correctamente'
            };
          }

          return {
            'success': false,
            'message': 'No se pudo crear ni recuperar la empresa'
          };
        }
      }

      return {
        'success': false,
        'message': 'Error al crear la cuenta'
      };
    } catch (e) {
      final msg = e.toString();
      // Si el usuario ya existe (422), intentar iniciar sesión y devolver empresa
      if (msg.contains('422') || msg.toLowerCase().contains('already') || msg.toLowerCase().contains('exists')) {
        try {
          final signin = await signInCompany(email, password);
          if (signin['success'] == true) {
            return {
              'success': true,
              'user': signin['user'],
              'company': signin['company'],
              'message': 'Cuenta existente, sesión iniciada y empresa recuperada'
            };
          }
        } catch (_) {}
      }

      return {
        'success': false,
        'message': 'Error al registrar empresa: ${e.toString()}'
      };
    }
  }

  // CRUD Operaciones para Company
  static Future<Company?> createCompany(Company company) async {
    try {
      // Construir payload sin el id para permitir que la BD lo genere
      final data = Map<String, dynamic>.from(company.toJson());
      data.remove('id');

      final response = await _supabase
          .from('companies')
          .insert(data)
          .select()
          .maybeSingle();

      return response != null ? Company.fromJson(response) : null;
    } catch (e) {
      // Si hay conflicto por NIT, intentar recuperar la empresa existente
      final msg = e.toString();
      print('Error creating company: $e');
      if (msg.contains('companies_nit_key') || msg.contains('duplicate key value')) {
        try {
          // Recuperar por NIT si hay conflicto
          final existing = await getCompanyByNit(company.nit);
          if (existing != null) return existing;
        } catch (_) {}
      }
      return null;
    }
  }

  static Future<Company?> getCompany(String id) async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Company.fromJson(response);
    } catch (e) {
      print('Error getting company: $e');
      return null;
    }
  }

  static Future<Company?> getCompanyByEmail(String email) async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) return null;
      return Company.fromJson(response);
    } catch (e) {
      print('Error getting company by email: $e');
      return null;
    }
  }

  static Future<Company?> getCompanyByNit(String nit) async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .eq('nit', nit)
          .maybeSingle();

      if (response == null) return null;
      return Company.fromJson(response);
    } catch (e) {
      print('Error getting company by nit: $e');
      return null;
    }
  }

  static Future<List<Company>> getAllCompanies() async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Company.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all companies: $e');
      return [];
    }
  }

  static Future<Company?> updateCompany(Company company) async {
    try {
      final updatedCompany = company.copyWith(updatedAt: DateTime.now());
      
      final response = await _supabase
          .from('companies')
          .update(updatedCompany.toJson())
          .eq('id', company.id)
          .select()
          .maybeSingle();

      return response != null ? Company.fromJson(response) : null;
    } catch (e) {
      print('Error updating company: $e');
      return null;
    }
  }

  static Future<bool> deleteCompany(String id) async {
    try {
      await _supabase
          .from('companies')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);

      return true;
    } catch (e) {
      print('Error deleting company: $e');
      return false;
    }
  }

  // CRUD Operaciones para CompanySchedule
  static Future<CompanySchedule?> createSchedule(CompanySchedule schedule) async {
    try {
      final response = await _supabase
          .from('company_schedules')
          .insert(schedule.toJson())
          .select()
          .maybeSingle();

      return response != null ? CompanySchedule.fromJson(response) : null;
    } catch (e) {
      print('Error creating schedule: $e');
      return null;
    }
  }

  static Future<List<CompanySchedule>> getCompanySchedules(String companyId) async {
    try {
      final response = await _supabase
          .from('company_schedules')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('departure_time');

      return (response as List)
          .map((json) => CompanySchedule.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting company schedules: $e');
      return [];
    }
  }

  static Future<List<CompanySchedule>> searchSchedules({
    required String origin,
    required String destination,
    DateTime? date,
  }) async {
    try {
      var query = _supabase
          .from('company_schedules')
          .select('*, companies!inner(*)')
          .eq('origin', origin)
          .eq('destination', destination)
          .eq('is_active', true)
          .eq('companies.is_active', true);

      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        query = query
            .gte('departure_time', startOfDay.toIso8601String())
            .lt('departure_time', endOfDay.toIso8601String());
      }

      final response = await query.order('departure_time');

      return (response as List)
          .map((json) => CompanySchedule.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching schedules: $e');
      return [];
    }
  }

  static Future<CompanySchedule?> updateSchedule(CompanySchedule schedule) async {
    try {
      final response = await _supabase
          .from('company_schedules')
          .update(schedule.toJson())
          .eq('id', schedule.id)
          .select()
          .maybeSingle();

      return response != null ? CompanySchedule.fromJson(response) : null;
    } catch (e) {
      print('Error updating schedule: $e');
      return null;
    }
  }

  static Future<bool> deleteSchedule(String id) async {
    try {
      await _supabase
          .from('company_schedules')
          .update({'is_active': false})
          .eq('id', id);

      return true;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }

  // Métodos de utilidad
  static Future<bool> updateAvailableSeats(String scheduleId, int newAvailableSeats) async {
    try {
      await _supabase
          .from('company_schedules')
          .update({'available_seats': newAvailableSeats})
          .eq('id', scheduleId);

      return true;
    } catch (e) {
      print('Error updating available seats: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  static bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }
}