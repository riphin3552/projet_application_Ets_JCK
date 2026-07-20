import 'dart:convert';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// Résultat d'une tentative d'impression sur imprimante thermique Bluetooth.
enum PrintOutcome { success, permissionDenied, bluetoothOff, noPrinterPaired, chooseOne, failed }

class PrintResult {
  final PrintOutcome outcome;
  final List<BluetoothInfo> printers; // rempli seulement quand outcome == chooseOne
  final String? message;
  PrintResult(this.outcome, {this.printers = const [], this.message});
}

/// Impression sur imprimante thermique appairée en Bluetooth (norme ESC/POS).
/// Sélectionne automatiquement l'imprimante si une seule est appairée ;
/// si plusieurs sont disponibles, renvoie la liste pour que l'écran demande
/// à l'utilisateur de choisir (une seule fois, pas à chaque impression idéalement).
class BluetoothPrinter {
  static Future<PrintResult> imprimerTicket(
    Map<String, dynamic> achat, {
    String? macAdressChoisie,
  }) async {
    if (!await PrintBluetoothThermal.isPermissionBluetoothGranted) {
      final statuts = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();
      final accorde = statuts.values.every((s) => s.isGranted || s.isLimited);
      if (!accorde) {
        return PrintResult(PrintOutcome.permissionDenied, message: "Autorisation Bluetooth refusée");
      }
    }

    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      return PrintResult(PrintOutcome.bluetoothOff, message: "Le Bluetooth du téléphone est désactivé");
    }

    final appaires = await PrintBluetoothThermal.pairedBluetooths;
    if (appaires.isEmpty) {
      return PrintResult(
        PrintOutcome.noPrinterPaired,
        message: "Aucune imprimante appairée. Associez d'abord l'imprimante thermique dans les réglages Bluetooth du téléphone.",
      );
    }

    String macAdress;
    if (macAdressChoisie != null) {
      macAdress = macAdressChoisie;
    } else if (appaires.length == 1) {
      macAdress = appaires.first.macAdress;
    } else {
      // Plusieurs périphériques Bluetooth appairés : on laisse l'écran choisir.
      return PrintResult(PrintOutcome.chooseOne, printers: appaires);
    }

    final connecte = await PrintBluetoothThermal.connect(macPrinterAddress: macAdress);
    if (!connecte) {
      return PrintResult(PrintOutcome.failed, message: "Impossible de se connecter à l'imprimante");
    }

    try {
      final bytes = await _construireTicketEscPos(achat);
      final envoye = await PrintBluetoothThermal.writeBytes(bytes);
      if (!envoye) {
        return PrintResult(PrintOutcome.failed, message: "Échec de l'envoi à l'imprimante");
      }
      return PrintResult(PrintOutcome.success);
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }

  static Future<List<int>> _construireTicketEscPos(Map<String, dynamic> achat) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    final numeroBon = (achat['NumeroBon'] ?? '').toString().isNotEmpty
        ? achat['NumeroBon'].toString()
        : 'BON-${achat['Idachat']}';

    final qrPayload = jsonEncode({
      'numeroBon': numeroBon,
      'idAchat': achat['Idachat'],
      'planteur': achat['nomAgriculteur'],
      'quantiteKg': achat['Quantite_KG'],
      'date': achat['dateAchat'],
    });

    void ligne(String label, String valeur, {bool accent = false}) {
      bytes += generator.row([
        PosColumn(text: label, width: 5, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(
          text: valeur,
          width: 7,
          styles: PosStyles(align: PosAlign.right, bold: accent),
        ),
      ]);
    }

    bytes += generator.text(
      'ETABLISSEMENT JCK',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
    );
    bytes += generator.text("REÇU D'ACHAT", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    bytes += generator.text(
      'N° $numeroBon',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    );
    bytes += generator.hr();

    ligne('Date', '${achat['dateAchat']}');
    ligne('Dépôt', '${achat['CodeDepot']}');
    if ((achat['nomutilisateur'] ?? '').toString().isNotEmpty) {
      ligne('Opérateur', '${achat['nomutilisateur']}');
    }
    bytes += generator.hr();

    ligne('Planteur', '${achat['nomAgriculteur']}');
    ligne('Code planteur', '${achat['CodePlanteur'] ?? '---'}');
    bytes += generator.hr();

    ligne('Produit', '${achat['designationProduit']}');
    ligne('Quantité', '${achat['Quantite_KG']} kg');
    ligne('Prix unitaire', '${achat['prixUnitaire']} FC/kg');
    ligne('Prime planteur', '${achat['PrimePlanteur']} FC');
    bytes += generator.hr(ch: '=');

    bytes += generator.text(
      'TOTAL PAYÉ',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      '${achat['totalPayer']} FC',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    );

    bytes += generator.feed(1);
    bytes += generator.qrcode(qrPayload, size: QRSize.size6);
    bytes += generator.feed(1);
    bytes += generator.text('Merci pour votre confiance', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }
}
