import 'package:flutter/material.dart';
import '../models/viaje_model.dart';
import '../services/viaje_service.dart';

class ViajeController extends ChangeNotifier {
  final ViajeService _viajeService = ViajeService();

  // Estado
  List<ViajeModel> _viajes = [];
  List<ViajeModel> _viajesFiltrados = [];
  ViajeModel? _viajeSeleccionado;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _estadisticas = {};

  // Getters
  List<ViajeModel> get viajes => _viajes;
  List<ViajeModel> get viajesFiltrados => _viajesFiltrados;
  ViajeModel? get viajeSeleccionado => _viajeSeleccionado;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get estadisticas => _estadisticas;

  // Getters de listas filtradas
  List<ViajeModel> get viajesProgramados => 
      _viajes.where((v) => v.estado == ViajeStatus.programado).toList();
  
  List<ViajeModel> get viajesEnCurso => 
      _viajes.where((v) => v.estado == ViajeStatus.enCurso).toList();
  
  List<ViajeModel> get viajesCompletados => 
      _viajes.where((v) => v.estado == ViajeStatus.completado).toList();
  
  List<ViajeModel> get viajesCancelados => 
      _viajes.where((v) => v.estado == ViajeStatus.cancelado).toList();

  List<ViajeModel> get viajesDisponibles => 
      _viajes.where((v) => v.hasAvailableSeats && v.estado == ViajeStatus.programado).toList();

  // Crear viaje
  Future<bool> crearViaje(ViajeModel viaje) async {
    try {
      _setLoading(true);
      _clearError();

      final nuevoViaje = await _viajeService.crearViaje(viaje);
      _viajes.insert(0, nuevoViaje);
      _actualizarViajesFiltrados();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear viaje: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cargar viajes por empresa
  Future<void> cargarViajesPorEmpresa(String empresaId) async {
    try {
      _setLoading(true);
      _clearError();

      _viajes = await _viajeService.obtenerViajesPorEmpresa(empresaId);
      _actualizarViajesFiltrados();
      
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar viajes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Cargar viaje por ID
  Future<void> cargarViajePorId(String viajeId) async {
    try {
      _setLoading(true);
      _clearError();

      final viaje = await _viajeService.obtenerViajePorId(viajeId);
      if (viaje != null) {
        _viajeSeleccionado = viaje;
        notifyListeners();
      }
    } catch (e) {
      _setError('Error al cargar viaje: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar viaje
  Future<bool> actualizarViaje(ViajeModel viaje) async {
    try {
      _setLoading(true);
      _clearError();

      final viajeActualizado = await _viajeService.actualizarViaje(viaje);
      
      // Actualizar en la lista local
      final index = _viajes.indexWhere((v) => v.id == viaje.id);
      if (index != -1) {
        _viajes[index] = viajeActualizado;
        _actualizarViajesFiltrados();
      }

      // Actualizar viaje seleccionado si es el mismo
      if (_viajeSeleccionado?.id == viaje.id) {
        _viajeSeleccionado = viajeActualizado;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar viaje: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cambiar estado del viaje
  Future<bool> cambiarEstadoViaje(String viajeId, ViajeStatus nuevoEstado, {String? motivoCancelacion}) async {
    try {
      _setLoading(true);
      _clearError();

      await _viajeService.cambiarEstadoViaje(viajeId, nuevoEstado, motivoCancelacion: motivoCancelacion);
      
      // Actualizar en la lista local
      final index = _viajes.indexWhere((v) => v.id == viajeId);
      if (index != -1) {
        _viajes[index] = _viajes[index].copyWith(
          estado: nuevoEstado,
          motivoCancelacion: motivoCancelacion,
          updatedAt: DateTime.now(),
        );
        _actualizarViajesFiltrados();
      }

      // Actualizar viaje seleccionado si es el mismo
      if (_viajeSeleccionado?.id == viajeId) {
        _viajeSeleccionado = _viajeSeleccionado!.copyWith(
          estado: nuevoEstado,
          motivoCancelacion: motivoCancelacion,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al cambiar estado del viaje: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar viaje
  Future<bool> eliminarViaje(String viajeId) async {
    try {
      _setLoading(true);
      _clearError();

      await _viajeService.eliminarViaje(viajeId);
      
      // Remover de la lista local
      _viajes.removeWhere((v) => v.id == viajeId);
      _actualizarViajesFiltrados();

      // Limpiar viaje seleccionado si es el mismo
      if (_viajeSeleccionado?.id == viajeId) {
        _viajeSeleccionado = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar viaje: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cargar viajes disponibles
  Future<void> cargarViajesDisponibles(String empresaId) async {
    try {
      _setLoading(true);
      _clearError();

      _viajes = await _viajeService.obtenerViajesDisponibles(empresaId);
      _actualizarViajesFiltrados();
      
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar viajes disponibles: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Buscar viajes
  Future<void> buscarViajes({
    required String empresaId,
    String? query,
    ViajeStatus? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      _viajes = await _viajeService.buscarViajes(
        empresaId: empresaId,
        query: query,
        estado: estado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
      _actualizarViajesFiltrados();
      
      notifyListeners();
    } catch (e) {
      _setError('Error al buscar viajes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Filtrar viajes localmente
  void filtrarViajes({
    String? query,
    ViajeStatus? estado,
  }) {
    _viajesFiltrados = _viajes.where((viaje) {
      bool matchQuery = true;
      bool matchEstado = true;

      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        matchQuery = viaje.rutaId.toLowerCase().contains(queryLower) ||
                    viaje.vehiculoId.toLowerCase().contains(queryLower) ||
                    viaje.estado.name.toLowerCase().contains(queryLower);
      }

      if (estado != null) {
        matchEstado = viaje.estado == estado;
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

      _estadisticas = await _viajeService.obtenerEstadisticasViajes(empresaId);
      
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar estadísticas: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar cupos ocupados
  Future<bool> actualizarCuposOcupados(String viajeId, int nuevosCupos) async {
    try {
      _setLoading(true);
      _clearError();

      await _viajeService.actualizarCuposOcupados(viajeId, nuevosCupos);
      
      // Actualizar en la lista local
      final index = _viajes.indexWhere((v) => v.id == viajeId);
      if (index != -1) {
        _viajes[index] = _viajes[index].copyWith(
          cuposOcupados: nuevosCupos,
          updatedAt: DateTime.now(),
        );
        _actualizarViajesFiltrados();
      }

      // Actualizar viaje seleccionado si es el mismo
      if (_viajeSeleccionado?.id == viajeId) {
        _viajeSeleccionado = _viajeSeleccionado!.copyWith(
          cuposOcupados: nuevosCupos,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar cupos: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verificar disponibilidad de cupos
  Future<bool> verificarDisponibilidadCupos(String viajeId, int cuposRequeridos) async {
    try {
      return await _viajeService.verificarDisponibilidadCupos(viajeId, cuposRequeridos);
    } catch (e) {
      _setError('Error al verificar disponibilidad: ${e.toString()}');
      return false;
    }
  }

  // Seleccionar viaje
  void seleccionarViaje(ViajeModel? viaje) {
    _viajeSeleccionado = viaje;
    notifyListeners();
  }

  // Limpiar datos
  void limpiarDatos() {
    _viajes.clear();
    _viajesFiltrados.clear();
    _viajeSeleccionado = null;
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

  void _actualizarViajesFiltrados() {
    _viajesFiltrados = List.from(_viajes);
  }

  // Validaciones
  String? validarDatosViaje(ViajeModel viaje) {
    if (viaje.rutaId.isEmpty) {
      return 'La ruta es requerida';
    }
    if (viaje.vehiculoId.isEmpty) {
      return 'El vehículo es requerido';
    }
    if (viaje.precio <= 0) {
      return 'El precio debe ser mayor a 0';
    }
    if (viaje.cuposDisponibles <= 0) {
      return 'Los cupos disponibles deben ser mayor a 0';
    }
    if (viaje.fechaSalida.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'La fecha de salida no puede ser anterior a hoy';
    }
    return null;
  }
}