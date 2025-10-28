import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../controllers/reports_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/empresa_controller.dart';
import '../../../widgets/custom_button.dart';
import '../../../utils/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarReportes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarReportes() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final empresaController = Provider.of<EmpresaController>(context, listen: false);
    final reportsController = Provider.of<ReportsController>(context, listen: false);

    if (authController.isEmpresa && empresaController.empresa?.id != null) {
      await reportsController.generarReportes(
        empresaId: empresaController.empresa!.id,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Estadísticas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.trending_up), text: 'Ventas'),
            Tab(icon: Icon(Icons.directions_bus), text: 'Viajes'),
            Tab(icon: Icon(Icons.people), text: 'Ocupación'),
          ],
        ),
      ),
      body: Consumer<ReportsController>(
        builder: (context, reportsController, child) {
          if (reportsController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reportsController.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar reportes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reportsController.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Reintentar',
                    onPressed: _cargarReportes,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildFiltroFechas(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(reportsController),
                    _buildVentasTab(reportsController),
                    _buildViajesTab(reportsController),
                    _buildOcupacionTab(reportsController),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltroFechas() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fecha Inicio', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _seleccionarFecha(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text('${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fecha Fin', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _seleccionarFecha(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text('${_fechaFin.day}/${_fechaFin.month}/${_fechaFin.year}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CustomButton(
            text: 'Actualizar',
            onPressed: _cargarReportes,
            width: 100,
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              final reportsController = Provider.of<ReportsController>(context, listen: false);
              if (!reportsController.isLoading) {
                reportsController.exportarReportePDF('general');
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              final reportsController = Provider.of<ReportsController>(context, listen: false);
              if (!reportsController.isLoading) {
                reportsController.exportarReporteExcel();
              }
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('Excel'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(ReportsController controller) {
    final stats = controller.estadisticasGenerales;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen General',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildEstadisticasGrid(stats),
          const SizedBox(height: 24),
          _buildGraficoOcupacion(controller),
        ],
      ),
    );
  }

  Widget _buildVentasTab(ReportsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reporte de Ventas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildGraficoVentas(controller),
        ],
      ),
    );
  }

  Widget _buildViajesTab(ReportsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reporte de Viajes',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildGraficoViajes(controller),
        ],
      ),
    );
  }

  Widget _buildOcupacionTab(ReportsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reporte de Ocupación',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTablaOcupacion(controller),
        ],
      ),
    );
  }

  Widget _buildEstadisticasGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildEstadisticaCard(
          'Total Viajes',
          '${stats['totalViajes'] ?? 0}',
          Icons.directions_bus,
          AppColors.primary,
        ),
        _buildEstadisticaCard(
          'Total Reservas',
          '${stats['totalReservas'] ?? 0}',
          Icons.book_online,
          AppColors.secondary,
        ),
        _buildEstadisticaCard(
          'Ingresos Totales',
          '\$${(stats['ingresosTotales'] ?? 0.0).toStringAsFixed(0)}',
          Icons.attach_money,
          AppColors.success,
        ),
        _buildEstadisticaCard(
          'Tasa Ocupación',
          '${(stats['tasaOcupacion'] ?? 0.0).toStringAsFixed(1)}%',
          Icons.people,
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildEstadisticaCard(String titulo, String valor, IconData icono, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              valor,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoOcupacion(ReportsController controller) {
    final stats = controller.estadisticasGenerales;
    final tasaOcupacion = (stats['tasaOcupacion'] ?? 0.0) as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasa de Ocupación',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: tasaOcupacion,
                      color: AppColors.primary,
                      title: 'Ocupado',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: (100 - tasaOcupacion).toDouble(),
                      color: Colors.grey[300]!,
                      title: 'Disponible',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoVentas(ReportsController controller) {
    final ventas = controller.reporteVentas;
    
    if (ventas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text('No hay datos de ventas para mostrar'),
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
              'Ventas por Día',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text('\$${value.toInt()}');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < ventas.length) {
                            return Text(ventas[index]['fecha'] as String);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: ventas.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['ventas'] as double),
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoViajes(ReportsController controller) {
    final viajes = controller.reporteViajes;
    
    if (viajes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text('No hay datos de viajes para mostrar'),
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
              'Viajes por Estado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: viajes.map((v) => (v['cantidad'] as int).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < viajes.length) {
                            return Text(viajes[index]['estado'] as String);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: viajes.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: (entry.value['cantidad'] as int).toDouble(),
                          color: AppColors.primary,
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaOcupacion(ReportsController controller) {
    final ocupacion = controller.reporteOcupacion;
    
    if (ocupacion.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text('No hay datos de ocupación para mostrar'),
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
              'Ocupación por Viaje',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Ocupación')),
                  DataColumn(label: Text('Asientos')),
                ],
                rows: ocupacion.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text(item['fecha'] as String)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getOcupacionColor((item['ocupacion'] as double)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(item['ocupacion'] as double).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text('${item['asientosOcupados']}/${item['asientosTotales']}')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOcupacionColor(double ocupacion) {
    if (ocupacion >= 80) return AppColors.success;
    if (ocupacion >= 60) return AppColors.warning;
    if (ocupacion >= 40) return Colors.orange;
    return AppColors.error;
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
    }
  }
}