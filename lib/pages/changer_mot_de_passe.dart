import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class ChangerMotDePassePage extends StatefulWidget {
  const ChangerMotDePassePage({super.key});

  @override
  State<ChangerMotDePassePage> createState() => _ChangerMotDePassePageState();
}

class _ChangerMotDePassePageState extends State<ChangerMotDePassePage> {
  final _formKey = GlobalKey<FormState>();
  final _ancienController = TextEditingController();
  final _nouveauController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _envoi = false;

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nouveauController.text != _confirmationController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Les deux mots de passe ne correspondent pas")));
      return;
    }

    setState(() => _envoi = true);
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/change_password.php'),
      headers: await Session.authHeaders(),
      body: jsonEncode({
        'ancienMotDePasse': _ancienController.text,
        'nouveauMotDePasse': _nouveauController.text,
      }),
    );
    final data = jsonDecode(response.body);
    if (!mounted) return;
    setState(() => _envoi = false);

    if (data['success'] == true) {
      _ancienController.clear();
      _nouveauController.clear();
      _confirmationController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mot de passe modifié avec succès")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Changer mon mot de passe", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _ancienController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Mot de passe actuel", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Requis" : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nouveauController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Nouveau mot de passe (min. 6 caractères)", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.length < 6) ? "Au moins 6 caractères" : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmationController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirmer le nouveau mot de passe", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Requis" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _envoi ? null : _valider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(_envoi ? "..." : "Valider"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
