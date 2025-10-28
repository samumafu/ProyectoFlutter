import 'package:flutter/material.dart';
import '../models/reserva_model.dart';
import '../services/reserva_service.dart';

class ReservaController extends ChangeNotifier {
  final ReservaService _reservaService = ReservaService();

  // Estado
  List<ReservaModel> _reservas = [];
  List<ReservaModel> _reservasFiltradas = [];
  ReservaModel? _reservaSeleccionada;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _estadisticas = {};

  // Getters
  List<ReservaModel> get reservas => _reservas;
  List<ReservaModel> get reservasFiltradas => _reservasFiltradas;
  ReservaModel? get reservaSeleccionada => _reservaSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get estadisticas => _estadisticas;

  // Getters de listas filtradas
  List<ReservaModel> get reservasPendientes => 
      _reservas.where((r) => r.estado == ReservaStatus.pendiente).toList();
  
  List<ReservaModel> get reservasConfirmadas => 
      _reservas.where((r) => r.estado == ReservaStatus.confirmada).toList();
  
  List<ReservaModel> get reservasPagadas => 
      _reservas.where((r) => r.estado == ReservaStatus.pagada).toList();
  
  List<ReservaModel> get reservasCanceladas => 
      _reservas.where((r) => r.estado == ReservaStatus.cancelada).toList();

  List<ReservaModel> get reservasCompletadas => 
      _reservas.where((r) => r.estado == ReservaStatus.completada).toList();

  List<ReservaModel> get reservasActivas => 
      _reservas.where((r) => r.isActive).toList();

  // Crear reserva
  Future<bool> crearReserva(ReservaModel reserva) async {
    try {
      _setLoading(true);
      _clearError();

      final nuevaReserva = await _reservaService.crearReserva(reserva);
      _reservas.insert(0, nuevaReserva);
      _actualizarReservasFiltradas();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear reserva: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cargar reservas por usuario
  Future<void> cargarReservasPorUsuario(String usuarioId) async {
    try {
      _setLoading(true);
      _clearError();

      _reservas = await _reservaService.obtenerReservasPorUsuario(usuarioId);
      _actualizarReservasFiltradas();
      
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar reservas: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Cargar reservas por empresa
  Future<void> cargarReservasPorEmpresa(String empresaId) async {
    try {
      _setLoading(true);
      _clearError();

      _reservas = await _reservaService.obtenerReservasPorEmpresa(empresaId);
      _actualizarReservasFiltradas();
      
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar reservas: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Cargar reserva por ID
  Future<void> cargarReservaPorId(String reservaId) async {
    try {
      _setLoading(true);
      _clearError();

      final reserva = await _reservaService.obtenerReservaPorId(reservaId);
      if (reserva != null) {
        _reservaSeleccionada = reserva;
        notifyListeners();
      }
    } catch (e) {
      _setError('Error al cargar reserva: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Cargar reserva por código
  Future<void> cargarReservaPorCodigo(String codigoReserva) async {
    try {
      _setLoading(true);
      _clearError();

      final reserva = await _reservaService.obtenerReservaPorCodigo(codigoReserva);
      if (reserva != null) {
        _reservaSeleccionada = reserva;
        notifyListeners();
      }
    } catch (e) {
      _setError('Error al cargar reserva: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar reserva
  Future<bool> actualizarReserva(ReservaModel reserva) async {
    try {
      _setLoading(true);
      _clearError();

      final reservaActualizada = await _reservaService.actualizarReserva(reserva);
      
      // Actualizar en la lista local
      final index = _reservas.indexWhere((r) => r.id == reserva.id);
      if (index != -1) {
        _reservas[index] = reservaActualizada;
        _actualizarReservasFiltradas();
      }

      // Actualizar reserva seleccionada si es la misma
      if (_reservaSeleccionada?.id == reserva.id) {
        _reservaSeleccionada = reservaActualizada;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar reserva: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cambiar estado de reserva
  Future<bool> cambiarEstadoReserva(String reservaId, ReservaStatus nuevoEstado) async {
    try {
      _setLoading(true);
      _clearError();

      await _reservaService.cambiarEstadoReserva(reservaId, nuevoEstado);
      
      // Actualizar en la lista local
      final index = _reservas.indexWhere((r) => r.id == reservaId);
      if (index != -1) {
        _reservas[index] = _reservas[index].copyWith(
          estado: nuevoEstado,
          updatedAt: DateTime.now(),
        );
        _actualizarReservasFiltradas();
      }

      // Actualizar reserva seleccionada si es la misma
      if (_reservaSeleccionada?.id == reservaId) {
        _reservaSeleccionada = _reservaSeleccionada!.copyWith(
          estado: nuevoEstado,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al cambiar estado de reserva: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Confirmar pago
  Future<bool> confirmarPago(String reservaId, MetodoPago metodoPago, {String? transactionId}) async {
    try {
      _setLoading(true);
      _clearError();

      await _reservaService.confirmarPago(reservaId, metodoPago, transactionId: transactionId);
      
      // Actualizar en la lista local
      final index = _reservas.indexWhere((r) => r.id == reservaId);
      if (index != -1) {
        _reservas[index] = _reservas[index].copyWith(
          estado: ReservaStatus.pagada,
          metodoPago: metodoPago,
          fechaPago: DateTime.now(),
          transactionId: transactionId,
          updatedAt: DateTime.now(),
        );
        _actualizarReservasFiltradas();
      }

      // Actualizar reserva seleccionada si es la misma
      if (_reservaSeleccionada?.id == reservaId) {
        _reservaSeleccionada = _reservaSeleccionada!.copyWith(
          estado: ReservaStatus.pagada,
          metodoPago: metodoPago,
          fechaPago: DateTime.now(),
          transactionId: transactionId,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al confirmar pago: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancelar reserva
  Future<bool> cancelarReserva(String reservaId) async {
    try {
      _setLoading(true);
      _clearError();

      await _reservaService.cancelarReserva(reservaId);
      
      // Actualizar en la lista local
      final index = _reservas.indexWhere((r) => r.id == reservaId);
      if (index != -1) {
        _reservas[index] = _reservas[index].copyWith(
          estado: ReservaStatus.cancelada,
          updatedAt: DateTime.now(),
        );
        _actualizarReservasFiltradas();
      }

      // Actualizar reserva seleccionada si es la misma
      if (_reservaSeleccionada?.id == reservaId) {
        _reservaSeleccionada = _reservaSeleccionada!.copyWith(
          estado: ReservaStatus.cancelada,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al cancelar reserva: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Buscar reservas
  Future<void> buscarReservas({
    required String empresaId,
    String? query,
    ReservaStatus? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      _reservas = await _reservaService.buscarReservas(
        empresaId: empresaId,
        query: query,
        estado: estado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
      _actualizarReservasFiltradas();
      
      notifyListeners();
    } catch (e) {
      _setError('Error al buscar reservas: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Filtrar reservas localmente
  void filtrarReservas({
    String? query,
    ReservaStatus? estado,
  }) {
    _reservasFiltradas = _reservas.where((reserva) {
      bool matchQuery = true;
      bool matchEstado = true;

      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        matchQuery = reserva.nombrePasajero.toLowerCase().contains(queryLower) ||
                    reserva.telefonoPasajero.toLowerCase().contains(queryLower) ||
                    (reserva.codigoReserva?.toLowerCase().contains(queryLower) ?? false) ||
                    (reserva.documentoPasajero?.toLowerCase().contains(queryLower) ?? false);
      }

      if (estado != null) {
        matchEstado = reserva.estado == estado;
      }

      return matchQuery && matchEstado;
    }).toList();

    notifyListeners();
  }

  // Cargar estadísticas
  Future<void> cargarEstadisticas(String empresaId) async {
    try {
      _setLoading(true);
      _clearError();

      _estadisticas = await _reservaService.obtenerEstadisticasReservas(empresaId);
      
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar estadísticas: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Seleccionar reserva
  void seleccionarReserva(ReservaModel? reserva) {
    _reservaSeleccionada = reserva;
    notifyListeners();
  }

  // Limpiar datos
  void limpiarDatos() {
    _reservas.clear();
    _reservasFiltradas.clear();
    _reservaSeleccionada = null;
    _estadisticas.clear();
    _clearError();
    notifyListeners();
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _actualizarReservasFiltradas() {
    _reservasFiltradas = List.from(_reservas);
  }

  // Validaciones
  String? validarDatosReserva(ReservaModel reserva) {
    if (reserva.nombrePasajero.isEmpty) {
      return 'El nombre del pasajero es requerido';
    }
    if (reserva.telefonoPasajero.isEmpty) {
      return 'El teléfono del pasajero es requerido';
    }
    if (reserva.numeroAsientos <= 0) {
      return 'El número de asientos debe ser mayor a 0';
    }
    if (reserva.asientosSeleccionados.isEmpty) {
      return 'Debe seleccionar al menos un asiento';
    }
    if (reserva.asientosSeleccionados.length != reserva.numeroAsientos) {
      return 'El número de asientos seleccionados no coincide';
    }
    if (reserva.precioTotal <= 0) {
      return 'El precio total debe ser mayor a 0';
    }
    if (reserva.precioFinal <= 0) {
      return 'El precio final debe ser mayor a 0';
    }
    return null;
  }

  // Calcular precio con descuento
  double calcularPrecioConDescuento(double precioBase, double? descuento) {
    if (descuento == null || descuento <= 0) {
      return precioBase;
    }
    return precioBase - descuento;
  }

  // Generar resumen de reserva
  Map<String, dynamic> generarResumenReserva(ReservaModel reserva) {
    return {
      'codigo_reserva': reserva.codigoReserva,
      'pasajero': reserva.nombrePasajero,
      'telefono': reserva.telefonoPasajero,
      'asientos': reserva.numeroAsientos,
      'asientos_seleccionados': reserva.asientosTexto,
      'precio_total': reserva.precioTotal,
      'descuento': reserva.montoDescuento,
      'precio_final': reserva.precioFinal,
      'estado': reserva.estado.toString().split('.').last,
      'viaje': reserva.descripcionViaje,
      'fecha_reserva': reserva.createdAt,
    };
  }
}