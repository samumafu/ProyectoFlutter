// File: lib/features/company/screens/company_create_trip_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/core/data/narino_municipalities.dart'; 
import 'dart:convert';

// Lista de tipos de vehículo para el Dropdown
const List<String> _vehicleTypes = ['Bus', 'Van', 'SUV', 'Minibus', 'Truck'];
const Color _primaryColor = Color(0xFF1E88E5); 

class CompanyCreateTripScreen extends ConsumerStatefulWidget {
  const CompanyCreateTripScreen({super.key});

  @override
  ConsumerState<CompanyCreateTripScreen> createState() => _CompanyCreateTripScreenState();
}

class _CompanyCreateTripScreenState extends ConsumerState<CompanyCreateTripScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedOrigin;
  String? _selectedDestination;
  String? _selectedVehicleType; 
  
  final _departure = TextEditingController();
  final _arrival = TextEditingController();
  final _price = TextEditingController();
  final _availableSeats = TextEditingController();
  final _totalSeats = TextEditingController();
  final _vehicleId = TextEditingController();
  final _additionalInfo = TextEditingController();
  bool _isActive = true;

  DateTime? _departureDateTime;
  DateTime? _arrivalDateTime;

  @override
  void dispose() {
    _departure.dispose();
    _arrival.dispose();
    _price.dispose();
    _availableSeats.dispose();
    _totalSeats.dispose();
    _vehicleId.dispose();
    _additionalInfo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validate form and ensure dropdowns are selected
    if (!_formKey.currentState!.validate() || _selectedOrigin == null || _selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please correct the highlighted errors.')));
      return;
    }

    final companyId = ref.read(companyControllerProvider).company?.id;
    if (companyId == null) return;
    
    final schedule = CompanySchedule(
      id: '',
      companyId: companyId,
      origin: _selectedOrigin!, 
      destination: _selectedDestination!,
      departureTime: _departure.text.trim(),
      arrivalTime: _arrival.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0,
      availableSeats: int.tryParse(_availableSeats.text.trim()) ?? 0,
      totalSeats: int.tryParse(_totalSeats.text.trim()) ?? 0,
      vehicleType: _selectedVehicleType, 
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.actionFailed}: $e')));
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
    final today = DateTime(now.year, now.month, now.day);
    
    // --- 1. Pick Date ---
    DateTime initialDate;
    DateTime firstDateRestriction;

    if (isDeparture) {
      initialDate = _departureDateTime ?? now;
      // RULE 1: Departure's first selectable day is today.
      firstDateRestriction = today; 
    } else {
      // RULE 2: Arrival's first selectable day is the Departure date.
      if (_departureDateTime == null) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please set the Departure time first.')),
          );
        }
        return;
      }
      firstDateRestriction = DateTime(_departureDateTime!.year, _departureDateTime!.month, _departureDateTime!.day);
      initialDate = _arrivalDateTime ?? _departureDateTime!.add(const Duration(hours: 1));
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDateRestriction, // <-- APPLYING STRICT CALENDAR RESTRICTION HERE
      lastDate: DateTime(now.year + 2),
      helpText: AppStrings.pickDate,
    );
    if (date == null) return;

    // --- 2. Pick Time ---
    TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDate);

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: AppStrings.pickTime,
    );
    if (time == null) return;
    
    final pickedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    
    // --- 3. Core Logic: Departure Validation (Today + Future Time) ---
    if (isDeparture) {
      final isPickedDateToday = pickedDateTime.year == now.year && 
                                pickedDateTime.month == now.month && 
                                pickedDateTime.day == now.day;

      // RULE 1.1: If the date is TODAY, the time must be AFTER the current time.
      if (isPickedDateToday && pickedDateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Departure time for today must be after the current time (now).')),
          );
        }
        return;
      }
      _departureDateTime = pickedDateTime;
    } else {
      // --- 4. Core Logic: Arrival Validation (Must be after Departure) ---
      
      // RULE 2.1: Arrival time must be strictly after the Departure time.
      if (pickedDateTime.isBefore(_departureDateTime!.add(const Duration(minutes: 1)))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arrival time must be strictly after the Departure time.')),
          );
        }
        return;
      }
      _arrivalDateTime = pickedDateTime;
    }

    // Convert DateTime to ISO string format and update UI
    final iso = ref.read(companyControllerProvider.notifier).formatIso(
      DateTime(pickedDateTime.year, pickedDateTime.month, pickedDateTime.day), 
      TimeOfDay.fromDateTime(pickedDateTime)
    );

    setState(() {
      if (isDeparture) {
        _departure.text = iso;
        // Check if setting a new departure time invalidates the existing arrival time
        if (_arrivalDateTime != null && _arrivalDateTime!.isBefore(_departureDateTime!.add(const Duration(minutes: 1)))) {
          _arrival.clear();
          _arrivalDateTime = null;
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arrival time reset as it was before the new Departure time.')),
          );
        }
      } else {
        _arrival.text = iso;
      }
      _formKey.currentState!.validate(); // Trigger validation for immediate feedback
    });
  }

  Widget _buildMunicipalityDropdown({
    required String label,
    String? value,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: deco(label).copyWith(
        prefixIcon: const Icon(Icons.location_city_outlined, color: _primaryColor),
      ),
      value: value,
      items: narinoMunicipalities.map((municipio) {
        return DropdownMenuItem(
          value: municipio,
          child: Text(municipio),
        );
      }).toList(),
      onChanged: onChanged,
      validator: _req,
      isExpanded: true,
      menuMaxHeight: 300,
    );
  }

  Widget _buildVehicleTypeDropdown({
    required String label,
    String? value,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: deco(label).copyWith(
        prefixIcon: const Icon(Icons.directions_bus_outlined, color: _primaryColor),
      ),
      value: value,
      items: _vehicleTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: onChanged,
      validator: _req,
      isExpanded: true,
      menuMaxHeight: 300,
    );
  }

  InputDecoration deco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)), 
      borderSide: BorderSide(color: _primaryColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(AppStrings.createTrip, style: TextStyle(color: Colors.black87)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: _save, 
              icon: const Icon(Icons.send_outlined, size: 20), 
              label: const Text('Save Trip'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 780;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Card(
                    elevation: 8, 
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24), 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trip Route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const Divider(height: 20, thickness: 1),
                          // --- ORIGIN / DESTINATION DROPDOWNS ---
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: _buildMunicipalityDropdown(
                                        label: AppStrings.origin,
                                        value: _selectedOrigin,
                                        onChanged: (v) => setState(() => _selectedOrigin = v),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildMunicipalityDropdown(
                                        label: AppStrings.destination,
                                        value: _selectedDestination,
                                        onChanged: (v) => setState(() => _selectedDestination = v),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildMunicipalityDropdown(
                                      label: AppStrings.origin,
                                      value: _selectedOrigin,
                                      onChanged: (v) => setState(() => _selectedOrigin = v),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildMunicipalityDropdown(
                                      label: AppStrings.destination,
                                      value: _selectedDestination,
                                      onChanged: (v) => setState(() => _selectedDestination = v),
                                    ),
                                  ],
                                ),
                          
                          const SizedBox(height: 24),
                          const Text('Schedule & Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const Divider(height: 20, thickness: 1),
                          // --- TIME FIELDS ---
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _departure,
                                        readOnly: true,
                                        decoration: deco(AppStrings.departureTimeIso).copyWith(
                                          prefixIcon: const Icon(Icons.departure_board_outlined, color: _primaryColor),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.event),
                                            onPressed: () => _pickDateTime(isDeparture: true),
                                            tooltip: AppStrings.pickDate,
                                          ),
                                        ),
                                        validator: (v) {
                                          if (_req(v) != null) return _req(v);
                                          final now = DateTime.now();
                                          // Validation check ensures time is always future if today, or any time if a future date.
                                          if (_departureDateTime == null || (_departureDateTime!.day == now.day && _departureDateTime!.isBefore(now.subtract(const Duration(minutes: 1))))) {
                                            return 'Departure must be after the current time.';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _arrival,
                                        readOnly: true,
                                        decoration: deco(AppStrings.arrivalTimeIso).copyWith(
                                          prefixIcon: const Icon(Icons.access_time_outlined, color: _primaryColor),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.event),
                                            onPressed: () => _pickDateTime(isDeparture: false),
                                            tooltip: AppStrings.pickDate,
                                          ),
                                        ),
                                        validator: (v) {
                                          if (_req(v) != null) return _req(v);
                                          // Arrival must be AT LEAST one minute after departure
                                          if (_arrivalDateTime == null || _departureDateTime == null || _arrivalDateTime!.isBefore(_departureDateTime!.add(const Duration(minutes: 1)))) {
                                            return 'Arrival must be strictly after Departure time.';
                                          }
                                          return null;
                                        },
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
                                        prefixIcon: const Icon(Icons.departure_board_outlined, color: _primaryColor),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.event),
                                          onPressed: () => _pickDateTime(isDeparture: true),
                                          tooltip: AppStrings.pickDate,
                                        ),
                                      ),
                                      validator: (v) {
                                          if (_req(v) != null) return _req(v);
                                          final now = DateTime.now();
                                          if (_departureDateTime == null || (_departureDateTime!.day == now.day && _departureDateTime!.isBefore(now.subtract(const Duration(minutes: 1))))) {
                                            return 'Departure must be after the current time.';
                                          }
                                          return null;
                                        },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _arrival,
                                      readOnly: true,
                                      decoration: deco(AppStrings.arrivalTimeIso).copyWith(
                                        prefixIcon: const Icon(Icons.access_time_outlined, color: _primaryColor),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.event),
                                          onPressed: () => _pickDateTime(isDeparture: false),
                                          tooltip: AppStrings.pickDate,
                                        ),
                                      ),
                                      validator: (v) {
                                          if (_req(v) != null) return _req(v);
                                          if (_arrivalDateTime == null || _departureDateTime == null || _arrivalDateTime!.isBefore(_departureDateTime!.add(const Duration(minutes: 1)))) {
                                            return 'Arrival must be strictly after Departure time.';
                                          }
                                          return null;
                                        },
                                    ),
                                  ],
                                ),
                          
                          const SizedBox(height: 12),
                          // --- PRICE / SEATS FIELDS ---
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(child: TextFormField(controller: _price, decoration: deco(AppStrings.price).copyWith(prefixIcon: const Icon(Icons.money, color: _primaryColor)), keyboardType: TextInputType.number, validator: _req)),
                                    const SizedBox(width: 16),
                                    Expanded(child: TextFormField(controller: _availableSeats, decoration: deco(AppStrings.availableSeats).copyWith(prefixIcon: const Icon(Icons.event_seat_outlined, color: _primaryColor)), keyboardType: TextInputType.number, validator: _req)),
                                    const SizedBox(width: 16),
                                    Expanded(child: TextFormField(controller: _totalSeats, decoration: deco(AppStrings.totalSeats).copyWith(prefixIcon: const Icon(Icons.groups_2_outlined, color: _primaryColor)), keyboardType: TextInputType.number, validator: _req)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(controller: _price, decoration: deco(AppStrings.price).copyWith(prefixIcon: const Icon(Icons.money, color: _primaryColor)), keyboardType: TextInputType.number, validator: _req),
                                    const SizedBox(height: 12),
                                    TextFormField(controller: _availableSeats, decoration: deco(AppStrings.availableSeats).copyWith(prefixIcon: const Icon(Icons.event_seat_outlined, color: _primaryColor)), keyboardType: TextInputType.number, validator: _req),
                                    const SizedBox(height: 12),
                                    TextFormField(controller: _totalSeats, decoration: deco(AppStrings.totalSeats).copyWith(prefixIcon: const Icon(Icons.groups_2_outlined, color: _primaryColor)), keyboardType: TextInputType.number, validator: _req),
                                  ],
                                ),

                          const SizedBox(height: 24),
                          const Text('Vehicle Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const Divider(height: 20, thickness: 1),
                          // --- VEHICLE TYPE DROPDOWN & ID FIELD ---
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: _buildVehicleTypeDropdown(
                                        label: AppStrings.vehicleType,
                                        value: _selectedVehicleType,
                                        onChanged: (v) => setState(() => _selectedVehicleType = v),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _vehicleId, 
                                        decoration: deco(AppStrings.vehicleId).copyWith(prefixIcon: const Icon(Icons.badge, color: _primaryColor)), 
                                        keyboardType: TextInputType.text
                                      )
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildVehicleTypeDropdown(
                                      label: AppStrings.vehicleType,
                                      value: _selectedVehicleType,
                                      onChanged: (v) => setState(() => _selectedVehicleType = v),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _vehicleId, 
                                      decoration: deco(AppStrings.vehicleId).copyWith(prefixIcon: const Icon(Icons.badge, color: _primaryColor)), 
                                      keyboardType: TextInputType.text
                                    ),
                                  ],
                                ),
                          
                          // --- ADDITIONAL INFO / SWITCH ---
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _additionalInfo, 
                            decoration: deco(AppStrings.additionalInfo).copyWith(
                              prefixIcon: const Icon(Icons.info_outline, color: _primaryColor),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            keyboardType: TextInputType.multiline,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: SwitchListTile(
                              title: const Text(AppStrings.active, style: TextStyle(fontWeight: FontWeight.w500)), 
                              value: _isActive, 
                              onChanged: (v) => setState(() => _isActive = v),
                              secondary: Icon(
                                _isActive ? Icons.check_circle : Icons.pause_circle_outline, 
                                color: _isActive ? Colors.green : Colors.orange,
                              ),
                              tileColor: Colors.grey.shade50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                            ),
                          ),
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