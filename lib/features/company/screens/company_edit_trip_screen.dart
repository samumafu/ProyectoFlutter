import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // Necesario para un mejor formato de fecha/hora

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
  static const Color _primaryColor = Color(0xFF1E88E5); // Azul Corporativo
  static const Color _secondaryColor = Color(0xFF00C853); // Verde (Éxito/Guardar)
  static const Color _backgroundColor = Color(0xFFF0F4F8); // Fondo claro y suave

  @override
  void initState() {
    super.initState();
    _s = widget.schedule as CompanySchedule;
    _origin = TextEditingController(text: _s.origin);
    _destination = TextEditingController(text: _s.destination);
    // Usar formato más legible para la visualización (aunque se guarda en ISO)
    _departure = TextEditingController(text: _s.departureTime); 
    _arrival = TextEditingController(text: _s.arrivalTime);
    _price = TextEditingController(text: _s.price.toStringAsFixed(2)); // Mostrar precio con 2 decimales
    _availableSeats = TextEditingController(text: _s.availableSeats.toString());
    _totalSeats = TextEditingController(text: _s.totalSeats.toString());
    _vehicleType = TextEditingController(text: _s.vehicleType ?? '');
    _vehicleId = TextEditingController(text: _s.vehicleId ?? '');
    
    // Formatear JSON de forma legible
    try {
        _additionalInfo = TextEditingController(text: const JsonEncoder.withIndent('  ').convert(_s.additionalInfo ?? {}));
    } catch (_) {
        _additionalInfo = TextEditingController(text: jsonEncode(_s.additionalInfo ?? {}));
    }

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
    
    // Tratar de parsear el texto actual del campo
    DateTime? currentDateTime;
    try {
      // Intenta parsear desde ISO (que es como se guarda)
      currentDateTime = DateTime.parse((isDeparture ? _departure.text : _arrival.text).trim());
    } catch (_) {
      // Si falla, usa 'now'
      currentDateTime = now;
    }
    
    // Aseguramos que la fecha mínima sea HOY
    final firstDate = DateTime(now.year, now.month, now.day);
    
    // La fecha inicial debe ser la fecha actual del campo o 'now', sin ser anterior al primer día.
    final initialDate = currentDateTime!.isAfter(firstDate) ? currentDateTime : firstDate;


    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      helpText: AppStrings.pickDate,
    );
    if (date == null) return;
    
    TimeOfDay initialTime = TimeOfDay.fromDateTime(currentDateTime!.isAfter(now) ? currentDateTime : now);
    
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: AppStrings.pickTime,
    );
    if (time == null) return;
    
    final selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // Validación final para asegurar que no se seleccione hora en el pasado
    if (selectedDateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
        if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('La hora y fecha seleccionadas deben ser futuras.'),
                backgroundColor: Colors.red,
            ));
        }
        return;
    }
    
    // Guardar en formato ISO (requerido por la lógica de negocio)
    final iso = selectedDateTime.toIso8601String(); 
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
      backgroundColor: _backgroundColor, // Fondo más limpio
      appBar: AppBar(
        backgroundColor: _primaryColor, // Color principal para el AppBar
        elevation: 0,
        centerTitle: true,
        title: const Text(AppStrings.editTrip, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white), // Íconos blancos
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check_circle_outline, size: 28),
            tooltip: 'Guardar cambios',
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 780;
            
            // Widget para agrupar campos y dar estilo de tarjeta
            Widget buildSection({required String title, required List<Widget> fields, required IconData icon}) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de Sección estilizado
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Icon(icon, color: _primaryColor, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    // Usar un Container sutil como tarjeta para la sección
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: fields,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 32 : 16), 
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column( // Eliminamos el Card exterior y usamos secciones internas con Cards
                    children: [
                      // 1. Origen y Destino (Route Info)
                      buildSection(
                        title: 'Ruta del Viaje',
                        icon: Icons.alt_route,
                        fields: [
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(child: TextFormField(controller: _origin, decoration: _inputDeco(AppStrings.origin, Icons.map_outlined), validator: _req)),
                                    const SizedBox(width: 16),
                                    Expanded(child: TextFormField(controller: _destination, decoration: _inputDeco(AppStrings.destination, Icons.location_on_outlined), validator: _req)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(controller: _origin, decoration: _inputDeco(AppStrings.origin, Icons.map_outlined), validator: _req),
                                    const SizedBox(height: 16),
                                    TextFormField(controller: _destination, decoration: _inputDeco(AppStrings.destination, Icons.location_on_outlined), validator: _req),
                                  ],
                                ),
                        ],
                      ),
                      
                      // 2. Tiempos (Schedule)
                      buildSection(
                        title: 'Horario',
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
                        title: 'Capacidad y Tarifa',
                        icon: Icons.attach_money_rounded,
                        fields: [
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(child: TextFormField(controller: _price, decoration: _inputDeco(AppStrings.price, Icons.paid_outlined).copyWith(prefixText: '\$'), keyboardType: TextInputType.number, validator: _validateDouble)),
                                    const SizedBox(width: 16),
                                    Expanded(child: TextFormField(controller: _availableSeats, decoration: _inputDeco(AppStrings.availableSeats, Icons.event_seat_outlined), keyboardType: TextInputType.number, validator: _validateInt)),
                                    const SizedBox(width: 16),
                                    Expanded(child: TextFormField(controller: _totalSeats, decoration: _inputDeco(AppStrings.totalSeats, Icons.group_outlined), keyboardType: TextInputType.number, validator: _validateInt)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(controller: _price, decoration: _inputDeco(AppStrings.price, Icons.paid_outlined).copyWith(prefixText: '\$'), keyboardType: TextInputType.number, validator: _validateDouble),
                                    const SizedBox(height: 16),
                                    TextFormField(controller: _availableSeats, decoration: _inputDeco(AppStrings.availableSeats, Icons.event_seat_outlined), keyboardType: TextInputType.number, validator: _validateInt),
                                    const SizedBox(height: 16),
                                    TextFormField(controller: _totalSeats, decoration: _inputDeco(AppStrings.totalSeats, Icons.group_outlined), keyboardType: TextInputType.number, validator: _validateInt),
                                  ],
                                ),
                        ],
                      ),

                      // 4. Vehículo y Conductor
                      buildSection(
                        title: 'Asignación de Unidad',
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
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: _inputDeco(AppStrings.assignDriver, Icons.person_outline),
                            value: _assignedDriverId,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('No Assigned Driver', style: TextStyle(color: Colors.grey))),
                              ...ref.watch(companyControllerProvider).drivers.map((d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              )).toList(),
                            ],
                            onChanged: (v) => setState(() => _assignedDriverId = v),
                            isExpanded: true,
                            menuMaxHeight: 300,
                          ),
                        ],
                      ),

                      // 5. Info Adicional y Estado (Settings)
                      buildSection(
                        title: 'Configuración Adicional',
                        icon: Icons.tune,
                        fields: [
                          TextFormField(
                            controller: _additionalInfo,
                            decoration: _inputDeco(AppStrings.additionalInfo, Icons.info_outline)
                                .copyWith(hintText: 'Ej. {"paradas": ["cali", "armenia"]}', alignLabelWithHint: true),
                            maxLines: 5,
                            minLines: 3,
                            validator: _validateJson,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          // Diseño de SwitchListTile mejorado
                          Container(
                            decoration: BoxDecoration(
                              color: _isActive ? _secondaryColor.withOpacity(0.1) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _isActive ? _secondaryColor : Colors.grey.shade300),
                            ),
                            child: SwitchListTile(
                              title: const Text(AppStrings.active, style: TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(_isActive ? 'Programación activa y visible para pasajeros.' : 'Programación inactiva y oculta.'),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                              activeColor: _secondaryColor,
                              tileColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check_circle_outline, size: 24),
                        label: const Text('GUARDAR CAMBIOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _secondaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                          minimumSize: Size(isWide ? 400 : double.infinity, 50),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
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
    final icon = isDeparture ? Icons.departure_board : Icons.access_time_filled;
    final controller = isDeparture ? _departure : _arrival;
    
    // Formatear el texto para la visualización (si es una fecha ISO válida)
    String displayTime = controller.text.isNotEmpty
        ? _formatIsoToDateTime(controller.text)
        : '';

    return TextFormField(
      controller: TextEditingController(text: displayTime), // Usar controller temporal para la visualización
      readOnly: true,
      decoration: _inputDeco(label, icon).copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month, color: _primaryColor),
          onPressed: () => _pickDateTime(isDeparture: isDeparture),
          tooltip: AppStrings.pickDate,
        ),
      ),
      validator: _req,
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
  }

  // --- Helper para Formato (Diseño) ---
  String _formatIsoToDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy HH:mm').format(dateTime);
    } catch (_) {
      return isoString; // Retorna el ISO si falla el parseo
    }
  }


  // --- Validation Helpers (Lógica INTACTA) ---
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