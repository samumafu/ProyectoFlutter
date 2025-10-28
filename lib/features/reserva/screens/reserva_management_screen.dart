import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/reserva_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/empresa_controller.dart';
import '../../../models/reserva_model.dart';
import '../../../models/viaje_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../utils/app_colors.dart';

class ReservaManagementScreen extends StatefulWidget {
  const ReservaManagementScreen({super.key});

  @override
  State<ReservaManagementScreen> createState() => _ReservaManagementScreenState();
}

class _ReservaManagementScreenState extends State<ReservaManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  ReservaStatus? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final reservaController = Provider.of<ReservaController>(context, listen: false);

    String? empresaId;
    if (authController.isEmpresa) {
      empresaId = authController.user?.id;
    } else {
      empresaId = empresaController.empresa?.id;
    }

    if (empresaId != null) {
      await reservaController.cargarReservasPorEmpresa(empresaId);
      await reservaController.cargarEstadisticas(empresaId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Reservas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.book_online), text: 'Reservas'),
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
          _buildReservasTab(),
          _buildEstadisticasTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Consumer<ReservaController>(
      builder: (context, reservaController, child) {
        if (reservaController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _cargarDatos,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResumenRapido(reservaController),
                const SizedBox(height: 24),
                _buildReservasRecientes(reservaController),
                const SizedBox(height: 24),
                _buildReservasPendientes(reservaController),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReservasTab() {
    return Consumer<ReservaController>(
      builder: (context, reservaController, child) {
        return Column(
          children: [
            _buildFiltrosReservas(reservaController),
            Expanded(
              child: reservaController.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildListaReservas(reservaController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstadisticasTab() {
    return Consumer<ReservaController>(
      builder: (context, reservaController, child) {
        final estadisticas = reservaController.estadisticas;
        
        if (reservaController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (estadisticas.isEmpty) {
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

  Widget _buildResumenRapido(ReservaController reservaController) {
    final reservas = reservaController.reservas;
    final reservasHoy = reservas.where((r) => 
      r.createdAt.day == DateTime.now().day &&
      r.createdAt.month == DateTime.now().month &&
      r.createdAt.year == DateTime.now().year
    ).length;
    
    final reservasPendientes = reservas.where((r) => r.estado == ReservaStatus.pendiente).length;
    final reservasConfirmadas = reservas.where((r) => r.estado == ReservaStatus.confirmada).length;
    final ingresosTotales = reservas
        .where((r) => r.estado == ReservaStatus.confirmada)
        .fold(0.0, (sum, r) => sum + r.precioFinal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Reservas',
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
                    'Reservas Hoy',
                    reservasHoy.toString(),
                    Icons.today,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEstadisticaCard(
                    'Pendientes',
                    reservasPendientes.toString(),
                    Icons.pending,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEstadisticaCard(
                    'Confirmadas',
                    reservasConfirmadas.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEstadisticaCard(
                    'Ingresos',
                    '\$${ingresosTotales.toStringAsFixed(0)}',
                    Icons.attach_money,
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

  Widget _buildReservasRecientes(ReservaController reservaController) {
    final reservasRecientes = reservaController.reservas
        .where((r) => r.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
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
                  'Reservas Recientes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (reservasRecientes.isEmpty)
              const Center(
                child: Text('No hay reservas recientes'),
              )
            else
              ...reservasRecientes.map((reserva) => _buildReservaCard(reserva, true)),
          ],
        ),
      ),
    );
  }

  Widget _buildReservasPendientes(ReservaController reservaController) {
    final reservasPendientes = reservaController.reservas
        .where((r) => r.estado == ReservaStatus.pendiente)
        .take(5)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reservas Pendientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (reservasPendientes.isEmpty)
              const Center(
                child: Text('No hay reservas pendientes'),
              )
            else
              ...reservasPendientes.map((reserva) => _buildReservaCard(reserva, false)),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosReservas(ReservaController reservaController) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por código o pasajero...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              reservaController.filtrarReservas(
                query: value,
                estado: _filtroEstado,
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ReservaStatus?>(
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
                    ...ReservaStatus.values.map((estado) {
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
                    reservaController.filtrarReservas(
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

  Widget _buildListaReservas(ReservaController reservaController) {
    final reservas = reservaController.reservasFiltradas.isNotEmpty
        ? reservaController.reservasFiltradas
        : reservaController.reservas;

    if (reservas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_online, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay reservas registradas',
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
        itemCount: reservas.length,
        itemBuilder: (context, index) {
          return _buildReservaCard(reservas[index], false);
        },
      ),
    );
  }

  Widget _buildReservaCard(ReservaModel reserva, bool isCompact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _mostrarDetallesReserva(reserva),
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
                      'Código: ${reserva.codigoReserva ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildEstadoChip(reserva.estado),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reserva.nombrePasajero,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    reserva.telefonoPasajero,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reserva.emailPasajero ?? 'N/A',
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (!isCompact) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${reserva.numeroAsientos} asiento${reserva.numeroAsientos > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '\$${reserva.precioFinal.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (reserva.metodoPago != null) ...[
                      Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _getMetodoPagoText(reserva.metodoPago!),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${reserva.createdAt.day}/${reserva.createdAt.month}/${reserva.createdAt.year}',
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

  Widget _buildEstadoChip(ReservaStatus estado) {
    Color color;
    String text;

    switch (estado) {
      case ReservaStatus.pendiente:
        color = AppColors.warning;
        text = 'Pendiente';
        break;
      case ReservaStatus.confirmada:
        color = AppColors.success;
        text = 'Confirmada';
        break;
      case ReservaStatus.pagada:
        color = AppColors.info;
        text = 'Pagada';
        break;
      case ReservaStatus.cancelada:
        color = AppColors.error;
        text = 'Cancelada';
        break;
      case ReservaStatus.completada:
        color = AppColors.primary;
        text = 'Completada';
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
                    'Total Reservas',
                    estadisticas['totalReservas']?.toString() ?? '0',
                    Icons.book_online,
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
              'Reservas por Estado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...ReservaStatus.values.map((estado) {
              final count = estadisticas['reservasPorEstado']?[estado.toString()] ?? 0;
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

  String _getEstadoText(ReservaStatus estado) {
    switch (estado) {
      case ReservaStatus.pendiente:
        return 'Pendiente';
      case ReservaStatus.confirmada:
        return 'Confirmada';
      case ReservaStatus.pagada:
        return 'Pagada';
      case ReservaStatus.cancelada:
        return 'Cancelada';
      case ReservaStatus.completada:
        return 'Completada';
    }
  }

  String _getMetodoPagoText(MetodoPago metodo) {
    switch (metodo) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.tarjeta:
        return 'Tarjeta';
      case MetodoPago.transferencia:
        return 'Transferencia';
      case MetodoPago.pse:
        return 'PSE';
    }
  }

  void _mostrarDetallesReserva(ReservaModel reserva) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la Reserva'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem('Código', reserva.codigoReserva ?? 'N/A'),
              _buildDetalleItem('Pasajero', reserva.nombrePasajero),
              _buildDetalleItem('Teléfono', reserva.telefonoPasajero),
              _buildDetalleItem('Email', reserva.emailPasajero ?? 'N/A'),
              _buildDetalleItem('Asientos', '${reserva.numeroAsientos} asiento${reserva.numeroAsientos > 1 ? 's' : ''}'),
              _buildDetalleItem('Precio Final', '\$${reserva.precioFinal.toStringAsFixed(0)}'),
              if (reserva.metodoPago != null)
                _buildDetalleItem('Método de Pago', _getMetodoPagoText(reserva.metodoPago!)),
              _buildDetalleItem('Estado', _getEstadoText(reserva.estado)),
              _buildDetalleItem('Fecha Reserva', '${reserva.createdAt.day}/${reserva.createdAt.month}/${reserva.createdAt.year}'),
              if (reserva.observaciones != null)
                _buildDetalleItem('Observaciones', reserva.observaciones!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (reserva.estado == ReservaStatus.pendiente) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmarReserva(reserva);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('Confirmar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelarReserva(reserva);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Cancelar'),
            ),
          ],
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
            width: 120,
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

  Future<void> _confirmarReserva(ReservaModel reserva) async {
    final reservaController = Provider.of<ReservaController>(context, listen: false);
    
    final success = await reservaController.cambiarEstadoReserva(
      reserva.id, 
      ReservaStatus.confirmada,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva confirmada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarDatos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reservaController.error ?? 'Error al confirmar reserva'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelarReserva(ReservaModel reserva) async {
    final reservaController = Provider.of<ReservaController>(context, listen: false);
    
    final success = await reservaController.cancelarReserva(
      reserva.id,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva cancelada exitosamente'),
          backgroundColor: Colors.orange,
        ),
      );
      _cargarDatos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reservaController.error ?? 'Error al cancelar reserva'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}