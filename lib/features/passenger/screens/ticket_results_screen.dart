import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/ticket_model.dart';
import '../controllers/ticket_search_controller.dart';
import 'ticket_detail_screen.dart';

class TicketResultsScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime departureDate;
  final int passengers;
  final bool isRoundTrip;
  final DateTime? returnDate;

  const TicketResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.passengers,
    this.isRoundTrip = false,
    this.returnDate,
  });

  @override
  State<TicketResultsScreen> createState() => _TicketResultsScreenState();
}

class _TicketResultsScreenState extends State<TicketResultsScreen> {
  String _sortBy = 'price';
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketSearchController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Resultados de Búsqueda'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => setState(() => _showFilters = !_showFilters),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (value) {
                  controller.setSortBy(value);
                  setState(() => _sortBy = value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'price',
                    child: Text('Precio'),
                  ),
                  const PopupMenuItem(
                    value: 'departure',
                    child: Text('Hora de salida'),
                  ),
                  const PopupMenuItem(
                    value: 'duration',
                    child: Text('Duración'),
                  ),
                  const PopupMenuItem(
                    value: 'rating',
                    child: Text('Calificación'),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (_showFilters) _buildFiltersSection(controller),
              _buildResultsHeader(controller),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.error != null
                        ? _buildErrorWidget(controller.error!)
                        : controller.filteredTickets.isEmpty
                            ? _buildEmptyWidget()
                            : _buildTicketsList(controller.filteredTickets),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltersSection(TicketSearchController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceFilter(controller),
          const SizedBox(height: 16),
          _buildTimeFilter(controller),
          const SizedBox(height: 16),
          _buildCompanyFilter(controller),
          const SizedBox(height: 16),
          _buildDirectRouteFilter(controller),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.clearFilters(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _showFilters = false),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFilter(TicketSearchController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rango de precio'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Precio mínimo',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  if (price != null) {
                    final newFilter = TicketFilter(
                      minPrice: price,
                      maxPrice: controller.currentFilter.maxPrice,
                      departureTimeRange: controller.currentFilter.departureTimeRange,
                      companies: controller.currentFilter.companies,
                      directRouteOnly: controller.currentFilter.directRouteOnly,
                    );
                    controller.applyFilter(newFilter);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Precio máximo',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  if (price != null) {
                    final newFilter = TicketFilter(
                      minPrice: controller.currentFilter.minPrice,
                      maxPrice: price,
                      departureTimeRange: controller.currentFilter.departureTimeRange,
                      companies: controller.currentFilter.companies,
                      directRouteOnly: controller.currentFilter.directRouteOnly,
                    );
                    controller.applyFilter(newFilter);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeFilter(TicketSearchController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Horario de salida'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Mañana (6-12)'),
              selected: controller.currentFilter.departureTimeRange == 'morning',
              onSelected: (selected) {
                final newFilter = TicketFilter(
                  minPrice: controller.currentFilter.minPrice,
                  maxPrice: controller.currentFilter.maxPrice,
                  departureTimeRange: selected ? 'morning' : null,
                  companies: controller.currentFilter.companies,
                  directRouteOnly: controller.currentFilter.directRouteOnly,
                );
                controller.applyFilter(newFilter);
              },
            ),
            FilterChip(
              label: const Text('Tarde (12-18)'),
              selected: controller.currentFilter.departureTimeRange == 'afternoon',
              onSelected: (selected) {
                final newFilter = TicketFilter(
                  minPrice: controller.currentFilter.minPrice,
                  maxPrice: controller.currentFilter.maxPrice,
                  departureTimeRange: selected ? 'afternoon' : null,
                  companies: controller.currentFilter.companies,
                  directRouteOnly: controller.currentFilter.directRouteOnly,
                );
                controller.applyFilter(newFilter);
              },
            ),
            FilterChip(
              label: const Text('Noche (18-22)'),
              selected: controller.currentFilter.departureTimeRange == 'evening',
              onSelected: (selected) {
                final newFilter = TicketFilter(
                  minPrice: controller.currentFilter.minPrice,
                  maxPrice: controller.currentFilter.maxPrice,
                  departureTimeRange: selected ? 'evening' : null,
                  companies: controller.currentFilter.companies,
                  directRouteOnly: controller.currentFilter.directRouteOnly,
                );
                controller.applyFilter(newFilter);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompanyFilter(TicketSearchController controller) {
    final companies = controller.getAvailableCompanies();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Compañías'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: companies.map((company) {
            final isSelected = controller.currentFilter.companies?.contains(company) ?? false;
            return FilterChip(
              label: Text(company),
              selected: isSelected,
              onSelected: (selected) {
                List<String> selectedCompanies = List.from(controller.currentFilter.companies ?? []);
                if (selected) {
                  selectedCompanies.add(company);
                } else {
                  selectedCompanies.remove(company);
                }
                
                final newFilter = TicketFilter(
                  minPrice: controller.currentFilter.minPrice,
                  maxPrice: controller.currentFilter.maxPrice,
                  departureTimeRange: controller.currentFilter.departureTimeRange,
                  companies: selectedCompanies.isEmpty ? null : selectedCompanies,
                  directRouteOnly: controller.currentFilter.directRouteOnly,
                );
                controller.applyFilter(newFilter);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDirectRouteFilter(TicketSearchController controller) {
    return Row(
      children: [
        Checkbox(
          value: controller.currentFilter.directRouteOnly ?? false,
          onChanged: (value) {
            final newFilter = TicketFilter(
              minPrice: controller.currentFilter.minPrice,
              maxPrice: controller.currentFilter.maxPrice,
              departureTimeRange: controller.currentFilter.departureTimeRange,
              companies: controller.currentFilter.companies,
              directRouteOnly: value,
            );
            controller.applyFilter(newFilter);
          },
        ),
        const Text('Solo rutas directas'),
      ],
    );
  }

  Widget _buildResultsHeader(TicketSearchController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.indigo[600]),
          const SizedBox(width: 8),
          Text(
            '${controller.filteredTickets.length} tickets encontrados',
            style: TextStyle(
              color: Colors.indigo[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'Ordenado por: ${_getSortLabel(_sortBy)}',
            style: TextStyle(
              color: Colors.indigo[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'price':
        return 'Precio';
      case 'departure':
        return 'Hora de salida';
      case 'duration':
        return 'Duración';
      case 'rating':
        return 'Calificación';
      default:
        return 'Precio';
    }
  }

  Widget _buildTicketsList(List<Ticket> tickets) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(ticket: ticket),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTicketHeader(ticket),
              const SizedBox(height: 12),
              _buildTicketRoute(ticket),
              const SizedBox(height: 12),
              _buildTicketInfo(ticket),
              const SizedBox(height: 12),
              _buildTicketFooter(ticket),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketHeader(Ticket ticket) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.indigo[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.directions_bus,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.companyName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                ticket.busType,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              ticket.formattedPrice,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.indigo,
              ),
            ),
            Text(
              'por persona',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTicketRoute(Ticket ticket) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.departureTimeFormatted,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                ticket.origin,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.indigo,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: Colors.indigo,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.indigo,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                ticket.duration,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ticket.arrivalTimeFormatted,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                ticket.destination,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketInfo(Ticket ticket) {
    return Row(
      children: [
        if (ticket.isDirectRoute)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Directo',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (!ticket.isDirectRoute)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${ticket.stops.length} parada${ticket.stops.length != 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber[600],
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${ticket.rating}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            Text(
              ' (${ticket.reviewCount})',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          '${ticket.availableSeats} asientos disponibles',
          style: TextStyle(
            color: ticket.availableSeats < 5 ? Colors.red[600] : Colors.grey[600],
            fontSize: 12,
            fontWeight: ticket.availableSeats < 5 ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketFooter(Ticket ticket) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 4,
            children: ticket.amenities.take(3).map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  amenity,
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (ticket.amenities.length > 3)
          Text(
            '+${ticket.amenities.length - 3} más',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar los tickets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Reintentar búsqueda
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
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
            'No se encontraron tickets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta modificar tus filtros de búsqueda',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}