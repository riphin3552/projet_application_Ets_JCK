import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/config.dart';
import 'package:sale_manager/pages/login.dart';

/// Création d'une nouvelle entreprise cliente, avec son premier utilisateur
/// (Directeur Général) créé automatiquement. Une fois le compte créé,
/// ramène l'utilisateur à l'écran de connexion pour qu'il se connecte avec
/// ce compte administrateur.
class RegisterEntreprisePage extends StatefulWidget {
  const RegisterEntreprisePage({super.key});

  @override
  State<RegisterEntreprisePage> createState() => _RegisterEntreprisePageState();
}

class _RegisterEntreprisePageState extends State<RegisterEntreprisePage> {
  final _formKey = GlobalKey<FormState>();

  final _denominationController = TextEditingController();
  final _secteurController = TextEditingController();
  final _adresseController = TextEditingController();
  final _contactController = TextEditingController();

  final _nomDirecteurController = TextEditingController();
  final _emailDirecteurController = TextEditingController();
  final _passwordDirecteurController = TextEditingController();
  final _phoneDirecteurController = TextEditingController();

  bool _envoi = false;

  Future<void> _creerCompte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _envoi = true);
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/register_entreprise.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'denomination': _denominationController.text.trim(),
              'secteurActivites': _secteurController.text.trim(),
              'adresse': _adresseController.text.trim(),
              'contact': _contactController.text.trim(),
              'nomDirecteur': _nomDirecteurController.text.trim(),
              'emailDirecteur': _emailDirecteurController.text.trim(),
              'passwordDirecteur': _passwordDirecteurController.text,
              'phoneDirecteur': _phoneDirecteurController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      Map<String, dynamic>? jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (_) {
        jsonResponse = null;
      }

      if (jsonResponse != null && jsonResponse['success'] == true) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Entreprise créée"),
            content: const Text(
              "Votre entreprise et votre compte Directeur Général ont été créés avec succès. "
              "Connectez-vous maintenant avec l'email et le mot de passe que vous venez de choisir.",
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse?['message'] ?? 'Échec de la création du compte')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Créer un compte entreprise", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Votre entreprise", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _denominationController,
                decoration: const InputDecoration(labelText: "Nom de l'entreprise", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _secteurController,
                decoration: const InputDecoration(labelText: "Secteur d'activité (optionnel)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(labelText: "Adresse (optionnel)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: "Contact / téléphone entreprise (optionnel)", border: OutlineInputBorder()),
              ),

              const SizedBox(height: 28),
              const Text("Votre compte Directeur Général", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nomDirecteurController,
                decoration: const InputDecoration(labelText: "Votre nom", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailDirecteurController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Votre email", border: OutlineInputBorder()),
                validator: (v) => (v == null || !v.contains('@')) ? "Email invalide" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordDirecteurController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Mot de passe (min. 6 caractères)", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.length < 6) ? "Au moins 6 caractères" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneDirecteurController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Votre téléphone", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Requis" : null,
              ),

              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _envoi ? null : _creerCompte,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _envoi
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Créer le compte"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
