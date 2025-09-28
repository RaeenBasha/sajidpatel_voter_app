import 'package:flutter/material.dart' show BuildContext, ScaffoldMessenger, SnackBar, Text;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/voter.dart';

Future<void> generateVoterSlipsPDF(List<Voter> voters, BuildContext context) async {
  if (voters.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No voters to print')));
    return;
  }
  final pdf = pw.Document();
  for (final v in voters) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Voter Slip', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Voter Name: ${v.name}'),
            pw.Text('EPIC No (RSC): ${v.rscNumber}'),
            pw.Text('List No / Part No (YADI): ${v.yadiNo}'),
            pw.Text('Sr No: ${v.srNo}'),
            pw.Text('Sector: ${v.sector}'),
            pw.Text('Building: ${v.buildingName} (${v.buildingNo})'),
            pw.Text('Flat: ${v.flatNumber}'),
            pw.Text('Polling Booth: ${v.pollingBooth}'),
          ],
        ),
      ),
    );
  }
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
