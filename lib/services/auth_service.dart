import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/simple_user_model.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener usuario actual
  static User? get currentUser => _supabase.auth.currentUser;
  
  // Stream de cambios de autenticación
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Registrar usuario con rol
  static Future<AuthResponse> signUpWithRole({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Crear perfil de usuario en la tabla users
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'role': role.name,
          'password_hash': 'supabase_managed', // Supabase maneja las contraseñas
        });
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Iniciar sesión
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Obtener perfil completo del usuario actual
  static Future<SimpleUserModel?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response != null ? SimpleUserModel.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  // Verificar si el usuario tiene un rol específico
  static Future<bool> hasRole(UserRole role) async {
    try {
      final userProfile = await getCurrentUserProfile();
      return userProfile?.role == role;
    } catch (e) {
      return false;
    }
  }

  // Verificar si es empresa
  static Future<bool> isEmpresa() async {
    return await hasRole(UserRole.empresa);
  }

  // Verificar si es conductor
  static Future<bool> isConductor() async {
    return await hasRole(UserRole.conductor);
  }

  // Verificar si es usuario regular
  static Future<bool> isUsuario() async {
    return await hasRole(UserRole.pasajero);
  }

  // Verificar si es admin
  static Future<bool> isAdmin() async {
    return await hasRole(UserRole.admin);
  }

  // Actualizar perfil de usuario
  static Future<void> updateUserProfile({
    String? nombres,
    String? apellidos,
    String? telefono,
    DateTime? fechaNacimiento,
    String? direccion,
    String? municipio,
    String? fotoPerfilUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final updateData = <String, dynamic>{};
      
      if (nombres != null) updateData['nombres'] = nombres;
      if (apellidos != null) updateData['apellidos'] = apellidos;
      if (telefono != null) updateData['telefono'] = telefono;
      if (fechaNacimiento != null) {
        updateData['fecha_nacimiento'] = fechaNacimiento.toIso8601String().split('T')[0];
      }
      if (direccion != null) updateData['direccion'] = direccion;
      if (municipio != null) updateData['municipio'] = municipio;
      if (fotoPerfilUrl != null) updateData['foto_perfil_url'] = fotoPerfilUrl;
      
      if (updateData.isNotEmpty) {
        updateData['updated_at'] = DateTime.now().toIso8601String();
        
        await _supabase
            .from('usuarios')
            .update(updateData)
            .eq('id', user.id);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Cambiar contraseña
  static Future<void> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Enviar email de recuperación de contraseña
  static Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Verificar email
  static Future<void> verifyEmail() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Marcar email como verificado en la base de datos
      await _supabase
          .from('usuarios')
          .update({
            'email_verificado': true,
          })
          .eq('id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  // Verificar teléfono
  static Future<void> verifyPhone() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Marcar teléfono como verificado en la base de datos
      await _supabase
          .from('usuarios')
          .update({
            'telefono_verificado': true,
          })
          .eq('id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  // Obtener información de empresa si el usuario es empresa
  static Future<Map<String, dynamic>?> getEmpresaInfo() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final isEmp = await isEmpresa();
      if (!isEmp) return null;

      final response = await _supabase
          .from('empresas_transportadoras')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Obtener información de conductor si el usuario es conductor
  static Future<Map<String, dynamic>?> getConductorInfo() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final isCond = await isConductor();
      if (!isCond) return null;

      final response = await _supabase
          .from('conductores')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
}