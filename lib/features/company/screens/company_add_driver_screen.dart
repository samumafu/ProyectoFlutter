import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/company/models/company_model.dart';

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
  final _autoModel = TextEditingController();
  final _autoColor = TextEditingController();
  final _autoPlate = TextEditingController();
  bool _available = true;
  Driver? _editing;

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Driver) {
      _editing = args;
      _name.text = args.name;
      _phone.text = args.phone ?? '';
      _autoModel.text = args.autoModel ?? '';
      _autoColor.text = args.autoColor ?? '';
      _autoPlate.text = args.autoPlate ?? '';
      _available = args.available;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _phone.dispose();
    _autoModel.dispose();
    _autoColor.dispose();
    _autoPlate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    String? linkedUserId;
    if (_editing == null) {
      final email = _email.text.trim();
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.required)),
        );
        return;
      }
      linkedUserId = await SupabaseService().findUserIdByEmail(email);
      if (linkedUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.driverAccountNotFound)),
        );
        return;
      }
    }
    if (_editing == null) {
      final driver = Driver(
        id: 0,
        userId: linkedUserId!,
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        autoModel: _autoModel.text.trim().isEmpty ? null : _autoModel.text.trim(),
        autoColor: _autoColor.text.trim().isEmpty ? null : _autoColor.text.trim(),
        autoPlate: _autoPlate.text.trim().isEmpty ? null : _autoPlate.text.trim(),
        available: _available,
        rating: null,
      );
      await ref.read(companyControllerProvider.notifier).createDriver(driver);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.driverCreated)),
      );
    } else {
      final current = _editing!;
      final updated = Driver(
        id: current.id,
        userId: current.userId,
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        autoModel: _autoModel.text.trim().isEmpty ? null : _autoModel.text.trim(),
        autoColor: _autoColor.text.trim().isEmpty ? null : _autoColor.text.trim(),
        autoPlate: _autoPlate.text.trim().isEmpty ? null : _autoPlate.text.trim(),
        available: _available,
        rating: current.rating,
      );
      await ref.read(companyControllerProvider.notifier).updateDriver(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.driverUpdated)),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing == null ? AppStrings.addDriver : AppStrings.editDriver), actions: [
        IconButton(onPressed: _save, icon: const Icon(Icons.save))
      ]),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_editing == null)
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: AppStrings.driverEmail),
                  validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.required : null,
                ),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: AppStrings.name),
                validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.required : null,
              ),
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: AppStrings.phone)),
              TextFormField(controller: _autoModel, decoration: const InputDecoration(labelText: AppStrings.vehicleModel)),
              TextFormField(controller: _autoColor, decoration: const InputDecoration(labelText: AppStrings.vehicleColor)),
              TextFormField(controller: _autoPlate, decoration: const InputDecoration(labelText: AppStrings.plate)),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text(AppStrings.available),
                value: _available,
                onChanged: (v) => setState(() => _available = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}