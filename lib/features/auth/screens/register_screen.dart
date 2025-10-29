import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/simple_user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'pasajero';
  bool _passwordVisible = false;

  final List<Map<String, dynamic>> roles = [
    {'value': 'pasajero', 'label': 'PASAJERO'},
    {'value': 'conductor', 'label': 'CONDUCTOR'},
    {'value': 'empresa', 'label': 'EMPRESA'},
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = Provider.of<AuthController>(context, listen: false);

    // Convertir string a UserRole
    UserRole role;
    switch (_selectedRole) {
      case 'empresa':
        role = UserRole.empresa;
        break;
      case 'conductor':
        role = UserRole.conductor;
        break;
      default:
        role = UserRole.pasajero;
        break;
    }

    final success = await authController.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: role,
    );

    if (success && mounted) {
      // Usuario registrado correctamente → Usar el método getRouteByRole del AuthController
      final route = authController.getRouteByRole();
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro"),
        centerTitle: true,
      ),
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 30),
                  const Icon(Icons.account_circle, size: 80, color: Colors.indigo),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu correo';
                      }
                      if (!value.contains('@')) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() {
                          _passwordVisible = !_passwordVisible;
                        }),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa una contraseña';
                      }
                      if (value.length < 6) {
                        return 'Debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                     value: _selectedRole,
                     items: roles
                         .map((role) => DropdownMenuItem<String>(
                               value: role['value'] as String,
                               child: Text(role['label'] as String),
                             ))
                         .toList(),
                    onChanged: (value) {
                      setState(() => _selectedRole = value!);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Selecciona tu rol',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_box_outlined),
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (authController.errorMessage != null)
                    Text(
                      authController.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: authController.isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: authController.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Registrarme',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("¿Ya tienes cuenta? Inicia sesión"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
