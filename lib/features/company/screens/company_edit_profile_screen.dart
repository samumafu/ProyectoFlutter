import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/company/models/company_model.dart';

class CompanyEditProfileScreen extends ConsumerStatefulWidget {
  const CompanyEditProfileScreen({super.key});

  @override
  ConsumerState<CompanyEditProfileScreen> createState() => _CompanyEditProfileScreenState();
}

class _CompanyEditProfileScreenState extends ConsumerState<CompanyEditProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _address;
  late TextEditingController _nit;
  late TextEditingController _description;
  late TextEditingController _routes;
  late TextEditingController _settingsJson;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final c = ref.read(companyControllerProvider).company;
    _name = TextEditingController(text: c?.name ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _address = TextEditingController(text: c?.address ?? '');
    _nit = TextEditingController(text: c?.nit ?? '');
    _description = TextEditingController(text: c?.description ?? '');
    _routes = TextEditingController(text: (c?.routes ?? []).join(','));
    _settingsJson = TextEditingController(text: jsonEncode(c?.settings ?? {}));
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _nit.dispose();
    _description.dispose();
    _routes.dispose();
    _settingsJson.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = ref.read(companyControllerProvider).company;
    if (current == null) return;
    final routes = _routes.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    Map<String, dynamic>? settings;
    try {
      settings = jsonDecode(_settingsJson.text) as Map<String, dynamic>;
    } catch (_) {
      settings = current.settings;
    }
    final updated = current.copyWith(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      nit: _nit.text.trim().isEmpty ? null : _nit.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      routes: routes,
      settings: settings,
      isActive: _isActive,
    );
    await ref.read(companyControllerProvider.notifier).updateCompanyProfile(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.save), tooltip: AppStrings.save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: AppStrings.name)),
            TextField(controller: _email, decoration: const InputDecoration(labelText: AppStrings.email)),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: AppStrings.phone)),
            TextField(controller: _address, decoration: const InputDecoration(labelText: AppStrings.address)),
            TextField(controller: _nit, decoration: const InputDecoration(labelText: AppStrings.nit)),
            TextField(controller: _description, decoration: const InputDecoration(labelText: AppStrings.description)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text(AppStrings.active),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: _routes, decoration: const InputDecoration(labelText: AppStrings.routesCommaSeparated)),
            const SizedBox(height: 12),
            TextField(
              controller: _settingsJson,
              maxLines: 6,
              decoration: const InputDecoration(labelText: AppStrings.companySettings),
            ),
          ],
        ),
      ),
    );
  }
}