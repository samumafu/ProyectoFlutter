import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/empresa_model.dart';
import '../services/empresa_service.dart';

class EmpresaController extends ChangeNotifier {
  // Estado de la empresa
  EmpresaModel? _empresa;
  List<EmpresaModel> _empresas = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _estadisticas;

  // Getters
  EmpresaModel? get empresa => _empresa;
  List<EmpresaModel> get empresas => _empresas;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get estadisticas => _estadisticas;

  // Registrar nueva empresa
  Future<bool> registrarEmpresa({
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
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      // Verificar si el NIT ya existe
      final nitExiste = await EmpresaService.verificarNitExiste(nit);
      if (nitExiste) {
        _errorMessage = 'El NIT ya está registrado en el sistema';
        return false;
      }

      _empresa = await EmpresaService.registrarEmpresa(
        userId: userId,
        razonSocial: razonSocial,
        nit: nit,
        representanteLegal: representanteLegal,
        cedulaRepresentante: cedulaRepresentante,
        telefono: telefono,
        email: email,
        direccion: direccion,
        municipio: municipio,
        sitioWeb: sitioWeb,
        logoUrl: logoUrl,
      );

      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar empresa por user ID
  Future<void> cargarEmpresaPorUserId(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      _empresa = await EmpresaService.obtenerEmpresaPorUserId(userId);
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar empresa por ID
  Future<void> cargarEmpresaPorId(String empresaId) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      _empresa = await EmpresaService.obtenerEmpresaPorId(empresaId);
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar información de empresa
  Future<bool> actualizarEmpresa({
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
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      _empresa = await EmpresaService.actualizarEmpresa(
        empresaId: empresaId,
        razonSocial: razonSocial,
        representanteLegal: representanteLegal,
        cedulaRepresentante: cedulaRepresentante,
        telefono: telefono,
        email: email,
        direccion: direccion,
        municipio: municipio,
        sitioWeb: sitioWeb,
        logoUrl: logoUrl,
        resolucionHabilitacionUrl: resolucionHabilitacionUrl,
        rntUrl: rntUrl,
        camaraComercioUrl: camaraComercioUrl,
        rutUrl: rutUrl,
        polizaUrl: polizaUrl,
      );

      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cambiar estado de empresa
  Future<bool> cambiarEstadoEmpresa(String empresaId, EmpresaStatus nuevoEstado) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      await EmpresaService.cambiarEstadoEmpresa(empresaId, nuevoEstado);
      
      // Actualizar el estado local si es la empresa actual
      if (_empresa?.id == empresaId) {
        _empresa = _empresa!.copyWith(estado: nuevoEstado);
      }

      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar todas las empresas (para admin)
  Future<void> cargarTodasLasEmpresas({
    EmpresaStatus? filtroEstado,
    int? limite,
    int? offset,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      _empresas = await EmpresaService.obtenerTodasLasEmpresas(
        filtroEstado: filtroEstado,
        limite: limite,
        offset: offset,
      );
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subir documento
  Future<String?> subirDocumento({
    required String empresaId,
    required String tipoDocumento,
    required Uint8List archivoBytes,
    required String nombreArchivo,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final documentoUrl = await EmpresaService.subirDocumento(
        empresaId: empresaId,
        tipoDocumento: tipoDocumento,
        archivoBytes: archivoBytes,
        nombreArchivo: nombreArchivo,
      );

      return documentoUrl;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Eliminar documento
  Future<bool> eliminarDocumento(String documentoUrl) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      await EmpresaService.eliminarDocumento(documentoUrl);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar estadísticas de empresa
  Future<void> cargarEstadisticas(String empresaId) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      _estadisticas = await EmpresaService.obtenerEstadisticasEmpresa(empresaId);
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verificar si NIT existe
  Future<bool> verificarNitExiste(String nit, {String? excludeEmpresaId}) async {
    try {
      return await EmpresaService.verificarNitExiste(nit, excludeEmpresaId: excludeEmpresaId);
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    }
  }

  // Limpiar datos
  void limpiarDatos() {
    _empresa = null;
    _empresas = [];
    _estadisticas = null;
    _errorMessage = '';
    notifyListeners();
  }

  // Limpiar mensaje de error
  void limpiarError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Obtener mensaje de error legible
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('duplicate key value violates unique constraint')) {
      if (errorString.contains('nit')) {
        return 'El NIT ya está registrado en el sistema';
      }
      return 'Ya existe un registro con estos datos';
    }
    
    if (errorString.contains('violates foreign key constraint')) {
      return 'Error de referencia en los datos';
    }
    
    if (errorString.contains('permission denied')) {
      return 'No tienes permisos para realizar esta acción';
    }
    
    if (errorString.contains('network')) {
      return 'Error de conexión. Verifica tu internet';
    }
    
    return 'Error: ${error.toString()}';
  }

  // Validar datos de empresa
  Map<String, String?> validarDatosEmpresa({
    required String razonSocial,
    required String nit,
    required String representanteLegal,
    required String cedulaRepresentante,
    required String telefono,
    required String email,
    required String direccion,
    required String municipio,
  }) {
    final errores = <String, String?>{};

    if (razonSocial.trim().isEmpty) {
      errores['razonSocial'] = 'La razón social es requerida';
    }

    if (nit.trim().isEmpty) {
      errores['nit'] = 'El NIT es requerido';
    } else if (!RegExp(r'^\d{9,15}$').hasMatch(nit.replaceAll(RegExp(r'[^0-9]'), ''))) {
      errores['nit'] = 'El NIT debe tener entre 9 y 15 dígitos';
    }

    if (representanteLegal.trim().isEmpty) {
      errores['representanteLegal'] = 'El representante legal es requerido';
    }

    if (cedulaRepresentante.trim().isEmpty) {
      errores['cedulaRepresentante'] = 'La cédula del representante es requerida';
    } else if (!RegExp(r'^\d{6,12}$').hasMatch(cedulaRepresentante.replaceAll(RegExp(r'[^0-9]'), ''))) {
      errores['cedulaRepresentante'] = 'La cédula debe tener entre 6 y 12 dígitos';
    }

    if (telefono.trim().isEmpty) {
      errores['telefono'] = 'El teléfono es requerido';
    } else if (!RegExp(r'^\+?[\d\s\-\(\)]{7,15}$').hasMatch(telefono)) {
      errores['telefono'] = 'El teléfono no tiene un formato válido';
    }

    if (email.trim().isEmpty) {
      errores['email'] = 'El email es requerido';
    } else if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
      errores['email'] = 'El email no tiene un formato válido';
    }

    if (direccion.trim().isEmpty) {
      errores['direccion'] = 'La dirección es requerida';
    }

    if (municipio.trim().isEmpty) {
      errores['municipio'] = 'El municipio es requerido';
    }

    return errores;
  }
}