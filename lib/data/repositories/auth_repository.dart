import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService().client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role},
    );

    if (response.user == null) {
      throw Exception('Error al registrar usuario');
    }

    await _client.from('users').insert({
      'email': email,
      'password_hash': password, // temporal (usa hashing real más adelante)
      'role': role,
    });

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Credenciales inválidas');
    }

    return response;
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
