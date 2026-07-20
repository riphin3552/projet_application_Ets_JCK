import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache local des données de référence (planteurs, produits, dépôts, lots)
/// utilisées pour remplir le formulaire d'achat. Sauvegardée à chaque
/// récupération réussie depuis le serveur ; relue si le réseau échoue
/// (mode hors-ligne), pour que le formulaire reste utilisable sur le terrain.
class ReferenceCache {
  static Future<void> save(String cle, List<Map<String, dynamic>> donnees) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$cle', jsonEncode(donnees));
  }

  static Future<List<Map<String, dynamic>>> get(String cle) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cache_$cle');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }
}
