import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/services/supabase_service.dart';

// Definiciones de estilo
const Color _primaryColor = Color(0xFF1E88E5); // Azul principal
const Color _accentColor = Color(0xFF00C853); // Verde de acento
const Color _backgroundColor = Color(0xFFF0F4F8); // Fondo gris claro sutil
const Color _cardColor = Colors.white;

// 🚨 RECREACIÓN DE LA ESTRUCTURA DE DATOS Y PROVIDER (CONSISTENTE CON LA EDICIÓN) 🚨
// Si ya tienes estos definidos globalmente, puedes eliminar esta sección.
// Si no, déjala aquí para que el código sea runnable y consistente.
class MockUserProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? avatarUrl;
  final String memberSince; // Añadido para mostrar en el perfil

  MockUserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.avatarUrl,
    required this.memberSince,
  });
}

// SIMULACIÓN del provider que contendrá los datos del usuario logeado
final userProfileProvider = FutureProvider<MockUserProfile>((ref) async {
  // Simulación de una carga de datos de 1 segundo.
  await Future.delayed(const Duration(milliseconds: 1000));
  
  // Obtener datos del usuario autenticado de Supabase
  final user = SupabaseService().client.auth.currentUser;
  final email = user?.email ?? 'correo@ejemplo.com';
  final userId = user?.id ?? 'UID-INDEFINIDO';

  // ⚠️ Aquí iría la consulta real a Supabase para obtener el perfil:
  // final data = await SupabaseService().client.from('profiles').select().eq('id', userId).single();
  
  // Datos simulados (reemplazar con data real):
  return MockUserProfile(
    id: userId,
    name: 'Juan Sebastián', // Dato real del perfil
    phone: '310 123 4567', // Dato real del perfil
    email: email,
    avatarUrl: null, // URL real del avatar
    memberSince: '18 Nov 2023', // Fecha de creación del perfil o auth
  );
});
// 🚨 FIN DE ESTRUCTURA CONSISTENTE 🚨


class PassengerProfileScreen extends ConsumerWidget {
  const PassengerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observar el FutureProvider para obtener los datos del perfil
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      
      // 2. Usar el FutureBuilder de Riverpod (AsyncValue)
      body: profileAsync.when(
        // Estado de Carga: Muestra un indicador
        loading: () => const Center(child: CircularProgressIndicator(color: _primaryColor)),
        
        // Estado de Error: Muestra un mensaje de error
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Error al cargar el perfil: ${err.toString()}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ),
        
        // Estado de Datos: Muestra la interfaz con los datos cargados
        data: (profile) {
          final userId = profile.id.substring(0, 8); // Mostrar solo una parte del ID

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2. SECCIÓN DE ENCABEZADO Y AVATAR
                _buildHeaderAndAvatar(context, profile.name, profile.email, profile.avatarUrl),
                
                const SizedBox(height: 30),

                // 3. SECCIÓN DE DETALLES DEL PERFIL (Card)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: _cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información General',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: _primaryColor),
                        ),
                        const Divider(height: 20),
                        _buildProfileRow(context, Icons.person_outline, 'Nombre Completo', profile.name),
                        _buildProfileRow(context, Icons.phone_android, 'Teléfono', profile.phone),
                        _buildProfileRow(context, Icons.badge, 'ID de Usuario', userId),
                        _buildProfileRow(context, Icons.calendar_today, 'Miembro Desde', profile.memberSince),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),

                // 4. BOTÓN PRINCIPAL DE ACCIÓN (Editar Perfil)
                ElevatedButton.icon(
                  onPressed: () {
                    // 🔥 NAVEGACIÓN CORREGIDA A LA RUTA DE EDICIÓN
                    Navigator.pushNamed(context, '/passenger/profile/edit');
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('EDITAR PERFIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER: Encabezado y Avatar ---
  Widget _buildHeaderAndAvatar(BuildContext context, String name, String email, String? avatarUrl) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          backgroundColor: _primaryColor.withOpacity(0.1),
          child: avatarUrl == null 
              ? const Icon(Icons.person, size: 70, color: _primaryColor)
              : null,
        ),
        const SizedBox(height: 15),
        Text(
          name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.black87),
        ),
        Text(
          email,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  // --- WIDGET HELPER: Fila de detalle reutilizable para el perfil ---
  Widget _buildProfileRow(BuildContext context, IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accentColor.withOpacity(0.8), size: 24), // Usar el color de acento para los iconos de detalle
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}