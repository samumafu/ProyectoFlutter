import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/empresa_controller.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';
import '../../../models/user_model.dart';

class CompanyRegistrationScreen extends StatefulWidget {
  const CompanyRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<CompanyRegistrationScreen> createState() => _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends State<CompanyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Controladores de texto
  final _razonSocialController = TextEditingController();
  final _nitController = TextEditingController();
  final _representanteLegalController = TextEditingController();
  final _cedulaRepresentanteController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _municipioController = TextEditingController();
  final _sitioWebController = TextEditingController();

  // Estado del formulario
  bool _acceptTerms = false;
  Map<String, String?> _fieldErrors = {};

  @override
  void dispose() {
    _razonSocialController.dispose();
    _nitController.dispose();
    _representanteLegalController.dispose();
    _cedulaRepresentanteController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _municipioController.dispose();
    _sitioWebController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Registro de Empresa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer2<AuthController, EmpresaController>(
        builder: (context, authController, empresaController, child) {
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 30),

                  // Información básica
                  _buildSectionTitle('Información Básica'),
                  const SizedBox(height: 16),
                  _buildBasicInfoFields(),
                  const SizedBox(height: 30),

                  // Representante legal
                  _buildSectionTitle('Representante Legal'),
                  const SizedBox(height: 16),
                  _buildRepresentativeFields(),
                  const SizedBox(height: 30),

                  // Información de contacto
                  _buildSectionTitle('Información de Contacto'),
                  const SizedBox(height: 16),
                  _buildContactFields(),
                  const SizedBox(height: 30),

                  // Términos y condiciones
                  _buildTermsCheckbox(),
                  const SizedBox(height: 30),

                  // Botón de registro
                  _buildRegisterButton(authController, empresaController),
                  const SizedBox(height: 20),

                  // Mensaje de error
                  if (empresaController.errorMessage.isNotEmpty)
                    _buildErrorMessage(empresaController.errorMessage),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
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
          Icon(
            Icons.business,
            size: 60,
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(height: 16),
          const Text(
            'Registro de Empresa Transportadora',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete la información para registrar su empresa en el sistema de transporte intermunicipal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  Widget _buildBasicInfoFields() {
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
            controller: _razonSocialController,
            label: 'Razón Social',
            hint: 'Ingrese la razón social de la empresa',
            prefixIcon: Icons.business,
            validator: (value) => _fieldErrors['razonSocial'],
            onChanged: (value) => _clearFieldError('razonSocial'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _nitController,
            label: 'NIT',
            hint: 'Ingrese el NIT de la empresa',
            prefixIcon: Icons.numbers,
            keyboardType: TextInputType.number,
            validator: (value) => _fieldErrors['nit'],
            onChanged: (value) => _clearFieldError('nit'),
          ),
        ],
      ),
    );
  }

  Widget _buildRepresentativeFields() {
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
            controller: _representanteLegalController,
            label: 'Nombre del Representante Legal',
            hint: 'Ingrese el nombre completo',
            prefixIcon: Icons.person,
            validator: (value) => _fieldErrors['representanteLegal'],
            onChanged: (value) => _clearFieldError('representanteLegal'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _cedulaRepresentanteController,
            label: 'Cédula del Representante',
            hint: 'Ingrese el número de cédula',
            prefixIcon: Icons.badge,
            keyboardType: TextInputType.number,
            validator: (value) => _fieldErrors['cedulaRepresentante'],
            onChanged: (value) => _clearFieldError('cedulaRepresentante'),
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
            hint: 'Ingrese el teléfono de contacto',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) => _fieldErrors['telefono'],
            onChanged: (value) => _clearFieldError('telefono'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Email Corporativo',
            hint: 'Ingrese el email de la empresa',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => _fieldErrors['email'],
            onChanged: (value) => _clearFieldError('email'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _direccionController,
            label: 'Dirección',
            hint: 'Ingrese la dirección de la empresa',
            prefixIcon: Icons.location_on,
            validator: (value) => _fieldErrors['direccion'],
            onChanged: (value) => _clearFieldError('direccion'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _municipioController,
            label: 'Municipio',
            hint: 'Ingrese el municipio',
            prefixIcon: Icons.location_city,
            validator: (value) => _fieldErrors['municipio'],
            onChanged: (value) => _clearFieldError('municipio'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _sitioWebController,
            label: 'Sitio Web (Opcional)',
            hint: 'Ingrese la URL del sitio web',
            prefixIcon: Icons.web,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _acceptTerms,
            onChanged: (value) {
              setState(() {
                _acceptTerms = value ?? false;
              });
            },
            activeColor: const Color(0xFF1565C0),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _acceptTerms = !_acceptTerms;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    children: [
                      const TextSpan(text: 'Acepto los '),
                      TextSpan(
                        text: 'términos y condiciones',
                        style: TextStyle(
                          color: const Color(0xFF1565C0),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' del servicio y confirmo que la información proporcionada es veraz.'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(AuthController authController, EmpresaController empresaController) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Registrar Empresa',
        onPressed: empresaController.isLoading || !_acceptTerms
            ? null
            : () => _handleRegister(authController, empresaController),
        isLoading: empresaController.isLoading,
        backgroundColor: const Color(0xFF1565C0),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFieldError(String field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() {
        _fieldErrors.remove(field);
      });
    }
  }

  Future<void> _handleRegister(AuthController authController, EmpresaController empresaController) async {
    // Limpiar errores previos
    empresaController.limpiarError();
    
    // Validar datos
    final errores = empresaController.validarDatosEmpresa(
      razonSocial: _razonSocialController.text,
      nit: _nitController.text,
      representanteLegal: _representanteLegalController.text,
      cedulaRepresentante: _cedulaRepresentanteController.text,
      telefono: _telefonoController.text,
      email: _emailController.text,
      direccion: _direccionController.text,
      municipio: _municipioController.text,
    );

    if (errores.isNotEmpty) {
      setState(() {
        _fieldErrors = errores;
      });
      
      // Hacer scroll al primer error
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe aceptar los términos y condiciones'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = authController.user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await empresaController.registrarEmpresa(
      userId: userId,
      razonSocial: _razonSocialController.text.trim(),
      nit: _nitController.text.trim(),
      representanteLegal: _representanteLegalController.text.trim(),
      cedulaRepresentante: _cedulaRepresentanteController.text.trim(),
      telefono: _telefonoController.text.trim(),
      email: _emailController.text.trim(),
      direccion: _direccionController.text.trim(),
      municipio: _municipioController.text.trim(),
      sitioWeb: _sitioWebController.text.trim().isEmpty ? null : _sitioWebController.text.trim(),
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empresa registrada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navegar al dashboard de empresa
      Navigator.of(context).pushReplacementNamed('/company-dashboard');
    }
  }
}