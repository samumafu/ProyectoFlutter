import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/passenger/screens/passenger_home_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/company/screens/dashboard_screen.dart';
import 'features/driver/screens/profile_screen.dart';
import 'features/passenger/controllers/ticket_search_controller.dart';
import 'controllers/auth_controller.dart';

class TuFlotaApp extends StatelessWidget {
  const TuFlotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TicketSearchController()..initializeSampleData()),
        ChangeNotifierProvider(create: (context) => AuthController()),
      ],
      child: MaterialApp(
        title: 'TuFlota',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        routes: {
          '/': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/passenger-home': (context) => const PassengerHomeScreen(),
          '/company-dashboard': (context) => const CompanyDashboardScreen(),
          '/driver-home': (context) => const DriverProfileScreen(),
          '/admin-dashboard': (context) => const PassengerHomeScreen(), // Temporal hasta crear admin
        },
        initialRoute: '/',
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
