import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/viaje_controller.dart';
import '../../../controllers/empresa_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/viaje_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/validators.dart';

class ViajeRegistrationScreen extends StatefulWidget {
  const ViajeRegistrationScreen({super.key});

  @override
  State<ViajeRegistrationScreen> createState() => _ViajeRegistrationScreenState();
}

class _ViajeRegistrationScreenState extends State<ViajeRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rutaIdController = TextEditingController();
  final _vehiculoIdController = TextEditingController();
  final _conductorIdController = TextEditingController();
  final _precioController = TextEditingController();
  final _cuposDisponiblesController = TextEditingController();
  final _observacionesController = TextEditingController();

  DateTime _fechaSalida = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaSalida = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _horaLlegadaEstimada;
  ViajeStatus _estado = ViajeStatus.programado;

  @override
  void dispose() {
    _rutaIdController.dispose();
    _vehiculoIdController.dispose();
    _conductorIdController.dispose();
    _precioController.dispose();
    _cuposDisponiblesController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Viaje'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ViajeController>(
        builder: (context, viajeController, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),
                  _buildScheduleSection(),
                  const SizedBox(height: 24),
                  _buildCapacitySection(),
                  const SizedBox(height: 24),
                  _buildObservationsSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(viajeController),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Información del Viaje',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Complete la información básica del viaje programado.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Básica',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _rutaIdController,
              label: 'ID de Ruta',
              hint: 'Ingrese el ID de la ruta',
              prefixIcon: Icons.route,
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _vehiculoIdController,
              label: 'ID de Vehículo',
              hint: 'Ingrese el ID del vehículo',
              prefixIcon: Icons.directions_bus,
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _conductorIdController,
              label: 'ID de Conductor (Opcional)',
              hint: 'Ingrese el ID del conductor',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),
            CustomDropdown<ViajeStatus>(
              value: _estado,
              label: 'Estado del Viaje',
              items: ViajeStatus.values.map((estado) {
                return DropdownMenuItem(
                  value: estado,
                  child: Text(_getEstadoText(estado)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _estado = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horarios',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectFechaSalida,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fecha de Salida',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${_fechaSalida.day}/${_fechaSalida.month}/${_fechaSalida.year}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectHoraSalida,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hora de Salida',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _horaSalida.format(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectHoraLlegadaEstimada,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hora de Llegada Estimada (Opcional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _horaLlegadaEstimada?.format(context) ?? 'No definida',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (_horaLlegadaEstimada != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _horaLlegadaEstimada = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capacidad y Precio',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _cuposDisponiblesController,
                    label: 'Cupos Disponibles',
                    hint: 'Ej: 40',
                    prefixIcon: Icons.airline_seat_recline_normal,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final cupos = int.tryParse(value);
                      if (cupos == null || cupos <= 0) {
                        return 'Debe ser un número mayor a 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _precioController,
                    label: 'Precio por Asiento',
                    hint: 'Ej: 25000',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final precio = double.tryParse(value);
                      if (precio == null || precio <= 0) {
                        return 'Debe ser un número mayor a 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Observaciones',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _observacionesController,
              label: 'Observaciones (Opcional)',
              hint: 'Ingrese observaciones adicionales sobre el viaje',
              prefixIcon: Icons.note,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ViajeController viajeController) {
    return Column(
      children: [
        CustomButton(
          text: 'Registrar Viaje',
          onPressed: viajeController.isLoading ? null : _registrarViaje,
          isLoading: viajeController.isLoading,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Future<void> _selectFechaSalida() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSalida,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _fechaSalida) {
      setState(() {
        _fechaSalida = picked;
      });
    }
  }

  Future<void> _selectHoraSalida() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaSalida,
    );
    if (picked != null && picked != _horaSalida) {
      setState(() {
        _horaSalida = picked;
      });
    }
  }

  Future<void> _selectHoraLlegadaEstimada() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaLlegadaEstimada ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _horaLlegadaEstimada = picked;
      });
    }
  }

  String _getEstadoText(ViajeStatus estado) {
    switch (estado) {
      case ViajeStatus.programado:
        return 'Programado';
      case ViajeStatus.enCurso:
        return 'En Curso';
      case ViajeStatus.completado:
        return 'Completado';
      case ViajeStatus.cancelado:
        return 'Cancelado';
    }
  }

  Future<void> _registrarViaje() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    final empresaController = Provider.of<EmpresaController>(context, listen: false);
    final viajeController = Provider.of<ViajeController>(context, listen: false);

    // Obtener empresa ID
    String? empresaId;
    if (authController.isEmpresa) {
      empresaId = authController.user?.id;
    } else {
      empresaId = empresaController.empresa?.id;
    }

    if (empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la información de la empresa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Crear objeto viaje
    final viaje = ViajeModel(
      id: '', // Se generará en el servidor
      rutaId: _rutaIdController.text.trim(),
      empresaId: empresaId,
      vehiculoId: _vehiculoIdController.text.trim(),
      conductorId: _conductorIdController.text.trim().isEmpty 
          ? null 
          : _conductorIdController.text.trim(),
      fechaSalida: _fechaSalida,
      horaSalida: DateTime(2000, 1, 1, _horaSalida.hour, _horaSalida.minute),
      horaLlegadaEstimada: _horaLlegadaEstimada != null
          ? DateTime(2000, 1, 1, _horaLlegadaEstimada!.hour, _horaLlegadaEstimada!.minute)
          : null,
      precio: double.parse(_precioController.text),
      cuposDisponibles: int.parse(_cuposDisponiblesController.text),
      estado: _estado,
      observaciones: _observacionesController.text.trim().isEmpty 
          ? null 
          : _observacionesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Validar datos
    final validationError = viajeController.validarDatosViaje(viaje);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Registrar viaje
    final success = await viajeController.crearViaje(viaje);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viaje registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viajeController.error ?? 'Error al registrar viaje'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}