import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../features/auth/screens/login_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  int _selectedIndex = 0;
  final supabase = SupabaseService();

  final List<Widget> _pages = const [
    _TripsScreen(),
    _DriversScreen(),
    _StatsScreen(),
    _ProfileScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['Viajes', 'Conductores', 'Estadísticas', 'Perfil'][_selectedIndex]),
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
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus, color: Colors.indigo),
            label: 'Viajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Colors.indigo),
            label: 'Conductores',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Colors.indigo),
            label: 'Estadísticas',
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

class _TripsScreen extends StatelessWidget {
  const _TripsScreen();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Gestión de viajes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      );
}

class _DriversScreen extends StatelessWidget {
  const _DriversScreen();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Gestión de conductores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      );
}

class _StatsScreen extends StatelessWidget {
  const _StatsScreen();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Estadísticas y reportes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
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
          const Icon(Icons.business, size: 90, color: Colors.indigo),
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
