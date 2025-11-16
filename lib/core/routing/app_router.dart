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
import 'package:tu_flota/features/passenger/screens/passenger_search_trips_screen.dart';
import 'package:tu_flota/features/passenger/screens/passenger_profile_screen.dart';
import 'package:tu_flota/features/passenger/screens/passenger_edit_profile_screen.dart';
import 'package:tu_flota/features/passenger/screens/passenger_history_screen.dart';
import 'package:tu_flota/features/passenger/screens/passenger_trip_detail_screen.dart';
import 'package:tu_flota/features/driver/screens/driver_dashboard_screen.dart';

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
        '/auth/login': (context) => const _LoginScreen(),
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
        // Passenger routes
        '/passenger/dashboard': (context) => const PassengerSearchTripsScreen(),
        '/passenger/profile': (context) => const PassengerProfileScreen(),
        '/passenger/profile/edit': (context) => const PassengerEditProfileScreen(),
        '/passenger/history': (context) => const PassengerHistoryScreen(),
        '/passenger/trip/detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return PassengerTripDetailScreen(schedule: args);
        },
        // Driver route (placeholder)
        '/driver/dashboard': (context) => const DriverDashboardScreen(),
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
    } else if (role == 'pasajero') {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/passenger/dashboard');
      }
    } else if (role == 'conductor') {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/driver/dashboard');
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

class _LoginScreen extends ConsumerStatefulWidget {
  const _LoginScreen();
  @override
  ConsumerState<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<_LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = AppStrings.emailPasswordRequired);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await SupabaseService().signIn(email, password);
      if (!mounted) return;
      final svc = SupabaseService();
      final user = svc.currentUser;
      final role = user == null ? null : await svc.fetchUserRoleById(user.id);
      if (role == 'empresa') {
        await ref.read(companyControllerProvider.notifier).loadAuthAndCompany();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/company/dashboard');
      } else if (role == 'conductor') {
        Navigator.pushReplacementNamed(context, '/driver/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/passenger/dashboard');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpPassenger() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = AppStrings.emailPasswordRequired);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await SupabaseService().signUp(email, password, 'pasajero');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/passenger/dashboard');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.login)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: AppStrings.email),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordCtrl,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(labelText: AppStrings.password),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                      if (isNarrow) ...[
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: const Text(AppStrings.signIn),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signUpPassenger,
                          child: const Text(AppStrings.registerAsPassenger),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final email = _emailCtrl.text.trim();
                                  final password = _passwordCtrl.text.trim();
                                  if (email.isEmpty || password.isEmpty) {
                                    setState(() => _error = AppStrings.emailPasswordRequired);
                                    return;
                                  }
                                  setState(() { _isLoading = true; _error = null; });
                                  try {
                                    await SupabaseService().signUp(email, password, 'conductor');
                                    if (!mounted) return;
                                    Navigator.pushReplacementNamed(context, '/driver/dashboard');
                                  } catch (e) {
                                    setState(() => _error = e.toString());
                                  } finally {
                                    if (mounted) setState(() => _isLoading = false);
                                  }
                                },
                          child: const Text(AppStrings.registerAsDriver),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                child: const Text(AppStrings.signIn),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signUpPassenger,
                                child: const Text(AppStrings.registerAsPassenger),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        final email = _emailCtrl.text.trim();
                                        final password = _passwordCtrl.text.trim();
                                        if (email.isEmpty || password.isEmpty) {
                                          setState(() => _error = AppStrings.emailPasswordRequired);
                                          return;
                                        }
                                        setState(() { _isLoading = true; _error = null; });
                                        try {
                                          await SupabaseService().signUp(email, password, 'conductor');
                                          if (!mounted) return;
                                          Navigator.pushReplacementNamed(context, '/driver/dashboard');
                                        } catch (e) {
                                          setState(() => _error = e.toString());
                                        } finally {
                                          if (mounted) setState(() => _isLoading = false);
                                        }
                                      },
                                child: const Text(AppStrings.registerAsDriver),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_isLoading) const LinearProgressIndicator(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}