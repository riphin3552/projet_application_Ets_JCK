import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

Future<void> generateAchatPdf(Map<String, dynamic> achat) async {
  final pdf = pw.Document();

  // 🔹 Charge le logo depuis les assets
  final ByteData bytes = await rootBundle.load('images/etsJCK.jpg');
  
  final Uint8List logoBytes = bytes.buffer.asUint8List();

  pdf.addPage(
    pw.Page(
      //pageFormat: PdfPageFormat.a4,
      pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity),

      build: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ✅ Logo centré
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  height: 80,
                ),
                
              ),
              
              
              // ✅ Titre
              pw.Center(child: pw.Text('ETABLISSEMENT JCK', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'RECU DE VENTE', 
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), 
                ),
              ),
              pw.SizedBox(height: 20),

              // ✅ Infos générales
              pw.Text('Date : ${achat['dateAchat']}'),
              pw.Text('N° Reçu : ${achat['Idachat']}'),
              pw.Text('planteur : ${achat['nomAgriculteur']}'),
              pw.Text('Code fermer : ${achat['CodePlanteur'] ?? '---'}'),
              pw.Text('Dépôt : ${achat['CodeDepot']}'),

              pw.Divider(),

              // ✅ Détails produit
              pw.Text('Produit : ${achat['designationProduit']}'),
              pw.Text('Quantité : ${achat['Quantite_KG']} kg'),
              pw.Text('Prix unitaire : ${achat['prixUnitaire']} FC'),
              pw.Text('Prime : ${achat['PrimePlanteur']} FC'),
              pw.Text('Total payé : ${achat['totalPayer']} FC', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

              pw.Divider(),

              pw.SizedBox(height: 20),
              pw.Text('Merci pour votre vente !', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 10),
              pw.Text('Signature planteur :\n           \n_________________'),
            ],
          ),
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}

