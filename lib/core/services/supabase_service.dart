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
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = res.user;
    if (user != null) {
      // Ensure SQL row exists but do NOT override existing role on sign-in
      final existing = await client
          .from('users')
          .select('id, role')
          .eq('id', user.id)
          .maybeSingle();
      final metaRole = user.userMetadata?['role']?.toString();
      if (existing == null) {
        await client.from('users').insert({
          'id': user.id,
          'email': user.email ?? email,
          'password_hash': 'auth_managed',
          'role': metaRole ?? 'pasajero',
        });
      } else {
        final dbRole = (existing['role'] as String?);
        if (metaRole != null && dbRole != metaRole) {
          // Sync role from auth metadata to SQL users table when mismatched
          await client
              .from('users')
              .update({'role': metaRole})
              .eq('id', user.id);
        }
      }
    }
    return res;
  }

  Future<AuthResponse> signUp(String email, String password, String role) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role},
    );
    final user = res.user;
    if (user != null) {
      await ensureSqlUserRow(userId: user.id, email: email, role: role);
    }
    return res;
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
    final v = res['role'];
    return v == null ? null : v.toString();
  }

  // Ensure a corresponding row exists in SQL public.users
  Future<void> ensureSqlUserRow({
    required String userId,
    required String email,
    required String role,
  }) async {
    await client
        .from('users')
        .upsert({
          'id': userId,
          'email': email,
          'password_hash': 'auth_managed',
          'role': role,
        }, onConflict: 'id');
  }
}
