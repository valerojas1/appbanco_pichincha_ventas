import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/productividad_asesor_model.dart';

class ReporteProductividadPdfService {
  Future<Uint8List> generar(List<ProductividadAsesorModel> filas) async {
    final doc = pw.Document();
    final mes = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Text(
            'Reporte de productividad — ${mes.month}/${mes.year}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: [
              'Asesor',
              'Enviadas',
              'Aprobadas',
              'Desembolsadas',
              'Monto S/',
              'Tasa %',
            ],
            data: filas
                .map(
                  (f) => [
                    f.nombreAsesor,
                    '${f.enviadas}',
                    '${f.aprobadas}',
                    '${f.desembolsadas}',
                    f.montoDesembolsado.toStringAsFixed(0),
                    f.tasaAprobacion.toStringAsFixed(1),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> compartir(Uint8List bytes) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'productividad_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
