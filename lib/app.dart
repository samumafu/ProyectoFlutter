import 'package:flutter/material.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/passenger/screens/profile_screen.dart';
import 'features/company/screens/dashboard_screen.dart';
import 'features/driver/screens/profile_screen.dart';

class TuFlotaApp extends StatelessWidget {
  const TuFlotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tu Flota',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const _RootNavigator(),
    );
  }
}

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  final supabase = SupabaseService();

  @override
  Widget build(BuildContext context) {
    // Si no hay sesión activa → login
    if (!supabase.isLoggedIn) {
      return const LoginScreen();
    }

    // Si hay sesión activa, obtenemos el rol del usuario
    final user = supabase.currentUser;
    final role = user?.userMetadata?['role'] ?? 'pasajero'; // temporal

    // Dependiendo del rol, redirige a la pantalla correspondiente
    switch (role) {
      case 'empresa':
        return const CompanyDashboardScreen();
      case 'conductor':
        return const DriverProfileScreen();
      default:
        return const PassengerProfileScreen();
    }
  }
}
