import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import '../../company/screens/dashboard_screen.dart';
import '../../driver/screens/profile_screen.dart';
import '../../passenger/screens/profile_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      await _authController.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final user = SupabaseService().client.auth.currentUser;
      final role = user?.userMetadata?['role'] ?? 'pasajero';

      if (context.mounted) {
        Widget nextScreen;
        switch (role) {
          case 'empresa':
            nextScreen = const CompanyDashboardScreen();
            break;
          case 'conductor':
            nextScreen = const DriverProfileScreen();
            break;
          default:
            nextScreen = const PassengerProfileScreen();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Ingresar'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              },
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text('Crear cuenta nueva'),
            ),
          ],
        ),
      ),
    );
  }
}
