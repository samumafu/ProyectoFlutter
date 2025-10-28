import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehiculo_model.dart';

class VehiculoService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'vehiculos';

  // Registrar nuevo vehículo
  Future<VehiculoModel?> registrarVehiculo(VehiculoModel vehiculo) async {
    try {
      final data = vehiculo.toJson();
      data.remove('id'); // Remover ID para que Supabase lo genere

      final response = await _supabase
          .from(_tableName)
          .insert(data)
          .select()
          .maybeSingle();

      return response != null ? VehiculoModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al registrar vehículo: $e');
    }
  }

  // Obtener vehículos por empresa
  Future<List<VehiculoModel>> obtenerVehiculosPorEmpresa(String empresaId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('empresa_id', empresaId)
          .order('created_at', ascending: false);

      return response.map<VehiculoModel>((json) => VehiculoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener vehículos: $e');
    }
  }

  // Obtener vehículo por ID
  Future<VehiculoModel?> obtenerVehiculoPorId(String id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? VehiculoModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al obtener vehículo: $e');
    }
  }

  // Obtener vehículo por placa
  Future<VehiculoModel?> obtenerVehiculoPorPlaca(String placa) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('placa', placa)
          .maybeSingle();

      return response != null ? VehiculoModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al obtener vehículo por placa: $e');
    }
  }

  // Actualizar vehículo
  Future<VehiculoModel?> actualizarVehiculo(VehiculoModel vehiculo) async {
    try {
      final data = vehiculo.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_tableName)
          .update(data)
          .eq('id', vehiculo.id)
          .select()
          .maybeSingle();

      return response != null ? VehiculoModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al actualizar vehículo: $e');
    }
  }

  // Cambiar estado del vehículo
  Future<void> cambiarEstadoVehiculo(String id, VehiculoStatus nuevoEstado) async {
    try {
      await _supabase
          .from(_tableName)
          .update({
            'estado': nuevoEstado.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al cambiar estado del vehículo: $e');
    }
  }

  // Eliminar vehículo
  Future<void> eliminarVehiculo(String id) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar vehículo: $e');
    }
  }

  // Verificar si la placa ya existe
  Future<bool> verificarPlacaExiste(String placa, {String? excludeId}) async {
    try {
      var query = _supabase
          .from(_tableName)
          .select('id')
          .eq('placa', placa);

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      throw Exception('Error al verificar placa: $e');
    }
  }

  // Obtener vehículos disponibles (activos y sin conductor asignado)
  Future<List<VehiculoModel>> obtenerVehiculosDisponibles(String empresaId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('empresa_id', empresaId)
          .eq('estado', VehiculoStatus.activo.name)
          .order('placa');

      return response.map<VehiculoModel>((json) => VehiculoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener vehículos disponibles: $e');
    }
  }

  // Obtener vehículos con documentos próximos a vencer
  Future<List<VehiculoModel>> obtenerVehiculosConDocumentosProximosAVencer(
    String empresaId, {
    int diasAnticipacion = 30,
  }) async {
    try {
      final fechaLimite = DateTime.now().add(Duration(days: diasAnticipacion));
      final fechaLimiteStr = fechaLimite.toIso8601String().split('T')[0];

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('empresa_id', empresaId)
          .or(
            'fecha_vencimiento_soat.lte.$fechaLimiteStr,'
            'fecha_vencimiento_revision.lte.$fechaLimiteStr,'
            'fecha_vencimiento_operacion.lte.$fechaLimiteStr,'
            'fecha_vencimiento_poliza.lte.$fechaLimiteStr'
          )
          .order('placa');

      return response.map<VehiculoModel>((json) => VehiculoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener vehículos con documentos próximos a vencer: $e');
    }
  }

  // Subir documento
  Future<String> subirDocumento(String vehiculoId, String tipoDocumento, File file) async {
    try {
      final fileName = '${vehiculoId}_${tipoDocumento}_${DateTime.now().millisecondsSinceEpoch}';
      final path = 'vehiculos/$vehiculoId/$fileName';

      await _supabase.storage
          .from('documentos')
          .upload(path, file);

      final url = _supabase.storage
          .from('documentos')
          .getPublicUrl(path);

      return url;
    } catch (e) {
      throw Exception('Error al subir documento: $e');
    }
  }

  // Eliminar documento
  Future<void> eliminarDocumento(String url) async {
    try {
      // Extraer el path del URL
      final uri = Uri.parse(url);
      final path = uri.pathSegments.skip(4).join('/'); // Skip /storage/v1/object/public/documentos/

      await _supabase.storage
          .from('documentos')
          .remove([path]);
    } catch (e) {
      throw Exception('Error al eliminar documento: $e');
    }
  }

  // Obtener estadísticas de vehículos por empresa
  Future<Map<String, dynamic>> obtenerEstadisticasVehiculos(String empresaId) async {
    try {
      final vehiculos = await obtenerVehiculosPorEmpresa(empresaId);

      final total = vehiculos.length;
      final activos = vehiculos.where((v) => v.estado == VehiculoStatus.activo).length;
      final inactivos = vehiculos.where((v) => v.estado == VehiculoStatus.inactivo).length;
      final enMantenimiento = vehiculos.where((v) => v.estado == VehiculoStatus.mantenimiento).length;

      final conSoatVigente = vehiculos.where((v) => v.hasValidSoat).length;
      final conRevisionVigente = vehiculos.where((v) => v.hasValidRevision).length;

      final capacidadTotal = vehiculos.fold<int>(0, (sum, v) => sum + v.capacidadPasajeros);
      final capacidadActiva = vehiculos
          .where((v) => v.estado == VehiculoStatus.activo)
          .fold<int>(0, (sum, v) => sum + v.capacidadPasajeros);

      // Agrupar por tipo
      final porTipo = <String, int>{};
      for (final vehiculo in vehiculos) {
        final tipo = vehiculo.tipo.name;
        porTipo[tipo] = (porTipo[tipo] ?? 0) + 1;
      }

      // Agrupar por año
      final porAnio = <int, int>{};
      for (final vehiculo in vehiculos) {
        porAnio[vehiculo.anio] = (porAnio[vehiculo.anio] ?? 0) + 1;
      }

      return {
        'total': total,
        'activos': activos,
        'inactivos': inactivos,
        'en_mantenimiento': enMantenimiento,
        'con_soat_vigente': conSoatVigente,
        'con_revision_vigente': conRevisionVigente,
        'capacidad_total': capacidadTotal,
        'capacidad_activa': capacidadActiva,
        'por_tipo': porTipo,
        'por_anio': porAnio,
        'promedio_antiguedad': vehiculos.isNotEmpty
            ? vehiculos.map((v) => DateTime.now().year - v.anio).reduce((a, b) => a + b) / vehiculos.length
            : 0,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas de vehículos: $e');
    }
  }

  // Buscar vehículos
  Future<List<VehiculoModel>> buscarVehiculos(String empresaId, String query) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('empresa_id', empresaId)
          .or(
            'placa.ilike.%$query%,'
            'marca.ilike.%$query%,'
            'modelo.ilike.%$query%,'
            'numero_interno.ilike.%$query%'
          )
          .order('placa');

      return response.map<VehiculoModel>((json) => VehiculoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al buscar vehículos: $e');
    }
  }

  // Obtener vehículos por estado
  Future<List<VehiculoModel>> obtenerVehiculosPorEstado(
    String empresaId,
    VehiculoStatus estado,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('empresa_id', empresaId)
          .eq('estado', estado.name)
          .order('placa');

      return response.map<VehiculoModel>((json) => VehiculoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener vehículos por estado: $e');
    }
  }

  // Obtener vehículos por tipo
  Future<List<VehiculoModel>> obtenerVehiculosPorTipo(
    String empresaId,
    TipoVehiculo tipo,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('empresa_id', empresaId)
          .eq('tipo', tipo.name)
          .order('placa');

      return response.map<VehiculoModel>((json) => VehiculoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener vehículos por tipo: $e');
    }
  }
}