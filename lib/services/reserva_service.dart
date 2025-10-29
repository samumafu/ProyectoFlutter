import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reserva_model.dart';
import 'viaje_service.dart';

class ReservaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ViajeService _viajeService = ViajeService();

  // Crear una nueva reserva
  Future<ReservaModel> crearReserva(ReservaModel reserva) async {
    try {
      // Verificar disponibilidad de asientos
      final disponible = await _verificarDisponibilidadAsientos(
        reserva.viajeId, 
        reserva.numeroAsientos
      );

      if (!disponible) {
        throw Exception('No hay asientos disponibles para este viaje');
      }

      // Primero, crear o verificar que existe el pasajero
      final pasajeroId = await _crearOVerificarPasajero(reserva);

      // Generar código de reserva único
      final codigoReserva = _generarCodigoReserva();

      // Crear la reserva en la tabla reservations (según el esquema SQL real)
      final reservaData = {
        'trip_id': reserva.viajeId,
        'passenger_id': pasajeroId, // Usar el ID del pasajero válido
        'seats_reserved': reserva.numeroAsientos,
        'seat_numbers': reserva.asientosSeleccionados, // Guardar números específicos de asientos
        'total_price': reserva.precioFinal,
        'status': _mapearEstado(reserva.estado),
      };

      final response = await _supabase
          .from('reservations')
          .insert(reservaData)
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Error al crear la reserva');
      }

      // Actualizar asientos disponibles
      await _actualizarAsientosDisponibles(reserva.viajeId, reserva.numeroAsientos);

      // Convertir la respuesta al modelo de reserva
      final reservaCreada = reserva.copyWith(
        id: response['id'],
        codigoReserva: codigoReserva,
        createdAt: DateTime.parse(response['created_at']),
      );

      return reservaCreada;
    } catch (e) {
      throw Exception('Error al crear reserva: $e');
    }
  }

  // Obtener reservas por pasajero (alias para obtenerReservasPorUsuario)
  Future<List<ReservaModel>> obtenerReservasPorPasajero(String pasajeroId) async {
    return await obtenerReservasPorUsuario(pasajeroId);
  }

  // Obtener reservas por usuario
  Future<List<ReservaModel>> obtenerReservasPorUsuario(String usuarioId) async {
    try {
      // Primero obtener el passenger_id del usuario
      final pasajero = await _supabase
          .from('pasajeros')
          .select('id')
          .eq('user_id', usuarioId)
          .maybeSingle();

      if (pasajero == null) {
        return []; // No hay pasajero registrado, retornar lista vacía
      }

      final passengerId = pasajero['id'];

      // Ahora buscar las reservas por passenger_id
      final response = await _supabase
          .from('reservations')
          .select('*')
          .eq('passenger_id', passengerId)
          .order('created_at', ascending: false);

      return response.map<ReservaModel>((json) {
        return _convertirReservaDesdeSQL(json);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener reservas: $e');
    }
  }

  // Obtener reserva por ID
  Future<ReservaModel?> obtenerReservaPorId(String reservaId) async {
    try {
      final response = await _supabase
          .from('reservations')
          .select('*')
          .eq('id', reservaId)
          .maybeSingle();

      if (response == null) return null;

      return _convertirReservaDesdeSQL(response);
    } catch (e) {
      throw Exception('Error al obtener reserva: $e');
    }
  }

  // Cambiar estado de reserva
  Future<void> cambiarEstadoReserva(String reservaId, ReservaStatus nuevoEstado) async {
    try {
      await _supabase
          .from('reservations')
          .update({
            'status': _mapearEstado(nuevoEstado),
          })
          .eq('id', reservaId);
    } catch (e) {
      throw Exception('Error al cambiar estado de reserva: $e');
    }
  }

  // Cancelar reserva
  Future<void> cancelarReserva(String reservaId) async {
    try {
      final reserva = await obtenerReservaPorId(reservaId);
      if (reserva == null) {
        throw Exception('Reserva no encontrada');
      }

      await cambiarEstadoReserva(reservaId, ReservaStatus.cancelada);
      await _liberarAsientos(reserva.viajeId, reserva.numeroAsientos);
    } catch (e) {
      throw Exception('Error al cancelar reserva: $e');
    }
  }

  // Crear o verificar que existe el pasajero
  Future<String> _crearOVerificarPasajero(ReservaModel reserva) async {
    try {
      // Primero verificar si ya existe un pasajero con este user_id
      final existingPassenger = await _supabase
          .from('pasajeros')
          .select('id')
          .eq('user_id', reserva.usuarioId)
          .maybeSingle();

      if (existingPassenger != null) {
        return existingPassenger['id'];
      }

      // Verificar si el user_id existe en la tabla users
      final userExists = await _supabase
          .from('users')
          .select('id')
          .eq('id', reserva.usuarioId)
          .maybeSingle();

      if (userExists == null) {
        // Si el usuario no existe, crear uno primero
        final userData = {
          'id': reserva.usuarioId,
          'email': '${reserva.nombrePasajero.toLowerCase().replaceAll(' ', '')}@temp.com',
          'password_hash': 'temp_hash',
          'role': 'pasajero',
        };

        await _supabase
            .from('users')
            .insert(userData);
      }

      // Ahora crear el pasajero con user_id válido
      final pasajeroData = {
        'user_id': reserva.usuarioId,
        'name': reserva.nombrePasajero,
        'phone': reserva.telefonoPasajero ?? '',
        'rating': 5.0,
      };

      final response = await _supabase
          .from('pasajeros')
          .insert(pasajeroData)
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      throw Exception('Error al crear o verificar pasajero: $e');
    }
  }

  // Métodos privados de utilidad
  String _generarCodigoReserva() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'RES$random';
  }

  String _mapearEstado(ReservaStatus estado) {
    switch (estado) {
      case ReservaStatus.pendiente:
        return 'pending';
      case ReservaStatus.confirmada:
        return 'confirmed';
      case ReservaStatus.cancelada:
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  ReservaStatus _mapearEstadoDesdeSQL(String estado) {
    switch (estado) {
      case 'pending':
        return ReservaStatus.pendiente;
      case 'confirmed':
        return ReservaStatus.confirmada;
      case 'cancelled':
        return ReservaStatus.cancelada;
      default:
        return ReservaStatus.pendiente;
    }
  }

  ReservaModel _convertirReservaDesdeSQL(Map<String, dynamic> json) {
    // Convertir seat_numbers de array a lista de strings
    List<String> asientosSeleccionados = [];
    if (json['seat_numbers'] != null) {
      final seatNumbers = json['seat_numbers'] as List<dynamic>?;
      if (seatNumbers != null) {
        asientosSeleccionados = seatNumbers.map((s) => s.toString()).toList();
      }
    }

    return ReservaModel(
      id: json['id'],
      viajeId: json['trip_id'],
      usuarioId: json['passenger_id'],
      empresaId: '', // No está en la tabla SQL
      nombrePasajero: '', // No está en la tabla SQL
      telefonoPasajero: '', // No está en la tabla SQL
      documentoPasajero: '', // No está en la tabla SQL
      emailPasajero: '', // No está en la tabla SQL
      numeroAsientos: json['seats_reserved'] ?? 1,
      asientosSeleccionados: asientosSeleccionados,
      precioTotal: (json['total_price'] ?? 0.0).toDouble(),
      precioFinal: (json['total_price'] ?? 0.0).toDouble(),
      descuento: null,
      metodoPago: MetodoPago.efectivo, // Valor por defecto
      transactionId: '', // No está en la tabla SQL
      estado: _mapearEstadoDesdeSQL(json['status'] ?? 'pending'),
      codigoReserva: '', // Se genera al crear
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Future<bool> _verificarDisponibilidadAsientos(String viajeId, int asientosSolicitados) async {
    try {
      // Obtener asientos ocupados actuales
      final response = await _supabase
          .from('reservations')
          .select('seats_reserved')
          .eq('trip_id', viajeId)
          .eq('status', 'confirmed');

      int asientosOcupados = 0;
      for (final reserva in response) {
        asientosOcupados += (reserva['seats_reserved'] as int? ?? 0);
      }

      // Asumir capacidad máxima de 40 asientos por viaje
      const capacidadMaxima = 40;
      return (asientosOcupados + asientosSolicitados) <= capacidadMaxima;
    } catch (e) {
      return false;
    }
  }

  Future<void> _actualizarAsientosDisponibles(String viajeId, int asientosReservados) async {
    try {
      // Obtener los asientos disponibles actuales
      final viaje = await _supabase
          .from('company_schedules')
          .select('available_seats')
          .eq('id', viajeId)
          .single();

      final asientosActuales = viaje['available_seats'] as int;
      final nuevosAsientosDisponibles = asientosActuales - asientosReservados;

      // Actualizar los asientos disponibles
      await _supabase
          .from('company_schedules')
          .update({'available_seats': nuevosAsientosDisponibles})
          .eq('id', viajeId);
    } catch (e) {
      throw Exception('Error al actualizar asientos disponibles: $e');
    }
  }

  Future<void> _liberarAsientos(String viajeId, int asientosALiberar) async {
    try {
      // Obtener los asientos disponibles actuales
      final viaje = await _supabase
          .from('company_schedules')
          .select('available_seats')
          .eq('id', viajeId)
          .single();

      final asientosActuales = viaje['available_seats'] as int;
      final nuevosAsientosDisponibles = asientosActuales + asientosALiberar;

      // Actualizar los asientos disponibles
      await _supabase
          .from('company_schedules')
          .update({'available_seats': nuevosAsientosDisponibles})
          .eq('id', viajeId);
    } catch (e) {
      throw Exception('Error al liberar asientos: $e');
    }
  }

  // Obtener asientos ocupados específicos por viaje
  Future<List<String>> obtenerAsientosOcupados(String viajeId) async {
    try {
      final response = await _supabase
          .from('reservations')
          .select('seat_numbers')
          .eq('trip_id', viajeId)
          .eq('status', 'confirmed');

      List<String> asientosOcupados = [];
      for (final reserva in response) {
        final seatNumbers = reserva['seat_numbers'] as List<dynamic>?;
        if (seatNumbers != null) {
          asientosOcupados.addAll(seatNumbers.map((s) => s.toString()));
        }
      }

      return asientosOcupados;
    } catch (e) {
      throw Exception('Error al obtener asientos ocupados: $e');
    }
  }
}