import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
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
// ⚠️ Importa la pantalla de Reservas (asumiendo que ya la creaste en un archivo separado)
import 'package:tu_flota/features/company/screens/company_reservations_screen.dart'; 

import 'package:tu_flota/features/passenger/screens/passenger_search_trips_screen.dart';
import 'package:tu_flota/features/passenger/screens/passenger_profile_screen.dart';
import 'package:tu_flota/features/passenger/screens/passenger_edit_profile_screen.dart';
import 'package:tu_flota/features/passenger/screens/passenger_history_screen.dart';
import 'package:tu_flota/features/passenger/screens/passenger_trip_detail_screen.dart';
import 'package:tu_flota/features/driver/screens/driver_dashboard_screen.dart';
import 'package:tu_flota/features/passenger/screens/chat_assistant_screen.dart'; 
import 'package:tu_flota/features/passenger/screens/route_map_screen.dart'; 

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
        // 🔑 RUTA AÑADIDA: Para la pantalla dedicada a la lista de Reservas
        '/company/reservations': (context) => const CompanyReservationsScreen(),
        
        // Passenger routes
        '/passenger/dashboard': (context) => const PassengerSearchTripsScreen(),
        '/passenger/profile': (context) => const PassengerProfileScreen(),
        '/passenger/profile/edit': (context) => const PassengerEditProfileScreen(),
        '/passenger/history': (context) => const PassengerHistoryScreen(),
        
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
// SECCIÓN MEJORADA: _LoginScreen y _LoginScreenState (DISEÑO Y RESPONSIVE)
// ----------------------------------------------------------------------

class _LoginScreen extends ConsumerStatefulWidget {
  const _LoginScreen();
  @override
  ConsumerState<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<_LoginScreen> with SingleTickerProviderStateMixin {
  // Design Colors
  static const Color _primaryColor = Color(0xFF1E88E5); // Azul Corporativo (más saturado)
  static const Color _secondaryColor = Color(0xFF00C853); // Verde para Pasajero
  static const Color _driverColor = Color(0xFFFFA000); // Naranja para Conductor

  // Controllers and State (LÓGICA INTACTA)
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  // Para animaciones de entrada
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
    _animationController.forward(); // Inicia la animación al cargar la pantalla
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animationController.dispose(); // Liberar recursos
    super.dispose();
  }

  // --- Lógica de Negocio (Funcionalidad 100% INTACTA) ---

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
  
  // Función para registrar conductor
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

  // Helper para el diseño de inputs (MEJORA VISUAL)
  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    // Estilo de label flotante mejorado
    labelStyle: const TextStyle(color: _primaryColor),
    prefixIcon: Icon(icon, color: _primaryColor),
    filled: true,
    fillColor: Colors.white,
    // Borde más suave
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16), 
      borderSide: BorderSide.none, // Elimina el borde por defecto para usar la sombra del Card
    ), 
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)), 
      borderSide: BorderSide(color: _primaryColor, width: 2.5),
    ),
    // Padding de contenido (opcional, para campos grandes)
    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CRUCIAL: Fondo transparente para que el Container controle el color
      backgroundColor: Colors.transparent, 
      body: Container( // Usar Container para el fondo con gradiente
        constraints: BoxConstraints.expand(height: MediaQuery.of(context).size.height), // Asegura altura de pantalla completa
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, // Inicia desde arriba
            end: Alignment.bottomCenter, // Termina abajo
            colors: [
              _primaryColor.withOpacity(1.0), // Azul principal (arriba)
              _primaryColor.withOpacity(0.8), 
              const Color(0xFFF0F4F8), // Fondo de color claro para el card
            ],
            // Controla la distribución, el fondo claro empieza más o menos a la mitad
            stops: const [0.0, 0.4, 1.0], 
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determina si el ancho es estrecho (móvil)
              final isNarrow = constraints.maxWidth < 600; 
              return FadeTransition( // Animación de aparición
                opacity: _fadeAnimation,
                child: SlideTransition( // Animación de deslizamiento
                  position: _slideAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450), // Ancho máximo ligeramente más estrecho para móvil (RESPONSIVE)
                        child: Column( // Envuelve el Card y el posible branding
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Header/Branding fuera del Card
                            Icon(
                              Icons.directions_bus_filled, 
                              size: isNarrow ? 90 : 110,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              AppStrings.appTitle, 
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 38, 
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    blurRadius: 5.0,
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            // --- CARD DE LOGIN ---
                            Card(
                              elevation: 20, // Mayor sombra para un efecto flotante
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), // Bordes más redondeados
                              ), 
                              child: Padding(
                                padding: const EdgeInsets.all(30), // Más padding dentro del Card
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    
                                    // Título del Formulario
                                    Text(
                                      'Welcome Back', 
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 26, 
                                        fontWeight: FontWeight.bold,
                                        color: _primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Sign in to continue your journey', 
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
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
                                      decoration: _inputDeco(AppStrings.email, Icons.email_outlined), // Diseño mejorado
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: _passwordCtrl,
                                      textInputAction: TextInputAction.done,
                                      decoration: _inputDeco(AppStrings.password, Icons.lock_outline), // Diseño mejorado
                                      obscureText: true,
                                    ),
                                    
                                    const SizedBox(height: 25),
                                    
                                    // --- ERROR MESSAGE ---
                                    if (_error != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 15),
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
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        elevation: 8, // Sombra prominente
                                      ),
                                      child: _isLoading 
                                          ? const SizedBox(
                                              height: 20, width: 20, 
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                            ) 
                                          : const Text(AppStrings.signIn),
                                    ),
                                    
                                    const SizedBox(height: 30),
                                    // Divisor más estilizado
                                    Row(
                                      children: [
                                        const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            "OR",
                                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    const Text(
                                      "Don't have an account? Register as:",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.black54, fontSize: 16),
                                    ),
                                    const SizedBox(height: 15),

                                    // --- BOTONES DE REGISTRO (ADAPTIVE Y MEJORADOS) ---
                                    isNarrow 
                                        ? Column( // Uso de Column en pantallas estrechas
                                            children: [
                                              _buildRegisterButton(
                                                onPressed: _isLoading ? null : _signUpPassenger,
                                                icon: Icons.person_outline,
                                                label: AppStrings.registerAsPassenger,
                                                color: _secondaryColor,
                                              ),
                                              const SizedBox(height: 12),
                                              _buildRegisterButton(
                                                onPressed: _isLoading ? null : _signUpDriver,
                                                icon: Icons.drive_eta_outlined,
                                                label: AppStrings.registerAsDriver,
                                                color: _driverColor,
                                              ),
                                            ],
                                          )
                                        : Row( // Uso de Row en pantallas anchas
                                            children: [
                                              Expanded(
                                                child: _buildRegisterButton(
                                                  onPressed: _isLoading ? null : _signUpPassenger,
                                                  icon: Icons.person_outline,
                                                  label: AppStrings.registerAsPassenger,
                                                  color: _secondaryColor,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildRegisterButton(
                                                  onPressed: _isLoading ? null : _signUpDriver,
                                                  icon: Icons.drive_eta_outlined,
                                                  label: AppStrings.registerAsDriver,
                                                  color: _driverColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

  // --- NUEVO WIDGET HELPER PARA BOTÓN DE REGISTRO RESPONSIVE ---
  Widget _buildRegisterButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: FittedBox( // <--- CLAVE PARA HACER EL TEXTO RESPONSIVE
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          // Un poco más pequeña la fuente para dar margen en pantallas estrechas
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), 
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 2), 
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // Más padding horizontal para que no se pegue el texto
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}