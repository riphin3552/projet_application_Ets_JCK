import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Paiements partiels enregistrés sur des achats pas encore synchronisés
/// (donc sans Idachat réel côté serveur). Rattachés localement par
/// uuidClient, puis envoyés à register_paiement.php une fois que l'achat
/// correspondant a été synchronisé et a reçu son vrai Idachat.
class OfflinePayments {
  static const _cle = 'paiementsHorsLigne';

  static Future<Map<String, dynamic>> _tous() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cle);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> _sauvegarder(Map<String, dynamic> tous) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cle, jsonEncode(tous));
  }

  static Future<void> ajouter(String uuidClient, Map<String, dynamic> paiement) async {
    final tous = await _tous();
    final liste = List<Map<String, dynamic>>.from(tous[uuidClient] ?? []);
    liste.add(paiement);
    tous[uuidClient] = liste;
    await _sauvegarder(tous);
  }

  static Future<List<Map<String, dynamic>>> pour(String uuidClient) async {
    final tous = await _tous();
    return List<Map<String, dynamic>>.from(tous[uuidClient] ?? []);
  }

  static Future<double> totalPaye(String uuidClient) async {
    final liste = await pour(uuidClient);
    return liste.fold<double>(0, (s, p) => s + (double.tryParse(p['montant'].toString()) ?? 0));
  }

  static Future<void> supprimer(String uuidClient) async {
    final tous = await _tous();
    tous.remove(uuidClient);
    await _sauvegarder(tous);
  }
}
