import 'package:flutter/foundation.dart';
import '../models/viaje_model.dart';
import '../models/reserva_model.dart';
import '../services/viaje_service.dart';
import '../services/reserva_service.dart';
import '../services/export_service.dart';

class ReportsController extends ChangeNotifier {
  final ViajeService _viajeService = ViajeService();
  final ReservaService _reservaService = ReservaService();
  final ExportService _exportService = ExportService();

  bool _isLoading = false;
  String? _error;

  // Datos de reportes
  Map<String, dynamic> _estadisticasGenerales = {};
  List<Map<String, dynamic>> _reporteVentas = [];
  List<Map<String, dynamic>> _reporteViajes = [];
  List<Map<String, dynamic>> _reporteOcupacion = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get estadisticasGenerales => _estadisticasGenerales;
  List<Map<String, dynamic>> get reporteVentas => _reporteVentas;
  List<Map<String, dynamic>> get reporteViajes => _reporteViajes;
  List<Map<String, dynamic>> get reporteOcupacion => _reporteOcupacion;

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Generar reportes completos
  Future<void> generarReportes({
    required String empresaId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Obtener datos
      final viajes = await _viajeService.buscarViajes(
        empresaId: empresaId,
        fechaDesde: fechaInicio,
        fechaHasta: fechaFin,
      );

      final reservas = await _reservaService.buscarReservas(
        empresaId: empresaId,
        fechaDesde: fechaInicio,
        fechaHasta: fechaFin,
      );

      // Generar estadísticas
      _generarEstadisticasGenerales(viajes, reservas, fechaInicio, fechaFin);
      _generarReporteVentas(reservas, fechaInicio, fechaFin);
      _generarReporteViajes(viajes, fechaInicio, fechaFin);
      _generarReporteOcupacion(viajes, reservas, fechaInicio, fechaFin);

      notifyListeners();
    } catch (e) {
      _setError('Error al generar reportes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _generarEstadisticasGenerales(
    List<ViajeModel> viajes,
    List<ReservaModel> reservas,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) {
    final viajesEnRango = viajes.where((v) => 
      v.fechaSalida.isAfter(fechaInicio) && 
      v.fechaSalida.isBefore(fechaFin.add(const Duration(days: 1)))
    ).toList();

    final reservasEnRango = reservas.where((r) => 
      r.createdAt.isAfter(fechaInicio) && 
      r.createdAt.isBefore(fechaFin.add(const Duration(days: 1)))
    ).toList();

    final reservasConfirmadas = reservasEnRango.where((r) => 
      r.estado == ReservaStatus.confirmada || r.estado == ReservaStatus.pagada
    ).toList();

    _estadisticasGenerales = {
      'totalViajes': viajesEnRango.length,
      'totalReservas': reservasEnRango.length,
      'reservasConfirmadas': reservasConfirmadas.length,
      'ingresosTotales': reservasConfirmadas.fold(0.0, (sum, r) => sum + r.precioFinal),
      'tasaOcupacion': _calcularTasaOcupacion(viajesEnRango, reservasConfirmadas),
      'viajesProgramados': viajesEnRango.where((v) => v.estado == ViajeStatus.programado).length,
      'viajesCompletados': viajesEnRango.where((v) => v.estado == ViajeStatus.completado).length,
      'viajesCancelados': viajesEnRango.where((v) => v.estado == ViajeStatus.cancelado).length,
    };
  }

  void _generarReporteVentas(
    List<ReservaModel> reservas,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) {
    final reservasEnRango = reservas.where((r) => 
      r.createdAt.isAfter(fechaInicio) && 
      r.createdAt.isBefore(fechaFin.add(const Duration(days: 1))) &&
      (r.estado == ReservaStatus.confirmada || r.estado == ReservaStatus.pagada)
    ).toList();

    // Agrupar por día
    final ventasPorDia = <String, double>{};
    for (final reserva in reservasEnRango) {
      final fecha = '${reserva.createdAt.day.toString().padLeft(2, '0')}/${reserva.createdAt.month.toString().padLeft(2, '0')}';
      ventasPorDia[fecha] = (ventasPorDia[fecha] ?? 0.0) + reserva.precioFinal;
    }

    _reporteVentas = ventasPorDia.entries
        .map((e) => {'fecha': e.key, 'ventas': e.value})
        .toList()
      ..sort((a, b) => (a['fecha'] as String).compareTo(b['fecha'] as String));
  }

  void _generarReporteViajes(
    List<ViajeModel> viajes,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) {
    final viajesEnRango = viajes.where((v) => 
      v.fechaSalida.isAfter(fechaInicio) && 
      v.fechaSalida.isBefore(fechaFin.add(const Duration(days: 1)))
    ).toList();

    // Agrupar por estado
    final viajesPorEstado = <String, int>{};
    for (final viaje in viajesEnRango) {
      final estado = _getEstadoText(viaje.estado);
      viajesPorEstado[estado] = (viajesPorEstado[estado] ?? 0) + 1;
    }

    _reporteViajes = viajesPorEstado.entries
        .map((e) => {'estado': e.key, 'cantidad': e.value})
        .toList();
  }

  void _generarReporteOcupacion(
    List<ViajeModel> viajes,
    List<ReservaModel> reservas,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) {
    final viajesEnRango = viajes.where((v) => 
      v.fechaSalida.isAfter(fechaInicio) && 
      v.fechaSalida.isBefore(fechaFin.add(const Duration(days: 1)))
    ).toList();

    _reporteOcupacion = [];
    for (final viaje in viajesEnRango) {
      final reservasViaje = reservas.where((r) => 
        r.viajeId == viaje.id && 
        (r.estado == ReservaStatus.confirmada || r.estado == ReservaStatus.pagada)
      ).toList();

      final asientosOcupados = reservasViaje.fold(0, (sum, r) => sum + r.numeroAsientos);
      final ocupacion = viaje.cuposDisponibles > 0 
          ? (asientosOcupados / viaje.cuposDisponibles) * 100 
          : 0.0;

      _reporteOcupacion.add({
        'viajeId': viaje.id,
        'fecha': '${viaje.fechaSalida.day}/${viaje.fechaSalida.month}',
        'ocupacion': ocupacion,
        'asientosOcupados': asientosOcupados,
        'asientosTotales': viaje.cuposDisponibles,
      });
    }
  }

  double _calcularTasaOcupacion(List<ViajeModel> viajes, List<ReservaModel> reservas) {
    if (viajes.isEmpty) return 0.0;

    int asientosTotales = viajes.fold(0, (sum, v) => sum + v.cuposDisponibles);
    int asientosOcupados = 0;
    
    for (final viaje in viajes) {
      final reservasViaje = reservas.where((r) => r.viajeId == viaje.id).toList();
      asientosOcupados += reservasViaje.fold(0, (sum, r) => sum + r.numeroAsientos);
    }

    return asientosTotales > 0 ? (asientosOcupados / asientosTotales) * 100 : 0.0;
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

  // Métodos de exportación
  Future<void> exportarReportePDF(String tipoReporte) async {
    try {
      _setLoading(true);
      
      final pdfBytes = await _exportService.exportarReporteGeneralPDF(
        estadisticas: _estadisticasGenerales,
        reporteVentas: _reporteVentas,
        reporteViajes: _reporteViajes,
        reporteOcupacion: _reporteOcupacion,
        fechaInicio: DateTime.now().subtract(const Duration(days: 30)),
        fechaFin: DateTime.now(),
      );
      
      await _exportService.compartirPDF(pdfBytes, 'reporte_$tipoReporte.pdf');
    } catch (e) {
      _setError('Error al exportar PDF: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> exportarReporteExcel() async {
    try {
      _setLoading(true);
      await _exportService.exportarReporteExcel(
        estadisticas: _estadisticasGenerales,
        reporteVentas: _reporteVentas,
        reporteViajes: _reporteViajes,
        reporteOcupacion: _reporteOcupacion,
        fechaInicio: DateTime.now().subtract(const Duration(days: 30)),
        fechaFin: DateTime.now(),
      );
    } catch (e) {
      _setError('Error al exportar Excel: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Exportar datos (preparación para futuras funcionalidades)
  Map<String, dynamic> exportarDatos() {
    return {
      'estadisticasGenerales': _estadisticasGenerales,
      'reporteVentas': _reporteVentas,
      'reporteViajes': _reporteViajes,
      'reporteOcupacion': _reporteOcupacion,
      'fechaGeneracion': DateTime.now().toIso8601String(),
    };
  }

  // Limpiar datos
  void limpiarDatos() {
    _estadisticasGenerales = {};
    _reporteVentas = [];
    _reporteViajes = [];
    _reporteOcupacion = [];
    _clearError();
    notifyListeners();
  }
}