import 'dart:io';
import 'package:flutter/material.dart';
import '../models/vehiculo_model.dart';
import '../services/vehiculo_service.dart';

class VehiculoController extends ChangeNotifier {
  final VehiculoService _vehiculoService = VehiculoService();

  // Estado
  List<VehiculoModel> _vehiculos = [];
  List<VehiculoModel> _vehiculosFiltrados = [];
  VehiculoModel? _vehiculoSeleccionado;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _estadisticas;

  // Getters
  List<VehiculoModel> get vehiculos => _vehiculos;
  List<VehiculoModel> get vehiculosFiltrados => _vehiculosFiltrados.isEmpty ? _vehiculos : _vehiculosFiltrados;
  VehiculoModel? get vehiculoSeleccionado => _vehiculoSeleccionado;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get estadisticas => _estadisticas;

  List<VehiculoModel> get vehiculosActivos =>
      _vehiculos.where((v) => v.estado == VehiculoStatus.activo).toList();

  List<VehiculoModel> get vehiculosDisponibles =>
      _vehiculos.where((v) => v.isActive).toList();

  List<VehiculoModel> get vehiculosEnMantenimiento =>
      _vehiculos.where((v) => v.estado == VehiculoStatus.mantenimiento).toList();

  // Registrar nuevo vehículo
  Future<bool> registrarVehiculo(VehiculoModel vehiculo) async {
    try {
      _setLoading(true);
      _limpiarError();

      // Validar datos
      final validationError = _validarDatosVehiculo(vehiculo);
      if (validationError != null) {
        _setError(validationError);
        return false;
      }

      // Verificar si la placa ya existe
      final placaExiste = await _vehiculoService.verificarPlacaExiste(vehiculo.placa);
      if (placaExiste) {
        _setError('Ya existe un vehículo con esta placa');
        return false;
      }

      final nuevoVehiculo = await _vehiculoService.registrarVehiculo(vehiculo);
      _vehiculos.insert(0, nuevoVehiculo);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cargar vehículos por empresa
  Future<void> cargarVehiculosPorEmpresa(String empresaId) async {
    try {
      _setLoading(true);
      _limpiarError();

      _vehiculos = await _vehiculoService.obtenerVehiculosPorEmpresa(empresaId);
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Cargar vehículo por ID
  Future<void> cargarVehiculoPorId(String id) async {
    try {
      _setLoading(true);
      _limpiarError();

      _vehiculoSeleccionado = await _vehiculoService.obtenerVehiculoPorId(id);
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar vehículo
  Future<bool> actualizarVehiculo(VehiculoModel vehiculo) async {
    try {
      _setLoading(true);
      _limpiarError();

      // Validar datos
      final validationError = _validarDatosVehiculo(vehiculo);
      if (validationError != null) {
        _setError(validationError);
        return false;
      }

      // Verificar si la placa ya existe (excluyendo el vehículo actual)
      final placaExiste = await _vehiculoService.verificarPlacaExiste(
        vehiculo.placa,
        excludeId: vehiculo.id,
      );
      if (placaExiste) {
        _setError('Ya existe otro vehículo con esta placa');
        return false;
      }

      final vehiculoActualizado = await _vehiculoService.actualizarVehiculo(vehiculo);
      
      // Actualizar en la lista local
      final index = _vehiculos.indexWhere((v) => v.id == vehiculo.id);
      if (index != -1) {
        _vehiculos[index] = vehiculoActualizado;
      }

      // Actualizar vehículo seleccionado si es el mismo
      if (_vehiculoSeleccionado?.id == vehiculo.id) {
        _vehiculoSeleccionado = vehiculoActualizado;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cambiar estado del vehículo
  Future<bool> cambiarEstadoVehiculo(String id, VehiculoStatus nuevoEstado) async {
    try {
      _setLoading(true);
      _limpiarError();

      await _vehiculoService.cambiarEstadoVehiculo(id, nuevoEstado);

      // Actualizar en la lista local
      final index = _vehiculos.indexWhere((v) => v.id == id);
      if (index != -1) {
        _vehiculos[index] = _vehiculos[index].copyWith(
          estado: nuevoEstado,
          updatedAt: DateTime.now(),
        );
      }

      // Actualizar vehículo seleccionado si es el mismo
      if (_vehiculoSeleccionado?.id == id) {
        _vehiculoSeleccionado = _vehiculoSeleccionado!.copyWith(
          estado: nuevoEstado,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar vehículo
  Future<bool> eliminarVehiculo(String id) async {
    try {
      _setLoading(true);
      _limpiarError();

      await _vehiculoService.eliminarVehiculo(id);

      // Remover de la lista local
      _vehiculos.removeWhere((v) => v.id == id);

      // Limpiar vehículo seleccionado si es el mismo
      if (_vehiculoSeleccionado?.id == id) {
        _vehiculoSeleccionado = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Subir documento
  Future<bool> subirDocumento(
    String vehiculoId,
    String tipoDocumento,
    File file,
  ) async {
    try {
      _setLoading(true);
      _limpiarError();

      final url = await _vehiculoService.subirDocumento(vehiculoId, tipoDocumento, file);

      // Actualizar el vehículo con la nueva URL del documento
      final vehiculo = _vehiculos.firstWhere((v) => v.id == vehiculoId);
      VehiculoModel vehiculoActualizado;

      switch (tipoDocumento.toLowerCase()) {
        case 'soat':
          vehiculoActualizado = vehiculo.copyWith(soatUrl: url);
          break;
        case 'revision_tecnica':
          vehiculoActualizado = vehiculo.copyWith(revisionTecnicaUrl: url);
          break;
        case 'tarjeta_operacion':
          vehiculoActualizado = vehiculo.copyWith(tarjetaOperacionUrl: url);
          break;
        case 'poliza':
          vehiculoActualizado = vehiculo.copyWith(polizaUrl: url);
          break;
        default:
          throw Exception('Tipo de documento no válido');
      }

      await actualizarVehiculo(vehiculoActualizado);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar documento
  Future<bool> eliminarDocumento(String vehiculoId, String tipoDocumento) async {
    try {
      _setLoading(true);
      _limpiarError();

      final vehiculo = _vehiculos.firstWhere((v) => v.id == vehiculoId);
      String? urlToDelete;
      VehiculoModel vehiculoActualizado;

      switch (tipoDocumento.toLowerCase()) {
        case 'soat':
          urlToDelete = vehiculo.soatUrl;
          vehiculoActualizado = vehiculo.copyWith(soatUrl: null);
          break;
        case 'revision_tecnica':
          urlToDelete = vehiculo.revisionTecnicaUrl;
          vehiculoActualizado = vehiculo.copyWith(revisionTecnicaUrl: null);
          break;
        case 'tarjeta_operacion':
          urlToDelete = vehiculo.tarjetaOperacionUrl;
          vehiculoActualizado = vehiculo.copyWith(tarjetaOperacionUrl: null);
          break;
        case 'poliza':
          urlToDelete = vehiculo.polizaUrl;
          vehiculoActualizado = vehiculo.copyWith(polizaUrl: null);
          break;
        default:
          throw Exception('Tipo de documento no válido');
      }

      if (urlToDelete != null) {
        await _vehiculoService.eliminarDocumento(urlToDelete);
      }

      await actualizarVehiculo(vehiculoActualizado);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cargar estadísticas
  Future<void> cargarEstadisticas(String empresaId) async {
    try {
      _setLoading(true);
      _limpiarError();

      _estadisticas = await _vehiculoService.obtenerEstadisticasVehiculos(empresaId);
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Buscar vehículos
  Future<void> buscarVehiculos(String empresaId, String query) async {
    try {
      _setLoading(true);
      _limpiarError();

      if (query.isEmpty) {
        await cargarVehiculosPorEmpresa(empresaId);
      } else {
        _vehiculos = await _vehiculoService.buscarVehiculos(empresaId, query);
        notifyListeners();
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Filtrar por estado
  Future<void> filtrarPorEstado(String empresaId, VehiculoStatus estado) async {
    try {
      _setLoading(true);
      _limpiarError();

      _vehiculos = await _vehiculoService.obtenerVehiculosPorEstado(empresaId, estado);
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Filtrar por tipo
  Future<void> filtrarPorTipo(String empresaId, TipoVehiculo tipo) async {
    try {
      _setLoading(true);
      _limpiarError();

      _vehiculos = await _vehiculoService.obtenerVehiculosPorTipo(empresaId, tipo);
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Obtener vehículos con documentos próximos a vencer
  Future<void> cargarVehiculosConDocumentosProximosAVencer(
    String empresaId, {
    int diasAnticipacion = 30,
  }) async {
    try {
      _setLoading(true);
      _limpiarError();

      _vehiculos = await _vehiculoService.obtenerVehiculosConDocumentosProximosAVencer(
        empresaId,
        diasAnticipacion: diasAnticipacion,
      );
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Seleccionar vehículo
  void seleccionarVehiculo(VehiculoModel? vehiculo) {
    _vehiculoSeleccionado = vehiculo;
    notifyListeners();
  }

  // Limpiar datos
  void limpiarDatos() {
    _vehiculos.clear();
    _vehiculosFiltrados.clear();
    _vehiculoSeleccionado = null;
    _estadisticas = null;
    _limpiarError();
    notifyListeners();
  }

  // Filtrar vehículos localmente
  void filtrarVehiculos({
    String? query,
    VehiculoStatus? estado,
    TipoVehiculo? tipo,
  }) {
    List<VehiculoModel> vehiculosFiltrados = List.from(_vehiculos);

    // Filtrar por query (placa, marca, modelo)
    if (query != null && query.isNotEmpty) {
      vehiculosFiltrados = vehiculosFiltrados.where((vehiculo) {
        final queryLower = query.toLowerCase();
        return vehiculo.placa.toLowerCase().contains(queryLower) ||
               vehiculo.marca.toLowerCase().contains(queryLower) ||
               vehiculo.modelo.toLowerCase().contains(queryLower);
      }).toList();
    }

    // Filtrar por estado
    if (estado != null) {
      vehiculosFiltrados = vehiculosFiltrados.where((vehiculo) => vehiculo.estado == estado).toList();
    }

    // Filtrar por tipo
    if (tipo != null) {
      vehiculosFiltrados = vehiculosFiltrados.where((vehiculo) => vehiculo.tipo == tipo).toList();
    }

    _vehiculosFiltrados = vehiculosFiltrados;
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

  void _limpiarError() {
    _error = null;
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('duplicate key')) {
      return 'Ya existe un vehículo con estos datos';
    } else if (error.toString().contains('foreign key')) {
      return 'Error de referencia en los datos';
    } else if (error.toString().contains('not found')) {
      return 'Vehículo no encontrado';
    } else if (error.toString().contains('network')) {
      return 'Error de conexión. Verifica tu internet';
    } else {
      return 'Error inesperado: ${error.toString()}';
    }
  }

  String? _validarDatosVehiculo(VehiculoModel vehiculo) {
    if (vehiculo.placa.isEmpty) {
      return 'La placa es obligatoria';
    }
    if (vehiculo.placa.length < 6) {
      return 'La placa debe tener al menos 6 caracteres';
    }
    if (vehiculo.marca.isEmpty) {
      return 'La marca es obligatoria';
    }
    if (vehiculo.modelo.isEmpty) {
      return 'El modelo es obligatorio';
    }
    if (vehiculo.anio < 1900 || vehiculo.anio > DateTime.now().year + 1) {
      return 'El año no es válido';
    }
    if (vehiculo.capacidadPasajeros <= 0) {
      return 'La capacidad de pasajeros debe ser mayor a 0';
    }
    if (vehiculo.numeroInterno.isEmpty) {
      return 'El número interno es obligatorio';
    }

    return null;
  }
}