import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://iemghgzismoncmirtkyy.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImllbWdoZ3ppc21vbmNtaXJ0a3l5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MjA3MjQsImV4cCI6MjA3Njk5NjcyNH0.6UjRSM3NxM3IEvMwWsAVOQhGkVO2qBR672LW_S1gzA8';

  Future<void> init() async {
    print('🔧🔧🔧 Inicializando Supabase...');
    print('🔧🔧🔧 URL: $supabaseUrl');
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    print('🔧🔧🔧 ✅ Supabase inicializado correctamente');
    
    // TEST DE CONEXIÓN INMEDIATO
    try {
      print('🔧🔧🔧 Probando conexión...');
      final response = await client
          .from('company_schedules')
          .select('id')
          .limit(1);
      
      print('🔧🔧🔧 ✅ Conexión exitosa - respuesta: ${response.length} registros');
    } catch (e) {
      print('🔧🔧🔧 ❌ Error de conexión: $e');
    }
  }

  SupabaseClient get client => Supabase.instance.client;

  bool get isLoggedIn => client.auth.currentUser != null;

  User? get currentUser => client.auth.currentUser;

  Future<void> signOut() async {
    await client.auth.signOut();
  }
}
