import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/conductor_model.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';

class ConductorRegistrationScreen extends StatefulWidget {
  const ConductorRegistrationScreen({super.key});

  @override
  State<ConductorRegistrationScreen> createState() => _ConductorRegistrationScreenState();
}

class _ConductorRegistrationScreenState extends State<ConductorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controladores de texto
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _municipioController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _numeroLicenciaController = TextEditingController();
  final _categoriaLicenciaController = TextEditingController();
  final _fechaVencimientoLicenciaController = TextEditingController();
  final _experienciaController = TextEditingController();

  // Estado del formulario
  DateTime? _fechaNacimiento;
  DateTime? _fechaVencimientoLicencia;
  bool _acceptTerms = false;
  Map<String, String?> _fieldErrors = {};

  @override
  void dispose() {
    _scrollController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _municipioController.dispose();
    _fechaNacimientoController.dispose();
    _numeroLicenciaController.dispose();
    _categoriaLicenciaController.dispose();
    _fechaVencimientoLicenciaController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }

  void _clearFieldError(String field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() {
        _fieldErrors.remove(field);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBirthDate ? DateTime(1990) : DateTime.now().add(const Duration(days: 365)),
      firstDate: isBirthDate ? DateTime(1950) : DateTime.now(),
      lastDate: isBirthDate ? DateTime.now().subtract(const Duration(days: 6570)) : DateTime(2030), // 18 años mínimo
    );

    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _fechaNacimiento = picked;
          _fechaNacimientoController.text = '${picked.day}/${picked.month}/${picked.year}';
        } else {
          _fechaVencimientoLicencia = picked;
          _fechaVencimientoLicenciaController.text = '${picked.day}/${picked.month}/${picked.year}';
        }
      });
    }
  }

  Map<String, String?> _validateForm() {
    final errors = <String, String?>{};

    if (_nombresController.text.trim().isEmpty) {
      errors['nombres'] = 'Los nombres son requeridos';
    }

    if (_apellidosController.text.trim().isEmpty) {
      errors['apellidos'] = 'Los apellidos son requeridos';
    }

    if (_cedulaController.text.trim().isEmpty) {
      errors['cedula'] = 'La cédula es requerida';
    } else if (!RegExp(r'^\d{6,12}$').hasMatch(_cedulaController.text.replaceAll(RegExp(r'[^0-9]'), ''))) {
      errors['cedula'] = 'La cédula debe tener entre 6 y 12 dígitos';
    }

    if (_telefonoController.text.trim().isEmpty) {
      errors['telefono'] = 'El teléfono es requerido';
    }

    if (_emailController.text.trim().isEmpty) {
      errors['email'] = 'El email es requerido';
    } else if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(_emailController.text)) {
      errors['email'] = 'El email no tiene un formato válido';
    }

    if (_direccionController.text.trim().isEmpty) {
      errors['direccion'] = 'La dirección es requerida';
    }

    if (_municipioController.text.trim().isEmpty) {
      errors['municipio'] = 'El municipio es requerido';
    }

    if (_fechaNacimiento == null) {
      errors['fechaNacimiento'] = 'La fecha de nacimiento es requerida';
    }

    if (_numeroLicenciaController.text.trim().isEmpty) {
      errors['numeroLicencia'] = 'El número de licencia es requerido';
    }

    if (_categoriaLicenciaController.text.trim().isEmpty) {
      errors['categoriaLicencia'] = 'La categoría de licencia es requerida';
    }

    if (_fechaVencimientoLicencia == null) {
      errors['fechaVencimientoLicencia'] = 'La fecha de vencimiento de licencia es requerida';
    }

    if (_experienciaController.text.trim().isEmpty) {
      errors['experiencia'] = 'Los años de experiencia son requeridos';
    }

    if (!_acceptTerms) {
      errors['terms'] = 'Debes aceptar los términos y condiciones';
    }

    return errors;
  }

  Future<void> _handleRegister(AuthController authController) async {
    final errors = _validateForm();
    
    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors = errors;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor corrige los errores en el formulario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // TODO: Implementar registro de conductor
      // Aquí se llamaría al servicio de conductores
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conductor registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar al dashboard de conductor
      Navigator.pushReplacementNamed(context, '/conductor-dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar conductor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registro de Conductor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          return Form(
            key: _formKey,
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Información Personal'),
                    const SizedBox(height: 16),
                    _buildPersonalInfoFields(),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Información de Contacto'),
                    const SizedBox(height: 16),
                    _buildContactFields(),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Información de Licencia'),
                    const SizedBox(height: 16),
                    _buildLicenseFields(),
                    const SizedBox(height: 24),
                    
                    _buildTermsCheckbox(),
                    const SizedBox(height: 24),
                    
                    _buildRegisterButton(authController),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1565C0),
      ),
    );
  }

  Widget _buildPersonalInfoFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _nombresController,
            label: 'Nombres',
            hint: 'Ingrese sus nombres completos',
            prefixIcon: Icons.person,
            validator: (value) => _fieldErrors['nombres'],
            onChanged: (value) => _clearFieldError('nombres'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _apellidosController,
            label: 'Apellidos',
            hint: 'Ingrese sus apellidos completos',
            prefixIcon: Icons.person_outline,
            validator: (value) => _fieldErrors['apellidos'],
            onChanged: (value) => _clearFieldError('apellidos'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _cedulaController,
            label: 'Cédula de Ciudadanía',
            hint: 'Ingrese su número de cédula',
            prefixIcon: Icons.badge,
            keyboardType: TextInputType.number,
            validator: (value) => _fieldErrors['cedula'],
            onChanged: (value) => _clearFieldError('cedula'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _fechaNacimientoController,
            label: 'Fecha de Nacimiento',
            hint: 'Seleccione su fecha de nacimiento',
            prefixIcon: Icons.calendar_today,
            readOnly: true,
            onTap: () => _selectDate(context, true),
            validator: (value) => _fieldErrors['fechaNacimiento'],
          ),
        ],
      ),
    );
  }

  Widget _buildContactFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _telefonoController,
            label: 'Teléfono',
            hint: 'Ingrese su número de teléfono',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) => _fieldErrors['telefono'],
            onChanged: (value) => _clearFieldError('telefono'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Ingrese su correo electrónico',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => _fieldErrors['email'],
            onChanged: (value) => _clearFieldError('email'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _direccionController,
            label: 'Dirección',
            hint: 'Ingrese su dirección de residencia',
            prefixIcon: Icons.location_on,
            validator: (value) => _fieldErrors['direccion'],
            onChanged: (value) => _clearFieldError('direccion'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _municipioController,
            label: 'Municipio',
            hint: 'Ingrese su municipio de residencia',
            prefixIcon: Icons.location_city,
            validator: (value) => _fieldErrors['municipio'],
            onChanged: (value) => _clearFieldError('municipio'),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _numeroLicenciaController,
            label: 'Número de Licencia',
            hint: 'Ingrese el número de su licencia de conducir',
            prefixIcon: Icons.credit_card,
            validator: (value) => _fieldErrors['numeroLicencia'],
            onChanged: (value) => _clearFieldError('numeroLicencia'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _categoriaLicenciaController,
            label: 'Categoría de Licencia',
            hint: 'Ej: C1, C2, C3',
            prefixIcon: Icons.category,
            validator: (value) => _fieldErrors['categoriaLicencia'],
            onChanged: (value) => _clearFieldError('categoriaLicencia'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _fechaVencimientoLicenciaController,
            label: 'Fecha de Vencimiento',
            hint: 'Seleccione la fecha de vencimiento',
            prefixIcon: Icons.event,
            readOnly: true,
            onTap: () => _selectDate(context, false),
            validator: (value) => _fieldErrors['fechaVencimientoLicencia'],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _experienciaController,
            label: 'Años de Experiencia',
            hint: 'Ingrese sus años de experiencia conduciendo',
            prefixIcon: Icons.timeline,
            keyboardType: TextInputType.number,
            validator: (value) => _fieldErrors['experiencia'],
            onChanged: (value) => _clearFieldError('experiencia'),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _fieldErrors.containsKey('terms') ? Colors.red : Colors.grey.shade300,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _acceptTerms,
            onChanged: (value) {
              setState(() {
                _acceptTerms = value ?? false;
                _clearFieldError('terms');
              });
            },
            activeColor: const Color(0xFF1565C0),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _acceptTerms = !_acceptTerms;
                  _clearFieldError('terms');
                });
              },
              child: const Text(
                'Acepto los términos y condiciones, y autorizo el tratamiento de mis datos personales de acuerdo con la política de privacidad.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(AuthController authController) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Registrar Conductor',
        onPressed: !_acceptTerms
            ? null
            : () => _handleRegister(authController),
        backgroundColor: const Color(0xFF1565C0),
      ),
    );
  }
}