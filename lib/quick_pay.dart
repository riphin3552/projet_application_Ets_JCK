import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

/// Règlement d'un achat : le montant est pré-rempli avec le solde restant
/// mais reste modifiable, pour permettre un paiement partiel (on paie ce qui
/// est disponible, le reste est réglé plus tard). Retourne true si le
/// paiement a réussi, pour que l'écran appelant rafraîchisse sa liste.
Future<bool> payerSolde(BuildContext context, Map<String, dynamic> achat) async {
  final soldeRestant = double.tryParse(achat['soldeRestant']?.toString() ?? '') ?? 0;
  if (soldeRestant <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cet achat est déjà payé")));
    return false;
  }

  final montantController = TextEditingController(text: soldeRestant.toStringAsFixed(0));
  String modePaiement = 'especes';
  String? erreur;

  final confirme = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("Enregistrer un paiement"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${achat['nomAgriculteur']} — solde restant dû : $soldeRestant FC"),
            const SizedBox(height: 16),
            TextField(
              controller: montantController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Montant à payer maintenant (FC)",
                border: const OutlineInputBorder(),
                errorText: erreur,
                helperText: "Laissez le montant proposé pour tout payer, ou réduisez-le pour un paiement partiel",
              ),
              onChanged: (_) => setState(() => erreur = null),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: modePaiement,
              items: const [
                DropdownMenuItem(value: 'especes', child: Text('Espèces')),
                DropdownMenuItem(value: 'mobile_money', child: Text('Mobile money')),
                DropdownMenuItem(value: 'virement', child: Text('Virement')),
              ],
              onChanged: (v) => setState(() => modePaiement = v ?? 'especes'),
              decoration: const InputDecoration(labelText: "Mode de paiement", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              final montant = double.tryParse(montantController.text.trim());
              if (montant == null || montant <= 0) {
                setState(() => erreur = "Montant invalide");
                return;
              }
              if (montant > soldeRestant) {
                setState(() => erreur = "Ne peut pas dépasser $soldeRestant FC");
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text("Payer"),
          ),
        ],
      ),
    ),
  );
  if (confirme != true) return false;

  final montantAPayer = double.tryParse(montantController.text.trim()) ?? soldeRestant;

  final response = await http.post(
    Uri.parse('${AppConfig.apiBaseUrl}/register_paiement.php'),
    headers: await Session.authHeaders(),
    body: jsonEncode({
      'montant': montantAPayer,
      'motif': montantAPayer >= soldeRestant ? 'Paiement intégral' : 'Paiement partiel',
      'typeOperation': 'sortie',
      'modePaiement': modePaiement,
      'idAchat': achat['Idachat'],
    }),
  );
  final data = jsonDecode(response.body);
  if (!context.mounted) return false;

  if (data['success'] == true) {
    final reste = soldeRestant - montantAPayer;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(reste > 0 ? "Paiement enregistré — reste $reste FC" : "Paiement enregistré, achat soldé")),
    );
    return true;
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec du paiement')));
    return false;
  }
}

/// Badge visuel Non payé / Partiel / Payé, à placer en `trailing` d'un ListTile.
Widget badgeStatutPaiement(Map<String, dynamic> achat) {
  final statut = achat['StatutPaiement'];
  final Color couleur;
  final Color fond;
  final String texte;
  switch (statut) {
    case 'paye':
      couleur = Colors.green;
      fond = const Color.fromARGB(255, 227, 246, 232);
      texte = 'Payé';
      break;
    case 'partiellement_paye':
      couleur = Colors.amber[800]!;
      fond = const Color.fromARGB(255, 255, 245, 214);
      texte = 'Partiel';
      break;
    default:
      couleur = Colors.orange;
      fond = const Color.fromARGB(255, 253, 235, 224);
      texte = 'Non payé';
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: fond,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: couleur),
    ),
    child: Text(texte, style: TextStyle(color: couleur, fontSize: 11, fontWeight: FontWeight.bold)),
  );
}

/// Ligne "Payé: X FC · Reste: Y FC" à afficher sous chaque achat pour une
/// visibilité immédiate sur ce qui a été réglé et ce qu'il reste à payer.
Widget ligneSoldePaiement(Map<String, dynamic> achat) {
  final totalPaye = achat['totalPaye'] ?? 0;
  final soldeRestant = achat['soldeRestant'] ?? 0;
  return Text(
    'Payé : $totalPaye FC  ·  Reste : $soldeRestant FC',
    style: TextStyle(
      color: (double.tryParse(soldeRestant.toString()) ?? 0) > 0 ? Colors.orange[800] : Colors.green[800],
      fontWeight: FontWeight.w600,
    ),
  );
}
