import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class InventairePage extends StatefulWidget {
  const InventairePage({super.key});

  @override
  State<InventairePage> createState() => _InventairePageState();
}

class _InventairePageState extends State<InventairePage> {
  final _formKey = GlobalKey<FormState>();
  final _quantitePhysiqueController = TextEditingController();
  final _commentaireController = TextEditingController();
  int? selectedDepotId;
  List<Map<String, dynamic>> depots = [];
  List<Map<String, dynamic>> inventaires = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchDepots();
    fetchInventaires();
  }

  Future<void> fetchDepots() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/get_depots.php'), headers: await Session.authHeaders());
    if (response.statusCode == 200) {
      setState(() {
        depots = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        if (depots.length == 1) selectedDepotId = depots.first['IdStockage'];
      });
    }
  }

  Future<void> fetchInventaires() async {
    setState(() => loading = true);
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/get_inventaires.php'), headers: await Session.authHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        inventaires = List<Map<String, dynamic>>.from(data['data']);
      }
    }
    setState(() => loading = false);
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/register_inventaire.php'),
      headers: await Session.authHeaders(),
      body: jsonEncode({
        'idStockage': selectedDepotId,
        'quantitePhysique': _quantitePhysiqueController.text.trim(),
        'commentaire': _commentaireController.text.trim(),
      }),
    );
    final data = jsonDecode(response.body);
    if (!mounted) return;
    if (data['success'] == true) {
      final ecart = data['ecart'];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Inventaire enregistré"),
          content: Text("Écart constaté : $ecart kg\n(théorique: ${data['quantiteTheorique']} kg, physique: ${data['quantitePhysique']} kg)"),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
      _quantitePhysiqueController.clear();
      _commentaireController.clear();
      await fetchInventaires();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Inventaire physique", style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: fetchInventaires,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text("Nouvel inventaire", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedDepotId,
                        items: depots.map((d) => DropdownMenuItem<int>(value: d['IdStockage'], child: Text(d['CodeDepot']))).toList(),
                        onChanged: (v) => setState(() => selectedDepotId = v),
                        decoration: const InputDecoration(labelText: "Dépôt", border: OutlineInputBorder()),
                        validator: (v) => v == null ? "Dépôt requis" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _quantitePhysiqueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Quantité physique comptée (kg)", border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.isEmpty) ? "Quantité requise" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _commentaireController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: "Commentaire (optionnel)", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        child: const Text("Enregistrer l'inventaire", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Historique", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            if (loading) const Center(child: CircularProgressIndicator()),
            ...inventaires.map((inv) => Card(
                  child: ListTile(
                    title: Text("${inv['CodeDepot']} — ${inv['date_inventaire']}"),
                    subtitle: Text(
                      "Théorique: ${inv['quantite_theorique']} kg • Physique: ${inv['quantite_physique']} kg • Écart: ${inv['ecart']} kg\nPar ${inv['nomutilisateur']}",
                    ),
                    isThreeLine: true,
                    trailing: Icon(
                      (double.tryParse(inv['ecart'].toString()) ?? 0) == 0 ? Icons.check_circle : Icons.warning,
                      color: (double.tryParse(inv['ecart'].toString()) ?? 0) == 0 ? Colors.green : Colors.orange,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
