import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class Securite2FAPage extends StatefulWidget {
  const Securite2FAPage({super.key});

  @override
  State<Securite2FAPage> createState() => _Securite2FAPageState();
}

class _Securite2FAPageState extends State<Securite2FAPage> {
  String? otpauthUri;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool loading = false;

  Future<void> commencerActivation() async {
    setState(() => loading = true);
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/enable_2fa.php'),
      headers: await Session.authHeaders(),
    );
    final data = jsonDecode(response.body);
    if (!mounted) return;
    setState(() => loading = false);
    if (data['success'] == true) {
      setState(() => otpauthUri = data['otpauthUri']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec')));
    }
  }

  Future<void> confirmerActivation() async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/verify_2fa.php'),
      headers: await Session.authHeaders(),
      body: jsonEncode({'code': _codeController.text.trim()}),
    );
    final data = jsonDecode(response.body);
    if (!mounted) return;
    if (data['success'] == true) {
      setState(() {
        otpauthUri = null;
        _codeController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Authentification à deux facteurs activée")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Code invalide')));
    }
  }

  Future<void> desactiver() async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/disable_2fa.php'),
      headers: await Session.authHeaders(),
      body: jsonEncode({'password': _passwordController.text}),
    );
    final data = jsonDecode(response.body);
    if (!mounted) return;
    if (data['success'] == true) {
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("2FA désactivée")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Sécurité (2FA)", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "L'authentification à deux facteurs ajoute un code temporaire (Google Authenticator, Microsoft Authenticator...) en plus du mot de passe à chaque connexion.",
            ),
            const SizedBox(height: 20),
            if (otpauthUri == null)
              ElevatedButton(
                onPressed: loading ? null : commencerActivation,
                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 63, 129, 86), foregroundColor: Colors.white),
                child: Text(loading ? "..." : "Activer la 2FA"),
              )
            else ...[
              const Text("1. Scannez ce QR code avec votre application d'authentification :"),
              const SizedBox(height: 12),
              Center(child: QrImageView(data: otpauthUri!, size: 200)),
              const SizedBox(height: 20),
              const Text("2. Entrez le code affiché pour confirmer :"),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: confirmerActivation,
                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 63, 129, 86), foregroundColor: Colors.white),
                child: const Text("Confirmer l'activation"),
              ),
            ],
            const Divider(height: 40),
            const Text("Désactiver la 2FA (nécessite votre mot de passe) :"),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mot de passe", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: desactiver,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Désactiver la 2FA", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
