import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'dart:convert';

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
  String? _assignedDriverId;

  // Colores para el diseño
  static const Color _primaryColor = Color(0xFF1E88E5);
  static const Color _secondaryColor = Color(0xFF00C853);

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
    _vehicleId = TextEditingController(text: _s.vehicleId ?? '');
    _additionalInfo = TextEditingController(text: jsonEncode(_s.additionalInfo ?? {}));
    _isActive = _s.isActive;
    _assignedDriverId = _s.assignedDriverId;
    Future.microtask(() async {
      final company = ref.read(companyControllerProvider).company;
      if (company != null && ref.read(companyControllerProvider).drivers.isEmpty) {
        await ref.read(companyControllerProvider.notifier).loadDrivers();
      }
    });
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
      // Se mantiene la lógica de fallback si el parseo falla
      price: double.tryParse(_price.text.trim()) ?? _s.price,
      availableSeats: int.tryParse(_availableSeats.text.trim()) ?? _s.availableSeats,
      totalSeats: int.tryParse(_totalSeats.text.trim()) ?? _s.totalSeats,
      vehicleType: _vehicleType.text.trim().isEmpty ? null : _vehicleType.text.trim(),
      vehicleId: _vehicleId.text.trim().isEmpty ? null : _vehicleId.text.trim(),
      isActive: _isActive,
      additionalInfo: _parseJsonOrKeep(_s.additionalInfo, _additionalInfo.text.trim()),
      assignedDriverId: _assignedDriverId,
      assignmentStatus: _assignedDriverId != _s.assignedDriverId ? 'pending' : _s.assignmentStatus,
    );
    try {
      await ref.read(companyControllerProvider.notifier).updateSchedule(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.success)));
      Navigator.of(context).pop(); 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.actionFailed}: $e')));
    }
  }

  // Lógica de selección de fecha/hora MEJORADA (y FIX de compilación)
  Future<void> _pickDateTime({required bool isDeparture}) async {
    final now = DateTime.now();
    
    // Si el campo tiene un valor previo, úsalo como valor inicial (si es válido)
    final initialDate = (isDeparture ? _departure.text : _arrival.text).isNotEmpty
        ? DateTime.tryParse((isDeparture ? _departure.text : _arrival.text).trim()) ?? now
        : now;
    
    // Aseguramos que la fecha mínima sea HOY, para no programar viajes en el pasado
    final firstDate = DateTime(now.year, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      // Usar initialDate si es posterior a firstDate, si no, usar firstDate
      initialDate: initialDate.isAfter(firstDate) ? initialDate : firstDate,
      firstDate: firstDate, // FIX: Solo fechas de hoy en adelante
      lastDate: DateTime(now.year + 5), // Límite de 5 años
      helpText: AppStrings.pickDate,
    );
    if (date == null) return;
    
    // Si la fecha seleccionada es HOY, la hora inicial debe ser la actual
    // Si no es hoy, la hora inicial es la hora actual del campo o 8:00
    TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDate.isAfter(now) ? initialDate : now);
    
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: AppStrings.pickTime,
    );
    if (time == null) return;
    
    final selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // FIX ADICIONAL: Validación final para asegurar que no se seleccione hora en el pasado
    if (selectedDateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
        if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('La hora y fecha seleccionadas deben ser futuras.'),
                backgroundColor: Colors.red,
            ));
        }
        return;
    }
    
    final iso = ref.read(companyControllerProvider.notifier).formatIso(date, time);
    setState(() {
      if (isDeparture) {
        _departure.text = iso;
      } else {
        _arrival.text = iso;
      }
    });
  }
  
  // FIX: Método _inputDeco movido fuera del build para ser accesible
  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primaryColor, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFF4), // Fondo más limpio
      appBar: AppBar(
        backgroundColor: _primaryColor, // Color principal para el AppBar
        elevation: 0,
        centerTitle: true,
        title: const Text(AppStrings.editTrip, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white), // Íconos blancos
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Guardar',
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 780;
            
            // Widget para agrupar campos y dar estilo de tarjeta
            // Se usa String literal para el título ya que AppStrings.xxx no existe.
            Widget buildSection({required String title, required List<Widget> fields, required IconData icon}) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: _primaryColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.grey, height: 20, thickness: 0.5),
                    ...fields,
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              // FIX: Se elimina 'const' para permitir la expresión condicional
              padding: EdgeInsets.all(isWide ? 32 : 16), 
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Card(
                    elevation: 8, // Más elevación para un efecto 3D
                    shadowColor: _primaryColor.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Más redondeado
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          // 1. Origen y Destino (Route Info)
                          buildSection(
                            title: 'Información de Ruta', // FIX: Usar String literal
                            icon: Icons.alt_route, // FIX: Ícono válido
                            fields: [
                              isWide
                                  ? Row(
                                      children: [
                                        // FIX: Íconos válidos
                                        Expanded(child: TextFormField(controller: _origin, decoration: _inputDeco(AppStrings.origin, Icons.map_outlined), validator: _req)),
                                        const SizedBox(width: 16),
                                        Expanded(child: TextFormField(controller: _destination, decoration: _inputDeco(AppStrings.destination, Icons.location_on_outlined), validator: _req)),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        // FIX: Íconos válidos
                                        TextFormField(controller: _origin, decoration: _inputDeco(AppStrings.origin, Icons.map_outlined), validator: _req),
                                        const SizedBox(height: 16),
                                        TextFormField(controller: _destination, decoration: _inputDeco(AppStrings.destination, Icons.location_on_outlined), validator: _req),
                                      ],
                                    ),
                            ],
                          ),
                          
                          // 2. Tiempos (Schedule)
                          buildSection(
                            title: 'Horario', // FIX: Usar String literal
                            icon: Icons.schedule,
                            fields: [
                              isWide
                                  ? Row(
                                      children: [
                                        Expanded(child: _buildDateTimePicker(isDeparture: true)),
                                        const SizedBox(width: 16),
                                        Expanded(child: _buildDateTimePicker(isDeparture: false)),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildDateTimePicker(isDeparture: true),
                                        const SizedBox(height: 16),
                                        _buildDateTimePicker(isDeparture: false),
                                      ],
                                    ),
                            ],
                          ),

                          // 3. Precios y Asientos (Capacity and Price)
                          buildSection(
                            title: 'Capacidad y Precio', // FIX: Usar String literal
                            icon: Icons.attach_money_rounded,
                            fields: [
                              isWide
                                  ? Row(
                                      children: [
                                        Expanded(child: TextFormField(controller: _price, decoration: _inputDeco(AppStrings.price, Icons.paid_outlined), keyboardType: TextInputType.number, validator: _validateDouble)),
                                        const SizedBox(width: 16),
                                        Expanded(child: TextFormField(controller: _availableSeats, decoration: _inputDeco(AppStrings.availableSeats, Icons.event_seat_outlined), keyboardType: TextInputType.number, validator: _validateInt)),
                                        const SizedBox(width: 16),
                                        Expanded(child: TextFormField(controller: _totalSeats, decoration: _inputDeco(AppStrings.totalSeats, Icons.group_outlined), keyboardType: TextInputType.number, validator: _validateInt)),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        TextFormField(controller: _price, decoration: _inputDeco(AppStrings.price, Icons.paid_outlined), keyboardType: TextInputType.number, validator: _validateDouble),
                                        const SizedBox(height: 16),
                                        TextFormField(controller: _availableSeats, decoration: _inputDeco(AppStrings.availableSeats, Icons.event_seat_outlined), keyboardType: TextInputType.number, validator: _validateInt),
                                        const SizedBox(height: 16),
                                        TextFormField(controller: _totalSeats, decoration: _inputDeco(AppStrings.totalSeats, Icons.group_outlined), keyboardType: TextInputType.number, validator: _validateInt),
                                      ],
                                    ),
                            ],
                          ),

                          // 4. Vehículo
                          buildSection(
                            title: AppStrings.vehicle,
                            icon: Icons.directions_bus_outlined,
                            fields: [
                              isWide
                                  ? Row(
                                      children: [
                                        Expanded(child: TextFormField(controller: _vehicleType, decoration: _inputDeco(AppStrings.vehicleType, Icons.style_outlined))),
                                        const SizedBox(width: 16),
                                        Expanded(child: TextFormField(controller: _vehicleId, decoration: _inputDeco(AppStrings.vehicleId, Icons.badge_outlined), keyboardType: TextInputType.text)),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        TextFormField(controller: _vehicleType, decoration: _inputDeco(AppStrings.vehicleType, Icons.style_outlined)),
                                        const SizedBox(height: 16),
                                        TextFormField(controller: _vehicleId, decoration: _inputDeco(AppStrings.vehicleId, Icons.badge_outlined), keyboardType: TextInputType.text),
                                      ],
                                    ),
                            ],
                          ),

                          // 5. Info Adicional y Estado (Settings)
                          buildSection(
                            title: 'Configuración', // FIX: Usar String literal
                            icon: Icons.tune,
                            fields: [
                              DropdownButtonFormField<String>(
                                decoration: _inputDeco(AppStrings.assignDriver, Icons.person_outline),
                                value: _assignedDriverId,
                                items: ref.watch(companyControllerProvider).drivers.map((d) => DropdownMenuItem(
                                      value: d.id,
                                      child: Text(d.name),
                                    )).toList(),
                                onChanged: (v) => setState(() => _assignedDriverId = v),
                                isExpanded: true,
                                menuMaxHeight: 300,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _additionalInfo,
                                decoration: _inputDeco(AppStrings.additionalInfo, Icons.info_outline)
                                    .copyWith(hintText: 'Ej. {"paradas": ["cali", "armenia"]}'),
                                maxLines: 3,
                                validator: _validateJson,
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: const Text(AppStrings.active, style: TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: Text(_isActive ? 'Programación activa y visible.' : 'Programación inactiva y oculta.'),
                                value: _isActive,
                                onChanged: (v) => setState(() => _isActive = v),
                                activeColor: _secondaryColor,
                                tileColor: Colors.grey.shade50,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.check_circle_outline, size: 24),
                            label: const Text('GUARDAR CAMBIOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          },
        ),
      ),
    );
  }

  // --- Widgets Helpers ---
  Widget _buildDateTimePicker({required bool isDeparture}) {
    final label = isDeparture ? AppStrings.departureTimeIso : AppStrings.arrivalTimeIso;
    // FIX: Íconos válidos
    final icon = isDeparture ? Icons.departure_board : Icons.access_time_filled;
    final controller = isDeparture ? _departure : _arrival;
    
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: _inputDeco(label, icon).copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, color: _primaryColor),
          onPressed: () => _pickDateTime(isDeparture: isDeparture),
          tooltip: AppStrings.pickDate,
        ),
      ),
      validator: _req,
    );
  }


  // --- Validation Helpers ---
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? AppStrings.required : null;
  
  String? _validateInt(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.required;
    if (int.tryParse(v) == null) return 'Debe ser un número entero.';
    return null;
  }
  
  String? _validateDouble(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.required;
    if (double.tryParse(v) == null) return 'Debe ser un número.';
    return null;
  }

  String? _validateJson(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(v);
      if (decoded is! Map<String, dynamic>) {
        return 'Debe ser un objeto JSON válido (ej. {"key": "value"}).';
      }
    } catch (e) {
      return 'Formato JSON inválido: $e';
    }
    return null;
  }
}

Map<String, dynamic>? _parseJsonOrKeep(Map<String, dynamic>? fallback, String s) {
  if (s.isEmpty) return fallback;
  try {
    final decoded = jsonDecode(s);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
  } catch (_) {}
  return fallback;
}