import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../models/conductor_model.dart';

class ConductorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Registrar nuevo conductor
  Future<ConductorModel?> registrarConductor(Map<String, dynamic> conductorData) async {
    try {
      final response = await _supabase
          .from('conductores')
          .insert(conductorData)
          .select()
          .maybeSingle();

      return response != null ? ConductorModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al registrar conductor: $e');
    }
  }

  // Obtener conductor por ID de usuario
  Future<ConductorModel?> obtenerConductorPorUserId(String userId) async {
    try {
      final response = await _supabase
          .from('conductores')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return ConductorModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener conductor: $e');
    }
  }

  // Obtener conductor por ID
  Future<ConductorModel?> obtenerConductorPorId(String conductorId) async {
    try {
      final response = await _supabase
          .from('conductores')
          .select()
          .eq('id', conductorId)
          .maybeSingle();

      if (response == null) return null;
      return ConductorModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener conductor: $e');
    }
  }

  // Obtener todos los conductores de una empresa
  Future<List<ConductorModel>> obtenerConductoresPorEmpresa(String empresaId) async {
    try {
      final response = await _supabase
          .from('conductores')
          .select()
          .eq('empresa_id', empresaId)
          .order('created_at', ascending: false);

      return response.map<ConductorModel>((json) => ConductorModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener conductores: $e');
    }
  }

  // Obtener todos los conductores (para admin)
  Future<List<ConductorModel>> obtenerTodosLosConductores() async {
    try {
      final response = await _supabase
          .from('conductores')
          .select()
          .order('created_at', ascending: false);

      return response.map<ConductorModel>((json) => ConductorModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener conductores: $e');
    }
  }

  // Actualizar información del conductor
  Future<ConductorModel?> actualizarConductor(String conductorId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from('conductores')
          .update(updates)
          .eq('id', conductorId)
          .select()
          .maybeSingle();

      return response != null ? ConductorModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al actualizar conductor: $e');
    }
  }

  // Cambiar estado del conductor
  Future<void> cambiarEstadoConductor(String conductorId, ConductorStatus nuevoEstado) async {
    try {
      await _supabase
          .from('conductores')
          .update({
            'estado': nuevoEstado.toString().split('.').last,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conductorId);
    } catch (e) {
      throw Exception('Error al cambiar estado del conductor: $e');
    }
  }

  // Vincular conductor a empresa
  Future<void> vincularConductorAEmpresa(String conductorId, String empresaId) async {
    try {
      await _supabase
          .from('conductores')
          .update({
            'empresa_id': empresaId,
            'fecha_vinculacion': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conductorId);
    } catch (e) {
      throw Exception('Error al vincular conductor: $e');
    }
  }

  // Desvincular conductor de empresa
  Future<void> desvincularConductorDeEmpresa(String conductorId) async {
    try {
      await _supabase
          .from('conductores')
          .update({
            'empresa_id': null,
            'fecha_desvinculacion': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conductorId);
    } catch (e) {
      throw Exception('Error al desvincular conductor: $e');
    }
  }

  // Subir documento del conductor
  Future<String> subirDocumento(String conductorId, String tipoDocumento, Uint8List archivoBytes, String nombreArchivo) async {
    try {
      final fileName = '${conductorId}_${tipoDocumento}_${DateTime.now().millisecondsSinceEpoch}_$nombreArchivo';
      final filePath = 'conductores/$conductorId/documentos/$fileName';

      await _supabase.storage
          .from('documentos')
          .uploadBinary(filePath, archivoBytes);

      final publicUrl = _supabase.storage
          .from('documentos')
          .getPublicUrl(filePath);

      // Actualizar la URL del documento en la base de datos
      final updateField = '${tipoDocumento}_url';
      await _supabase
          .from('conductores')
          .update({
            updateField: publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conductorId);

      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir documento: $e');
    }
  }

  // Eliminar documento del conductor
  Future<void> eliminarDocumento(String conductorId, String tipoDocumento, String documentoUrl) async {
    try {
      // Extraer el path del archivo de la URL
      final uri = Uri.parse(documentoUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('documentos');
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        
        await _supabase.storage
            .from('documentos')
            .remove([filePath]);
      }

      // Actualizar la URL del documento en la base de datos
      final updateField = '${tipoDocumento}_url';
      await _supabase
          .from('conductores')
          .update({
            updateField: null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conductorId);
    } catch (e) {
      throw Exception('Error al eliminar documento: $e');
    }
  }

  // Verificar si existe un conductor con la cédula
  Future<bool> verificarCedulaExiste(String cedula, {String? excludeId}) async {
    try {
      var query = _supabase
          .from('conductores')
          .select('id')
          .eq('cedula', cedula);

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      throw Exception('Error al verificar cédula: $e');
    }
  }

  // Verificar si existe un conductor con el número de licencia
  Future<bool> verificarLicenciaExiste(String numeroLicencia, {String? excludeId}) async {
    try {
      var query = _supabase
          .from('conductores')
          .select('id')
          .eq('numero_licencia', numeroLicencia);

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      throw Exception('Error al verificar licencia: $e');
    }
  }

  // Obtener estadísticas de conductores
  Future<Map<String, dynamic>> obtenerEstadisticasConductores({String? empresaId}) async {
    try {
      var query = _supabase.from('conductores').select();
      
      if (empresaId != null) {
        query = query.eq('empresa_id', empresaId);
      }

      final conductores = await query;

      final total = conductores.length;
      final activos = conductores.where((c) => c['estado'] == 'activo').length;
      final inactivos = conductores.where((c) => c['estado'] == 'inactivo').length;
      final suspendidos = conductores.where((c) => c['estado'] == 'suspendido').length;
      final pendientes = conductores.where((c) => c['estado'] == 'pendiente').length;

      return {
        'total': total,
        'activos': activos,
        'inactivos': inactivos,
        'suspendidos': suspendidos,
        'pendientes': pendientes,
        'porcentajeActivos': total > 0 ? (activos / total * 100).round() : 0,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Buscar conductores
  Future<List<ConductorModel>> buscarConductores(String termino, {String? empresaId}) async {
    try {
      var query = _supabase.from('conductores').select();
      
      if (empresaId != null) {
        query = query.eq('empresa_id', empresaId);
      }

      // Buscar por nombre, apellido, cédula o número de licencia
      query = query.or('nombres.ilike.%$termino%,apellidos.ilike.%$termino%,cedula.ilike.%$termino%,numero_licencia.ilike.%$termino%');

      final response = await query.order('created_at', ascending: false);
      return response.map<ConductorModel>((json) => ConductorModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al buscar conductores: $e');
    }
  }

  // Obtener conductores disponibles
  Future<List<ConductorModel>> obtenerConductoresDisponibles({String? empresaId}) async {
    try {
      var query = _supabase
          .from('conductores')
          .select()
          .eq('estado', 'activo');
      
      if (empresaId != null) {
        query = query.eq('empresa_id', empresaId);
      }

      final response = await query.order('created_at', ascending: false);
      return response.map<ConductorModel>((json) => ConductorModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener conductores disponibles: $e');
    }
  }

  // Actualizar calificación del conductor
  Future<void> actualizarCalificacion(String conductorId, double nuevaCalificacion) async {
    try {
      // Obtener conductor actual
      final conductor = await obtenerConductorPorId(conductorId);
      if (conductor == null) throw Exception('Conductor no encontrado');

      // Por ahora solo actualizamos las observaciones con la calificación
      // En el futuro se pueden agregar campos específicos para calificaciones
      await _supabase
          .from('conductores')
          .update({
            'observaciones': 'Última calificación: $nuevaCalificacion',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conductorId);
    } catch (e) {
      throw Exception('Error al actualizar calificación: $e');
    }
  }
}