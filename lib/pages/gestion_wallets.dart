import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';
import 'package:sale_manager/pages/wallet.dart';

/// Réservé au caissier (permission 'operations.gerer') : liste les wallets
/// des acheteurs/chefs de dépôt avec leur solde, et permet de les créditer
/// pour leur permettre de continuer à faire des achats.
class GestionWalletsPage extends StatefulWidget {
  const GestionWalletsPage({super.key});

  @override
  State<GestionWalletsPage> createState() => _GestionWalletsPageState();
}

class _GestionWalletsPageState extends State<GestionWalletsPage> {
  bool chargement = true;
  List<Map<String, dynamic>> wallets = [];
  final _rechercheController = TextEditingController();
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    fetchWallets();
    _rechercheController.addListener(() {
      setState(() => _recherche = _rechercheController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _walletsFiltres {
    if (_recherche.isEmpty) return wallets;
    return wallets.where((w) => (w['nomutilisateur'] ?? '').toString().toLowerCase().contains(_recherche)).toList();
  }

  Future<void> fetchWallets() async {
    setState(() => chargement = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/get_wallets.php'),
        headers: await Session.authHeaders(),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() => wallets = List<Map<String, dynamic>>.from(data['data']));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec du chargement')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    }
    if (mounted) setState(() => chargement = false);
  }

  Future<void> _crediter(Map<String, dynamic> w) async {
    final montantController = TextEditingController();
    final motifController = TextEditingController(text: "Crédit wallet");
    final formKey = GlobalKey<FormState>();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Créditer ${w['nomutilisateur']}"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Solde actuel : ${(double.tryParse(w['solde'].toString()) ?? 0).toStringAsFixed(0)} FC"),
              const SizedBox(height: 16),
              TextFormField(
                controller: montantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Montant à créditer (FC)", border: OutlineInputBorder()),
                validator: (v) {
                  final m = double.tryParse(v ?? '');
                  if (m == null || m <= 0) return "Montant invalide";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: motifController,
                decoration: const InputDecoration(labelText: "Motif", border: OutlineInputBorder()),
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
            child: const Text("Créditer"),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/crediter_wallet.php'),
        headers: await Session.authHeaders(),
        body: jsonEncode({
          'idUtilisateur': w['Idutilisateur'],
          'montant': double.tryParse(montantController.text) ?? 0,
          'motif': motifController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wallet crédité — nouveau solde : ${data['nouveauSolde']} FC")));
        await fetchWallets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec du crédit')));
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
        title: const Text("Gestion des Wallets", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _rechercheController,
              decoration: InputDecoration(
                labelText: "Rechercher un chef de dépôt, acheteur ou directeur général",
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _recherche.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _rechercheController.clear())
                    : null,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchWallets,
              child: chargement
                  ? const Center(child: CircularProgressIndicator())
                  : _walletsFiltres.isEmpty
                      ? Center(child: Text(wallets.isEmpty ? "Aucun wallet trouvé" : "Aucun résultat pour \"${_rechercheController.text}\""))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _walletsFiltres.length,
                          itemBuilder: (context, index) {
                            final w = _walletsFiltres[index];
                            final solde = double.tryParse(w['solde'].toString()) ?? 0;
                            return Card(
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WalletPage(idUtilisateur: w['Idutilisateur'], nomUtilisateur: w['nomutilisateur']),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(w['nomutilisateur'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${w['nom_role'] ?? ''}${w['CodeDepot'] != null ? ' — ${w['CodeDepot']}' : ''}",
                                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "${solde.toStringAsFixed(0)} FC",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: solde < 0 ? Colors.orange[800] : Colors.green[800]),
                                          ),
                                          const SizedBox(height: 6),
                                          OutlinedButton(
                                            onPressed: () => _crediter(w),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              minimumSize: const Size(0, 32),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text("Créditer", style: TextStyle(fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
