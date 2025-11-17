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
import 'package:tu_flota/features/passenger/screens/chat_assistant_screen.dart'; 
import 'package:tu_flota/features/passenger/screens/route_map_screen.dart'; 
import 'package:latlong2/latlong.dart'; 

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
        
        // Company routes
        '/company/dashboard': (context) => const CompanyDashboardScreen(),
        '/company/profile': (context) => const CompanyProfileScreen(),
        '/company/profile/edit': (context) => const CompanyEditProfileScreen(),
        '/company/drivers': (context) => const CompanyDriversScreen(),
        '/company/driver/add': (context) => const CompanyAddDriverScreen(),
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
        
        // CORRECCIÓN CLAVE: Asegura la llamada al constructor del Widget.
        '/passenger/trip/detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return PassengerTripDetailScreen(schedule: args);
        },
        
        '/passenger/chat-assistant': (context) => const ChatAssistantScreen(), 

        // RUTA CRÍTICA DEL MAPA: Define la pantalla RouteMapScreen
        '/passenger/map/route': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, LatLng>;
          
          return RouteMapScreen(
            origin: args['origin']!,
            destination: args['destination']!,
          );
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

// ----------------------------------------------------------------------
// IMPROVED SECTION: _LoginScreen and _LoginScreenState (DESIGN ONLY)
// ----------------------------------------------------------------------

class _LoginScreen extends ConsumerStatefulWidget {
  const _LoginScreen();
  @override
  ConsumerState<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<_LoginScreen> with SingleTickerProviderStateMixin {
  // Design Colors
  static const Color _primaryColor = Color(0xFF1E88E5); // Corporate Blue
  static const Color _secondaryColor = Color(0xFF00C853); // Green for Passenger
  static const Color _driverColor = Color(0xFFFFA000); // Orange for Driver

  // Controllers and State (LOGIC INTACT)
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  // For animations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animationController.dispose(); // Important to release resources
    super.dispose();
  }

  // --- Business Logic (Functionality 100% INTACT) ---

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
  
  // Function to register driver (Extracted from previous inline logic)
  Future<void> _signUpDriver() async {
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
  }

  // Helper for input design (VISUAL IMPROVEMENT)
  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _primaryColor),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)), 
      borderSide: BorderSide(color: _primaryColor, width: 2),
    ),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CRUCIAL FIX: Set background to transparent so the Container takes full control
      backgroundColor: Colors.transparent, 
      body: Container( // Use Container for the background gradient
        constraints: BoxConstraints.expand(height: MediaQuery.of(context).size.height), // Ensure full screen height
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryColor.withOpacity(0.9), // Dark Blue (top)
              _primaryColor.withOpacity(0.6), // Light Blue
              Colors.white, // White/Light Gray (bottom)
            ],
            // Controls the gradient distribution: pushing blue higher up the screen
            stops: const [0.0, 0.45, 1.0], 
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // The layout is narrow if width is less than 600px (VISUAL IMPROVEMENT)
              final isNarrow = constraints.maxWidth < 600; 
              return FadeTransition( // Fade animation
                opacity: _fadeAnimation,
                child: SlideTransition( // Slide animation
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500), // Controlled maximum width (VISUAL IMPROVEMENT)
                        child: Card(
                          elevation: 12, // More shadow
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Large Bus Icon (VISUAL IMPROVEMENT)
                                Icon(
                                  Icons.directions_bus_filled, // A filled bus icon looks good
                                  size: 80,
                                  color: _primaryColor.withOpacity(0.8),
                                ),
                                const SizedBox(height: 10),

                                // Improved Titles (VISUAL IMPROVEMENT)
                                Text(
                                  AppStrings.appTitle, 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 34, // Larger size
                                    fontWeight: FontWeight.w900,
                                    color: _primaryColor.withOpacity(0.9),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Your journey starts here', // More welcoming message
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                
                                // --- TEXT FIELDS ---
                                TextField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: _inputDeco(AppStrings.email, Icons.email_outlined), // Improved design
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _passwordCtrl,
                                  textInputAction: TextInputAction.done,
                                  decoration: _inputDeco(AppStrings.password, Icons.lock_outline), // Improved design
                                  obscureText: true,
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // --- ERROR MESSAGE ---
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      _error!, 
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                
                                // --- MAIN SIGN IN BUTTON ---
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    elevation: 5, // Shadow for the button
                                  ),
                                  child: _isLoading 
                                      ? const SizedBox(
                                          height: 20, width: 20, 
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                        ) 
                                      : const Text(AppStrings.signIn),
                                ),
                                
                                const SizedBox(height: 25),
                                // Subtler divider
                                const Divider(height: 1, thickness: 0.8, color: Colors.grey), 
                                const SizedBox(height: 15),

                                const Text(
                                  "Don't have an account? Register as:",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54, fontSize: 16),
                                ),
                                const SizedBox(height: 15),

                                // --- REGISTRATION BUTTONS (ADAPTIVE) ---
                                isNarrow 
                                    ? Column(
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: _isLoading ? null : _signUpPassenger,
                                            icon: const Icon(Icons.person_outline),
                                            label: const Text(AppStrings.registerAsPassenger),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _secondaryColor,
                                              side: const BorderSide(color: _secondaryColor, width: 2), // Thicker border
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          OutlinedButton.icon(
                                            onPressed: _isLoading ? null : _signUpDriver, 
                                            icon: const Icon(Icons.drive_eta_outlined),
                                            label: const Text(AppStrings.registerAsDriver),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _driverColor,
                                              side: const BorderSide(color: _driverColor, width: 2), // Thicker border
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _isLoading ? null : _signUpPassenger,
                                              icon: const Icon(Icons.person_outline),
                                              label: const Text(AppStrings.registerAsPassenger),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: _secondaryColor,
                                                side: const BorderSide(color: _secondaryColor, width: 2),
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _isLoading ? null : _signUpDriver, 
                                              icon: const Icon(Icons.drive_eta_outlined),
                                              label: const Text(AppStrings.registerAsDriver),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: _driverColor,
                                                side: const BorderSide(color: _driverColor, width: 2),
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}