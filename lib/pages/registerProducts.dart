import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class Produits extends StatefulWidget {
  const Produits({super.key});

  @override
  State<Produits> createState() => _ProduitsState();
}

class _ProduitsState extends State<Produits> {
  final _produitFormKey = GlobalKey<FormState>();
  final _nomProduitController = TextEditingController();
  final _descriptionProduitController = TextEditingController();
  final _prixController = TextEditingController();

  List<Map<String, dynamic>> produits = [];
  bool chargement = false;
  bool peutGerer = false;

  @override
  void initState() {
    super.initState();
    chargerPermission();
    fetchProduits();
  }

// gestion des permissions pour savoir si l'utilisateur peut gérer les produits
  Future<void> chargerPermission() async {
    final peut = await Session.can('produits.gerer');
    if (mounted) setState(() => peutGerer = peut);
  }

  Future<void> fetchProduits() async {
    setState(() => chargement = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/getProducts.php'),
        headers: await Session.authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() => produits = data);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
      }
    }
    if (mounted) setState(() => chargement = false);
  }

  Future<void> addProduit(String nomProduit, String descriptionProduit, double prix) async {
    var url = Uri.parse('${AppConfig.apiBaseUrl}/registerProducts.php');
    var response = await http
        .post(
          url,
          headers: await Session.authHeaders(),
          body: json.encode({
            'nameproduct': nomProduit,
            'descriptionproduct': descriptionProduit,
            'prix': prix,
            'availablequantity': 0.0,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (!mounted) return;
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['error'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produit ajouté avec succès")));
        resetFields();
        await fetchProduits();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Échec: ${jsonResponse['error']}")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    }
  }

  void resetFields() {
    _nomProduitController.clear();
    _descriptionProduitController.clear();
    _prixController.clear();
  }

  /// Ouvre un formulaire pré-rempli pour modifier un produit existant
  /// (nom, description, prix). Le nouveau prix ne s'appliquera qu'aux
  /// achats créés après cette modification ; les achats déjà enregistrés
  /// gardent leur propre prix, jamais recalculé rétroactivement.
  Future<void> modifierProduit(Map<String, dynamic> produit) async {
    final nomController = TextEditingController(text: produit['designationProduit']);
    final descController = TextEditingController(text: produit['DescriptionProduit'] ?? '');
    final prixController = TextEditingController(text: (produit['Prix'] ?? 0).toString());
    final formKey = GlobalKey<FormState>();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier le produit"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(labelText: "Nom produit", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: prixController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Prix (FC)",
                  border: OutlineInputBorder(),
                  helperText: "S'applique uniquement aux prochains achats, pas aux achats déjà enregistrés",
                ),
                validator: (v) => (v == null || double.tryParse(v) == null) ? "Prix invalide" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/update_produit.php'),
        headers: await Session.authHeaders(),
        body: jsonEncode({
          'idProduit': produit['IdProduit'],
          'nameproduct': nomController.text,
          'descriptionproduct': descController.text,
          'prix': double.tryParse(prixController.text) ?? 0,
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produit mis à jour")));
        await fetchProduits();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec de la mise à jour')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Produits", style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: fetchProduits,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 4,
              color: const Color.fromARGB(230, 248, 236, 236),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _produitFormKey,
                  child: Column(
                    children: [
                      const Text("Ajouter un Produit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomProduitController,
                        decoration: const InputDecoration(
                          labelText: "Nom Produit",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? "Saisir le nom du produit" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionProduitController,
                        decoration: const InputDecoration(
                          labelText: "Description Produit",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? "Saisir la description du produit" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _prixController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Prix (FC)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.price_change),
                          helperText: "Ce prix sera proposé automatiquement lors des achats de ce produit",
                        ),
                        validator: (value) => (value == null || double.tryParse(value) == null) ? "Prix invalide" : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_produitFormKey.currentState!.validate()) {
                            addProduit(
                              _nomProduitController.text,
                              _descriptionProduitController.text,
                              double.tryParse(_prixController.text) ?? 0,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text("Enregistrer"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Liste des produits", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            if (chargement) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            if (!chargement && produits.isEmpty) const Text("Aucun produit enregistré"),
            ...produits.map((p) => Card(
                  child: ListTile(
                    title: Text(p['designationProduit'] ?? ''),
                    subtitle: Text(
                      "${(p['DescriptionProduit'] ?? '').toString().isNotEmpty ? '${p['DescriptionProduit']}\n' : ''}Prix : ${p['Prix'] ?? 0} FC",
                    ),
                    isThreeLine: (p['DescriptionProduit'] ?? '').toString().isNotEmpty,
                    trailing: peutGerer
                        ? IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueGrey),
                            onPressed: () => modifierProduit(p),
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
