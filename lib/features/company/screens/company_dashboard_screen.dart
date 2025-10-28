import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/company_controller.dart';
import 'company_login_screen.dart';
import 'route_management_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyController>().loadSchedules();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final controller = context.read<CompanyController>();
    await controller.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CompanyLoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel de Empresa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.route), text: 'Rutas'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final company = context.read<CompanyController>().currentCompany;
          if (company != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RouteManagementScreen(
                  companyId: company.id,
                  companyName: company.name,
                ),
              ),
            ).then((_) {
              // Recargar rutas cuando regrese de la pantalla de gestión
              context.read<CompanyController>().loadSchedules();
            });
          }
        },
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.route, color: Colors.white),
        label: const Text(
          'Gestionar Rutas',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildRoutesTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Consumer<CompanyController>(
      builder: (context, controller, child) {
        final company = controller.currentCompany;
        if (company == null) {
          return const Center(
            child: Text('No hay información de la empresa'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de la empresa
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.business_center,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  company.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'NIT: ${company.nit}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.email, 'Email', company.email),
                      _buildInfoRow(Icons.phone, 'Teléfono', company.phone),
                      _buildInfoRow(Icons.location_on, 'Dirección', company.address),
                      if (company.description.isNotEmpty)
                        _buildInfoRow(Icons.description, 'Descripción', company.description),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Estadísticas
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Horarios Activos',
                      controller.schedules.where((s) => s.isActive).length.toString(),
                      Icons.schedule,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Horarios',
                      controller.schedules.length.toString(),
                      Icons.list,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesTab() {
    return Consumer<CompanyController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.route,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No hay rutas creadas',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  'Usa el botón "Gestionar Rutas" para crear tu primera ruta',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    final company = context.read<CompanyController>().currentCompany;
                    if (company != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RouteManagementScreen(
                            companyId: company.id,
                            companyName: company.name,
                          ),
                        ),
                      ).then((_) {
                        // Recargar rutas cuando regrese de la pantalla de gestión
                        controller.loadSchedules();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Primera Ruta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadSchedules(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.schedules.length,
            itemBuilder: (context, index) {
              final route = controller.schedules[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: route.isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.route,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    '${route.origin} → ${route.destination}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha: ${route.departureTime.day}/${route.departureTime.month}/${route.departureTime.year}',
                      ),
                      Text(
                        'Hora: ${route.departureTime.hour.toString().padLeft(2, '0')}:${route.departureTime.minute.toString().padLeft(2, '0')}',
                      ),
                      Text('Precio: \$${route.price.toStringAsFixed(0)}'),
                      Text('Asientos: ${route.availableSeats}/${route.totalSeats}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              route.isActive ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(route.isActive ? 'Desactivar' : 'Activar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final company = context.read<CompanyController>().currentCompany;
                        if (company != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RouteManagementScreen(
                                companyId: company.id,
                                companyName: company.name,
                              ),
                            ),
                          ).then((_) {
                            // Recargar rutas cuando regrese
                            controller.loadSchedules();
                          });
                        }
                      } else if (value == 'toggle') {
                        final updatedRoute = route.copyWith(
                          isActive: !route.isActive,
                        );
                        await controller.updateSchedule(updatedRoute);
                      } else if (value == 'delete') {
                        // Mostrar diálogo de confirmación
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar eliminación'),
                            content: Text('¿Estás seguro de que deseas eliminar la ruta ${route.origin} → ${route.destination}?'),
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
                          await controller.deleteSchedule(route.id);
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

}