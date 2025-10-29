import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/simple_user_model.dart';

class AuthController extends ChangeNotifier {
  // Estado de autenticación
  User? _user;
  SimpleUserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  SimpleUserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Getters de roles
  bool get isEmpresa => _userProfile?.isEmpresa ?? false;
  bool get isConductor => _userProfile?.isConductor ?? false;
  bool get isUsuario => _userProfile?.isUsuario ?? false;
  bool get isAdmin => _userProfile?.isAdmin ?? false;

  AuthController() {
    _initializeAuth();
  }

  // Inicializar autenticación
  void _initializeAuth() {
    // Obtener usuario actual
    _user = AuthService.currentUser;
    
    // Escuchar cambios de autenticación
    AuthService.authStateChanges.listen((AuthState data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });

    // Cargar perfil si hay usuario autenticado
    if (_user != null) {
      _loadUserProfile();
    }
  }

  // Cargar perfil del usuario
  Future<void> _loadUserProfile() async {
    try {
      final profile = await AuthService.getCurrentUserProfile();
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar perfil: $e';
      notifyListeners();
    }
  }

  // Registro de usuario
  Future<bool> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final response = await AuthService.signUpWithRole(
        email: email,
        password: password,
        role: role,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadUserProfile();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Iniciar sesión
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final response = await AuthService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await AuthService.signOut();
      _userProfile = null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar perfil
  Future<bool> updateProfile({
    String? nombres,
    String? apellidos,
    String? telefono,
    DateTime? fechaNacimiento,
    String? direccion,
    String? municipio,
    String? fotoPerfilUrl,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      await AuthService.updateUserProfile(
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
        fechaNacimiento: fechaNacimiento,
        direccion: direccion,
        municipio: municipio,
        fotoPerfilUrl: fotoPerfilUrl,
      );

      await _loadUserProfile();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cambiar contraseña
  Future<bool> changePassword(String newPassword) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      await AuthService.changePassword(newPassword);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Recuperar contraseña
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      await AuthService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verificar email
  Future<bool> verifyEmail() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await AuthService.verifyEmail();
      await _loadUserProfile();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verificar teléfono
  Future<bool> verifyPhone() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await AuthService.verifyPhone();
      await _loadUserProfile();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
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

  // Obtener mensaje de error legible
  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Credenciales de acceso inválidas';
        case 'Email not confirmed':
          return 'Email no confirmado';
        case 'User already registered':
          return 'El usuario ya está registrado';
        case 'Password should be at least 6 characters':
          return 'La contraseña debe tener al menos 6 caracteres';
        default:
          return error.message;
      }
    }
    return error.toString();
  }

  // Obtener ruta según el rol del usuario
  String getRouteByRole() {
    if (!isAuthenticated || userProfile == null) {
      return '/login';
    }

    switch (userProfile!.role) {
      case UserRole.pasajero:
        return '/passenger-home';
      case UserRole.conductor:
        return '/driver-home';
      case UserRole.empresa:
        return '/company-dashboard';
      case UserRole.admin:
        return '/admin-dashboard';
      default:
        return '/login';
    }
  }
}