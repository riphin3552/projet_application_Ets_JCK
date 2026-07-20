// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sale_manager/config.dart';
import 'package:sale_manager/pages/home.dart';
import 'package:sale_manager/pages/two_factor.dart';
import 'package:sale_manager/pages/register_entreprise.dart';
import 'package:sale_manager/session.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _connexionEnCours = false;

  void loginApp(String email, String password) async {
  setState(() => _connexionEnCours = true);
  try {
    var url = Uri.parse('${AppConfig.apiBaseUrl}/connexion.php');

    var response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(Duration(seconds: 10));

    if (!mounted) return;

    // Le serveur répond toujours en JSON, y compris pour les erreurs
    // (401 identifiants incorrects, 403 compte désactivé...). On lit donc
    // le message renvoyé plutôt que de se fier uniquement au code HTTP.
    Map<String, dynamic>? jsonResponse;
    try {
      jsonResponse = jsonDecode(response.body);
    } catch (_) {
      jsonResponse = null;
    }

    if (jsonResponse != null) {
      if (jsonResponse['success'] == true && jsonResponse['requires2FA'] == true) {
        final tempToken = jsonResponse['tempToken'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TwoFactorScreen(tempToken: tempToken),
          ),
        );
        return;
      }

      if (jsonResponse['success'] == true) {
        final user = jsonResponse['user'];
        final token = user['Token'];

        if (token != null && token is String && token.isNotEmpty) {
          await Session.save(user);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Token invalide ou manquant")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec: ${jsonResponse['message']}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur serveur")),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur de connexion")),
    );
  } finally {
    if (mounted) setState(() => _connexionEnCours = false);
  }
}

  final _formKey = GlobalKey<FormState>(); // cle du formulaire
  final _emailController =
      TextEditingController(); // controlleur du champ email
  final _passwordController =
      TextEditingController(); // controlleur du champ password

  void validationFormulaire() {
    if (_formKey.currentState!.validate() &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _passwordController.text.length >= 6 &&
        _emailController.text.contains('@') &&
        _emailController.text.contains('.')) {
      // si le formulaire est valide
        loginApp(_emailController.text, _passwordController.text);
    } else {
      // si le formulaire n'est pas valide
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid Data, please check your inputs")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Form(
            key: _formKey, //associer la cle au formulaire
            child: Column(
              children: [
                SizedBox(height: 60),

                Text(
                  "Se connecter",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Image.asset("images/etsJCK.jpg", height: 250, width: 300),

                SizedBox(height: 20),

                TextFormField(
                  controller:
                      _emailController, // associer le controlleur au champ email

                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Email",
                    hintText: "Enter your email",
                    prefixIcon: Icon(Icons.mail),
                    helperText:
                        "Le mail doit contenir @ et .com (monnom@gmail.com)",
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 63, 129, 86),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 63, 129, 86),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  obscureText: true,
                  controller:
                      _passwordController, // associer le controlleur au champ password
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Password",
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 63, 129, 86),
                    ),
                    hintText: "Enter your password, at least 6 characters",
                    prefixIcon: Icon(Icons.lock),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 63, 129, 86),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _connexionEnCours
                      ? null
                      : () {
                          validationFormulaire();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 63, 129, 86),
                    minimumSize: const Size(double.infinity, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _connexionEnCours
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterEntreprisePage()));
                      },
                      child: Text("Créer un compte entreprise"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
