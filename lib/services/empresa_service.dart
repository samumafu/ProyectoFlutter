import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empresa_model.dart';

class EmpresaService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Registrar nueva empresa
  static Future<EmpresaModel?> registrarEmpresa({
    required String userId,
    required String razonSocial,
    required String nit,
    required String representanteLegal,
    required String cedulaRepresentante,
    required String telefono,
    required String email,
    required String direccion,
    required String municipio,
    String? sitioWeb,
    String? logoUrl,
  }) async {
    try {
      final response = await _supabase
          .from('empresas_transportadoras')
          .insert({
            'user_id': userId,
            'razon_social': razonSocial,
            'nit': nit,
            'representante_legal': representanteLegal,
            'cedula_representante': cedulaRepresentante,
            'telefono': telefono,
            'email': email,
            'direccion': direccion,
            'municipio': municipio,
            'sitio_web': sitioWeb,
            'logo_url': logoUrl,
            'estado': 'pendiente',
            'fecha_registro': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();

      return response != null ? EmpresaModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al registrar empresa: $e');
    }
  }

  // Obtener empresa por user_id
  static Future<EmpresaModel?> obtenerEmpresaPorUserId(String userId) async {
    try {
      final response = await _supabase
          .from('empresas_transportadoras')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return EmpresaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener empresa: $e');
    }
  }

  // Obtener empresa por ID
  static Future<EmpresaModel?> obtenerEmpresaPorId(String empresaId) async {
    try {
      final response = await _supabase
          .from('empresas_transportadoras')
          .select()
          .eq('id', empresaId)
          .maybeSingle();

      if (response == null) return null;
      return EmpresaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener empresa: $e');
    }
  }

  // Actualizar información de empresa
  static Future<EmpresaModel?> actualizarEmpresa({
    required String empresaId,
    String? razonSocial,
    String? representanteLegal,
    String? cedulaRepresentante,
    String? telefono,
    String? email,
    String? direccion,
    String? municipio,
    String? sitioWeb,
    String? logoUrl,
    String? resolucionHabilitacionUrl,
    String? rntUrl,
    String? camaraComercioUrl,
    String? rutUrl,
    String? polizaUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (razonSocial != null) updateData['razon_social'] = razonSocial;
      if (representanteLegal != null) updateData['representante_legal'] = representanteLegal;
      if (cedulaRepresentante != null) updateData['cedula_representante'] = cedulaRepresentante;
      if (telefono != null) updateData['telefono'] = telefono;
      if (email != null) updateData['email'] = email;
      if (direccion != null) updateData['direccion'] = direccion;
      if (municipio != null) updateData['municipio'] = municipio;
      if (sitioWeb != null) updateData['sitio_web'] = sitioWeb;
      if (logoUrl != null) updateData['logo_url'] = logoUrl;
      if (resolucionHabilitacionUrl != null) updateData['resolucion_habilitacion_url'] = resolucionHabilitacionUrl;
      if (rntUrl != null) updateData['rnt_url'] = rntUrl;
      if (camaraComercioUrl != null) updateData['camara_comercio_url'] = camaraComercioUrl;
      if (rutUrl != null) updateData['rut_url'] = rutUrl;
      if (polizaUrl != null) updateData['poliza_url'] = polizaUrl;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('empresas_transportadoras')
          .update(updateData)
          .eq('id', empresaId)
          .select()
          .maybeSingle();

      return response != null ? EmpresaModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al actualizar empresa: $e');
    }
  }

  // Cambiar estado de empresa
  static Future<void> cambiarEstadoEmpresa(String empresaId, EmpresaStatus nuevoEstado) async {
    try {
      await _supabase
          .from('empresas_transportadoras')
          .update({
            'estado': nuevoEstado.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', empresaId);
    } catch (e) {
      throw Exception('Error al cambiar estado de empresa: $e');
    }
  }

  // Obtener todas las empresas (para admin)
  static Future<List<EmpresaModel>> obtenerTodasLasEmpresas({
    EmpresaStatus? filtroEstado,
    int? limite,
    int? offset,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('empresas_transportadoras')
          .select();

      if (filtroEstado != null) {
        query = query.eq('estado', filtroEstado.name);
      }

      PostgrestTransformBuilder finalQuery;
      if (limite != null && offset != null) {
        finalQuery = query.range(offset, offset + limite - 1);
      } else if (limite != null) {
        finalQuery = query.limit(limite);
      } else {
        finalQuery = query;
      }

      final response = await finalQuery.order('fecha_registro', ascending: false);

      return response.map<EmpresaModel>((json) => EmpresaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener empresas: $e');
    }
  }

  // Verificar si NIT ya existe
  static Future<bool> verificarNitExiste(String nit, {String? excludeEmpresaId}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('empresas_transportadoras')
          .select('id')
          .eq('nit', nit);

      if (excludeEmpresaId != null) {
        query = query.neq('id', excludeEmpresaId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      throw Exception('Error al verificar NIT: $e');
    }
  }

  // Subir documento a Supabase Storage
  static Future<String> subirDocumento({
    required String empresaId,
    required String tipoDocumento,
    required Uint8List archivoBytes,
    required String nombreArchivo,
  }) async {
    try {
      final extension = nombreArchivo.split('.').last;
      final fileName = '${empresaId}_${tipoDocumento}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final filePath = 'empresas/$empresaId/documentos/$fileName';

      await _supabase.storage
          .from('documentos')
          .uploadBinary(filePath, archivoBytes);

      final publicUrl = _supabase.storage
          .from('documentos')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir documento: $e');
    }
  }

  // Eliminar documento de Supabase Storage
  static Future<void> eliminarDocumento(String documentoUrl) async {
    try {
      // Extraer el path del documento de la URL
      final uri = Uri.parse(documentoUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('documentos');
      
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        
        await _supabase.storage
            .from('documentos')
            .remove([filePath]);
      }
    } catch (e) {
      throw Exception('Error al eliminar documento: $e');
    }
  }

  // Obtener estadísticas de empresa
  static Future<Map<String, dynamic>> obtenerEstadisticasEmpresa(String empresaId) async {
    try {
      // Obtener conteo de conductores
      final conductoresResponse = await _supabase
          .from('conductores')
          .select('id')
          .eq('empresa_id', empresaId)
          .eq('estado', 'activo');

      // Obtener conteo de vehículos
      final vehiculosResponse = await _supabase
          .from('vehiculos')
          .select('id')
          .eq('empresa_id', empresaId)
          .eq('estado', 'activo');

      // Obtener conteo de rutas
      final rutasResponse = await _supabase
          .from('rutas')
          .select('id')
          .eq('empresa_id', empresaId)
          .eq('activa', true);

      // Obtener viajes del mes actual
      final inicioMes = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final finMes = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

      final viajesResponse = await _supabase
          .from('viajes')
          .select('id, precio_base')
          .eq('empresa_id', empresaId)
          .gte('fecha_salida', inicioMes.toIso8601String())
          .lte('fecha_salida', finMes.toIso8601String());

      // Calcular ingresos del mes
      double ingresosMes = 0;
      for (final viaje in viajesResponse) {
        ingresosMes += (viaje['precio_base'] as num?)?.toDouble() ?? 0;
      }

      return {
        'conductores_activos': conductoresResponse.length,
        'vehiculos_activos': vehiculosResponse.length,
        'rutas_activas': rutasResponse.length,
        'viajes_mes': viajesResponse.length,
        'ingresos_mes': ingresosMes,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}