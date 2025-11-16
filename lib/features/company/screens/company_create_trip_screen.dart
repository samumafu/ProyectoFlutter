import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';

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
      id: 0,
      companyId: companyId,
      origin: _origin.text.trim(),
      destination: _destination.text.trim(),
      departureTime: _departure.text.trim(),
      arrivalTime: _arrival.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0,
      availableSeats: int.tryParse(_availableSeats.text.trim()) ?? 0,
      totalSeats: int.tryParse(_totalSeats.text.trim()) ?? 0,
      vehicleType: _vehicleType.text.trim().isEmpty ? null : _vehicleType.text.trim(),
      vehicleId: int.tryParse(_vehicleId.text.trim()),
      isActive: _isActive,
      additionalInfo: _additionalInfo.text.trim().isEmpty ? null : _additionalInfo.text.trim(),
    );
    await ref.read(companyControllerProvider.notifier).createSchedule(schedule);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.success)));
    Navigator.pop(context);
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
      appBar: AppBar(title: const Text(AppStrings.createTrip), actions: [
        IconButton(onPressed: _save, icon: const Icon(Icons.save))
      ]),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(controller: _origin, decoration: const InputDecoration(labelText: AppStrings.origin), validator: _req),
              TextFormField(controller: _destination, decoration: const InputDecoration(labelText: AppStrings.destination), validator: _req),
              TextFormField(
                controller: _departure,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: AppStrings.departureTimeIso,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.event),
                    onPressed: () => _pickDateTime(isDeparture: true),
                    tooltip: AppStrings.pickDate,
                  ),
                ),
                validator: _req,
              ),
              TextFormField(
                controller: _arrival,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: AppStrings.arrivalTimeIso,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.event),
                    onPressed: () => _pickDateTime(isDeparture: false),
                    tooltip: AppStrings.pickDate,
                  ),
                ),
                validator: _req,
              ),
              TextFormField(controller: _price, decoration: const InputDecoration(labelText: AppStrings.price), keyboardType: TextInputType.number),
              TextFormField(controller: _availableSeats, decoration: const InputDecoration(labelText: AppStrings.availableSeats), keyboardType: TextInputType.number),
              TextFormField(controller: _totalSeats, decoration: const InputDecoration(labelText: AppStrings.totalSeats), keyboardType: TextInputType.number),
              TextFormField(controller: _vehicleType, decoration: const InputDecoration(labelText: AppStrings.vehicleType)),
              TextFormField(controller: _vehicleId, decoration: const InputDecoration(labelText: AppStrings.vehicleId), keyboardType: TextInputType.number),
              TextFormField(controller: _additionalInfo, decoration: const InputDecoration(labelText: AppStrings.additionalInfo)),
              const SizedBox(height: 12),
              SwitchListTile(title: const Text(AppStrings.active), value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
            ],
          ),
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? AppStrings.required : null;
}