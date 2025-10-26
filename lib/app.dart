import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/passenger/screens/passenger_home_screen.dart';
import 'features/auth/screens/login_screen.dart';

class TuFlotaApp extends StatelessWidget {
  const TuFlotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const _RootNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.hasData ? snapshot.data!.session : null;
        
        if (session != null) {
          return const PassengerHomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
