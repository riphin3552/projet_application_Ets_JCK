// ignore_for_file: file_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/pages/home.dart';
import '../config.dart';

class LoginService {
  static Future<void> loginUser(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/connexion.php");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );/*.timeout(const Duration(seconds: 30));*/

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success'] == true) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${jsonResponse['message']}")),
        );

        // Navigation vers la page d'accueil après connexion réussie
        // ignore: use_build_context_synchronously
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
        // ignore: use_build_context_synchronously
        
        
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ ${jsonResponse['message']}")),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion")),
      );
    }
  }
}
