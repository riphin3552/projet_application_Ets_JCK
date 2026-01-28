// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
//import 'package:sale_manager/LoginService.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'dart:async';
import 'package:sale_manager/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  void loginApp(String email, String password) async {
  try {
    var url = Uri.parse(
      'https://riphin-salemanager.com/Sale_manager_API/connexion.php',
    );

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

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      //print(jsonResponse); // 🔍 pour debug

      if (jsonResponse['success'] == true) {
        final token = jsonResponse['user']['Token'];

        if (token != null && token is String && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('Token', token);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Connexion réussie")),
          );

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
      SnackBar(content: Text("Erreur de connexion : $e")),
    );
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
                  onPressed: () {
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
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      
                      color: Colors.white,
                    ),
                  ),
  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Vous n'avez pas de compte?"),
                    TextButton(onPressed: () {}, child: Text("S'inscrire")),
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
