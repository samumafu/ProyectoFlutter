import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/vehiculo_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/empresa_controller.dart';
import '../../../models/vehiculo_model.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';

class VehiculoRegistrationScreen extends StatefulWidget {
  const VehiculoRegistrationScreen({super.key});

  @override
  State<VehiculoRegistrationScreen> createState() => _VehiculoRegistrationScreenState();
}

class _VehiculoRegistrationScreenState extends State<VehiculoRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controladores de texto
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _numeroInternoController = TextEditingController();
  final _colorController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Variables de estado
  TipoVehiculo _tipoSeleccionado = TipoVehiculo.bus;
  VehiculoStatus _estadoSeleccionado = VehiculoStatus.activo;
  DateTime? _fechaVencimientoSoat;
  DateTime? _fechaVencimientoRevision;
  DateTime? _fechaVencimientoOperacion;
  DateTime? _fechaVencimientoPoliza;

  bool _isLoading = false;

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _numeroInternoController.dispose();
    _colorController.dispose();
    _capacidadController.dispose();
    _observacionesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Vehículo'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<VehiculoController>(
        builder: (context, vehiculoController, child) {
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_bus,
                            size: 48,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nuevo Vehículo',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete la información del vehículo',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Información básica
                  _buildSectionCard(
                    'Información Básica',
                    Icons.info_outline,
                    [
                      CustomTextField(
                        controller: _placaController,
                        label: 'Placa',
                        hint: 'Ej: ABC123',
                        prefixIcon: Icons.confirmation_number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La placa es obligatoria';
                          }
                          if (value.length < 6) {
                            return 'La placa debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _marcaController,
                        label: 'Marca',
                        hint: 'Ej: Mercedes Benz',
                        prefixIcon: Icons.business,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La marca es obligatoria';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _modeloController,
                        label: 'Modelo',
                        hint: 'Ej: Sprinter',
                        prefixIcon: Icons.model_training,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El modelo es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _anioController,
                              label: 'Año',
                              hint: '2020',
                              prefixIcon: Icons.calendar_today,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El año es obligatorio';
                                }
                                final anio = int.tryParse(value);
                                if (anio == null || anio < 1900 || anio > DateTime.now().year + 1) {
                                  return 'Año no válido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _colorController,
                              label: 'Color',
                              hint: 'Blanco',
                              prefixIcon: Icons.palette,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Especificaciones técnicas
                  _buildSectionCard(
                    'Especificaciones Técnicas',
                    Icons.settings,
                    [
                      DropdownButtonFormField<TipoVehiculo>(
                        value: _tipoSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Vehículo',
                          prefixIcon: const Icon(Icons.directions_bus),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: TipoVehiculo.values.map((tipo) {
                          return DropdownMenuItem(
                            value: tipo,
                            child: Text(_getTipoVehiculoDisplayName(tipo)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _tipoSeleccionado = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _capacidadController,
                              label: 'Capacidad de Pasajeros',
                              hint: '20',
                              prefixIcon: Icons.people,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La capacidad es obligatoria';
                                }
                                final capacidad = int.tryParse(value);
                                if (capacidad == null || capacidad <= 0) {
                                  return 'Capacidad no válida';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _numeroInternoController,
                              label: 'Número Interno',
                              hint: '001',
                              prefixIcon: Icons.numbers,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El número interno es obligatorio';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<VehiculoStatus>(
                        value: _estadoSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Estado',
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: VehiculoStatus.values.map((estado) {
                          return DropdownMenuItem(
                            value: estado,
                            child: Text(_getEstadoDisplayName(estado)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _estadoSeleccionado = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Documentación
                  _buildSectionCard(
                    'Documentación (Opcional)',
                    Icons.description,
                    [
                      _buildDateField(
                        'Vencimiento SOAT',
                        _fechaVencimientoSoat,
                        (date) => setState(() => _fechaVencimientoSoat = date),
                        Icons.security,
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(
                        'Vencimiento Revisión Técnica',
                        _fechaVencimientoRevision,
                        (date) => setState(() => _fechaVencimientoRevision = date),
                        Icons.build,
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(
                        'Vencimiento Tarjeta de Operación',
                        _fechaVencimientoOperacion,
                        (date) => setState(() => _fechaVencimientoOperacion = date),
                        Icons.card_membership,
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(
                        'Vencimiento Póliza',
                        _fechaVencimientoPoliza,
                        (date) => setState(() => _fechaVencimientoPoliza = date),
                        Icons.shield,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Observaciones
                  _buildSectionCard(
                    'Observaciones',
                    Icons.note,
                    [
                      CustomTextField(
                        controller: _observacionesController,
                        label: 'Observaciones',
                        hint: 'Información adicional sobre el vehículo...',
                        prefixIcon: Icons.note_add,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancelar',
                          onPressed: () => Navigator.pop(context),
                          outlined: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          text: 'Registrar Vehículo',
                          onPressed: _isLoading ? null : _registrarVehiculo,
                          isLoading: _isLoading,
                          icon: Icons.save,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? selectedDate,
    Function(DateTime?) onDateSelected,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => _selectDate(context, selectedDate, onDateSelected),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: selectedDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onDateSelected(null),
                )
              : const Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
              : 'Seleccionar fecha',
          style: TextStyle(
            color: selectedDate != null ? null : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? currentDate,
    Function(DateTime?) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _registrarVehiculo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final vehiculoController = Provider.of<VehiculoController>(context, listen: false);
      final empresaController = Provider.of<EmpresaController>(context, listen: false);

      if (authController.user == null) {
        _showErrorDialog('Error: Usuario no autenticado');
        return;
      }

      if (empresaController.empresa == null) {
        _showErrorDialog('Error: No se encontró la empresa asociada');
        return;
      }

      final vehiculo = VehiculoModel(
        id: '', // Se generará automáticamente
        empresaId: empresaController.empresa!.id,
        placa: _placaController.text.trim().toUpperCase(),
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        anio: int.parse(_anioController.text.trim()),
        tipo: _tipoSeleccionado,
        capacidadPasajeros: int.parse(_capacidadController.text.trim()),
        numeroInterno: _numeroInternoController.text.trim(),
        color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
        estado: _estadoSeleccionado,
        fechaVencimientoSoat: _fechaVencimientoSoat,
        fechaVencimientoRevision: _fechaVencimientoRevision,
        fechaVencimientoOperacion: _fechaVencimientoOperacion,
        fechaVencimientoPoliza: _fechaVencimientoPoliza,
        observaciones: _observacionesController.text.trim().isNotEmpty 
            ? _observacionesController.text.trim() 
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await vehiculoController.registrarVehiculo(vehiculo);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehículo registrado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        _showErrorDialog(vehiculoController.error ?? 'Error al registrar vehículo');
      }
    } catch (e) {
      _showErrorDialog('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTipoVehiculoDisplayName(TipoVehiculo tipo) {
    switch (tipo) {
      case TipoVehiculo.bus:
        return 'Bus';
      case TipoVehiculo.buseta:
        return 'Buseta';
      case TipoVehiculo.microbus:
        return 'Microbús';
      case TipoVehiculo.van:
        return 'Van';
    }
  }

  String _getEstadoDisplayName(VehiculoStatus estado) {
    switch (estado) {
      case VehiculoStatus.activo:
        return 'Activo';
      case VehiculoStatus.inactivo:
        return 'Inactivo';
      case VehiculoStatus.mantenimiento:
        return 'En Mantenimiento';
    }
  }
}