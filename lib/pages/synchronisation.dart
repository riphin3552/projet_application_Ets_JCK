import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';
import 'package:sale_manager/offline_queue.dart';

class SynchronisationPage extends StatefulWidget {
  const SynchronisationPage({super.key});

  @override
  State<SynchronisationPage> createState() => _SynchronisationPageState();
}

class _SynchronisationPageState extends State<SynchronisationPage> {
  List<Map<String, dynamic>> pending = [];
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    pending = await OfflineQueue.getAll();
    setState(() {});
  }

  Future<void> synchroniser() async {
    if (pending.isEmpty) return;
    setState(() => syncing = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/sync_achats.php'),
        headers: await Session.authHeaders(),
        body: jsonEncode({'achats': pending}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final resultats = List<Map<String, dynamic>>.from(data['resultats']);
        final reussis = resultats.where((r) => r['success'] == true).map((r) => r['uuidClient'] as String).toList();
        final echecs = resultats.where((r) => r['success'] != true).toList();
        await OfflineQueue.removeByUuid(reussis);
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${reussis.length} achat(s) synchronisé(s)" + (echecs.isNotEmpty ? ", ${echecs.length} en échec" : ""))),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec de synchronisation')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Synchronisation", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("${pending.length} achat(s) en attente de synchronisation", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: (pending.isEmpty || syncing) ? null : synchroniser,
              icon: syncing ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
              label: Text(syncing ? "Synchronisation..." : "Synchroniser maintenant"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: pending.length,
                itemBuilder: (context, index) {
                  final a = pending[index];
                  return Card(
                    child: ListTile(
                      title: Text("Quantité: ${a['quantite']} kg — Total: ${a['totalpayer']} FC"),
                      subtitle: Text("Date: ${a['date']} • Dépôt: ${a['depot']}"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
