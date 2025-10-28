import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/empresa_controller.dart';
import '../../../models/empresa_model.dart';
import '../../../widgets/custom_button.dart';

class CompanyMainDashboard extends StatefulWidget {
  const CompanyMainDashboard({super.key});

  @override
  State<CompanyMainDashboard> createState() => _CompanyMainDashboardState();
}

class _CompanyMainDashboardState extends State<CompanyMainDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadCompanyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCompanyData() {
    final authController = context.read<AuthController>();
    final empresaController = context.read<EmpresaController>();
    
    if (authController.user != null) {
      empresaController.cargarEmpresaPorUserId(authController.user!.id);
      // Solo cargar estadísticas si tenemos una empresa
      if (empresaController.empresa != null) {
        empresaController.cargarEstadisticas(empresaController.empresa!.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel Empresarial',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // TODO: Implementar notificaciones
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _navigateToProfile();
                  break;
                case 'settings':
                  _navigateToSettings();
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Configuración'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
            Tab(icon: Icon(Icons.people), text: 'Conductores'),
            Tab(icon: Icon(Icons.directions_bus), text: 'Vehículos'),
            Tab(icon: Icon(Icons.route), text: 'Rutas'),
            Tab(icon: Icon(Icons.schedule), text: 'Viajes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildDriversTab(),
          _buildVehiclesTab(),
          _buildRoutesTab(),
          _buildTripsTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Consumer2<AuthController, EmpresaController>(
      builder: (context, authController, empresaController, child) {
        if (empresaController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final empresa = empresaController.empresa;
        if (empresa == null) {
          return _buildNoCompanyWidget();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompanyInfoCard(empresa),
              const SizedBox(height: 16),
              _buildStatsCards(empresaController),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildRecentActivity(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompanyInfoCard(EmpresaModel empresa) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
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
                        empresa.razonSocial,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'NIT: ${empresa.nit}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(empresa.estado),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          empresa.estado.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Representante Legal', empresa.representanteLegal),
            _buildInfoRow(Icons.phone, 'Teléfono', empresa.telefono),
            _buildInfoRow(Icons.email, 'Email', empresa.email ?? 'No especificado'),
            _buildInfoRow(Icons.location_on, 'Dirección', empresa.direccion),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(EmpresaController empresaController) {
    final stats = empresaController.estadisticas;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Conductores',
            stats?['conductores']?.toString() ?? '0',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Vehículos',
            stats?['vehiculos']?.toString() ?? '0',
            Icons.directions_bus,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rutas',
            stats?['rutas']?.toString() ?? '0',
            Icons.route,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Viajes',
            stats?['viajes']?.toString() ?? '0',
            Icons.schedule,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
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
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Nuevo Conductor',
                    icon: Icons.person_add,
                    onPressed: () {
                      // TODO: Navegar a registro de conductor
                    },
                    outlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Nuevo Vehículo',
                    icon: Icons.add_circle,
                    onPressed: () {
                      // TODO: Navegar a registro de vehículo
                    },
                    outlined: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Nueva Ruta',
                    icon: Icons.add_road,
                    onPressed: () {
                      // TODO: Navegar a creación de ruta
                    },
                    outlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Programar Viaje',
                    icon: Icons.schedule,
                    onPressed: () {
                      // TODO: Navegar a programación de viaje
                    },
                    outlined: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              Icons.person_add,
              'Nuevo conductor registrado',
              '2 horas atrás',
              Colors.green,
            ),
            _buildActivityItem(
              Icons.schedule,
              'Viaje programado para mañana',
              '4 horas atrás',
              Colors.blue,
            ),
            _buildActivityItem(
              Icons.directions_bus,
              'Vehículo actualizado',
              '1 día atrás',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
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
    );
  }

  Widget _buildDriversTab() {
    return const Center(
      child: Text(
        'Módulo de Conductores\n(En desarrollo)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildVehiclesTab() {
    return const Center(
      child: Text(
        'Módulo de Vehículos\n(En desarrollo)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildRoutesTab() {
    return const Center(
      child: Text(
        'Módulo de Rutas\n(En desarrollo)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildTripsTab() {
    return const Center(
      child: Text(
        'Módulo de Viajes\n(En desarrollo)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildNoCompanyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_center,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontró información de la empresa',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Registrar Empresa',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/company-registration');
            },
          ),
        ],
      ),
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
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(EmpresaStatus status) {
    switch (status) {
      case EmpresaStatus.activa:
        return Colors.green;
      case EmpresaStatus.suspendida:
        return Colors.red;
      case EmpresaStatus.inactiva:
        return Colors.grey;
    }
  }

  void _navigateToProfile() {
    // TODO: Implementar navegación al perfil
  }

  void _navigateToSettings() {
    // TODO: Implementar navegación a configuración
  }

  void _handleLogout() async {
    final authController = context.read<AuthController>();
    await authController.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}