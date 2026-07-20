import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Session utilisateur courante : token + rôle + permissions renvoyés par
/// connexion.php. Remplace l'ancien stockage qui ne gardait que le token
/// brut sous la clé 'Token' (conservée pour compatibilité avec les écrans
/// pas encore migrés).
class Session {
  static const _kToken = 'Token';
  static const _kIdUtilisateur = 'idUtilisateur';
  static const _kNom = 'nomUtilisateur';
  static const _kEmail = 'email';
  static const _kIdEntreprise = 'idEntreprise';
  static const _kIdRole = 'idRole';
  static const _kRole = 'role';
  static const _kIdStockage = 'idStockage';
  static const _kPermissions = 'permissions';

  static Future<void> save(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, user['Token'] ?? user['token'] ?? '');
    await prefs.setInt(_kIdUtilisateur, user['idutilisateur'] ?? 0);
    await prefs.setString(_kNom, user['name'] ?? '');
    await prefs.setString(_kEmail, user['email'] ?? '');
    await prefs.setInt(_kIdEntreprise, user['idEntreprise'] ?? 0);
    await prefs.setInt(_kIdRole, user['idRole'] ?? 0);
    await prefs.setString(_kRole, user['role'] ?? '');
    if (user['idStockage'] != null) {
      await prefs.setInt(_kIdStockage, user['idStockage']);
    } else {
      await prefs.remove(_kIdStockage);
    }
    await prefs.setString(_kPermissions, jsonEncode(user['permissions'] ?? []));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kIdUtilisateur);
    await prefs.remove(_kNom);
    await prefs.remove(_kEmail);
    await prefs.remove(_kIdEntreprise);
    await prefs.remove(_kIdRole);
    await prefs.remove(_kRole);
    await prefs.remove(_kIdStockage);
    await prefs.remove(_kPermissions);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    return (token == null || token.isEmpty) ? null : token;
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String> getNomUtilisateur() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNom) ?? '';
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRole) ?? '';
  }

  static Future<int?> getIdStockage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kIdStockage);
  }

  static Future<int> getIdUtilisateur() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kIdUtilisateur) ?? 0;
  }

  static Future<List<String>> getPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPermissions);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  static Future<bool> can(String permission) async {
    final perms = await getPermissions();
    return perms.contains(permission);
  }

  static Future<bool> isLoggedIn() async {
    return await getToken() != null;
  }
}
