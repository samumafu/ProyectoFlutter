import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/company_model.dart';

class RouteService {
  static final _supabase = Supabase.instance.client;

  // Obtener todas las rutas activas
  static Future<List<CompanySchedule>> getAllActiveRoutes() async {
    try {
      final response = await _supabase
          .from('company_schedules')
          .select('''
            *,
            companies!inner(
              id,
              name,
              is_active
            )
          ''')
          .eq('is_active', true)
          .eq('companies.is_active', true)
          .order('departure_time');

      return response.map((json) => CompanySchedule.fromJson(json)).toList();
    } catch (e) {
      print('Error obteniendo rutas: $e');
      return [];
    }
  }

  // Obtener ciudades de origen únicas
  static Future<List<String>> getOriginCities() async {
    try {
      final response = await _supabase
          .from('company_schedules')
          .select('origin')
          .eq('is_active', true);

      final origins = response
          .map((item) => item['origin'] as String)
          .toSet()
          .toList();
      
      origins.sort();
      return origins;
    } catch (e) {
      print('Error obteniendo ciudades de origen: $e');
      return [];
    }
  }

  // Obtener ciudades de destino únicas
  static Future<List<String>> getDestinationCities() async {
    try {
      final response = await _supabase
          .from('company_schedules')
          .select('destination')
          .eq('is_active', true);

      final destinations = response
          .map((item) => item['destination'] as String)
          .toSet()
          .toList();
      
      destinations.sort();
      return destinations;
    } catch (e) {
      print('Error obteniendo ciudades de destino: $e');
      return [];
    }
  }

  // Obtener todas las ciudades (origen + destino)
  static Future<List<String>> getAllCities() async {
    try {
      final origins = await getOriginCities();
      final destinations = await getDestinationCities();
      
      final allCities = {...origins, ...destinations}.toList();
      allCities.sort();
      return allCities;
    } catch (e) {
      print('Error obteniendo todas las ciudades: $e');
      return [];
    }
  }

  // Buscar rutas entre dos ciudades
  static Future<List<CompanySchedule>> searchRoutes({
    required String origin,
    required String destination,
    DateTime? date,
  }) async {
    try {
      print('🔍 Buscando rutas:');
      print('   Origen: "$origin"');
      print('   Destino: "$destination"');
      print('   Fecha: $date');

      // Primero verificar si hay datos en la tabla
      final allRoutes = await _supabase
          .from('company_schedules')
          .select('*')
          .limit(10);
      
      print('📋 Total de rutas en la tabla: ${allRoutes.length}');
      if (allRoutes.isNotEmpty) {
        print('   Ejemplo de ruta: ${allRoutes.first}');
        print('   Todas las rutas disponibles:');
        for (var route in allRoutes) {
          print('     - ${route['origin']} → ${route['destination']} (${route['departure_time']}) - Activa: ${route['is_active']}');
        }
      }

      // Consulta directa sin JOIN
      var query = _supabase
          .from('company_schedules')
          .select('*')
          .eq('origin', origin)
          .eq('destination', destination)
          .eq('is_active', true);

      print('🔍 Consulta específica:');
      print('   Buscando origen exacto: "$origin"');
      print('   Buscando destino exacto: "$destination"');
      print('   Solo rutas activas: true');

      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        print('   Rango de fecha: ${startOfDay.toIso8601String()} - ${endOfDay.toIso8601String()}');
        
        query = query
            .gte('departure_time', startOfDay.toIso8601String())
            .lt('departure_time', endOfDay.toIso8601String());
      }

      final response = await query.order('departure_time');
      
      print('📊 Resultados encontrados: ${response.length}');
      for (var item in response) {
        print('   - Ruta: "${item['origin']}" → "${item['destination']}" a las ${item['departure_time']}');
      }

      return response.map((json) => CompanySchedule.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error buscando rutas: $e');
      return [];
    }
  }

  // Crear nueva ruta (para empresas)
  static Future<bool> createRoute({
    required String companyId,
    required String origin,
    required String destination,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required double price,
    required int totalSeats,
    required String vehicleType,
    required String vehicleId,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      print('💾 Creando nueva ruta:');
      print('   Empresa ID: $companyId');
      print('   Origen: $origin');
      print('   Destino: $destination');
      print('   Salida: ${departureTime.toIso8601String()}');
      print('   Llegada: ${arrivalTime.toIso8601String()}');
      print('   Precio: \$${price}');
      print('   Asientos: $totalSeats');

      // Verificar si la empresa existe, con reintento para empresas recién registradas
      bool companyExists = await _verifyCompanyExists(companyId);
      
      if (!companyExists) {
        print('⚠️ Company ID no encontrado, reintentando en 2 segundos...');
        await Future.delayed(const Duration(seconds: 2));
        companyExists = await _verifyCompanyExists(companyId);
        
        if (!companyExists) {
          // Verificar si el usuario está autenticado y el company_id coincide con el user_id
          final currentUser = _supabase.auth.currentUser;
          if (currentUser != null && currentUser.id == companyId) {
            print('⚠️ Company ID no encontrado en tabla, pero usuario autenticado coincide. Permitiendo creación...');
            companyExists = true;
          } else {
            print('❌ Company ID "$companyId" no existe en la tabla companies después del reintento');
            print('💡 Usuario actual: ${currentUser?.id ?? "No autenticado"}');
            return false;
          }
        }
      }

      print('✅ Company ID verificado, procediendo con la creación de la ruta');

      await _supabase.from('company_schedules').insert({
        'company_id': companyId,
        'origin': origin,
        'destination': destination,
        'departure_time': departureTime.toIso8601String(),
        'arrival_time': arrivalTime.toIso8601String(),
        'price': price,
        'available_seats': totalSeats,
        'total_seats': totalSeats,
        'vehicle_type': vehicleType,
        'vehicle_id': vehicleId,
        'is_active': true,
        'additional_info': additionalInfo ?? {},
      });

      print('✅ Ruta creada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error creando ruta: $e');
      
      // Si el error es de clave foránea, proporcionar un mensaje más claro
      if (e.toString().contains('foreign key') || e.toString().contains('violates')) {
        print('💡 Sugerencia: Asegúrate de que la empresa esté completamente registrada antes de crear rutas');
      }
      
      return false;
    }
  }

  // Función auxiliar para verificar si una empresa existe
  static Future<bool> _verifyCompanyExists(String companyId) async {
    try {
      print('🔍 Verificando existencia de company_id: $companyId');
      
      final response = await _supabase
          .from('companies')
          .select('id, name, is_active')
          .eq('id', companyId)
          .maybeSingle();
      
      if (response != null) {
        print('✅ Empresa encontrada: ${response['name']} (activa: ${response['is_active']})');
        return true;
      } else {
        print('❌ No se encontró empresa con ID: $companyId');
        
        // Mostrar algunas empresas existentes para depuración
        final allCompanies = await _supabase
            .from('companies')
            .select('id, name')
            .limit(5);
        
        print('📋 Empresas existentes en la tabla:');
        for (var company in allCompanies) {
          print('   - ${company['id']}: ${company['name']}');
        }
        
        return false;
      }
    } catch (e) {
      print('❌ Error verificando empresa: $e');
      return false;
    }
  }

  // Actualizar ruta
  static Future<bool> updateRoute({
    required String routeId,
    String? origin,
    String? destination,
    DateTime? departureTime,
    DateTime? arrivalTime,
    double? price,
    int? availableSeats,
    int? totalSeats,
    String? vehicleType,
    String? vehicleId,
    bool? isActive,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (origin != null) updateData['origin'] = origin;
      if (destination != null) updateData['destination'] = destination;
      if (departureTime != null) updateData['departure_time'] = departureTime.toIso8601String();
      if (arrivalTime != null) updateData['arrival_time'] = arrivalTime.toIso8601String();
      if (price != null) updateData['price'] = price;
      if (availableSeats != null) updateData['available_seats'] = availableSeats;
      if (totalSeats != null) updateData['total_seats'] = totalSeats;
      if (vehicleType != null) updateData['vehicle_type'] = vehicleType;
      if (vehicleId != null) updateData['vehicle_id'] = vehicleId;
      if (isActive != null) updateData['is_active'] = isActive;
      if (additionalInfo != null) updateData['additional_info'] = additionalInfo;

      await _supabase
          .from('company_schedules')
          .update(updateData)
          .eq('id', routeId);

      return true;
    } catch (e) {
      print('Error actualizando ruta: $e');
      return false;
    }
  }

  // Eliminar ruta (desactivar)
  static Future<bool> deleteRoute(String routeId) async {
    try {
      await _supabase
          .from('company_schedules')
          .update({'is_active': false})
          .eq('id', routeId);

      return true;
    } catch (e) {
      print('Error eliminando ruta: $e');
      return false;
    }
  }

  // Obtener rutas de una empresa específica
  static Future<List<CompanySchedule>> getCompanyRoutes(String companyId) async {
    try {
      final response = await _supabase
          .from('company_schedules')
          .select('''
            *,
            companies!inner(
              id,
              name
            )
          ''')
          .eq('company_id', companyId)
          .order('departure_time');

      return response.map((json) => CompanySchedule.fromJson(json)).toList();
    } catch (e) {
      print('Error obteniendo rutas de empresa: $e');
      return [];
    }
  }
}