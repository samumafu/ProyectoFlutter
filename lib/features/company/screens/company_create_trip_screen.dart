import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'dart:convert';

class CompanyCreateTripScreen extends ConsumerStatefulWidget {
  const CompanyCreateTripScreen({super.key});

  @override
  ConsumerState<CompanyCreateTripScreen> createState() => _CompanyCreateTripScreenState();
}

class _CompanyCreateTripScreenState extends ConsumerState<CompanyCreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _departure = TextEditingController();
  final _arrival = TextEditingController();
  final _price = TextEditingController();
  final _availableSeats = TextEditingController();
  final _totalSeats = TextEditingController();
  final _vehicleType = TextEditingController();
  final _vehicleId = TextEditingController();
  final _additionalInfo = TextEditingController();
  bool _isActive = true;

  @override
  void dispose() {
    _origin.dispose();
    _destination.dispose();
    _departure.dispose();
    _arrival.dispose();
    _price.dispose();
    _availableSeats.dispose();
    _totalSeats.dispose();
    _vehicleType.dispose();
    _vehicleId.dispose();
    _additionalInfo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final companyId = ref.read(companyControllerProvider).company?.id;
    if (companyId == null) return;
    final schedule = CompanySchedule(
      id: '',
      companyId: companyId,
      origin: _origin.text.trim(),
      destination: _destination.text.trim(),
      departureTime: _departure.text.trim(),
      arrivalTime: _arrival.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0,
      availableSeats: int.tryParse(_availableSeats.text.trim()) ?? 0,
      totalSeats: int.tryParse(_totalSeats.text.trim()) ?? 0,
      vehicleType: _vehicleType.text.trim().isEmpty ? null : _vehicleType.text.trim(),
      vehicleId: _vehicleId.text.trim().isEmpty ? null : _vehicleId.text.trim(),
      isActive: _isActive,
      additionalInfo: _additionalInfo.text.trim().isEmpty
          ? null
          : _parseJsonOrNull(_additionalInfo.text.trim()),
    );
    try {
      await ref.read(companyControllerProvider.notifier).createSchedule(schedule);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.success)));
      Navigator.pushNamedAndRemoveUntil(context, '/company/dashboard', (route) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.actionFailed)));
    }
  }

  Map<String, dynamic>? _parseJsonOrNull(String s) {
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return null;
  }

  Future<void> _pickDateTime({required bool isDeparture}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      helpText: AppStrings.pickDate,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: AppStrings.pickTime,
    );
    if (time == null) return;
    final iso = ref.read(companyControllerProvider.notifier).formatIso(date, time);
    setState(() {
      if (isDeparture) {
        _departure.text = iso;
      } else {
        _arrival.text = iso;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(AppStrings.createTrip, style: TextStyle(color: Colors.black87)),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.save, color: Colors.black87))],
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 780;
            InputDecoration deco(String label) => InputDecoration(
                  labelText: label,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Card(
                    elevation: 4,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(child: TextFormField(controller: _origin, decoration: deco(AppStrings.origin), validator: _req)),
                                    const SizedBox(width: 16),
                                    Expanded(child: TextFormField(controller: _destination, decoration: deco(AppStrings.destination), validator: _req)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(controller: _origin, decoration: deco(AppStrings.origin), validator: _req),
                                    const SizedBox(height: 12),
                                    TextFormField(controller: _destination, decoration: deco(AppStrings.destination), validator: _req),
                                  ],
                                ),
                          const SizedBox(height: 12),
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _departure,
                                        readOnly: true,
                                        decoration: deco(AppStrings.departureTimeIso).copyWith(
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.event),
                                            onPressed: () => _pickDateTime(isDeparture: true),
                                            tooltip: AppStrings.pickDate,
                                          ),
                                        ),
                                        validator: _req,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _arrival,
                                        readOnly: true,
                                        decoration: deco(AppStrings.arrivalTimeIso).copyWith(
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.event),
                                            onPressed: () => _pickDateTime(isDeparture: false),
                                            tooltip: AppStrings.pickDate,
                                          ),
                                        ),
                                        validator: _req,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(
                                      controller: _departure,
                                      readOnly: true,
                                      decoration: deco(AppStrings.departureTimeIso).copyWith(
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.event),
                                          onPressed: () => _pickDateTime(isDeparture: true),
                                          tooltip: AppStrings.pickDate,
                                        ),
                                      ),
                                      validator: _req,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _arrival,
                                      readOnly: true,
                                      decoration: deco(AppStrings.arrivalTimeIso).copyWith(
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.event),
                                          onPressed: () => _pickDateTime(isDeparture: false),
                                          tooltip: AppStrings.pickDate,
                                        ),
                                      ),
                                      validator: _req,
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 12),
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(child: TextFormField(controller: _price, decoration: deco(AppStrings.price), keyboardType: TextInputType.number)),
                                    const SizedBox(width: 16),
                                    Expanded(child: TextFormField(controller: _availableSeats, decoration: deco(AppStrings.availableSeats), keyboardType: TextInputType.number)),
                                    const SizedBox(width: 16),
                                    Expanded(child: TextFormField(controller: _totalSeats, decoration: deco(AppStrings.totalSeats), keyboardType: TextInputType.number)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(controller: _price, decoration: deco(AppStrings.price), keyboardType: TextInputType.number),
                                    const SizedBox(height: 12),
                                    TextFormField(controller: _availableSeats, decoration: deco(AppStrings.availableSeats), keyboardType: TextInputType.number),
                                    const SizedBox(height: 12),
                                    TextFormField(controller: _totalSeats, decoration: deco(AppStrings.totalSeats), keyboardType: TextInputType.number),
                                  ],
                                ),
                          const SizedBox(height: 12),
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(child: TextFormField(controller: _vehicleType, decoration: deco(AppStrings.vehicleType))),
                                    const SizedBox(width: 16),
                                    Expanded(child: TextFormField(controller: _vehicleId, decoration: deco(AppStrings.vehicleId), keyboardType: TextInputType.text)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(controller: _vehicleType, decoration: deco(AppStrings.vehicleType)),
                                    const SizedBox(height: 12),
                                    TextFormField(controller: _vehicleId, decoration: deco(AppStrings.vehicleId), keyboardType: TextInputType.text),
                                  ],
                                ),
                          const SizedBox(height: 12),
                          TextFormField(controller: _additionalInfo, decoration: deco(AppStrings.additionalInfo)),
                          const SizedBox(height: 12),
                          SwitchListTile(title: const Text(AppStrings.active), value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
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
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? AppStrings.required : null;
}