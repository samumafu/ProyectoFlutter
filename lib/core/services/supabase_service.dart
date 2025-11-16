import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Riverpod provider for SupabaseClient
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class SupabaseService {
  // ========================================
  // Supabase Credentials
  // ========================================
  static const String supabaseUrl = 'https://iemghgzismoncmirtkyy.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImllbWdoZ3ppc21vbmNtaXJ0a3l5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MjA3MjQsImV4cCI6MjA3Njk5NjcyNH0.6UjRSM3NxM3IEvMwWsAVOQhGkVO2qBR672LW_S1gzA8';

  // ========================================
  // Initialize Supabase
  // ========================================
  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // ========================================
  // Client instance (use everywhere)
  // ========================================
  final SupabaseClient client = Supabase.instance.client;

  // ========================================
  // Auth helpers
  // ========================================
  bool get isLoggedIn => client.auth.currentUser != null;

  User? get currentUser => client.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password, String role) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role},
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Fetch user role from SQL users table (source of truth)
  Future<String?> fetchUserRoleById(String userId) async {
    final res = await client
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    if (res == null) return null;
    return res['role'] as String?;
  }
}
