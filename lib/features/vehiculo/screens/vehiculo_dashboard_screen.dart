import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/vehiculo_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/empresa_controller.dart';
import '../../../models/vehiculo_model.dart';
import '../../../widgets/custom_button.dart';
import 'vehiculo_registration_screen.dart';

class VehiculoDashboardScreen extends StatefulWidget {
  const VehiculoDashboardScreen({super.key});

  @override
  State<VehiculoDashboardScreen> createState() => _VehiculoDashboardScreenState();
}

class _VehiculoDashboardScreenState extends State<VehiculoDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  VehiculoStatus? _filtroEstado;
  TipoVehiculo? _filtroTipo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final vehiculoController = Provider.of<VehiculoController>(context, listen: false);
    final empresaController = Provider.of<EmpresaController>(context, listen: false);
    
    if (empresaController.empresa != null) {
      await vehiculoController.cargarVehiculosPorEmpresa(empresaController.empresa!.id);
      await vehiculoController.cargarEstadisticas(empresaController.empresa!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Vehículos'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.directions_bus), text: 'Vehículos'),
            Tab(icon: Icon(Icons.description), text: 'Documentos'),
            Tab(icon: Icon(Icons.analytics), text: 'Estadísticas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToRegistration(),
          ),
        ],
      ),
      body: Consumer<VehiculoController>(
        builder: (context, vehiculoController, child) {
          if (vehiculoController.isLoading && vehiculoController.vehiculos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(vehiculoController),
              _buildVehiculosTab(vehiculoController),
              _buildDocumentosTab(vehiculoController),
              _buildEstadisticasTab(vehiculoController),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardTab(VehiculoController controller) {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen rápido
            _buildQuickSummary(controller),
            const SizedBox(height: 20),
            
            // Acciones rápidas
            _buildQuickActions(),
            const SizedBox(height: 20),
            
            // Vehículos con documentos próximos a vencer
            _buildExpiringDocuments(controller),
            const SizedBox(height: 20),
            
            // Vehículos recientes
            _buildRecentVehicles(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSummary(VehiculoController controller) {
    final stats = controller.estadisticas;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen General',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Vehículos',
                    '${stats?['total'] ?? controller.vehiculos.length}',
                    Icons.directions_bus,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Activos',
                    '${controller.vehiculos.where((v) => v.estado == VehiculoStatus.activo).length}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Mantenimiento',
                    '${controller.vehiculos.where((v) => v.estado == VehiculoStatus.mantenimiento).length}',
                    Icons.build,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Inactivos',
                    '${controller.vehiculos.where((v) => v.estado == VehiculoStatus.inactivo).length}',
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Nuevo Vehículo',
                    onPressed: _navigateToRegistration,
                    icon: Icons.add,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Actualizar',
                    onPressed: _loadInitialData,
                    outlined: true,
                    icon: Icons.refresh,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringDocuments(VehiculoController controller) {
    final vehiculosConDocumentosVencidos = controller.vehiculos.where((vehiculo) {
      final now = DateTime.now();
      final treintaDias = now.add(const Duration(days: 30));
      
      return (vehiculo.fechaVencimientoSoat != null && 
              vehiculo.fechaVencimientoSoat!.isBefore(treintaDias)) ||
             (vehiculo.fechaVencimientoRevision != null && 
              vehiculo.fechaVencimientoRevision!.isBefore(treintaDias)) ||
             (vehiculo.fechaVencimientoOperacion != null && 
              vehiculo.fechaVencimientoOperacion!.isBefore(treintaDias)) ||
             (vehiculo.fechaVencimientoPoliza != null && 
              vehiculo.fechaVencimientoPoliza!.isBefore(treintaDias));
    }).toList();

    if (vehiculosConDocumentosVencidos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Documentos por Vencer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...vehiculosConDocumentosVencidos.take(3).map((vehiculo) => 
              _buildExpiringDocumentItem(vehiculo)
            ),
            if (vehiculosConDocumentosVencidos.length > 3)
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: Text('Ver todos (${vehiculosConDocumentosVencidos.length})'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringDocumentItem(VehiculoModel vehiculo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bus, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehiculo.placa} - ${vehiculo.marca} ${vehiculo.modelo}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Documentos próximos a vencer',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildRecentVehicles(VehiculoController controller) {
    final vehiculosRecientes = controller.vehiculos.take(5).toList();
    
    if (vehiculosRecientes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.directions_bus, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No hay vehículos registrados',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: 'Registrar Primer Vehículo',
                onPressed: _navigateToRegistration,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehículos Recientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 12),
            ...vehiculosRecientes.map((vehiculo) => _buildVehicleListItem(vehiculo)),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiculosTab(VehiculoController controller) {
    return Column(
      children: [
        // Barra de búsqueda y filtros
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[50],
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por placa, marca o modelo...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => _filterVehicles(controller),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<VehiculoStatus?>(
                      value: _filtroEstado,
                      decoration: InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos')),
                        ...VehiculoStatus.values.map((estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(_getEstadoDisplayName(estado)),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filtroEstado = value;
                        });
                        _filterVehicles(controller);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<TipoVehiculo?>(
                      value: _filtroTipo,
                      decoration: InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos')),
                        ...TipoVehiculo.values.map((tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(_getTipoVehiculoDisplayName(tipo)),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filtroTipo = value;
                        });
                        _filterVehicles(controller);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Lista de vehículos
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitialData,
            child: controller.vehiculosFiltrados.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: controller.vehiculosFiltrados.length,
                    itemBuilder: (context, index) {
                      final vehiculo = controller.vehiculosFiltrados[index];
                      return _buildVehicleCard(vehiculo, controller);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(VehiculoModel vehiculo, VehiculoController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(vehiculo.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTipoIcon(vehiculo.tipo),
                    color: _getStatusColor(vehiculo.estado),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehiculo.placa,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${vehiculo.marca} ${vehiculo.modelo} (${vehiculo.anio})',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(vehiculo.estado),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getEstadoDisplayName(vehiculo.estado),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.people, '${vehiculo.capacidadPasajeros} pasajeros'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.numbers, 'N° ${vehiculo.numeroInterno}'),
                if (vehiculo.color != null) ...[
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.palette, vehiculo.color!),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Ver Detalles',
                    onPressed: () => _showVehicleDetails(vehiculo),
                    outlined: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'Editar',
                    onPressed: () => _editVehicle(vehiculo),
                    icon: Icons.edit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleListItem(VehiculoModel vehiculo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(vehiculo.estado).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTipoIcon(vehiculo.tipo),
            color: _getStatusColor(vehiculo.estado),
          ),
        ),
        title: Text(vehiculo.placa),
        subtitle: Text('${vehiculo.marca} ${vehiculo.modelo}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(vehiculo.estado),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getEstadoDisplayName(vehiculo.estado),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _showVehicleDetails(vehiculo),
      ),
    );
  }

  Widget _buildDocumentosTab(VehiculoController controller) {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Estado de Documentos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 16),
          ...controller.vehiculos.map((vehiculo) => _buildDocumentCard(vehiculo)),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(VehiculoModel vehiculo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTipoIcon(vehiculo.tipo),
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Text(
                  '${vehiculo.placa} - ${vehiculo.marca} ${vehiculo.modelo}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDocumentStatus('SOAT', vehiculo.fechaVencimientoSoat, vehiculo.soatUrl),
            _buildDocumentStatus('Revisión Técnica', vehiculo.fechaVencimientoRevision, vehiculo.revisionTecnicaUrl),
            _buildDocumentStatus('Tarjeta de Operación', vehiculo.fechaVencimientoOperacion, vehiculo.tarjetaOperacionUrl),
            _buildDocumentStatus('Póliza', vehiculo.fechaVencimientoPoliza, vehiculo.polizaUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentStatus(String nombre, DateTime? fechaVencimiento, String? url) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (fechaVencimiento == null) {
      statusColor = Colors.grey;
      statusText = 'No registrado';
      statusIcon = Icons.help_outline;
    } else {
      final now = DateTime.now();
      final diasRestantes = fechaVencimiento.difference(now).inDays;

      if (diasRestantes < 0) {
        statusColor = Colors.red;
        statusText = 'Vencido';
        statusIcon = Icons.error;
      } else if (diasRestantes <= 30) {
        statusColor = Colors.orange;
        statusText = 'Por vencer ($diasRestantes días)';
        statusIcon = Icons.warning;
      } else {
        statusColor = Colors.green;
        statusText = 'Vigente';
        statusIcon = Icons.check_circle;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
                if (fechaVencimiento != null)
                  Text(
                    'Vence: ${fechaVencimiento.day}/${fechaVencimiento.month}/${fechaVencimiento.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (url != null)
            Icon(Icons.attachment, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }

  Widget _buildEstadisticasTab(VehiculoController controller) {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de Flota',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 20),
            _buildEstadisticasGenerales(controller),
            const SizedBox(height: 20),
            _buildEstadisticasPorTipo(controller),
            const SizedBox(height: 20),
            _buildEstadisticasPorEstado(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasGenerales(VehiculoController controller) {
    final totalVehiculos = controller.vehiculos.length;
    final promedioAnio = totalVehiculos > 0 
        ? controller.vehiculos.map((v) => v.anio).reduce((a, b) => a + b) / totalVehiculos
        : 0;
    final capacidadTotal = controller.vehiculos.fold(0, (sum, v) => sum + v.capacidadPasajeros);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas Generales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Vehículos',
                    '$totalVehiculos',
                    Icons.directions_bus,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Capacidad Total',
                    '$capacidadTotal',
                    Icons.people,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Año Promedio',
              promedioAnio.toStringAsFixed(0),
              Icons.calendar_today,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasPorTipo(VehiculoController controller) {
    final estadisticasPorTipo = <TipoVehiculo, int>{};
    for (final vehiculo in controller.vehiculos) {
      estadisticasPorTipo[vehiculo.tipo] = (estadisticasPorTipo[vehiculo.tipo] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por Tipo de Vehículo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...estadisticasPorTipo.entries.map((entry) => 
              _buildStatRow(
                _getTipoVehiculoDisplayName(entry.key),
                entry.value.toString(),
                _getTipoIcon(entry.key),
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasPorEstado(VehiculoController controller) {
    final estadisticasPorEstado = <VehiculoStatus, int>{};
    for (final vehiculo in controller.vehiculos) {
      estadisticasPorEstado[vehiculo.estado] = (estadisticasPorEstado[vehiculo.estado] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por Estado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...estadisticasPorEstado.entries.map((entry) => 
              _buildStatRow(
                _getEstadoDisplayName(entry.key),
                entry.value.toString(),
                _getStatusIcon(entry.key),
                color: _getStatusColor(entry.key),
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.blue,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron vehículos',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra tu primer vehículo para comenzar',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Registrar Vehículo',
            onPressed: _navigateToRegistration,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  void _filterVehicles(VehiculoController controller) {
    final query = _searchController.text.toLowerCase();
    controller.filtrarVehiculos(
      query: query.isNotEmpty ? query : null,
      estado: _filtroEstado,
      tipo: _filtroTipo,
    );
  }

  Future<void> _navigateToRegistration() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VehiculoRegistrationScreen(),
      ),
    );
    
    if (result == true) {
      _loadInitialData();
    }
  }

  void _showVehicleDetails(VehiculoModel vehiculo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${vehiculo.placa} - Detalles'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Marca', vehiculo.marca),
              _buildDetailRow('Modelo', vehiculo.modelo),
              _buildDetailRow('Año', vehiculo.anio.toString()),
              _buildDetailRow('Tipo', _getTipoVehiculoDisplayName(vehiculo.tipo)),
              _buildDetailRow('Capacidad', '${vehiculo.capacidadPasajeros} pasajeros'),
              _buildDetailRow('Número Interno', vehiculo.numeroInterno),
              if (vehiculo.color != null) _buildDetailRow('Color', vehiculo.color!),
              _buildDetailRow('Estado', _getEstadoDisplayName(vehiculo.estado)),
              if (vehiculo.observaciones != null) 
                _buildDetailRow('Observaciones', vehiculo.observaciones!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editVehicle(vehiculo);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editVehicle(VehiculoModel vehiculo) {
    // TODO: Implementar pantalla de edición
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de edición en desarrollo'),
      ),
    );
  }

  // Métodos auxiliares
  Color _getStatusColor(VehiculoStatus estado) {
    switch (estado) {
      case VehiculoStatus.activo:
        return Colors.green;
      case VehiculoStatus.inactivo:
        return Colors.red;
      case VehiculoStatus.mantenimiento:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(VehiculoStatus estado) {
    switch (estado) {
      case VehiculoStatus.activo:
        return Icons.check_circle;
      case VehiculoStatus.inactivo:
        return Icons.cancel;
      case VehiculoStatus.mantenimiento:
        return Icons.build;
    }
  }

  IconData _getTipoIcon(TipoVehiculo tipo) {
    switch (tipo) {
      case TipoVehiculo.bus:
        return Icons.directions_bus;
      case TipoVehiculo.buseta:
        return Icons.airport_shuttle;
      case TipoVehiculo.microbus:
        return Icons.directions_transit;
      case TipoVehiculo.van:
        return Icons.local_shipping;
    }
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
        return 'Mantenimiento';
    }
  }
}