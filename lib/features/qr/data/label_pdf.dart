import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../assets/domain/asset.dart';
import '../domain/qr_payload.dart';

/// Builds the printable PDFs: one label, or an A4 sheet of labels
/// (3 columns by 8 rows, 24 per page) ready for sticker paper.
class LabelPdf {
  const LabelPdf._();

  static pw.Widget _label(Asset asset, {required double qr, double? width, double? height}) {
    return pw.Container(
      width: width,
      height: height,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 0.6),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: QrPayload.encode(asset.code),
            width: qr,
            height: qr,
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SCANDESK', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
                pw.SizedBox(height: 2),
                pw.Text(
                  asset.code,
                  style: pw.TextStyle(font: pw.Font.courierBold(), fontSize: 11),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  asset.name,
                  maxLines: 2,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One 100 x 60 mm label.
  static Future<Uint8List> single(Asset asset) async {
    final doc = pw.Document();
    const format = PdfPageFormat(100 * PdfPageFormat.mm, 60 * PdfPageFormat.mm, marginAll: 4 * PdfPageFormat.mm);
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (_) => _label(asset, qr: 120, width: format.availableWidth, height: format.availableHeight),
      ),
    );
    return doc.save();
  }

  /// An A4 sheet of labels, 24 per page.
  static Future<Uint8List> sheet(List<Asset> assets) async {
    final doc = pw.Document();
    const perPage = 24;
    for (var start = 0; start < assets.length; start += perPage) {
      final chunk = assets.skip(start).take(perPage).toList();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => pw.GridView(
            crossAxisCount: 3,
            childAspectRatio: 1.9,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            children: [for (final a in chunk) _label(a, qr: 46)],
          ),
        ),
      );
    }
    return doc.save();
  }
}
