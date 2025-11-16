import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/services/supabase_service.dart';

// Definiciones de estilo
const Color _primaryColor = Color(0xFF1E88E5); // Azul
const Color _accentColor = Color(0xFF00C853); // Verde
const Color _backgroundColor = Color(0xFFF0F4F8); // Gris claro

class PassengerProfileScreen extends ConsumerWidget {
  const PassengerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⚠️ NOTA: Asumiendo que el usuario ya está autenticado a través de Supabase
    final user = SupabaseService().client.auth.currentUser;
    final email = user?.email ?? 'N/A';
    final userId = user?.id.substring(0, 8) ?? 'N/A'; // Mostrar solo una parte del ID

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sección superior de la foto/icono
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Icon(Icons.person_pin, size: 80, color: _primaryColor),
            ),
            const SizedBox(height: 10),
            Text(
              '¡Bienvenido!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 30),

            // Card de Detalles del Perfil
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildProfileRow(context, Icons.email, 'Correo Electrónico', email),
                    _buildProfileRow(context, Icons.badge, 'ID de Usuario', userId),
                    _buildProfileRow(context, Icons.calendar_today, 'Miembro Desde', 'N/A (Falta Dato)'), // Dato de ejemplo
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // Botón principal de acción
            ElevatedButton.icon(
              onPressed: () {
                // Navegar a la pantalla de edición de perfil (si existe)
                // Navigator.pushNamed(context, '/passenger/profile/edit');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función de edición de perfil no implementada aún.')),
                );
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('EDITAR PERFIL', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fila de detalle reutilizable para el perfil
  Widget _buildProfileRow(BuildContext context, IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryColor.withOpacity(0.8), size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}