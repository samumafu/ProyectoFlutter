// lib/features/company/screens/company_add_driver_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/driver/models/driver_model.dart'; // <-- IMPORT CORREGIDO
import 'package:tu_flota/core/constants/app_data.dart'; // <-- IMPORT CORREGIDO

// Definiciones de estilo
const Color _primaryColor = Color(0xFF1E88E5);
const Color _secondaryColor = Color(0xFF00C853);
const double _maxFormWidth = 600.0;

class CompanyAddDriverScreen extends ConsumerStatefulWidget {
  const CompanyAddDriverScreen({super.key});

  @override
  ConsumerState<CompanyAddDriverScreen> createState() => _CompanyAddDriverScreenState();
}

class _CompanyAddDriverScreenState extends ConsumerState<CompanyAddDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  
  String? _selectedAutoModel; // Estado para el Dropdown
  
  final _autoColor = TextEditingController();
  final _autoPlate = TextEditingController();
  bool _available = true;
  Driver? _editing;
  bool _isDataInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Driver) {
        _editing = args;
        _name.text = args.name;
        _phone.text = args.phone ?? '';
        _selectedAutoModel = args.autoModel;
        _autoColor.text = args.autoColor ?? '';
        _autoPlate.text = args.autoPlate ?? '';
        _available = args.available;
      }
      if (_editing != null && _selectedAutoModel != null && !allowedVehicleModels.contains(_selectedAutoModel)) {
        _selectedAutoModel = null;
      }
      _isDataInitialized = true;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _phone.dispose();
    _autoColor.dispose();
    _autoPlate.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    // FIX: Cambiado 'side' por 'borderSide'
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primaryColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? AppStrings.required : null;

  String? _reqModel(String? v) => (v == null || v.isEmpty) ? 'Debe seleccionar un modelo de vehículo.' : null;


  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedAutoModel == null) return;
    
    String? linkedUserId;
    final scaffold = ScaffoldMessenger.of(context);

    if (_editing == null) {
      final email = _email.text.trim();
      if (email.isEmpty) return; 

      linkedUserId = await SupabaseService().findUserIdByEmail(email);
      
      if (linkedUserId == null) {
        scaffold.showSnackBar(
          const SnackBar(content: Text(AppStrings.driverAccountNotFound), backgroundColor: Colors.red),
        );
        return;
      }
    }

    try {
      final Driver driver = Driver(
        id: _editing?.id ?? 0,
        userId: _editing?.userId ?? linkedUserId!,
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        autoModel: _selectedAutoModel,
        autoColor: _autoColor.text.trim().isEmpty ? null : _autoColor.text.trim(),
        autoPlate: _autoPlate.text.trim().isEmpty ? null : _autoPlate.text.trim(),
        available: _available,
        rating: _editing?.rating,
      );

      if (_editing == null) {
        await ref.read(companyControllerProvider.notifier).createDriver(driver);
        if (mounted) scaffold.showSnackBar(const SnackBar(content: Text(AppStrings.driverCreated), backgroundColor: _secondaryColor));
      } else {
        await ref.read(companyControllerProvider.notifier).updateDriver(driver);
        if (mounted) scaffold.showSnackBar(const SnackBar(content: Text(AppStrings.driverUpdated), backgroundColor: _secondaryColor));
      }
      
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        scaffold.showSnackBar(SnackBar(content: Text('${AppStrings.actionFailed}: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;
    final title = isEditing ? AppStrings.editDriver : AppStrings.addDriver;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _save, 
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Guardar Conductor',
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxFormWidth),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Email (Solo para añadir)
                  if (!isEditing) ...[
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDeco(AppStrings.driverEmail, Icons.email_outlined),
                      validator: _req,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 2. Información Personal
                  _buildSectionHeader(context, title: 'Información Personal', icon: Icons.person_outline),
                  TextFormField(
                    controller: _name,
                    decoration: _inputDeco(AppStrings.name, Icons.badge_outlined),
                    validator: _req,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDeco(AppStrings.phone, Icons.phone_outlined),
                  ),
                  const SizedBox(height: 30),

                  // 3. Información del Vehículo
                  _buildSectionHeader(context, title: 'Datos del Vehículo', icon: Icons.directions_bus_filled),
                  
                  // Dropdown para Modelo
                  DropdownButtonFormField<String>(
                    value: _selectedAutoModel,
                    decoration: _inputDeco(AppStrings.vehicleModel, Icons.style_outlined),
                    hint: const Text('Selecciona el modelo'),
                    validator: _reqModel,
                    items: allowedVehicleModels.map((String model) {
                      return DropdownMenuItem<String>(
                        value: model,
                        child: Text(model),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedAutoModel = newValue;
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _autoColor,
                          decoration: _inputDeco(AppStrings.vehicleColor, Icons.color_lens_outlined),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _autoPlate,
                          decoration: _inputDeco(AppStrings.plate, Icons.tag),
                          validator: _req,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // 4. Disponibilidad (SwitchListTile)
                  _buildSectionHeader(context, title: 'Estado', icon: Icons.settings),
                  SwitchListTile(
                    title: const Text(AppStrings.available, style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_available ? 'El conductor está marcado como disponible.' : 'El conductor está marcado como no disponible.'),
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                    activeColor: _secondaryColor,
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Botón de Guardar
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: Icon(isEditing ? Icons.update : Icons.person_add_alt_1_rounded, size: 24),
                    label: Text(
                      isEditing ? 'ACTUALIZAR CONDCUTOR' : 'AGREGAR CONDCUTOR',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const Expanded(child: Divider(color: Colors.grey, height: 20, indent: 10, thickness: 0.5)),
        ],
      ),
    );
  }
}