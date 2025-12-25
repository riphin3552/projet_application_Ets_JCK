// lib/services/register_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class RegisterService {
  static Future<void> registerUser(
    BuildContext context, {
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required String description,
  }) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/registerUser.php");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nameUser": name,
          "emailUser": email,
          "passwordUser": password,
          "confirm_password": confirmPassword,
          "userphone": phone,
          "descriptionUser": description,
        }),
      ).timeout(const Duration(seconds: 10));

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success'] == true) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${jsonResponse['message']}")),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ ${jsonResponse['message']}")),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur de connexion: $e")),
      );
    }
  }
}
