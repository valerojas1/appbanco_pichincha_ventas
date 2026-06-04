import 'dart:typed_data';
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/solicitud_resumen_model.dart';

class SolicitudPdfService {
  Future<Uint8List> generarPdf(SolicitudDetalleModel solicitud) async {
    final doc = pw.Document();
    final qrData = 'BP-EXP:${solicitud.numeroExpediente ?? solicitud.id}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BANCO PICHINCHA',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    'Perú — Portal Oficial Ventas',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: qrData,
                width: 80,
                height: 80,
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Resumen de solicitud de crédito',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(),
          _fila('Expediente', solicitud.numeroExpediente ?? 'Pendiente'),
          _fila('Cliente', solicitud.nombreCliente),
          _fila('DNI', solicitud.dni),
          _fila('Monto', 'S/ ${solicitud.monto.toStringAsFixed(0)}'),
          _fila('Plazo', '${solicitud.plazoMeses} meses'),
          if (solicitud.cuotaMensual != null && solicitud.cuotaMensual! > 0)
            _fila(
              'Cuota estimada',
              'S/ ${solicitud.cuotaMensual!.toStringAsFixed(2)}',
            ),
          _fila('Estado', solicitud.estado?.etiqueta ?? '—'),
          _fila(
            'Analista',
            solicitud.analistaAsignado ?? 'Por asignar',
          ),
          if (solicitud.fechaEnvio != null)
            _fila('Fecha envío', _fmt(solicitud.fechaEnvio!)),
          if (solicitud.motivoRechazo != null &&
              solicitud.motivoRechazo!.isNotEmpty)
            _fila('Motivo rechazo', solicitud.motivoRechazo!),
          pw.SizedBox(height: 24),
          pw.Text(
            'Documento generado desde la app oficial. '
            'Escanee el código QR para verificar el expediente.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _fila(String label, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(valor, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> compartirPdf(Uint8List bytes, String nombreArchivo) async {
    await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
  }
}
