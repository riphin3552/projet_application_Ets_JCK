// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sale_manager/config.dart';
import 'package:sale_manager/session.dart';
import 'package:sale_manager/pages/home.dart';

/// Deuxième étape de connexion pour les comptes avec la 2FA activée :
/// demande le code à 6 chiffres de l'application d'authentification.
class TwoFactorScreen extends StatefulWidget {
  final String tempToken;
  const TwoFactorScreen({super.key, required this.tempToken});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;

  Future<void> _verifier() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/connexion_2fa.php');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'tempToken': widget.tempToken,
              'code': _codeController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success'] == true) {
        await Session.save(jsonResponse['user']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'] ?? 'Code invalide')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification en deux étapes')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Entrez le code affiché dans votre application d\'authentification'),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(counterText: ''),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _verifier,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Valider', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
