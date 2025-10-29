import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../features/auth/screens/login_screen.dart';
import 'booking_history_screen.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  int _selectedIndex = 0;
  final supabase = SupabaseService();

  final List<Widget> _pages = const [
    _SearchTripsScreen(),
    BookingHistoryScreen(),
    _FavoritesScreen(),
    _ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _logout(BuildContext context) async {
    await supabase.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ['Buscar', 'Historial', 'Frecuentes', 'Perfil'][_selectedIndex],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0.5,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        indicatorColor: Colors.indigo.shade100,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: Colors.indigo),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: Colors.indigo),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.star),
            selectedIcon: Icon(Icons.star, color: Colors.indigo),
            label: 'Frecuentes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            selectedIcon: Icon(Icons.person, color: Colors.indigo),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// -------------------- PANTALLAS TEMPORALES --------------------

class _SearchTripsScreen extends StatelessWidget {
  const _SearchTripsScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Buscar viajes',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Historial de viajes',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _FavoritesScreen extends StatelessWidget {
  const _FavoritesScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Viajes frecuentes',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService().currentUser;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.person, size: 90, color: Colors.indigo)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user?.email ?? 'Sin correo',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await SupabaseService().signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile-settings');
              },
              icon: const Icon(Icons.settings, color: Colors.indigo),
              label: const Text('Ajustes de perfil'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Opciones del perfil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.indigo),
              title: const Text('Historial de viajes'),
              subtitle: const Text('Consulta tus reservas y viajes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.indigo),
              title: const Text('Métodos de pago'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.indigo),
              title: const Text('Ayuda y soporte'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.indigo),
              title: const Text('Configuración'),
              subtitle: const Text('Gestiona login y ajustes de cuenta'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/profile-settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}
