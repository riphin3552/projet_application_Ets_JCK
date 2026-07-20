import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class ExportCsvPage extends StatefulWidget {
  const ExportCsvPage({super.key});

  @override
  State<ExportCsvPage> createState() => _ExportCsvPageState();
}

class _ExportCsvPageState extends State<ExportCsvPage> {
  DateTime start = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime end = DateTime.now();
  bool exporting = false;

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? start : end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          start = picked;
        } else {
          end = picked;
        }
      });
    }
  }

  Future<void> exportAndShare() async {
    setState(() => exporting = true);
    try {
      final s = DateFormat('yyyy-MM-dd').format(start);
      final e = DateFormat('yyyy-MM-dd').format(end);
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/export_achats.php?start=$s&end=$e'),
        headers: await Session.authHeaders(),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Échec de l'export (${response.statusCode})")));
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/achats_${s}_$e.csv');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Export achats $s au $e',
      );
    } catch (ex) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Export comptable", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Sélectionnez la période à exporter", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDate(true),
                    child: Text("Début: ${DateFormat('yyyy-MM-dd').format(start)}"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDate(false),
                    child: Text("Fin: ${DateFormat('yyyy-MM-dd').format(end)}"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: exporting ? null : exportAndShare,
              icon: exporting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.share),
              label: Text(exporting ? "Export en cours..." : "Exporter le CSV"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
