import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../features/auth/screens/login_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  int _selectedIndex = 0;
  final supabase = SupabaseService();

  final List<Widget> _pages = const [
    _AvailableTripsScreen(),
    _MyTripsScreen(),
    _EarningsScreen(),
    _ProfileScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['Disponibles', 'Mis viajes', 'Ganancias', 'Perfil'][_selectedIndex]),
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
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on, color: Colors.indigo),
            label: 'Disponibles',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car, color: Colors.indigo),
            label: 'Mis viajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money, color: Colors.indigo),
            label: 'Ganancias',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.indigo),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// -------------------- SUBPANTALLAS --------------------

class _AvailableTripsScreen extends StatelessWidget {
  const _AvailableTripsScreen();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Viajes disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      );
}

class _MyTripsScreen extends StatelessWidget {
  const _MyTripsScreen();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Mis viajes activos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      );
}

class _EarningsScreen extends StatelessWidget {
  const _EarningsScreen();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Mis ganancias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      );
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService().currentUser;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 90, color: Colors.indigo),
          const SizedBox(height: 16),
          Text(user?.email ?? 'Sin correo', style: const TextStyle(fontSize: 18)),
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
        ],
      ),
    );
  }
}
