import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

const String _nomEntreprise = 'ETABLISSEMENT JCK';
const PdfColor _encre = PdfColor.fromInt(0xFF1C2118);
const PdfColor _foret = PdfColor.fromInt(0xFF2B5A3B);
const PdfColor _filet = PdfColor.fromInt(0xFFBFBBA9);
const PdfColor _fondEnTete = PdfColor.fromInt(0xFFEFECDF);

/// Construit le document PDF du reçu (utilisé pour l'aperçu à l'écran et
/// pour l'impression via une imprimante autre que Bluetooth thermique).
/// N'imprime pas lui-même : l'appelant décide (aperçu, PDF système...).
Future<pw.Document> buildAchatPdf(Map<String, dynamic> achat) async {
  final pdf = pw.Document();

  final ByteData logoData = await rootBundle.load('images/etsJCK.jpg');
  final Uint8List logoBytes = logoData.buffer.asUint8List();

  final String numeroBon = (achat['NumeroBon'] ?? '').toString().isNotEmpty
      ? achat['NumeroBon'].toString()
      : 'BON-${achat['Idachat']}';

  final String qrPayload = jsonEncode({
    'numeroBon': numeroBon,
    'idAchat': achat['Idachat'],
    'planteur': achat['nomAgriculteur'],
    'quantiteKg': achat['Quantite_KG'],
    'date': achat['dateAchat'],
  });

  final fRegular = pw.Font.courier();
  final fBold = pw.Font.courierBold();
  final fItalic = pw.Font.courierOblique();

  pw.Widget ligne(String label, String valeur, {bool accent = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(font: fRegular, fontSize: 8, color: _encre)),
          pw.SizedBox(width: 8),
          pw.Flexible(
            child: pw.Text(
              valeur,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                font: accent ? fBold : fRegular,
                fontSize: accent ? 9 : 8.5,
                color: accent ? _foret : _encre,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget titreSection(String titre) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 3),
      child: pw.Text(
        titre.toUpperCase(),
        style: pw.TextStyle(font: fBold, fontSize: 7.5, color: _foret, letterSpacing: 1.2),
      ),
    );
  }

  pw.Widget filet({double epaisseur = 0.6}) => pw.Divider(color: _filet, thickness: epaisseur, height: 10);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity),
      margin: const pw.EdgeInsets.all(14),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // -------- En-tête --------
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              decoration: const pw.BoxDecoration(color: _fondEnTete),
              child: pw.Column(
                children: [
                  pw.Center(child: pw.Image(pw.MemoryImage(logoBytes), height: 46)),
                  pw.SizedBox(height: 6),
                  pw.Center(
                    child: pw.Text(_nomEntreprise, style: pw.TextStyle(font: fBold, fontSize: 10.5, color: _encre, letterSpacing: 0.6)),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Center(
                    child: pw.Text('REÇU D\'ACHAT', style: pw.TextStyle(font: fRegular, fontSize: 7, color: _foret, letterSpacing: 1.4)),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // -------- Référence du bon --------
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _foret, width: 0.8)),
              child: pw.Column(
                children: [
                  pw.Text('N° DE BON', style: pw.TextStyle(font: fRegular, fontSize: 6.5, color: _encre, letterSpacing: 1)),
                  pw.SizedBox(height: 2),
                  pw.Text(numeroBon, style: pw.TextStyle(font: fBold, fontSize: 13, color: _foret)),
                ],
              ),
            ),

            titreSection('Informations'),
            ligne('Date', '${achat['dateAchat']}'),
            ligne('Dépôt', '${achat['CodeDepot']}'),
            if ((achat['nomutilisateur'] ?? '').toString().isNotEmpty) ligne('Opérateur', '${achat['nomutilisateur']}'),

            filet(),
            titreSection('Planteur'),
            ligne('Nom', '${achat['nomAgriculteur']}'),
            ligne('Code planteur', '${achat['CodePlanteur'] ?? '---'}'),

            filet(),
            titreSection('Produit'),
            ligne('Désignation', '${achat['designationProduit']}'),
            ligne('Quantité', '${achat['Quantite_KG']} kg'),
            ligne('Prix unitaire', '${achat['prixUnitaire']} FC/kg'),
            ligne('Prime planteur', '${achat['PrimePlanteur']} FC'),

            filet(epaisseur: 1),

            // -------- Total --------
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              decoration: const pw.BoxDecoration(color: _fondEnTete),
              child: pw.Column(
                children: [
                  pw.Text('TOTAL PAYÉ', style: pw.TextStyle(font: fRegular, fontSize: 7, color: _encre, letterSpacing: 1)),
                  pw.SizedBox(height: 2),
                  pw.Text('${achat['totalPayer']} FC', style: pw.TextStyle(font: fBold, fontSize: 14, color: _encre)),
                ],
              ),
            ),

            pw.SizedBox(height: 14),
            pw.Center(
              child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: qrPayload, width: 78, height: 78),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text('Scannez pour vérifier ce bon', style: pw.TextStyle(font: fRegular, fontSize: 6, color: _encre)),
            ),

            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text('Merci pour votre confiance', style: pw.TextStyle(font: fItalic, fontSize: 8, color: _foret)),
            ),
            pw.SizedBox(height: 18),
            pw.Text('Signature du planteur :', style: pw.TextStyle(font: fRegular, fontSize: 7.5, color: _encre)),
            pw.SizedBox(height: 20),
            filet(),
          ],
        );
      },
    ),
  );

  return pdf;
}

/// Compatibilité : ouvre directement la boîte de dialogue d'impression du
/// système (utilisé comme solution de repli pour une imprimante non
/// Bluetooth, ou tel quel là où l'aperçu n'est pas branché).
Future<void> generateAchatPdf(Map<String, dynamic> achat) async {
  final pdf = await buildAchatPdf(achat);
  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}
