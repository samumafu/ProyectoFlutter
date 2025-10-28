import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/viaje_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/empresa_controller.dart';
import '../../../models/viaje_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../utils/app_colors.dart';
import 'viaje_registration_screen.dart';

class ViajeDashboardScreen extends StatefulWidget {
  const ViajeDashboardScreen({super.key});

  @override
  State<ViajeDashboardScreen> createState() => _ViajeDashboardScreenState();
}

class _ViajeDashboardScreenState extends State<ViajeDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  ViajeStatus? _filtroEstado;
  String? _filtroRuta;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final empresaController = Provider.of<EmpresaController>(context, listen: false);
    final viajeController = Provider.of<ViajeController>(context, listen: false);

    String? empresaId;
    if (authController.isEmpresa) {
      empresaId = authController.user?.id;
    } else {
      empresaId = empresaController.empresa?.id;
    }

    if (empresaId != null) {
      await viajeController.cargarViajesPorEmpresa(empresaId);
      await viajeController.cargarEstadisticas(empresaId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Viajes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.directions_bus), text: 'Viajes'),
            Tab(icon: Icon(Icons.people), text: 'Reservas'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildViajesTab(),
          _buildReservasTab(),
          _buildEstadisticasTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () => _navegarARegistroViaje(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildDashboardTab() {
    return Consumer<ViajeController>(
      builder: (context, viajeController, child) {
        if (viajeController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _cargarDatos,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResumenRapido(viajeController),
                const SizedBox(height: 24),
                _buildAccionesRapidas(),
                const SizedBox(height: 24),
                _buildViajesRecientes(viajeController),
                const SizedBox(height: 24),
                _buildProximosViajes(viajeController),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViajesTab() {
    return Consumer<ViajeController>(
      builder: (context, viajeController, child) {
        return Column(
          children: [
            _buildFiltrosViajes(viajeController),
            Expanded(
              child: viajeController.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildListaViajes(viajeController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReservasTab() {
    return const Center(
      child: Text(
        'Gestión de Reservas\n(En desarrollo)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildEstadisticasTab() {
    return Consumer<ViajeController>(
      builder: (context, viajeController, child) {
        final estadisticas = viajeController.estadisticas;
        
        if (viajeController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (estadisticas == null) {
          return const Center(
            child: Text('No hay estadísticas disponibles'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEstadisticasGenerales(estadisticas),
              const SizedBox(height: 24),
              _buildEstadisticasPorEstado(estadisticas),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResumenRapido(ViajeController viajeController) {
    final viajes = viajeController.viajes;
    final viajesHoy = viajes.where((v) => 
      v.fechaSalida.day == DateTime.now().day &&
      v.fechaSalida.month == DateTime.now().month &&
      v.fechaSalida.year == DateTime.now().year
    ).length;
    
    final viajesEnCurso = viajes.where((v) => v.estado == ViajeStatus.enCurso).length;
    final viajesProgramados = viajes.where((v) => v.estado == ViajeStatus.programado).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen Rápido',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEstadisticaCard(
                    'Viajes Hoy',
                    viajesHoy.toString(),
                    Icons.today,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEstadisticaCard(
                    'En Curso',
                    viajesEnCurso.toString(),
                    Icons.directions_bus,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEstadisticaCard(
                    'Programados',
                    viajesProgramados.toString(),
                    Icons.schedule,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEstadisticaCard(
                    'Total Viajes',
                    viajes.length.toString(),
                    Icons.list,
                    AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticaCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesRapidas() {
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
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Nuevo Viaje',
                    onPressed: _navegarARegistroViaje,
                    icon: Icons.add,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Ver Reservas',
                    onPressed: () => _tabController.animateTo(2),
                    icon: Icons.people,
                    outlined: true,
                    height: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViajesRecientes(ViajeController viajeController) {
    final viajesRecientes = viajeController.viajes
        .where((v) => v.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .take(5)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Viajes Recientes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (viajesRecientes.isEmpty)
              const Center(
                child: Text('No hay viajes recientes'),
              )
            else
              ...viajesRecientes.map((viaje) => _buildViajeCard(viaje, true)),
          ],
        ),
      ),
    );
  }

  Widget _buildProximosViajes(ViajeController viajeController) {
    final proximosViajes = viajeController.viajes
        .where((v) => v.fechaSalida.isAfter(DateTime.now()) && v.estado == ViajeStatus.programado)
        .take(5)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Próximos Viajes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (proximosViajes.isEmpty)
              const Center(
                child: Text('No hay viajes programados'),
              )
            else
              ...proximosViajes.map((viaje) => _buildViajeCard(viaje, true)),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosViajes(ViajeController viajeController) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar viajes...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              viajeController.filtrarViajes(
                query: value,
                estado: _filtroEstado,
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ViajeStatus?>(
                  value: _filtroEstado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos los estados'),
                    ),
                    ...ViajeStatus.values.map((estado) {
                      return DropdownMenuItem(
                        value: estado,
                        child: Text(_getEstadoText(estado)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filtroEstado = value;
                    });
                    viajeController.filtrarViajes(
                      query: _searchQuery,
                      estado: value,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaViajes(ViajeController viajeController) {
    final viajes = viajeController.viajesFiltrados.isNotEmpty
        ? viajeController.viajesFiltrados
        : viajeController.viajes;

    if (viajes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay viajes registrados',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: viajes.length,
        itemBuilder: (context, index) {
          return _buildViajeCard(viajes[index], false);
        },
      ),
    );
  }

  Widget _buildViajeCard(ViajeModel viaje, bool isCompact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _mostrarDetallesViaje(viaje),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Ruta: ${viaje.rutaId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildEstadoChip(viaje.estado),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${viaje.fechaSalida.day}/${viaje.fechaSalida.month}/${viaje.fechaSalida.year}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${viaje.horaSalida.hour.toString().padLeft(2, '0')}:${viaje.horaSalida.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (!isCompact) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '\$${viaje.precio.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${viaje.cuposOcupados}/${viaje.cuposDisponibles}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoChip(ViajeStatus estado) {
    Color color;
    String text;

    switch (estado) {
      case ViajeStatus.programado:
        color = AppColors.warning;
        text = 'Programado';
        break;
      case ViajeStatus.enCurso:
        color = AppColors.info;
        text = 'En Curso';
        break;
      case ViajeStatus.completado:
        color = AppColors.success;
        text = 'Completado';
        break;
      case ViajeStatus.cancelado:
        color = AppColors.error;
        text = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEstadisticasGenerales(Map<String, dynamic> estadisticas) {
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
                  child: _buildEstadisticaCard(
                    'Total Viajes',
                    estadisticas['totalViajes']?.toString() ?? '0',
                    Icons.directions_bus,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEstadisticaCard(
                    'Ingresos',
                    '\$${estadisticas['ingresosTotales']?.toStringAsFixed(0) ?? '0'}',
                    Icons.attach_money,
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasPorEstado(Map<String, dynamic> estadisticas) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Viajes por Estado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...ViajeStatus.values.map((estado) {
              final count = estadisticas['viajesPorEstado']?[estado.toString()] ?? 0;
              return ListTile(
                leading: _buildEstadoChip(estado),
                title: Text(_getEstadoText(estado)),
                trailing: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
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

  void _navegarARegistroViaje() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ViajeRegistrationScreen(),
      ),
    ).then((_) => _cargarDatos());
  }

  void _mostrarDetallesViaje(ViajeModel viaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Viaje'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem('Ruta', viaje.rutaId),
              _buildDetalleItem('Vehículo', viaje.vehiculoId),
              if (viaje.conductorId != null)
                _buildDetalleItem('Conductor', viaje.conductorId!),
              _buildDetalleItem('Fecha', '${viaje.fechaSalida.day}/${viaje.fechaSalida.month}/${viaje.fechaSalida.year}'),
              _buildDetalleItem('Hora Salida', '${viaje.horaSalida.hour.toString().padLeft(2, '0')}:${viaje.horaSalida.minute.toString().padLeft(2, '0')}'),
              _buildDetalleItem('Precio', '\$${viaje.precio.toStringAsFixed(0)}'),
              _buildDetalleItem('Cupos', '${viaje.cuposOcupados}/${viaje.cuposDisponibles}'),
              _buildDetalleItem('Estado', _getEstadoText(viaje.estado)),
              if (viaje.observaciones != null)
                _buildDetalleItem('Observaciones', viaje.observaciones!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (viaje.estado == ViajeStatus.programado)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cambiarEstadoViaje(viaje, ViajeStatus.enCurso);
              },
              child: const Text('Iniciar Viaje'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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

  Future<void> _cambiarEstadoViaje(ViajeModel viaje, ViajeStatus nuevoEstado) async {
    final viajeController = Provider.of<ViajeController>(context, listen: false);
    
    final success = await viajeController.cambiarEstadoViaje(viaje.id, nuevoEstado);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado del viaje actualizado'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarDatos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viajeController.error ?? 'Error al actualizar estado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}