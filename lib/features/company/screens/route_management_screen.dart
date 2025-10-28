import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/company_model.dart';
import '../../../services/route_service.dart';
import '../../../data/constants/narino_destinations.dart';

class RouteManagementScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const RouteManagementScreen({
    Key? key,
    required this.companyId,
    required this.companyName,
  }) : super(key: key);

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  List<CompanySchedule> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final routes = await RouteService.getCompanyRoutes(widget.companyId);
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error cargando rutas: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Rutas - ${widget.companyName}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showAddRouteDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Agregar nueva ruta',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? _buildEmptyState()
              : _buildRoutesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRouteDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay rutas registradas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera ruta para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddRouteDialog,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Ruta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesList() {
    return RefreshIndicator(
      onRefresh: _loadRoutes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          final route = _routes[index];
          return _buildRouteCard(route);
        },
      ),
    );
  }

  Widget _buildRouteCard(CompanySchedule route) {
    final departureTime = DateFormat('HH:mm').format(route.departureTime);
    final arrivalTime = DateFormat('HH:mm').format(route.arrivalTime);
    final date = DateFormat('dd/MM/yyyy').format(route.departureTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              route.origin,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.flag,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              route.destination,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: route.isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        route.isActive ? 'Activa' : 'Inactiva',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.schedule,
                    'Salida',
                    '$departureTime\n$date',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.schedule_outlined,
                    'Llegada',
                    arrivalTime,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.attach_money,
                    'Precio',
                    '\$${route.price.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.airline_seat_recline_normal,
                    'Asientos',
                    '${route.availableSeats}/${route.totalSeats}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.directions_bus,
                    'Vehículo',
                    '${route.vehicleType}\n${route.vehicleId}',
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _showEditRouteDialog(route),
                        icon: const Icon(Icons.edit),
                        color: Colors.blue,
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        onPressed: () => _toggleRouteStatus(route),
                        icon: Icon(
                          route.isActive ? Icons.pause : Icons.play_arrow,
                        ),
                        color: route.isActive ? Colors.orange : Colors.green,
                        tooltip: route.isActive ? 'Desactivar' : 'Activar',
                      ),
                      IconButton(
                        onPressed: () => _deleteRoute(route),
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showAddRouteDialog() {
    _showRouteDialog();
  }

  void _showEditRouteDialog(CompanySchedule route) {
    _showRouteDialog(route: route);
  }

  void _showRouteDialog({CompanySchedule? route}) {
    final isEditing = route != null;
    
    showDialog(
      context: context,
      builder: (context) => RouteFormDialog(
        companyId: widget.companyId,
        route: route,
        onSaved: () {
          Navigator.of(context).pop();
          _loadRoutes();
          _showSuccessSnackBar(
            isEditing ? 'Ruta actualizada exitosamente' : 'Ruta creada exitosamente',
          );
        },
      ),
    );
  }

  Future<void> _toggleRouteStatus(CompanySchedule route) async {
    final success = await RouteService.updateRoute(
      routeId: route.id,
      isActive: !route.isActive,
    );

    if (success) {
      _loadRoutes();
      _showSuccessSnackBar(
        route.isActive ? 'Ruta desactivada' : 'Ruta activada',
      );
    } else {
      _showErrorSnackBar('Error al cambiar estado de la ruta');
    }
  }

  Future<void> _deleteRoute(CompanySchedule route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la ruta ${route.origin} - ${route.destination}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await RouteService.deleteRoute(route.id);
      if (success) {
        _loadRoutes();
        _showSuccessSnackBar('Ruta eliminada exitosamente');
      } else {
        _showErrorSnackBar('Error al eliminar la ruta');
      }
    }
  }
}

class RouteFormDialog extends StatefulWidget {
  final String companyId;
  final CompanySchedule? route;
  final VoidCallback onSaved;

  const RouteFormDialog({
    Key? key,
    required this.companyId,
    this.route,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<RouteFormDialog> createState() => _RouteFormDialogState();
}

class _RouteFormDialogState extends State<RouteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  final _vehicleIdController = TextEditingController();

  String? _selectedOrigin;
  String? _selectedDestination;
  String? _selectedVehicleType;
  DateTime? _selectedDate;
  TimeOfDay? _departureTime;
  TimeOfDay? _arrivalTime;
  bool _isLoading = false;

  final List<String> _vehicleTypes = [
    'Bus',
    'Microbus',
    'Van',
    'Automóvil',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.route != null) {
      _initializeWithRoute(widget.route!);
    }
  }

  void _initializeWithRoute(CompanySchedule route) {
    _selectedOrigin = route.origin;
    _selectedDestination = route.destination;
    _selectedVehicleType = route.vehicleType;
    _selectedDate = DateTime(
      route.departureTime.year,
      route.departureTime.month,
      route.departureTime.day,
    );
    _departureTime = TimeOfDay.fromDateTime(route.departureTime);
    _arrivalTime = TimeOfDay.fromDateTime(route.arrivalTime);
    _priceController.text = route.price.toString();
    _seatsController.text = route.totalSeats.toString();
    _vehicleIdController.text = route.vehicleId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.route != null ? 'Editar Ruta' : 'Nueva Ruta'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCityDropdown(
                  label: 'Origen',
                  value: _selectedOrigin,
                  onChanged: (value) => setState(() => _selectedOrigin = value),
                ),
                const SizedBox(height: 16),
                _buildCityDropdown(
                  label: 'Destino',
                  value: _selectedDestination,
                  onChanged: (value) => setState(() => _selectedDestination = value),
                ),
                const SizedBox(height: 16),
                _buildDateField(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTimeField('Salida', _departureTime, (time) => _departureTime = time)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTimeField('Llegada', _arrivalTime, (time) => _arrivalTime = time)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el precio';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingresa un precio válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _seatsController,
                  decoration: const InputDecoration(
                    labelText: 'Número de asientos',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el número de asientos';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de vehículo',
                    border: OutlineInputBorder(),
                  ),
                  items: _vehicleTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedVehicleType = value),
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona el tipo de vehículo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID del vehículo (placa)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el ID del vehículo';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveRoute,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.route != null ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }

  Widget _buildCityDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: NarinoDestinations.municipalities.map((city) {
        return DropdownMenuItem(
          value: city,
          child: Text(city),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Selecciona $label';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _selectedDate != null
              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
              : 'Seleccionar fecha',
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay? time, ValueChanged<TimeOfDay> onChanged) {
    return InkWell(
      onTap: () => _selectTime(onChanged),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          time != null ? time.format(context) : 'Seleccionar',
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime(ValueChanged<TimeOfDay> onChanged) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => onChanged(time));
    }
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _departureTime == null || _arrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final departureDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _departureTime!.hour,
        _departureTime!.minute,
      );

      final arrivalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _arrivalTime!.hour,
        _arrivalTime!.minute,
      );

      bool success;
      if (widget.route != null) {
        success = await RouteService.updateRoute(
          routeId: widget.route!.id,
          origin: _selectedOrigin!,
          destination: _selectedDestination!,
          departureTime: departureDateTime,
          arrivalTime: arrivalDateTime,
          price: double.parse(_priceController.text),
          totalSeats: int.parse(_seatsController.text),
          vehicleType: _selectedVehicleType!,
          vehicleId: _vehicleIdController.text,
        );
      } else {
        success = await RouteService.createRoute(
          companyId: widget.companyId,
          origin: _selectedOrigin!,
          destination: _selectedDestination!,
          departureTime: departureDateTime,
          arrivalTime: arrivalDateTime,
          price: double.parse(_priceController.text),
          totalSeats: int.parse(_seatsController.text),
          vehicleType: _selectedVehicleType!,
          vehicleId: _vehicleIdController.text,
        );
      }

      if (success) {
        widget.onSaved();
      } else {
        throw Exception('Error al guardar la ruta');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _seatsController.dispose();
    _vehicleIdController.dispose();
    super.dispose();
  }
}