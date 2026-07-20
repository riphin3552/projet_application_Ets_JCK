import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class LotsPage extends StatefulWidget {
  const LotsPage({super.key});

  @override
  State<LotsPage> createState() => _LotsPageState();
}

class _LotsPageState extends State<LotsPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeLotController = TextEditingController();
  int? selectedProduitId;
  int? selectedDepotId;
  List<Map<String, dynamic>> produits = [];
  List<Map<String, dynamic>> depots = [];
  List<Map<String, dynamic>> lots = [];
  bool loading = false;
  bool canGererLots = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    canGererLots = await Session.can('lots.gerer');
    await Future.wait([fetchProduits(), fetchDepots(), fetchLots()]);
    setState(() {});
  }

  Future<void> fetchProduits() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/getProducts.php'), headers: await Session.authHeaders());
    if (response.statusCode == 200) {
      produits = List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
  }

  Future<void> fetchDepots() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/get_depots.php'), headers: await Session.authHeaders());
    if (response.statusCode == 200) {
      depots = List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
  }

  Future<void> fetchLots() async {
    setState(() => loading = true);
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/get_lots.php'), headers: await Session.authHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        lots = List<Map<String, dynamic>>.from(data['data']);
      }
    }
    setState(() => loading = false);
  }

  Future<void> createLot() async {
    if (!_formKey.currentState!.validate()) return;
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/create_lot.php'),
      headers: await Session.authHeaders(),
      body: jsonEncode({
        'codeLot': _codeLotController.text.trim(),
        'idProduit': selectedProduitId,
        'idStockage': selectedDepotId,
      }),
    );
    final data = jsonDecode(response.body);
    if (!mounted) return;
    if (data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lot créé avec succès')));
      _codeLotController.clear();
      setState(() {
        selectedProduitId = null;
        selectedDepotId = null;
      });
      await fetchLots();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec de la création du lot')));
    }
  }

  Future<void> closeLot(int idLot, String statut) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/close_lot.php'),
      headers: await Session.authHeaders(),
      body: jsonEncode({'idLot': idLot, 'statut': statut}),
    );
    final data = jsonDecode(response.body);
    if (!mounted) return;
    if (data['success'] == true) {
      await fetchLots();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Lots / Traçabilité", style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: fetchLots,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (canGererLots)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text("Nouveau lot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _codeLotController,
                          decoration: const InputDecoration(labelText: "Code du lot", border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.isEmpty) ? "Code requis" : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedProduitId,
                          items: produits.map((p) => DropdownMenuItem<int>(value: p['IdProduit'], child: Text(p['designationProduit']))).toList(),
                          onChanged: (v) => setState(() => selectedProduitId = v),
                          decoration: const InputDecoration(labelText: "Produit", border: OutlineInputBorder()),
                          validator: (v) => v == null ? "Produit requis" : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedDepotId,
                          items: depots.map((d) => DropdownMenuItem<int>(value: d['IdStockage'], child: Text(d['CodeDepot']))).toList(),
                          onChanged: (v) => setState(() => selectedDepotId = v),
                          decoration: const InputDecoration(labelText: "Dépôt", border: OutlineInputBorder()),
                          validator: (v) => v == null ? "Dépôt requis" : null,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: createLot,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          child: const Text("Créer le lot", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text("Lots existants", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            if (loading) const Center(child: CircularProgressIndicator()),
            ...lots.map((lot) => Card(
                  child: ListTile(
                    title: Text("${lot['code_lot']} — ${lot['designationProduit']}"),
                    subtitle: Text("Dépôt: ${lot['CodeDepot']} • Poids: ${lot['poids_total']} kg • Statut: ${lot['statut']}"),
                    trailing: canGererLots && lot['statut'] == 'ouvert'
                        ? PopupMenuButton<String>(
                            onSelected: (statut) => closeLot(lot['id_lot'], statut),
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'ferme', child: Text('Clôturer')),
                              PopupMenuItem(value: 'expedie', child: Text('Marquer expédié')),
                            ],
                          )
                        : null,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
