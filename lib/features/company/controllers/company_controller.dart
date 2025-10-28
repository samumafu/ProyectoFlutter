import 'package:flutter/material.dart';
import '../../../data/models/company_model.dart';
import '../../../services/company_service.dart';

class CompanyController extends ChangeNotifier {
  Company? _currentCompany;
  List<CompanySchedule> _schedules = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Company? get currentCompany => _currentCompany;
  List<CompanySchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => CompanyService.isLoggedIn();

  // Autenticación
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await CompanyService.signInCompany(email, password);
      
      if (result['success']) {
        _currentCompany = result['company'];
        await loadSchedules();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String nit,
    String description = '',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await CompanyService.registerCompany(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
        nit: nit,
        description: description,
      );

      if (result['success']) {
        _currentCompany = result['company'];
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await CompanyService.signOut();
    _currentCompany = null;
    _schedules = [];
    _clearError();
    notifyListeners();
  }

  // Gestión de empresa
  Future<bool> updateCompany({
    String? name,
    String? phone,
    String? address,
    String? description,
    String? logoUrl,
  }) async {
    if (_currentCompany == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final updatedCompany = _currentCompany!.copyWith(
        name: name ?? _currentCompany!.name,
        phone: phone ?? _currentCompany!.phone,
        address: address ?? _currentCompany!.address,
        description: description ?? _currentCompany!.description,
        logoUrl: logoUrl ?? _currentCompany!.logoUrl,
      );

      final result = await CompanyService.updateCompany(updatedCompany);
      
      if (result != null) {
        _currentCompany = result;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Error al actualizar la empresa');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Gestión de horarios
  Future<void> loadSchedules() async {
    if (_currentCompany == null) return;

    _setLoading(true);
    _clearError();

    try {
      _schedules = await CompanyService.getCompanySchedules(_currentCompany!.id);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar horarios: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<bool> createSchedule({
    required String origin,
    required String destination,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required double price,
    required int totalSeats,
    required String vehicleType,
    required String vehicleId,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentCompany == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final schedule = CompanySchedule(
        id: '', // Se generará en el servidor
        companyId: _currentCompany!.id,
        origin: origin,
        destination: destination,
        departureTime: departureTime,
        arrivalTime: arrivalTime,
        price: price,
        availableSeats: totalSeats,
        totalSeats: totalSeats,
        vehicleType: vehicleType,
        vehicleId: vehicleId,
        additionalInfo: additionalInfo ?? {},
      );

      final result = await CompanyService.createSchedule(schedule);
      
      if (result != null) {
        _schedules.add(result);
        _schedules.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Error al crear el horario');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateSchedule(CompanySchedule schedule) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await CompanyService.updateSchedule(schedule);
      
      if (result != null) {
        final index = _schedules.indexWhere((s) => s.id == schedule.id);
        if (index != -1) {
          _schedules[index] = result;
          _schedules.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        }
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Error al actualizar el horario');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await CompanyService.deleteSchedule(scheduleId);
      
      if (success) {
        _schedules.removeWhere((s) => s.id == scheduleId);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Error al eliminar el horario');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Métodos de utilidad
  List<CompanySchedule> getSchedulesByRoute(String origin, String destination) {
    return _schedules
        .where((s) => s.origin == origin && s.destination == destination && s.isActive)
        .toList();
  }

  List<CompanySchedule> getSchedulesByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _schedules
        .where((s) => 
            s.departureTime.isAfter(startOfDay) && 
            s.departureTime.isBefore(endOfDay) &&
            s.isActive)
        .toList();
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

  @override
  void dispose() {
    super.dispose();
  }
}