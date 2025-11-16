import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';

class CompanyEditTripScreen extends ConsumerStatefulWidget {
  final Object? schedule;
  const CompanyEditTripScreen({super.key, this.schedule});

  @override
  ConsumerState<CompanyEditTripScreen> createState() => _CompanyEditTripScreenState();
}

class _CompanyEditTripScreenState extends ConsumerState<CompanyEditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late CompanySchedule _s;

  late final TextEditingController _origin;
  late final TextEditingController _destination;
  late final TextEditingController _departure;
  late final TextEditingController _arrival;
  late final TextEditingController _price;
  late final TextEditingController _availableSeats;
  late final TextEditingController _totalSeats;
  late final TextEditingController _vehicleType;
  late final TextEditingController _vehicleId;
  late final TextEditingController _additionalInfo;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _s = widget.schedule as CompanySchedule;
    _origin = TextEditingController(text: _s.origin);
    _destination = TextEditingController(text: _s.destination);
    _departure = TextEditingController(text: _s.departureTime);
    _arrival = TextEditingController(text: _s.arrivalTime);
    _price = TextEditingController(text: _s.price.toString());
    _availableSeats = TextEditingController(text: _s.availableSeats.toString());
    _totalSeats = TextEditingController(text: _s.totalSeats.toString());
    _vehicleType = TextEditingController(text: _s.vehicleType ?? '');
    _vehicleId = TextEditingController(text: _s.vehicleId?.toString() ?? '');
    _additionalInfo = TextEditingController(text: _s.additionalInfo ?? '');
    _isActive = _s.isActive;
  }

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
    final updated = CompanySchedule(
      id: _s.id,
      companyId: _s.companyId,
      origin: _origin.text.trim(),
      destination: _destination.text.trim(),
      departureTime: _departure.text.trim(),
      arrivalTime: _arrival.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? _s.price,
      availableSeats: int.tryParse(_availableSeats.text.trim()) ?? _s.availableSeats,
      totalSeats: int.tryParse(_totalSeats.text.trim()) ?? _s.totalSeats,
      vehicleType: _vehicleType.text.trim().isEmpty ? null : _vehicleType.text.trim(),
      vehicleId: int.tryParse(_vehicleId.text.trim()),
      isActive: _isActive,
      additionalInfo: _additionalInfo.text.trim().isEmpty ? null : _additionalInfo.text.trim(),
    );
    await ref.read(companyControllerProvider.notifier).updateSchedule(updated);
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
      appBar: AppBar(title: const Text(AppStrings.editTrip), actions: [
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