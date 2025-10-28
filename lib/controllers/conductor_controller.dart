import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/conductor_model.dart';
import '../services/conductor_service.dart';

class ConductorController extends ChangeNotifier {
  final ConductorService _conductorService = ConductorService();

  // Estado del controlador
  ConductorModel? _conductor;
  List<ConductorModel> _conductores = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _estadisticas;

  // Getters
  ConductorModel? get conductor => _conductor;
  List<ConductorModel> get conductores => _conductores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get estadisticas => _estadisticas;

  // Registrar nuevo conductor
  Future<bool> registrarConductor(Map<String, dynamic> conductorData) async {
    try {
      _setLoading(true);
      _clearError();

      // Validar datos antes del registro
      final validationError = _validarDatosConductor(conductorData);
      if (validationError != null) {
        _setError(validationError);
        return false;
      }

      // Verificar si la cédula ya existe
      final cedulaExiste = await _conductorService.verificarCedulaExiste(conductorData['cedula']);
      if (cedulaExiste) {
        _setError('Ya existe un conductor registrado con esta cédula');
        return false;
      }

      // Verificar si el número de licencia ya existe
      final licenciaExiste = await _conductorService.verificarLicenciaExiste(conductorData['numero_licencia']);
      if (licenciaExiste) {
        _setError('Ya existe un conductor registrado con este número de licencia');
        return false;
      }

      // Agregar timestamps
      conductorData['created_at'] = DateTime.now().toIso8601String();
      conductorData['updated_at'] = DateTime.now().toIso8601String();

      _conductor = await _conductorService.registrarConductor(conductorData);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cargar conductor por ID de usuario
  Future<void> cargarConductorPorUserId(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      _conductor = await _conductorService.obtenerConductorPorUserId(userId);
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Cargar conductor por ID
  Future<void> cargarConductorPorId(String conductorId) async {
    try {
      _setLoading(true);
      _clearError();

      _conductor = await _conductorService.obtenerConductorPorId(conductorId);
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Cargar conductores por empresa
  Future<void> cargarConductoresPorEmpresa(String empresaId) async {
    try {
      _setLoading(true);
      _clearError();

      _conductores = await _conductorService.obtenerConductoresPorEmpresa(empresaId);
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Cargar todos los conductores (para admin)
  Future<void> cargarTodosLosConductores() async {
    try {
      _setLoading(true);
      _clearError();

      _conductores = await _conductorService.obtenerTodosLosConductores();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar conductor
  Future<bool> actualizarConductor(String conductorId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      // Validar datos de actualización
      final validationError = _validarDatosActualizacion(updates);
      if (validationError != null) {
        _setError(validationError);
        return false;
      }

      _conductor = await _conductorService.actualizarConductor(conductorId, updates);
      
      // Actualizar en la lista si existe
      final index = _conductores.indexWhere((c) => c.id == conductorId);
      if (index != -1) {
        _conductores[index] = _conductor!;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cambiar estado del conductor
  Future<bool> cambiarEstadoConductor(String conductorId, ConductorStatus nuevoEstado) async {
    try {
      _setLoading(true);
      _clearError();

      await _conductorService.cambiarEstadoConductor(conductorId, nuevoEstado);
      
      // Actualizar el conductor actual si es el mismo
      if (_conductor?.id == conductorId) {
        _conductor = _conductor!.copyWith(estado: nuevoEstado);
      }

      // Actualizar en la lista
      final index = _conductores.indexWhere((c) => c.id == conductorId);
      if (index != -1) {
        _conductores[index] = _conductores[index].copyWith(estado: nuevoEstado);
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

  // Vincular conductor a empresa
  Future<bool> vincularConductorAEmpresa(String conductorId, String empresaId) async {
    try {
      _setLoading(true);
      _clearError();

      await _conductorService.vincularConductorAEmpresa(conductorId, empresaId);
      
      // Recargar el conductor para obtener los datos actualizados
      await cargarConductorPorId(conductorId);
      
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Desvincular conductor de empresa
  Future<bool> desvincularConductorDeEmpresa(String conductorId) async {
    try {
      _setLoading(true);
      _clearError();

      await _conductorService.desvincularConductorDeEmpresa(conductorId);
      
      // Recargar el conductor para obtener los datos actualizados
      await cargarConductorPorId(conductorId);
      
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Subir documento
  Future<String?> subirDocumento(String conductorId, String tipoDocumento, Uint8List archivoBytes, String nombreArchivo) async {
    try {
      _setLoading(true);
      _clearError();

      final url = await _conductorService.subirDocumento(conductorId, tipoDocumento, archivoBytes, nombreArchivo);
      
      // Recargar el conductor para obtener la URL actualizada
      await cargarConductorPorId(conductorId);
      
      return url;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar documento
  Future<bool> eliminarDocumento(String conductorId, String tipoDocumento, String documentoUrl) async {
    try {
      _setLoading(true);
      _clearError();

      await _conductorService.eliminarDocumento(conductorId, tipoDocumento, documentoUrl);
      
      // Recargar el conductor para obtener los datos actualizados
      await cargarConductorPorId(conductorId);
      
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cargar estadísticas
  Future<void> cargarEstadisticas({String? empresaId}) async {
    try {
      _setLoading(true);
      _clearError();

      _estadisticas = await _conductorService.obtenerEstadisticasConductores(empresaId: empresaId);
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Buscar conductores
  Future<void> buscarConductores(String termino, {String? empresaId}) async {
    try {
      _setLoading(true);
      _clearError();

      _conductores = await _conductorService.buscarConductores(termino, empresaId: empresaId);
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Obtener conductores disponibles
  Future<void> cargarConductoresDisponibles({String? empresaId}) async {
    try {
      _setLoading(true);
      _clearError();

      _conductores = await _conductorService.obtenerConductoresDisponibles(empresaId: empresaId);
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar calificación
  Future<bool> actualizarCalificacion(String conductorId, double calificacion) async {
    try {
      _setLoading(true);
      _clearError();

      await _conductorService.actualizarCalificacion(conductorId, calificacion);
      
      // Recargar el conductor para obtener los datos actualizados
      await cargarConductorPorId(conductorId);
      
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Limpiar datos
  void limpiarDatos() {
    _conductor = null;
    _conductores = [];
    _estadisticas = null;
    _clearError();
    notifyListeners();
  }

  // Limpiar error
  void limpiarError() {
    _clearError();
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('duplicate key')) {
      return 'Ya existe un conductor con estos datos';
    } else if (error.toString().contains('foreign key')) {
      return 'Error de referencia en los datos';
    } else if (error.toString().contains('not found')) {
      return 'Conductor no encontrado';
    } else if (error.toString().contains('network')) {
      return 'Error de conexión. Verifique su internet';
    } else {
      return 'Error inesperado: ${error.toString()}';
    }
  }

  String? _validarDatosConductor(Map<String, dynamic> datos) {
    if (datos['nombres'] == null || datos['nombres'].toString().trim().isEmpty) {
      return 'Los nombres son requeridos';
    }

    if (datos['apellidos'] == null || datos['apellidos'].toString().trim().isEmpty) {
      return 'Los apellidos son requeridos';
    }

    if (datos['cedula'] == null || datos['cedula'].toString().trim().isEmpty) {
      return 'La cédula es requerida';
    }

    if (datos['numero_licencia'] == null || datos['numero_licencia'].toString().trim().isEmpty) {
      return 'El número de licencia es requerido';
    }

    if (datos['categoria_licencia'] == null || datos['categoria_licencia'].toString().trim().isEmpty) {
      return 'La categoría de licencia es requerida';
    }

    if (datos['fecha_vencimiento_licencia'] == null) {
      return 'La fecha de vencimiento de licencia es requerida';
    }

    if (datos['telefono'] == null || datos['telefono'].toString().trim().isEmpty) {
      return 'El teléfono es requerido';
    }

    if (datos['email'] == null || datos['email'].toString().trim().isEmpty) {
      return 'El email es requerido';
    }

    // Validar formato de email
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(datos['email'])) {
      return 'El formato del email no es válido';
    }

    return null;
  }

  String? _validarDatosActualizacion(Map<String, dynamic> datos) {
    // Validaciones básicas para actualización
    if (datos.containsKey('email') && datos['email'] != null) {
      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
      if (!emailRegex.hasMatch(datos['email'])) {
        return 'El formato del email no es válido';
      }
    }

    return null;
  }
}