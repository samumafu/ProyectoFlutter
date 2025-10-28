import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // Exportar reporte general a PDF
  Future<Uint8List> exportarReporteGeneralPDF({
    required Map<String, dynamic> estadisticas,
    required List<Map<String, dynamic>> reporteVentas,
    required List<Map<String, dynamic>> reporteViajes,
    required List<Map<String, dynamic>> reporteOcupacion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Text(
                'Reporte de Gestión Empresarial',
                style: pw.TextStyle(font: fontBold, fontSize: 24),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Información del período
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Período de Análisis',
                    style: pw.TextStyle(font: fontBold, fontSize: 16),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Desde: ${DateFormat('dd/MM/yyyy').format(fechaInicio)}',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                  pw.Text(
                    'Hasta: ${DateFormat('dd/MM/yyyy').format(fechaFin)}',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Estadísticas generales
            pw.Text(
              'Estadísticas Generales',
              style: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Métrica', style: pw.TextStyle(font: fontBold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Valor', style: pw.TextStyle(font: fontBold)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total Viajes', style: pw.TextStyle(font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${estadisticas['totalViajes'] ?? 0}', style: pw.TextStyle(font: font)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total Reservas', style: pw.TextStyle(font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${estadisticas['totalReservas'] ?? 0}', style: pw.TextStyle(font: font)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Ingresos Totales', style: pw.TextStyle(font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('\$${(estadisticas['ingresosTotales'] ?? 0.0).toStringAsFixed(0)}', style: pw.TextStyle(font: font)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Tasa de Ocupación', style: pw.TextStyle(font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${(estadisticas['tasaOcupacion'] ?? 0.0).toStringAsFixed(1)}%', style: pw.TextStyle(font: font)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Reporte de ventas
            if (reporteVentas.isNotEmpty) ...[
              pw.Text(
                'Reporte de Ventas por Día',
                style: pw.TextStyle(font: fontBold, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Fecha', style: pw.TextStyle(font: fontBold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Ventas', style: pw.TextStyle(font: fontBold)),
                      ),
                    ],
                  ),
                  ...reporteVentas.map((venta) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(venta['fecha'] as String, style: pw.TextStyle(font: font)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('\$${(venta['ventas'] as double).toStringAsFixed(0)}', style: pw.TextStyle(font: font)),
                      ),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // Reporte de viajes
            if (reporteViajes.isNotEmpty) ...[
              pw.Text(
                'Reporte de Viajes por Estado',
                style: pw.TextStyle(font: fontBold, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Estado', style: pw.TextStyle(font: fontBold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Cantidad', style: pw.TextStyle(font: fontBold)),
                      ),
                    ],
                  ),
                  ...reporteViajes.map((viaje) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(viaje['estado'] as String, style: pw.TextStyle(font: font)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${viaje['cantidad']}', style: pw.TextStyle(font: font)),
                      ),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // Reporte de ocupación
            if (reporteOcupacion.isNotEmpty) ...[
              pw.Text(
                'Reporte de Ocupación por Viaje',
                style: pw.TextStyle(font: fontBold, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Fecha', style: pw.TextStyle(font: fontBold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Ocupación', style: pw.TextStyle(font: fontBold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Asientos', style: pw.TextStyle(font: fontBold)),
                      ),
                    ],
                  ),
                  ...reporteOcupacion.map((ocupacion) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(ocupacion['fecha'] as String, style: pw.TextStyle(font: font)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${(ocupacion['ocupacion'] as double).toStringAsFixed(1)}%', style: pw.TextStyle(font: font)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${ocupacion['asientosOcupados']}/${ocupacion['asientosTotales']}', style: pw.TextStyle(font: font)),
                      ),
                    ],
                  )),
                ],
              ),
            ],

            // Pie de página
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.Text(
              'Reporte generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Exportar reporte a Excel
  Future<String> exportarReporteExcel({
    required Map<String, dynamic> estadisticas,
    required List<Map<String, dynamic>> reporteVentas,
    required List<Map<String, dynamic>> reporteViajes,
    required List<Map<String, dynamic>> reporteOcupacion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final excel = Excel.createExcel();
    
    // Eliminar hoja por defecto
    excel.delete('Sheet1');

    // Hoja de estadísticas generales
    final statsSheet = excel['Estadísticas Generales'];
    
    // Encabezados
    statsSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Reporte de Gestión Empresarial');
    statsSheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Período: ${DateFormat('dd/MM/yyyy').format(fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(fechaFin)}');
    
    // Estadísticas
    statsSheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Métrica');
    statsSheet.cell(CellIndex.indexByString('B4')).value = TextCellValue('Valor');
    
    statsSheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Total Viajes');
    statsSheet.cell(CellIndex.indexByString('B5')).value = IntCellValue(estadisticas['totalViajes'] ?? 0);
    
    statsSheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Total Reservas');
    statsSheet.cell(CellIndex.indexByString('B6')).value = IntCellValue(estadisticas['totalReservas'] ?? 0);
    
    statsSheet.cell(CellIndex.indexByString('A7')).value = TextCellValue('Ingresos Totales');
    statsSheet.cell(CellIndex.indexByString('B7')).value = DoubleCellValue(estadisticas['ingresosTotales'] ?? 0.0);
    
    statsSheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Tasa de Ocupación (%)');
    statsSheet.cell(CellIndex.indexByString('B8')).value = DoubleCellValue(estadisticas['tasaOcupacion'] ?? 0.0);

    // Hoja de ventas
    if (reporteVentas.isNotEmpty) {
      final ventasSheet = excel['Ventas por Día'];
      
      ventasSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Fecha');
      ventasSheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Ventas');
      
      for (int i = 0; i < reporteVentas.length; i++) {
        final row = i + 2;
        ventasSheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(reporteVentas[i]['fecha'] as String);
        ventasSheet.cell(CellIndex.indexByString('B$row')).value = DoubleCellValue(reporteVentas[i]['ventas'] as double);
      }
    }

    // Hoja de viajes
    if (reporteViajes.isNotEmpty) {
      final viajesSheet = excel['Viajes por Estado'];
      
      viajesSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Estado');
      viajesSheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Cantidad');
      
      for (int i = 0; i < reporteViajes.length; i++) {
        final row = i + 2;
        viajesSheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(reporteViajes[i]['estado'] as String);
        viajesSheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(reporteViajes[i]['cantidad'] as int);
      }
    }

    // Hoja de ocupación
    if (reporteOcupacion.isNotEmpty) {
      final ocupacionSheet = excel['Ocupación por Viaje'];
      
      ocupacionSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Fecha');
      ocupacionSheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Ocupación (%)');
      ocupacionSheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Asientos Ocupados');
      ocupacionSheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Asientos Totales');
      
      for (int i = 0; i < reporteOcupacion.length; i++) {
        final row = i + 2;
        ocupacionSheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(reporteOcupacion[i]['fecha'] as String);
        ocupacionSheet.cell(CellIndex.indexByString('B$row')).value = DoubleCellValue(reporteOcupacion[i]['ocupacion'] as double);
        ocupacionSheet.cell(CellIndex.indexByString('C$row')).value = IntCellValue(reporteOcupacion[i]['asientosOcupados'] as int);
        ocupacionSheet.cell(CellIndex.indexByString('D$row')).value = IntCellValue(reporteOcupacion[i]['asientosTotales'] as int);
      }
    }

    // Guardar archivo
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'reporte_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final filePath = '${directory.path}/$fileName';
    
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
    }

    return filePath;
  }

  // Compartir PDF
  Future<void> compartirPDF(Uint8List pdfBytes, String nombreArchivo) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: nombreArchivo,
    );
  }

  // Imprimir PDF
  Future<void> imprimirPDF(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }
}