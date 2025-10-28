import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reserva_model.dart';
import 'viaje_service.dart';

class ReservaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ViajeService _viajeService = ViajeService();

  // Crear una nueva reserva
  Future<ReservaModel> crearReserva(ReservaModel reserva) async {
    try {
      // Verificar disponibilidad de cupos
      final disponible = await _viajeService.verificarDisponibilidadCupos(
        reserva.viajeId, 
        reserva.numeroAsientos
      );

      if (!disponible) {
        throw Exception('No hay cupos disponibles para este viaje');
      }

      // Generar código de reserva único
      final codigoReserva = _generarCodigoReserva();
      final reservaConCodigo = reserva.copyWith(codigoReserva: codigoReserva);

      final response = await _supabase
          .from('reservas')
          .insert(reservaConCodigo.toJson())
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Error al crear la reserva');
      }

      // Actualizar cupos ocupados en el viaje
      await _actualizarCuposViaje(reserva.viajeId, reserva.numeroAsientos);

      return ReservaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear reserva: $e');
    }
  }

  // Obtener reservas por usuario
  Future<List<ReservaModel>> obtenerReservasPorUsuario(String usuarioId) async {
    try {
      final response = await _supabase
          .from('reservas')
          .select('''
            *,
            viajes!inner(
              fecha_salida,
              hora_salida,
              precio,
              rutas!inner(origen, destino)
            )
          ''')
          .eq('usuario_id', usuarioId)
          .order('created_at', ascending: false);

      return response.map<ReservaModel>((json) {
        // Agregar información del viaje
        final viaje = json['viajes'];
        final ruta = viaje?['rutas'];
        
        json['viaje_fecha_salida'] = viaje?['fecha_salida'];
        json['viaje_hora_salida'] = viaje?['hora_salida'];
        json['viaje_precio'] = viaje?['precio'];
        json['viaje_origen'] = ruta?['origen'];
        json['viaje_destino'] = ruta?['destino'];
        
        return ReservaModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener reservas: $e');
    }
  }

  // Obtener reservas por empresa
  Future<List<ReservaModel>> obtenerReservasPorEmpresa(String empresaId) async {
    try {
      final response = await _supabase
          .from('reservas')
          .select('''
            *,
            viajes!inner(
              fecha_salida,
              hora_salida,
              precio,
              rutas!inner(origen, destino)
            )
          ''')
          .eq('empresa_id', empresaId)
          .order('created_at', ascending: false);

      return response.map<ReservaModel>((json) {
        // Agregar información del viaje
        final viaje = json['viajes'];
        final ruta = viaje?['rutas'];
        
        json['viaje_fecha_salida'] = viaje?['fecha_salida'];
        json['viaje_hora_salida'] = viaje?['hora_salida'];
        json['viaje_precio'] = viaje?['precio'];
        json['viaje_origen'] = ruta?['origen'];
        json['viaje_destino'] = ruta?['destino'];
        
        return ReservaModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener reservas: $e');
    }
  }

  // Obtener reserva por ID
  Future<ReservaModel?> obtenerReservaPorId(String reservaId) async {
    try {
      final response = await _supabase
          .from('reservas')
          .select('''
            *,
            viajes!inner(
              fecha_salida,
              hora_salida,
              precio,
              rutas!inner(origen, destino)
            )
          ''')
          .eq('id', reservaId)
          .maybeSingle();

      if (response == null) return null;

      // Agregar información del viaje
      final viaje = response['viajes'];
      final ruta = viaje?['rutas'];
      
      response['viaje_fecha_salida'] = viaje?['fecha_salida'];
      response['viaje_hora_salida'] = viaje?['hora_salida'];
      response['viaje_precio'] = viaje?['precio'];
      response['viaje_origen'] = ruta?['origen'];
      response['viaje_destino'] = ruta?['destino'];

      return ReservaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener reserva: $e');
    }
  }

  // Obtener reserva por código
  Future<ReservaModel?> obtenerReservaPorCodigo(String codigoReserva) async {
    try {
      final response = await _supabase
          .from('reservas')
          .select('''
            *,
            viajes!inner(
              fecha_salida,
              hora_salida,
              precio,
              rutas!inner(origen, destino)
            )
          ''')
          .eq('codigo_reserva', codigoReserva)
          .maybeSingle();

      if (response == null) return null;

      // Agregar información del viaje
      final viaje = response['viajes'];
      final ruta = viaje?['rutas'];
      
      response['viaje_fecha_salida'] = viaje?['fecha_salida'];
      response['viaje_hora_salida'] = viaje?['hora_salida'];
      response['viaje_precio'] = viaje?['precio'];
      response['viaje_origen'] = ruta?['origen'];
      response['viaje_destino'] = ruta?['destino'];

      return ReservaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener reserva: $e');
    }
  }

  // Actualizar reserva
  Future<ReservaModel?> actualizarReserva(ReservaModel reserva) async {
    try {
      final response = await _supabase
          .from('reservas')
          .update(reserva.toJson())
          .eq('id', reserva.id)
          .select()
          .maybeSingle();

      return response != null ? ReservaModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al actualizar reserva: $e');
    }
  }

  // Cambiar estado de reserva
  Future<void> cambiarEstadoReserva(String reservaId, ReservaStatus nuevoEstado) async {
    try {
      await _supabase
          .from('reservas')
          .update({
            'estado': nuevoEstado.toString().split('.').last,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reservaId);
    } catch (e) {
      throw Exception('Error al cambiar estado de reserva: $e');
    }
  }

  // Confirmar pago de reserva
  Future<void> confirmarPago(String reservaId, MetodoPago metodoPago, {String? transactionId}) async {
    try {
      await _supabase
          .from('reservas')
          .update({
            'estado': ReservaStatus.pagada.toString().split('.').last,
            'metodo_pago': metodoPago.toString().split('.').last,
            'fecha_pago': DateTime.now().toIso8601String(),
            'transaction_id': transactionId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reservaId);
    } catch (e) {
      throw Exception('Error al confirmar pago: $e');
    }
  }

  // Cancelar reserva
  Future<void> cancelarReserva(String reservaId) async {
    try {
      // Obtener información de la reserva
      final reserva = await obtenerReservaPorId(reservaId);
      if (reserva == null) {
        throw Exception('Reserva no encontrada');
      }

      // Cambiar estado a cancelada
      await cambiarEstadoReserva(reservaId, ReservaStatus.cancelada);

      // Liberar cupos en el viaje
      await _liberarCuposViaje(reserva.viajeId, reserva.numeroAsientos);
    } catch (e) {
      throw Exception('Error al cancelar reserva: $e');
    }
  }

  // Buscar reservas
  Future<List<ReservaModel>> buscarReservas({
    required String empresaId,
    String? query,
    ReservaStatus? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('reservas')
          .select('''
            *,
            viajes!inner(
              fecha_salida,
              hora_salida,
              precio,
              rutas!inner(origen, destino)
            )
          ''')
          .eq('empresa_id', empresaId);

      if (estado != null) {
        queryBuilder = queryBuilder.eq('estado', estado.toString().split('.').last);
      }

      if (fechaDesde != null) {
        queryBuilder = queryBuilder.gte('created_at', fechaDesde.toIso8601String());
      }

      if (fechaHasta != null) {
        queryBuilder = queryBuilder.lte('created_at', fechaHasta.toIso8601String());
      }

      final response = await queryBuilder.order('created_at', ascending: false);

      var reservas = response.map<ReservaModel>((json) {
        // Agregar información del viaje
        final viaje = json['viajes'];
        final ruta = viaje?['rutas'];
        
        json['viaje_fecha_salida'] = viaje?['fecha_salida'];
        json['viaje_hora_salida'] = viaje?['hora_salida'];
        json['viaje_precio'] = viaje?['precio'];
        json['viaje_origen'] = ruta?['origen'];
        json['viaje_destino'] = ruta?['destino'];
        
        return ReservaModel.fromJson(json);
      }).toList();

      // Filtrar por query si se proporciona
      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        reservas = reservas.where((reserva) {
          return reserva.nombrePasajero.toLowerCase().contains(queryLower) ||
                 reserva.telefonoPasajero.toLowerCase().contains(queryLower) ||
                 (reserva.codigoReserva?.toLowerCase().contains(queryLower) ?? false) ||
                 (reserva.documentoPasajero?.toLowerCase().contains(queryLower) ?? false);
        }).toList();
      }

      return reservas;
    } catch (e) {
      throw Exception('Error al buscar reservas: $e');
    }
  }

  // Obtener estadísticas de reservas
  Future<Map<String, dynamic>> obtenerEstadisticasReservas(String empresaId) async {
    try {
      final response = await _supabase
          .from('reservas')
          .select('estado, numero_asientos, precio_final')
          .eq('empresa_id', empresaId);

      int totalReservas = response.length;
      int reservasPendientes = 0;
      int reservasConfirmadas = 0;
      int reservasPagadas = 0;
      int reservasCanceladas = 0;
      int reservasCompletadas = 0;
      int totalAsientos = 0;
      double ingresosTotales = 0;

      for (final reserva in response) {
        final estado = reserva['estado'] as String;
        final asientos = reserva['numero_asientos'] as int? ?? 0;
        final precio = (reserva['precio_final'] as num?)?.toDouble() ?? 0;

        switch (estado) {
          case 'pendiente':
            reservasPendientes++;
            break;
          case 'confirmada':
            reservasConfirmadas++;
            break;
          case 'pagada':
            reservasPagadas++;
            ingresosTotales += precio;
            break;
          case 'cancelada':
            reservasCanceladas++;
            break;
          case 'completada':
            reservasCompletadas++;
            ingresosTotales += precio;
            break;
        }

        totalAsientos += asientos;
      }

      return {
        'total_reservas': totalReservas,
        'reservas_pendientes': reservasPendientes,
        'reservas_confirmadas': reservasConfirmadas,
        'reservas_pagadas': reservasPagadas,
        'reservas_canceladas': reservasCanceladas,
        'reservas_completadas': reservasCompletadas,
        'total_asientos_reservados': totalAsientos,
        'ingresos_totales': ingresosTotales,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Métodos privados
  String _generarCodigoReserva() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'RES$random';
  }

  Future<void> _actualizarCuposViaje(String viajeId, int cuposReservados) async {
    try {
      // Obtener cupos actuales
      final response = await _supabase
          .from('viajes')
          .select('cupos_ocupados')
          .eq('id', viajeId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Viaje no encontrado');
      }

      final cuposActuales = response['cupos_ocupados'] as int;
      final nuevosCupos = cuposActuales + cuposReservados;

      await _viajeService.actualizarCuposOcupados(viajeId, nuevosCupos);
    } catch (e) {
      throw Exception('Error al actualizar cupos del viaje: $e');
    }
  }

  Future<void> _liberarCuposViaje(String viajeId, int cuposALiberar) async {
    try {
      // Obtener cupos actuales
      final response = await _supabase
          .from('viajes')
          .select('cupos_ocupados')
          .eq('id', viajeId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Viaje no encontrado');
      }

      final cuposActuales = response['cupos_ocupados'] as int;
      final nuevosCupos = (cuposActuales - cuposALiberar).clamp(0, cuposActuales);

      await _viajeService.actualizarCuposOcupados(viajeId, nuevosCupos);
    } catch (e) {
      throw Exception('Error al liberar cupos del viaje: $e');
    }
  }
}