import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:sale_manager/pages/TicketAchat.dart';
import 'package:sale_manager/bluetooth_printer.dart';

/// Aperçu du ticket avant impression : montre le rendu exact du reçu, puis
/// propose d'imprimer directement sur l'imprimante thermique Bluetooth
/// appairée (sélection automatique si une seule), ou de passer par le
/// partage / une autre imprimante en repli.
class TicketPreviewPage extends StatefulWidget {
  final Map<String, dynamic> achat;
  const TicketPreviewPage({super.key, required this.achat});

  @override
  State<TicketPreviewPage> createState() => _TicketPreviewPageState();
}

class _TicketPreviewPageState extends State<TicketPreviewPage> {
  PdfRaster? _apercu;
  bool _impressionEnCours = false;

  @override
  void initState() {
    super.initState();
    _construireApercu();
  }

  Future<void> _construireApercu() async {
    final pdf = await buildAchatPdf(widget.achat);
    final bytes = await pdf.save();
    await for (final page in Printing.raster(bytes, dpi: 200)) {
      if (mounted) setState(() => _apercu = page);
      break; // un seul page (58mm, longueur variable)
    }
  }

  Future<void> _imprimerBluetooth({String? macAdressChoisie}) async {
    setState(() => _impressionEnCours = true);
    final resultat = await BluetoothPrinter.imprimerTicket(widget.achat, macAdressChoisie: macAdressChoisie);
    if (!mounted) return;
    setState(() => _impressionEnCours = false);

    switch (resultat.outcome) {
      case PrintOutcome.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ticket envoyé à l'imprimante")),
        );
        break;
      case PrintOutcome.chooseOne:
        _demanderChoixImprimante(resultat.printers);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultat.message ?? "Échec de l'impression")),
        );
    }
  }

  void _demanderChoixImprimante(List<BluetoothInfo> printers) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Choisir l'imprimante"),
        children: printers
            .map((p) => SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    _imprimerBluetooth(macAdressChoisie: p.macAdress);
                  },
                  child: Text(p.name),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Aperçu du ticket", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color.fromARGB(255, 235, 233, 224),
              child: Center(
                child: _apercu == null
                    ? const CircularProgressIndicator()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Image(image: PdfRasterImage(_apercu!)),
                        ),
                      ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _impressionEnCours ? null : () => _imprimerBluetooth(),
                    icon: _impressionEnCours
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.print),
                    label: Text(_impressionEnCours ? "Impression..." : "Imprimer (imprimante Bluetooth)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => generateAchatPdf(widget.achat),
                    icon: const Icon(Icons.share),
                    label: const Text("Partager / autre imprimante"),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
