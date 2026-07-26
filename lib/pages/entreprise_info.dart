import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class EntrepriseInfoPage extends StatefulWidget {
  const EntrepriseInfoPage({super.key});

  @override
  State<EntrepriseInfoPage> createState() => _EntrepriseInfoPageState();
}

class _EntrepriseInfoPageState extends State<EntrepriseInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _denominationController = TextEditingController();
  final _secteurController = TextEditingController();
  final _rccmController = TextEditingController();
  final _numeroImpotController = TextEditingController();
  final _adresseController = TextEditingController();
  final _contactController = TextEditingController();

  bool chargement = true;
  bool enregistrement = false;
  bool peutModifier = false;
  String statut = '';
  String dateCreation = '';

  @override
  void initState() {
    super.initState();
    chargerPermission();
    fetchEntreprise();
  }

  Future<void> chargerPermission() async {
    final peut = await Session.can('entreprises.gerer');
    if (mounted) setState(() => peutModifier = peut);
  }

  Future<void> fetchEntreprise() async {
    setState(() => chargement = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/get_entreprise.php'),
        headers: await Session.authHeaders(),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final e = data['data'];
        _denominationController.text = e['DenominationEse'] ?? '';
        _secteurController.text = e['SecteurActivites'] ?? '';
        _rccmController.text = e['RCCM'] ?? '';
        _numeroImpotController.text = e['NumeroImpot'] ?? '';
        _adresseController.text = e['Adresse'] ?? '';
        _contactController.text = e['Contact'] ?? '';
        statut = e['Statut'] ?? '';
        dateCreation = (e['DateCreation'] ?? '').toString();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
      }
    }
    if (mounted) setState(() => chargement = false);
  }

  Future<void> enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => enregistrement = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/update_entreprise.php'),
        headers: await Session.authHeaders(),
        body: jsonEncode({
          'denomination': _denominationController.text,
          'secteur': _secteurController.text,
          'rccm': _rccmController.text,
          'numeroImpot': _numeroImpotController.text,
          'adresse': _adresseController.text,
          'contact': _contactController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Informations de l'entreprise mises à jour")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec de la mise à jour')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    } finally {
      if (mounted) setState(() => enregistrement = false);
    }
  }

  Widget _champ(TextEditingController controller, String label, IconData icone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: peutModifier,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icone),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Champ requis" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Informations de l'entreprise", style: TextStyle(color: Colors.white)),
      ),
      body: chargement
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!peutModifier)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          "Lecture seule — seul un administrateur (DG, caissier, comptable) peut modifier ces informations.",
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    _champ(_denominationController, "Dénomination de l'entreprise", Icons.business),
                    _champ(_secteurController, "Secteur d'activités", Icons.category),
                    _champ(_rccmController, "RCCM", Icons.badge),
                    _champ(_numeroImpotController, "Numéro d'impôt", Icons.receipt_long),
                    _champ(_adresseController, "Adresse", Icons.location_city),
                    _champ(_contactController, "Contact", Icons.phone),
                    if (statut.isNotEmpty) Text("Statut : $statut", style: const TextStyle(color: Colors.grey)),
                    if (dateCreation.isNotEmpty) Text("Créée le : $dateCreation", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    if (peutModifier)
                      ElevatedButton(
                        onPressed: enregistrement ? null : enregistrer,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: enregistrement
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("Enregistrer"),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
