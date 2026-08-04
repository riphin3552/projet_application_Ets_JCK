import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

/// "Mon Wallet" : solde et historique des paiements reçus du caissier et
/// des débits automatiques dus aux achats effectués. Le solde peut être
/// négatif (achat effectué à découvert) — il sera régularisé au prochain
/// crédit.
class WalletPage extends StatefulWidget {
  // Si null, affiche le wallet de l'utilisateur connecté. Sinon (consulté
  // par le caissier depuis la gestion des wallets), affiche celui indiqué.
  final int? idUtilisateur;
  final String? nomUtilisateur;
  const WalletPage({super.key, this.idUtilisateur, this.nomUtilisateur});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool chargement = true;
  double solde = 0;
  List<Map<String, dynamic>> transactions = [];
  String? erreur;

  @override
  void initState() {
    super.initState();
    fetchWallet();
  }

  Future<void> fetchWallet() async {
    setState(() {
      chargement = true;
      erreur = null;
    });
    try {
      final uri = widget.idUtilisateur != null
          ? Uri.parse('${AppConfig.apiBaseUrl}/get_wallet.php?idUtilisateur=${widget.idUtilisateur}')
          : Uri.parse('${AppConfig.apiBaseUrl}/get_wallet.php');
      final response = await http.get(
        uri,
        headers: await Session.authHeaders(),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          solde = double.tryParse(data['solde'].toString()) ?? 0;
          transactions = List<Map<String, dynamic>>.from(data['transactions']);
        });
      } else {
        setState(() => erreur = data['message'] ?? "Aucun wallet trouvé pour ce compte");
      }
    } catch (e) {
      setState(() => erreur = "Erreur de connexion");
    }
    setState(() => chargement = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: Text(
          widget.nomUtilisateur != null ? "Wallet — ${widget.nomUtilisateur}" : "Mon Wallet",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchWallet,
        child: chargement
            ? const Center(child: CircularProgressIndicator())
            : erreur != null
                ? Center(child: Text(erreur!))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: solde < 0 ? const Color.fromARGB(255, 253, 235, 224) : const Color.fromARGB(255, 227, 246, 232),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text("Solde actuel", style: TextStyle(fontSize: 14, color: Colors.black54)),
                              const SizedBox(height: 8),
                              Text(
                                "${solde.toStringAsFixed(0)} FC",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: solde < 0 ? Colors.orange[800] : Colors.green[800],
                                ),
                              ),
                              if (solde < 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    "Solde négatif : sera régularisé au prochain crédit",
                                    style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Historique des paiements", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      if (transactions.isEmpty) const Text("Aucune transaction pour l'instant"),
                      ...transactions.map((t) {
                        final estCredit = t['type'] == 'credit';
                        final montant = double.tryParse(t['montant'].toString()) ?? 0;
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              estCredit ? Icons.add_circle : Icons.remove_circle,
                              color: estCredit ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              "${estCredit ? '+' : '-'}${montant.toStringAsFixed(0)} FC",
                              style: TextStyle(fontWeight: FontWeight.bold, color: estCredit ? Colors.green[800] : Colors.red[800]),
                            ),
                            subtitle: Text(
                              "${t['motif'] ?? (estCredit ? 'Crédit' : 'Débit')}"
                              "${t['auteur'] != null ? ' — par ${t['auteur']}' : ''}"
                              "\n${t['DateCreation']}",
                            ),
                            isThreeLine: true,
                            trailing: Text("Solde: ${(double.tryParse(t['soldeApres'].toString()) ?? 0).toStringAsFixed(0)} FC"),
                          ),
                        );
                      }),
                    ],
                  ),
      ),
    );
  }
}
