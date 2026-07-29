import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';
import 'package:sale_manager/offline_queue.dart';
import 'package:sale_manager/offline_payments.dart';
import 'package:sale_manager/reference_cache.dart';
import 'package:sale_manager/pages/ticket_preview.dart';

class SynchronisationPage extends StatefulWidget {
  const SynchronisationPage({super.key});

  @override
  State<SynchronisationPage> createState() => _SynchronisationPageState();
}

class _SynchronisationPageState extends State<SynchronisationPage> {
  List<Map<String, dynamic>> pending = [];
  List<Map<String, dynamic>> agriculteurs = [];
  List<Map<String, dynamic>> produits = [];
  List<Map<String, dynamic>> depots = [];
  Map<String, double> paiementsLocaux = {};
  String chefDepot = '';
  bool syncing = false;
  bool enregistrementPlanteurEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    pending = await OfflineQueue.getAll();
    chefDepot = await Session.getNomUtilisateur();

    // On rafraîchit les données de référence depuis le serveur : cet écran
    // ne sert qu'une fois la connexion revenue, c'est le bon moment pour
    // avoir des listes à jour (planteurs, produits, dépôts).
    try {
      final resAgri = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/get_agriculteurs.php'), headers: await Session.authHeaders())
          .timeout(const Duration(seconds: 8));
      if (resAgri.statusCode == 200) {
        agriculteurs = List<Map<String, dynamic>>.from(jsonDecode(resAgri.body));
        await ReferenceCache.save('agriculteurs', agriculteurs);
      }
      final resProd = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/getProducts.php'), headers: await Session.authHeaders())
          .timeout(const Duration(seconds: 8));
      if (resProd.statusCode == 200) {
        produits = List<Map<String, dynamic>>.from(jsonDecode(resProd.body));
        await ReferenceCache.save('produits', produits);
      }
      final resDepots = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/get_depots.php'), headers: await Session.authHeaders())
          .timeout(const Duration(seconds: 8));
      if (resDepots.statusCode == 200) {
        depots = List<Map<String, dynamic>>.from(jsonDecode(resDepots.body));
        await ReferenceCache.save('depots', depots);
      }
    } catch (_) {
      agriculteurs = await ReferenceCache.get('agriculteurs');
      produits = await ReferenceCache.get('produits');
      depots = await ReferenceCache.get('depots');
    }

    final paiements = <String, double>{};
    for (final achat in pending) {
      final uuid = achat['uuidClient'];
      if (uuid != null) paiements[uuid] = await OfflinePayments.totalPaye(uuid);
    }
    paiementsLocaux = paiements;

    if (mounted) setState(() {});
  }

  bool _utilisePlanteurSecours(Map<String, dynamic> achat) {
    final agri = agriculteurs.where((a) => a['idAgriculteur'] == achat['idcultivateur']);
    if (agri.isEmpty) return false;
    return agri.first['CodePlanteur'] == 'SECOURS';
  }

  String _nomPlanteur(Map<String, dynamic> achat) {
    final agri = agriculteurs.where((a) => a['idAgriculteur'] == achat['idcultivateur']);
    return agri.isNotEmpty ? agri.first['nomAgriculteur'] : 'Planteur #${achat['idcultivateur']}';
  }

  String _codePlanteur(Map<String, dynamic> achat) {
    final agri = agriculteurs.where((a) => a['idAgriculteur'] == achat['idcultivateur']);
    return agri.isNotEmpty ? (agri.first['CodePlanteur'] ?? '---') : '---';
  }

  String _nomProduit(Map<String, dynamic> achat) {
    final p = produits.where((p) => p['IdProduit'] == achat['idproduit']);
    return p.isNotEmpty ? p.first['designationProduit'] : 'Produit #${achat['idproduit']}';
  }

  String _codeDepot(Map<String, dynamic> achat) {
    final d = depots.where((d) => d['IdStockage'] == achat['depot']);
    return d.isNotEmpty ? d.first['CodeDepot'] : 'Dépôt #${achat['depot']}';
  }

  double _total(Map<String, dynamic> achat) {
    return double.tryParse(achat['totalpayer']?.toString() ?? '') ?? 0;
  }

  double _paye(Map<String, dynamic> achat) {
    return paiementsLocaux[achat['uuidClient']] ?? 0;
  }

  double _reste(Map<String, dynamic> achat) {
    final reste = _total(achat) - _paye(achat);
    return reste < 0 ? 0 : reste;
  }

  /// Map adaptée aux champs attendus par buildAchatPdf (mêmes noms que la
  /// réponse serveur), construite à partir des données locales de l'achat
  /// en attente puisqu'il n'a pas encore d'Idachat/NumeroBon réel.
  Map<String, dynamic> _achatPourTicket(Map<String, dynamic> achat) {
    final refCourte = (achat['uuidClient'] ?? '').toString().replaceFirst('local-', '');
    return {
      'NumeroBon': 'EN ATTENTE (${refCourte.length > 10 ? refCourte.substring(0, 10) : refCourte})',
      'dateAchat': achat['date'],
      'CodeDepot': _codeDepot(achat),
      'nomutilisateur': chefDepot,
      'nomAgriculteur': _nomPlanteur(achat),
      'CodePlanteur': _codePlanteur(achat),
      'designationProduit': _nomProduit(achat),
      'Quantite_KG': achat['quantite'],
      'prixUnitaire': achat['prixUnitaire'],
      'PrimePlanteur': achat['primeplanteur'],
      'totalPayer': achat['totalpayer'],
      'totalPaye': _paye(achat),
      'soldeRestant': _reste(achat),
    };
  }

  void _imprimerTicket(Map<String, dynamic> achat) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TicketPreviewPage(achat: _achatPourTicket(achat))),
    );
  }

  /// Règlement local d'un achat pas encore synchronisé : le montant est
  /// gardé sur l'appareil (OfflinePayments) et sera envoyé à
  /// register_paiement.php une fois l'achat lui-même synchronisé et son
  /// vrai Idachat connu.
  Future<void> _payerHorsLigne(Map<String, dynamic> achat) async {
    final reste = _reste(achat);
    if (reste <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cet achat est déjà couvert par les paiements enregistrés")));
      return;
    }

    final montantController = TextEditingController(text: reste.toStringAsFixed(0));
    String modePaiement = 'especes';
    String? erreur;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Paiement (hors-ligne)"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${_nomPlanteur(achat)} — reste dû : ${reste.toStringAsFixed(0)} FC"),
              const SizedBox(height: 8),
              const Text(
                "Ce paiement est gardé sur l'appareil et envoyé au serveur une fois l'achat synchronisé.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: montantController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Montant à payer maintenant (FC)",
                  border: const OutlineInputBorder(),
                  errorText: erreur,
                ),
                onChanged: (_) => setStateDialog(() => erreur = null),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: modePaiement,
                items: const [
                  DropdownMenuItem(value: 'especes', child: Text('Espèces')),
                  DropdownMenuItem(value: 'mobile_money', child: Text('Mobile money')),
                  DropdownMenuItem(value: 'virement', child: Text('Virement')),
                ],
                onChanged: (v) => setStateDialog(() => modePaiement = v ?? 'especes'),
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
                  setStateDialog(() => erreur = "Montant invalide");
                  return;
                }
                if (montant > reste) {
                  setStateDialog(() => erreur = "Ne peut pas dépasser ${reste.toStringAsFixed(0)} FC");
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

    if (confirme != true) return;

    final montant = double.tryParse(montantController.text.trim()) ?? reste;
    await OfflinePayments.ajouter(achat['uuidClient'], {
      'montant': montant,
      'modePaiement': modePaiement,
      'motif': montant >= reste ? 'Paiement intégral' : 'Paiement partiel',
      'date': DateTime.now().toIso8601String(),
    });
    await _charger();
    if (!mounted) return;
    final nouveauReste = reste - montant;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(nouveauReste > 0 ? "Paiement local enregistré — reste ${nouveauReste.toStringAsFixed(0)} FC" : "Paiement local enregistré, achat soldé")),
    );
  }

  /// Ouvre le formulaire "Nouveau Planteur" (mêmes champs que la page
  /// Planteurs) pré-rempli avec le nom saisi hors-ligne, crée le vrai
  /// planteur en ligne, puis rattache l'achat en attente à ce nouveau
  /// planteur — sans toucher aux autres informations de l'achat.
  /// Renvoie true si le planteur a bien été créé et rattaché, false si
  /// l'utilisateur a annulé ou si la création a échoué (auquel cas la
  /// synchronisation ne doit pas continuer pour cet achat).
  Future<bool> _completerIdentitePlanteur(Map<String, dynamic> achat) async {
    final nomController = TextEditingController(text: achat['nomPlanteurSaisi'] ?? '');
    final codeController = TextEditingController();
    final adresseController = TextEditingController();
    final contactController = TextEditingController();
    final champsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Identité réelle du planteur"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cet achat a été saisi hors-ligne avec le planteur de secours. Complétez ici les vraies informations du planteur, comme sur le formulaire Nouveau Planteur.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: "Nom", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? "Le nom est requis" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: "Code planteur", prefixIcon: Icon(Icons.code), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: adresseController,
                  decoration: const InputDecoration(labelText: "Adresse", prefixIcon: Icon(Icons.location_city), border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? "L'adresse est requise" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: "Contact", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? "Le contact est requis" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: champsController,
                  decoration: const InputDecoration(labelText: "Nombre de champs", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text("Enregistrer le planteur"),
          ),
        ],
      ),
    );

    if (confirme != true) return false;

    setState(() => enregistrementPlanteurEnCours = true);
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/registerAgriculteur.php'),
            headers: await Session.authHeaders(),
            body: json.encode({
              'nameAgricultor': nomController.text,
              'codeplanteur': codeController.text,
              'adressAgricultor': adresseController.text,
              'contactAgricultor': contactController.text,
              'nmberOfifeldsAgricultor': champsController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (!mounted) return false;
      if (data['success'] != null && data['idAgriculteur'] != null) {
        final misAJour = Map<String, dynamic>.from(achat);
        misAJour['idcultivateur'] = data['idAgriculteur'];
        await OfflineQueue.update(achat['uuidClient'], misAJour);
        await _charger();
        if (!mounted) return true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Planteur ${nomController.text} enregistré et rattaché à l'achat")),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec: ${data['error'] ?? 'erreur inconnue'}")),
        );
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
      return false;
    } finally {
      if (mounted) setState(() => enregistrementPlanteurEnCours = false);
    }
  }

  /// Envoie au serveur les paiements gardés localement pour un achat qui
  /// vient d'être synchronisé, maintenant qu'on connaît son vrai Idachat.
  Future<void> _pousserPaiementsLocaux(String uuidClient, int idAchat, int? idAgriculteur) async {
    final paiements = await OfflinePayments.pour(uuidClient);
    if (paiements.isEmpty) return;
    for (final p in paiements) {
      try {
        await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/register_paiement.php'),
          headers: await Session.authHeaders(),
          body: jsonEncode({
            'montant': p['montant'],
            'motif': p['motif'] ?? 'Paiement partiel',
            'typeOperation': 'sortie',
            'modePaiement': p['modePaiement'] ?? 'especes',
            'idAchat': idAchat,
            'idAgriculteur': idAgriculteur,
          }),
        );
      } catch (_) {
        // Le paiement reste dans la file locale et sera retenté à la
        // prochaine synchronisation si l'envoi échoue.
        continue;
      }
    }
    await OfflinePayments.supprimer(uuidClient);
  }

  /// La synchronisation commence toujours par la partie planteur : tant
  /// qu'il reste des achats rattachés au planteur de secours, on force la
  /// complétion de leur vraie identité (création en ligne, récupération de
  /// l'id réel) avant d'envoyer le moindre achat au serveur.
  Future<void> synchroniser() async {
    if (pending.isEmpty) return;

    final aCompleter = pending.where(_utilisePlanteurSecours).toList();
    for (final achat in aCompleter) {
      final ok = await _completerIdentitePlanteur(achat);
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Synchronisation interrompue : complétez l'identité du planteur pour continuer")),
          );
        }
        return;
      }
    }

    if (!mounted || pending.isEmpty) return;
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
        final reussis = resultats.where((r) => r['success'] == true).toList();
        final echecs = resultats.where((r) => r['success'] != true).toList();

        // Une fois l'achat synchronisé et son vrai Idachat connu, on
        // pousse les paiements qui avaient été gardés localement.
        for (final r in reussis) {
          final uuid = r['uuidClient'] as String?;
          final idAchat = r['idAchat'];
          if (uuid == null || idAchat == null) continue;
          final achatLocal = pending.firstWhere((a) => a['uuidClient'] == uuid, orElse: () => {});
          await _pousserPaiementsLocaux(uuid, idAchat, achatLocal['idcultivateur']);
        }

        await OfflineQueue.removeByUuid(reussis.map((r) => r['uuidClient'] as String).toList());
        await _charger();
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
    final nbASecours = pending.where(_utilisePlanteurSecours).length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Synchronisation", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("${pending.length} achat(s) en attente de synchronisation", style: const TextStyle(fontSize: 16, color: Colors.black)),
            if (nbASecours > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "⚠ $nbASecours achat(s) utilisent le planteur de secours — la synchronisation vous demandera d'abord leur vraie identité",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
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
                  final aSecours = _utilisePlanteurSecours(a);
                  final total = _total(a);
                  final paye = _paye(a);
                  final reste = _reste(a);
                  return Card(
                    color: aSecours ? const Color.fromARGB(255, 255, 245, 214) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (aSecours) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.warning_amber, color: Colors.orange)),
                              Expanded(
                                child: Text(_nomPlanteur(a), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: reste > 0 ? const Color.fromARGB(255, 253, 235, 224) : const Color.fromARGB(255, 227, 246, 232),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  reste > 0 ? (paye > 0 ? 'Partiel' : 'Non payé') : 'Payé',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: reste > 0 ? Colors.orange[800] : Colors.green[800]),
                                ),
                              ),
                            ],
                          ),
                          if (aSecours)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Nom saisi sur le terrain : ${a['nomPlanteurSaisi'] ?? 'non précisé'}",
                                style: const TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ),
                          const Divider(height: 16),
                          DefaultTextStyle(
                            style: const TextStyle(fontSize: 13, color: Colors.black),
                            child: Table(
                              columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              children: [
                                TableRow(children: [
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('Produit : ${_nomProduit(a)}')),
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('Dépôt : ${_codeDepot(a)}')),
                                ]),
                                TableRow(children: [
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('Quantité : ${a['quantite']} kg')),
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('Chef dépôt : $chefDepot')),
                                ]),
                                TableRow(children: [
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('Prix unitaire : ${a['prixUnitaire']} FC')),
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('Prime : ${a['primeplanteur'] ?? 0} FC')),
                                ]),
                                TableRow(children: [
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('Date : ${a['date']}')),
                                  const SizedBox(),
                                ]),
                              ],
                            ),
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total : ${total.toStringAsFixed(0)} FC', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                              Text('Payé : ${paye.toStringAsFixed(0)} FC', style: TextStyle(color: Colors.green[800])),
                              Text('Reste : ${reste.toStringAsFixed(0)} FC', style: TextStyle(color: reste > 0 ? Colors.orange[800] : Colors.green[800])),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _imprimerTicket(a),
                                icon: const Icon(Icons.print, size: 18),
                                label: const Text("Imprimer"),
                              ),
                              OutlinedButton.icon(
                                onPressed: reste > 0 ? () => _payerHorsLigne(a) : null,
                                icon: const Icon(Icons.payments, size: 18),
                                label: const Text("Payer"),
                              ),
                              if (aSecours)
                                TextButton.icon(
                                  onPressed: enregistrementPlanteurEnCours ? null : () => _completerIdentitePlanteur(a),
                                  icon: const Icon(Icons.person_add_alt, size: 18),
                                  label: const Text("Compléter le planteur"),
                                ),
                            ],
                          ),
                        ],
                      ),
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
