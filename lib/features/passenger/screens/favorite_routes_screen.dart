import 'package:flutter/material.dart';
import '../../../data/constants/narino_destinations.dart';

class FavoriteRoutesScreen extends StatefulWidget {
  const FavoriteRoutesScreen({super.key});

  @override
  State<FavoriteRoutesScreen> createState() => _FavoriteRoutesScreenState();
}

class _FavoriteRoutesScreenState extends State<FavoriteRoutesScreen> {
  final List<Map<String, dynamic>> favoriteRoutes = [
    {
      'origin': 'Pasto',
      'destination': 'Ipiales',
      'frequency': 'Semanal',
      'lastUsed': '2024-01-15',
      'price': 15000,
      'duration': '1h 30min',
    },
    {
      'origin': 'Pasto',
      'destination': 'Túquerres',
      'frequency': 'Mensual',
      'lastUsed': '2024-01-10',
      'price': 12000,
      'duration': '1h 15min',
    },
    {
      'origin': 'Ipiales',
      'destination': 'Pasto',
      'frequency': 'Semanal',
      'lastUsed': '2024-01-12',
      'price': 15000,
      'duration': '1h 30min',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas Favoritas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRouteDialog,
          ),
        ],
      ),
      body: favoriteRoutes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: favoriteRoutes.length,
              itemBuilder: (context, index) {
                final route = favoriteRoutes[index];
                return _buildRouteCard(route, index);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes rutas favoritas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tus rutas más frecuentes para acceso rápido',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddRouteDialog,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Ruta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _searchRoute(route),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                              color: Colors.indigo,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              route['origin'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              route['destination'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.access_time,
                              route['duration'],
                              Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              Icons.attach_money,
                              '\$${route['price']}',
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteRoute(index);
                      } else if (value == 'edit') {
                        _editRoute(index);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Frecuencia: ${route['frequency']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Último uso: ${route['lastUsed']}',
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
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _searchRoute(Map<String, dynamic> route) {
    // TODO: Navegar a la pantalla de búsqueda con los datos prellenados
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Buscando viajes de ${route['origin']} a ${route['destination']}'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void _showAddRouteDialog() {
    String? selectedOrigin;
    String? selectedDestination;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Agregar Ruta Favorita'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Origen',
                  border: OutlineInputBorder(),
                ),
                value: selectedOrigin,
                items: NarinoDestinations.municipalities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedOrigin = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Destino',
                  border: OutlineInputBorder(),
                ),
                value: selectedDestination,
                items: NarinoDestinations.municipalities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDestination = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedOrigin != null && selectedDestination != null
                  ? () {
                      _addRoute(selectedOrigin!, selectedDestination!);
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _addRoute(String origin, String destination) {
    setState(() {
      favoriteRoutes.add({
        'origin': origin,
        'destination': destination,
        'frequency': 'Nueva',
        'lastUsed': DateTime.now().toString().substring(0, 10),
        'price': 10000, // Precio por defecto
        'duration': '1h 00min', // Duración por defecto
      });
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ruta agregada a favoritos'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editRoute(int index) {
    // TODO: Implementar edición de ruta
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de edición próximamente'),
      ),
    );
  }

  void _deleteRoute(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ruta'),
        content: const Text('¿Estás seguro de que quieres eliminar esta ruta favorita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                favoriteRoutes.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ruta eliminada'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}