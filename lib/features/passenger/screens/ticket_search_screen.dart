import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/constants/narino_destinations.dart';
import '../../../data/models/ticket_model.dart';
import 'ticket_results_screen.dart';
import 'map_selection_screen.dart';
import 'package:latlong2/latlong.dart';

class TicketSearchScreen extends StatefulWidget {
  const TicketSearchScreen({super.key});

  @override
  State<TicketSearchScreen> createState() => _TicketSearchScreenState();
}

class _TicketSearchScreenState extends State<TicketSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  
  String? _origin;
  String? _destination;
  LatLng? _originCoordinates;
  LatLng? _destinationCoordinates;
  DateTime? _departureDate;
  DateTime? _returnDate;
  int _passengers = 1;
  bool _isRoundTrip = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Tickets'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con imagen
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_bus, size: 40, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        '¿A dónde quieres viajar?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tipo de viaje
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Solo ida'),
                      value: false,
                      groupValue: _isRoundTrip,
                      onChanged: (value) => setState(() => _isRoundTrip = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Ida y vuelta'),
                      value: true,
                      groupValue: _isRoundTrip,
                      onChanged: (value) => setState(() => _isRoundTrip = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Origen y Destino
              Row(
                children: [
                  Expanded(
                    child: _buildCityField(
                      controller: _originController,
                      label: 'Origen',
                      icon: Icons.my_location,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _swapCities,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.swap_horiz, color: Colors.indigo),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCityField(
                      controller: _destinationController,
                      label: 'Destino',
                      icon: Icons.location_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fechas
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Fecha de salida',
                      date: _departureDate,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      label: 'Fecha de regreso',
                      date: _returnDate,
                      onTap: _isRoundTrip ? () => _selectDate(context, false) : null,
                      enabled: _isRoundTrip,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pasajeros
              _buildPassengerSelector(),
              const SizedBox(height: 24),

              // Botón de búsqueda
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _searchTickets,
                  child: const Text(
                    'Buscar Tickets',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Rutas populares
              _buildPopularRoutes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: const Icon(Icons.map),
          onPressed: () => _openMapSelection(controller, label),
          tooltip: 'Seleccionar en mapa',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo requerido';
        }
        return null;
      },
      onTap: () => _showCitySelector(controller),
      readOnly: true,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: enabled ? Colors.grey : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: enabled ? Colors.indigo : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Seleccionar',
                  style: TextStyle(
                    fontSize: 16,
                    color: enabled ? Colors.black87 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.indigo),
          const SizedBox(width: 12),
          const Text('Pasajeros:', style: TextStyle(fontSize: 16)),
          const Spacer(),
          IconButton(
            onPressed: _passengers > 1 ? () => setState(() => _passengers--) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$_passengers',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: _passengers < 9 ? () => setState(() => _passengers++) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularRoutes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rutas Populares',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            final routes = [
              'Bogotá → Medellín',
              'Medellín → Cali',
              'Bogotá → Cali',
              'Cali → Cartagena',
              'Bogotá → Barranquilla',
              'Medellín → Cartagena',
            ];
            return GestureDetector(
              onTap: () => _selectPopularRoute(routes[index]),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Center(
                  child: Text(
                    routes[index],
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showCitySelector(TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar Ciudad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: NarinoDestinations.municipalities.length,
                itemBuilder: (context, index) {
                  final destination = NarinoDestinations.municipalities[index];
                  final region = NarinoDestinations.getRegionForDestination(destination);
                  return ListTile(
                    leading: const Icon(Icons.location_city),
                    title: Text(destination),
                    subtitle: Text('Región: $region'),
                    onTap: () {
                      controller.text = destination;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate(BuildContext context, bool isDeparture) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = date;
          // Si es ida y vuelta y la fecha de regreso es anterior, resetearla
          if (_isRoundTrip && _returnDate != null && _returnDate!.isBefore(date)) {
            _returnDate = null;
          }
        } else {
          _returnDate = date;
        }
      });
    }
  }

  void _swapCities() {
    final temp = _originController.text;
    _originController.text = _destinationController.text;
    _destinationController.text = temp;
  }

  void _selectPopularRoute(String route) {
    final cities = route.split(' → ');
    _originController.text = cities[0];
    _destinationController.text = cities[1];
  }

  void _openMapSelection(TextEditingController controller, String label) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          title: 'Seleccionar $label',
        ),
      ),
    );

    if (result != null) {
      controller.text = result['address'] ?? result['name'] ?? 'Ubicación seleccionada';
      
      // Actualizar coordenadas según el campo
      if (label.toLowerCase().contains('origen')) {
        _originCoordinates = result['coordinates'];
      } else if (label.toLowerCase().contains('destino')) {
        _destinationCoordinates = result['coordinates'];
      }
    }
  }

  void _searchTickets() {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona origen y destino'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la fecha de salida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TicketResultsScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}