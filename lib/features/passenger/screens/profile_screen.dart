import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/screens/login_screen.dart';

class PassengerProfileScreen extends StatelessWidget {
  const PassengerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = SupabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Pasajero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Bienvenido, pasajero 🧳',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
