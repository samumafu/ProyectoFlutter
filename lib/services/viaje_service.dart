import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/viaje_model.dart';

class ViajeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Crear un nuevo viaje
  Future<ViajeModel?> crearViaje(ViajeModel viaje) async {
    try {
      final response = await _supabase
          .from('viajes')
          .insert(viaje.toJson())
          .select()
          .maybeSingle();

      return response != null ? ViajeModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al crear viaje: $e');
    }
  }

  // Obtener viajes por empresa
  Future<List<ViajeModel>> obtenerViajesPorEmpresa(String empresaId) async {
    try {
      final response = await _supabase
          .from('viajes')
          .select('''
            *,
            conductores!inner(nombres, apellidos),
            vehiculos!inner(placa, marca, modelo)
          ''')
          .eq('empresa_id', empresaId)
          .order('fecha_salida', ascending: false);

      return response.map<ViajeModel>((json) {
        // Agregar información del conductor y vehículo
        final conductor = json['conductores'];
        final vehiculo = json['vehiculos'];
        
        json['conductor_nombre'] = conductor != null 
            ? '${conductor['nombres']} ${conductor['apellidos']}'
            : null;
        json['vehiculo_placa'] = vehiculo?['placa'];
        json['vehiculo_marca'] = vehiculo?['marca'];
        json['vehiculo_modelo'] = vehiculo?['modelo'];
        
        return ViajeModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener viajes: $e');
    }
  }

  // Obtener viaje por ID
  Future<ViajeModel?> obtenerViajePorId(String viajeId) async {
    try {
      final response = await _supabase
          .from('viajes')
          .select('''
            *,
            conductores!inner(nombres, apellidos),
            vehiculos!inner(placa, marca, modelo)
          ''')
          .eq('id', viajeId)
          .maybeSingle();

      if (response == null) return null;

      // Agregar información del conductor y vehículo
      final conductor = response['conductores'];
      final vehiculo = response['vehiculos'];
      
      response['conductor_nombre'] = conductor != null 
          ? '${conductor['nombres']} ${conductor['apellidos']}'
          : null;
      response['vehiculo_placa'] = vehiculo?['placa'];
      response['vehiculo_marca'] = vehiculo?['marca'];
      response['vehiculo_modelo'] = vehiculo?['modelo'];

      return ViajeModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener viaje: $e');
    }
  }

  // Actualizar viaje
  Future<ViajeModel?> actualizarViaje(ViajeModel viaje) async {
    try {
      final response = await _supabase
          .from('viajes')
          .update(viaje.toJson())
          .eq('id', viaje.id)
          .select()
          .maybeSingle();

      return response != null ? ViajeModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al actualizar viaje: $e');
    }
  }

  // Cambiar estado del viaje
  Future<void> cambiarEstadoViaje(String viajeId, ViajeStatus nuevoEstado, {String? motivoCancelacion}) async {
    try {
      final updateData = {
        'estado': nuevoEstado.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nuevoEstado == ViajeStatus.cancelado && motivoCancelacion != null) {
        updateData['motivo_cancelacion'] = motivoCancelacion;
      }

      if (nuevoEstado == ViajeStatus.enCurso) {
        updateData['hora_salida_real'] = DateTime.now().toIso8601String();
      }

      if (nuevoEstado == ViajeStatus.completado) {
        updateData['hora_llegada_real'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('viajes')
          .update(updateData)
          .eq('id', viajeId);
    } catch (e) {
      throw Exception('Error al cambiar estado del viaje: $e');
    }
  }

  // Eliminar viaje
  Future<void> eliminarViaje(String viajeId) async {
    try {
      await _supabase
          .from('viajes')
          .delete()
          .eq('id', viajeId);
    } catch (e) {
      throw Exception('Error al eliminar viaje: $e');
    }
  }

  // Obtener viajes disponibles (con cupos)
  Future<List<ViajeModel>> obtenerViajesDisponibles(String empresaId) async {
    try {
      final response = await _supabase
          .from('viajes')
          .select('''
            *,
            conductores!inner(nombres, apellidos),
            vehiculos!inner(placa, marca, modelo)
          ''')
          .eq('empresa_id', empresaId)
          .eq('estado', 'programado')
          .gte('fecha_salida', DateTime.now().toIso8601String().split('T')[0])
          .order('fecha_salida', ascending: true);

      return response.map<ViajeModel>((json) {
        // Agregar información del conductor y vehículo
        final conductor = json['conductores'];
        final vehiculo = json['vehiculos'];
        
        json['conductor_nombre'] = conductor != null 
            ? '${conductor['nombres']} ${conductor['apellidos']}'
            : null;
        json['vehiculo_placa'] = vehiculo?['placa'];
        json['vehiculo_marca'] = vehiculo?['marca'];
        json['vehiculo_modelo'] = vehiculo?['modelo'];
        
        return ViajeModel.fromJson(json);
      }).where((viaje) => viaje.hasAvailableSeats).toList();
    } catch (e) {
      throw Exception('Error al obtener viajes disponibles: $e');
    }
  }

  // Buscar viajes
  Future<List<ViajeModel>> buscarViajes({
    required String empresaId,
    String? query,
    ViajeStatus? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('viajes')
          .select('''
            *,
            conductores!inner(nombres, apellidos),
            vehiculos!inner(placa, marca, modelo),
            rutas!inner(origen, destino)
          ''')
          .eq('empresa_id', empresaId);

      if (estado != null) {
        queryBuilder = queryBuilder.eq('estado', estado.name);
      }

      if (fechaDesde != null) {
        queryBuilder = queryBuilder.gte('fecha_salida', fechaDesde.toIso8601String().split('T')[0]);
      }

      if (fechaHasta != null) {
        queryBuilder = queryBuilder.lte('fecha_salida', fechaHasta.toIso8601String().split('T')[0]);
      }

      final response = await queryBuilder.order('fecha_salida', ascending: false);

      var viajes = response.map<ViajeModel>((json) {
        // Agregar información del conductor, vehículo y ruta
        final conductor = json['conductores'];
        final vehiculo = json['vehiculos'];
        final ruta = json['rutas'];
        
        json['conductor_nombre'] = conductor != null 
            ? '${conductor['nombres']} ${conductor['apellidos']}'
            : null;
        json['vehiculo_placa'] = vehiculo?['placa'];
        json['vehiculo_marca'] = vehiculo?['marca'];
        json['vehiculo_modelo'] = vehiculo?['modelo'];
        
        // Si no hay origen/destino en el viaje, usar los de la ruta
        if (json['origen'] == null && ruta != null) {
          json['origen'] = ruta['origen'];
        }
        if (json['destino'] == null && ruta != null) {
          json['destino'] = ruta['destino'];
        }
        
        return ViajeModel.fromJson(json);
      }).toList();

      // Filtrar por query si se proporciona
      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        viajes = viajes.where((viaje) {
          return viaje.rutaId.toLowerCase().contains(queryLower) ||
                 viaje.vehiculoId.toLowerCase().contains(queryLower) ||
                 viaje.estado.name.toLowerCase().contains(queryLower);
        }).toList();
      }

      return viajes;
    } catch (e) {
      throw Exception('Error al buscar viajes: $e');
    }
  }

  // Obtener estadísticas de viajes
  Future<Map<String, dynamic>> obtenerEstadisticasViajes(String empresaId) async {
    try {
      final response = await _supabase
          .from('viajes')
          .select('estado, cupos_disponibles, cupos_ocupados, precio')
          .eq('empresa_id', empresaId);

      int totalViajes = response.length;
      int viajesProgramados = 0;
      int viajesEnCurso = 0;
      int viajesCompletados = 0;
      int viajesCancelados = 0;
      int totalCupos = 0;
      int cuposOcupados = 0;
      double ingresosTotales = 0;

      for (final viaje in response) {
        final estado = viaje['estado'] as String;
        final cuposDisp = viaje['cupos_disponibles'] as int? ?? 0;
        final cuposOcup = viaje['cupos_ocupados'] as int? ?? 0;
        final precio = (viaje['precio'] as num?)?.toDouble() ?? 0;

        switch (estado) {
          case 'programado':
            viajesProgramados++;
            break;
          case 'enCurso':
            viajesEnCurso++;
            break;
          case 'completado':
            viajesCompletados++;
            ingresosTotales += precio * cuposOcup;
            break;
          case 'cancelado':
            viajesCancelados++;
            break;
        }

        totalCupos += cuposDisp;
        cuposOcupados += cuposOcup;
      }

      double porcentajeOcupacion = totalCupos > 0 ? (cuposOcupados / totalCupos) * 100 : 0;

      return {
        'total_viajes': totalViajes,
        'viajes_programados': viajesProgramados,
        'viajes_en_curso': viajesEnCurso,
        'viajes_completados': viajesCompletados,
        'viajes_cancelados': viajesCancelados,
        'total_cupos': totalCupos,
        'cupos_ocupados': cuposOcupados,
        'cupos_disponibles': totalCupos - cuposOcupados,
        'porcentaje_ocupacion': porcentajeOcupacion,
        'ingresos_totales': ingresosTotales,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Actualizar cupos ocupados
  Future<void> actualizarCuposOcupados(String viajeId, int nuevosCuposOcupados) async {
    try {
      await _supabase
          .from('viajes')
          .update({
            'cupos_ocupados': nuevosCuposOcupados,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', viajeId);
    } catch (e) {
      throw Exception('Error al actualizar cupos ocupados: $e');
    }
  }

  // Verificar disponibilidad de cupos
  Future<bool> verificarDisponibilidadCupos(String viajeId, int cuposRequeridos) async {
    try {
      final response = await _supabase
          .from('viajes')
          .select('cupos_disponibles, cupos_ocupados')
          .eq('id', viajeId)
          .maybeSingle();

      if (response == null) {
        return false; // Si no se encuentra el viaje, no hay cupos disponibles
      }

      final cuposDisponibles = response['cupos_disponibles'] as int;
      final cuposOcupados = response['cupos_ocupados'] as int;
      final cuposLibres = cuposDisponibles - cuposOcupados;

      return cuposLibres >= cuposRequeridos;
    } catch (e) {
      throw Exception('Error al verificar disponibilidad: $e');
    }
  }
}