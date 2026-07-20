import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class PaiementsPage extends StatefulWidget {
  final Map<String, dynamic> achatData;
  const PaiementsPage({super.key, required this.achatData});

  @override
  State<PaiementsPage> createState() => _PaiementsPageState();
}

class _PaiementsPageState extends State<PaiementsPage> {
  final _montantController = TextEditingController();
  final _motifController = TextEditingController();
  String modePaiement = 'especes';

  List<dynamic> paiements = [];
  double totalDu = 0;
  double totalPaye = 0;
  double soldeRestant = 0;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchPaiements();
  }

  Future<void> fetchPaiements() async {
    setState(() => loading = true);
    final idAchat = widget.achatData['Idachat'];
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/get_paiements.php?idAchat=$idAchat'),
      headers: await Session.authHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          paiements = data['data'];
          totalDu = double.tryParse(data['totalDu'].toString()) ?? 0;
          totalPaye = double.tryParse(data['totalPaye'].toString()) ?? 0;
          soldeRestant = double.tryParse(data['soldeRestant'].toString()) ?? 0;
        });
      }
    }
    setState(() => loading = false);
  }

  Future<void> enregistrerPaiement() async {
    final montant = double.tryParse(_montantController.text);
    if (montant == null || montant <= 0 || _motifController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Montant et motif requis")));
      return;
    }
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/register_paiement.php'),
      headers: await Session.authHeaders(),
      body: jsonEncode({
        'montant': montant,
        'motif': _motifController.text.trim(),
        'typeOperation': 'sortie',
        'modePaiement': modePaiement,
        'idAchat': widget.achatData['Idachat'],
      }),
    );
    final data = jsonDecode(response.body);
    if (!mounted) return;
    if (data['success'] == true) {
      _montantController.clear();
      _motifController.clear();
      await fetchPaiements();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Paiements", style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: fetchPaiements,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color.fromARGB(230, 248, 236, 236),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Achat #${widget.achatData['Idachat']} — ${widget.achatData['nomAgriculteur'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Total dû : $totalDu FC"),
                    Text("Total payé : $totalPaye FC"),
                    Text("Solde restant : $soldeRestant FC", style: TextStyle(fontWeight: FontWeight.bold, color: soldeRestant > 0 ? Colors.red : Colors.green)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (soldeRestant > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text("Nouvelle tranche de paiement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _montantController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Montant (FC)", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _motifController,
                        decoration: const InputDecoration(labelText: "Motif", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: modePaiement,
                        items: const [
                          DropdownMenuItem(value: 'especes', child: Text('Espèces')),
                          DropdownMenuItem(value: 'mobile_money', child: Text('Mobile money')),
                          DropdownMenuItem(value: 'virement', child: Text('Virement')),
                          DropdownMenuItem(value: 'autre', child: Text('Autre')),
                        ],
                        onChanged: (v) => setState(() => modePaiement = v ?? 'especes'),
                        decoration: const InputDecoration(labelText: "Mode de paiement", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: enregistrerPaiement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        child: const Text("Enregistrer le paiement", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text("Historique des paiements", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (loading) const Center(child: CircularProgressIndicator()),
            ...paiements.map((p) => Card(
                  child: ListTile(
                    title: Text("${p['mont']} FC — ${p['motifOperation']}"),
                    subtitle: Text("${p['ModePaiement']} • ${p['Statut']} • ${p['DateOperation']}"),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
