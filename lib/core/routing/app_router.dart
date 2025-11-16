import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/company/screens/company_dashboard_screen.dart';
import 'package:tu_flota/features/company/screens/company_profile_screen.dart';
import 'package:tu_flota/features/company/screens/company_edit_profile_screen.dart';
import 'package:tu_flota/features/company/screens/company_drivers_screen.dart';
import 'package:tu_flota/features/company/screens/company_add_driver_screen.dart';
import 'package:tu_flota/features/company/screens/company_schedules_screen.dart';
import 'package:tu_flota/features/company/screens/company_create_trip_screen.dart';
import 'package:tu_flota/features/company/screens/company_edit_trip_screen.dart';

// Unified router below

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _App());
  }
}

class _App extends ConsumerWidget {
  const _App();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appTitle,
      initialRoute: '/',
      routes: {
        '/': (context) => const _AuthGate(),
        '/company/dashboard': (context) => const CompanyDashboardScreen(),
        '/company/profile': (context) => const CompanyProfileScreen(),
        '/company/profile/edit': (context) => const CompanyEditProfileScreen(),
        '/company/drivers': (context) => const CompanyDriversScreen(),
        '/company/driver/add': (context) => const CompanyAddDriverScreen(),
        // Reuse add driver screen for editing when a Driver is passed in arguments.
        '/company/driver/edit': (context) => const CompanyAddDriverScreen(),
        '/company/schedules': (context) => const CompanySchedulesScreen(),
        '/company/trip/create': (context) => const CompanyCreateTripScreen(),
        '/company/trip/edit': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return CompanyEditTripScreen(schedule: args);
        },
      },
    );
  }
}

class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate({super.key});

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final client = ref.read(supabaseProvider);
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() => _checked = true);
      return;
    }
    final role = await SupabaseService().fetchUserRoleById(user.id);
    if (role == 'empresa') {
      await ref.read(companyControllerProvider.notifier).loadAuthAndCompany();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/company/dashboard');
      }
    } else {
      setState(() => _checked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const _LoginScreen();
  }
}

class _LoginScreen extends StatelessWidget {
  const _LoginScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.login)),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // For demo navigation; in a real app, sign-in then navigate.
            Navigator.pushReplacementNamed(context, '/company/dashboard');
          },
          child: const Text(AppStrings.companyDashboard),
        ),
      ),
    );
  }
}