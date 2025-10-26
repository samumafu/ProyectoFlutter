import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/schedule_model.dart';
import '../../models/vehicle_model.dart';
import '../../data/schedules_data.dart';
import 'seat_selection_screen.dart';

class TicketResultsScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime departureDate;
  final int passengers;
  final bool isRoundTrip;
  final DateTime? returnDate;

  const TicketResultsScreen({
    Key? key,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.passengers,
    this.isRoundTrip = false,
    this.returnDate,
  }) : super(key: key);

  @override
  State<TicketResultsScreen> createState() => _TicketResultsScreenState();
}

class _TicketResultsScreenState extends State<TicketResultsScreen> {
  List<Schedule> schedules = [];
  bool isLoading = true;
  String? selectedFilter;
  
  final List<String> filterOptions = [
    'Todos',
    'Económica',
    'Ejecutiva',
    'Premium',
    'Precio menor',
    'Precio mayor',
    'Más temprano',
    'Más tarde',
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  void _loadSchedules() {
    setState(() {
      isLoading = true;
    });

    // Simular carga de datos
    Future.delayed(const Duration(milliseconds: 800), () {
      final results = SchedulesData.searchSchedules(
        origin: widget.origin,
        destination: widget.destination,
        date: widget.departureDate,
      );

      setState(() {
        schedules = results;
        isLoading = false;
      });
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      
      switch (filter) {
        case 'Económica':
          schedules.sort((a, b) => a.vehicle.vehicleClass.index.compareTo(b.vehicle.vehicleClass.index));
          schedules = schedules.where((s) => s.vehicle.vehicleClass.name == 'economica').toList();
          break;
        case 'Ejecutiva':
          schedules = schedules.where((s) => s.vehicle.vehicleClass.name == 'ejecutiva').toList();
          break;
        case 'Premium':
          schedules = schedules.where((s) => s.vehicle.vehicleClass.name == 'premium').toList();
          break;
        case 'Precio menor':
          schedules.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'Precio mayor':
          schedules.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'Más temprano':
          schedules.sort((a, b) => a.departureTime.compareTo(b.departureTime));
          break;
        case 'Más tarde':
          schedules.sort((a, b) => b.departureTime.compareTo(a.departureTime));
          break;
        default:
          _loadSchedules();
          return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${widget.origin} → ${widget.destination}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con información del viaje
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(widget.departureDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (selectedFilter != null && selectedFilter != 'Todos')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Filtro: $selectedFilter',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Lista de resultados
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Buscando horarios disponibles...'),
                      ],
                    ),
                  )
                : schedules.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron horarios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Intenta con otra fecha o destino',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: schedules.length,
                        itemBuilder: (context, index) {
                          final schedule = schedules[index];
                          return _buildScheduleCard(schedule);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    final departureTime = DateFormat('HH:mm').format(schedule.departureTime);
    final arrivalTime = DateFormat('HH:mm').format(schedule.estimatedArrivalTime);
    final duration = schedule.route.estimatedDuration;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectSchedule(schedule),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horarios y duración
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          departureTime,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          widget.origin,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.grey[400],
                      ),
                      Text(
                        '${duration}min',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          arrivalTime,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          widget.destination,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información del vehículo y conductor
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getVehicleIcon(schedule.vehicle.type),
                              size: 20,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${schedule.vehicle.brand} ${schedule.vehicle.model}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${schedule.driver.name} ${schedule.driver.lastName}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${schedule.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        _getVehicleClassName(schedule.vehicle.vehicleClass),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Información adicional
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_seat,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${schedule.availableSeats.length} asientos disponibles',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schedule.driver.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Comodidades
              if (schedule.vehicle.amenities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: schedule.vehicle.amenities.keys.take(3).map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        amenity,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getVehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.bus:
        return Icons.directions_bus;
      case VehicleType.microbus:
        return Icons.airport_shuttle;
      case VehicleType.van:
        return Icons.local_shipping;
      case VehicleType.car:
        return Icons.directions_car;
    }
  }

  String _getVehicleClassName(VehicleClass vehicleClass) {
    switch (vehicleClass) {
      case VehicleClass.economica:
        return 'Económica';
      case VehicleClass.ejecutiva:
        return 'Ejecutiva';
      case VehicleClass.premium:
        return 'Premium';
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtrar resultados'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: filterOptions.map((filter) {
              return ListTile(
                title: Text(filter),
                leading: Radio<String>(
                  value: filter,
                  groupValue: selectedFilter ?? 'Todos',
                  onChanged: (String? value) {
                    Navigator.of(context).pop();
                    _applyFilter(value!);
                  },
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _selectSchedule(Schedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
          schedule: schedule,
          passengers: widget.passengers,
        ),
      ),
    );
  }
}