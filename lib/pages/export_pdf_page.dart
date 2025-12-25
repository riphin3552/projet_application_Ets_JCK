import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ExportPdfPage extends StatelessWidget {
  final List<dynamic> data;
  final DateTime? startDate;
  final DateTime? endDate;
  final String userName;
  final String depotId;
  final String companyName;

  ExportPdfPage({
    required this.data,
    required this.startDate,
    required this.endDate,
    required this.userName,
    required this.depotId,
    required this.companyName,
  });

  final formatter = DateFormat('yyyy-MM-dd');

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    // Logo (remplace par ton asset)
    final logo = await imageFromAssetBundle('assets/logo.png');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logo, width: 60, height: 60),
                  pw.Text(companyName,
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Infos dépôt et période
              pw.Text("Dépôt: $depotId"),
              pw.Text(
                  "Période: ${formatter.format(startDate!)} au ${formatter.format(endDate!)}"),
              pw.SizedBox(height: 20),

              // Tableau
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: [
                  'Date',
                  'Stock Initial',
                  'Entrée',
                  'Sortie',
                  'Stock Final'
                ],
                data: data.map((row) {
                  return [
                    row['DateJour'],
                    row['StockInitial'].toString(),
                    row['Entree'].toString(),
                    row['Sortie'].toString(),
                    row['StockFinal'].toString(),
                  ];
                }).toList(),
              ),

              pw.Spacer(),

              // Footer
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text("Utilisateur: $userName",
                    style: pw.TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Exporter PDF")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Printing.layoutPdf(
              onLayout: (PdfPageFormat format) async => _generatePdf(format),
            );
          },
          child: const Text("Générer et Imprimer PDF"),
        ),
      ),
    );
  }
}