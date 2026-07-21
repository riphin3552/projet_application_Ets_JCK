import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identifiants mémorisés localement pour permettre à un acheteur de se
/// connecter même sans réseau, avec les informations (rôle, permissions...)
/// de sa dernière connexion réussie en ligne. Le mot de passe n'est jamais
/// stocké en clair : seule son empreinte (SHA-256) est gardée, uniquement
/// pour être comparée localement.
class CachedCredentials {
  static const _kCle = 'comptesConnus';

  static String _empreinte(String motDePasse) {
    return sha256.convert(utf8.encode(motDePasse)).toString();
  }

  static Future<List<Map<String, dynamic>>> _tousLesComptes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCle);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> _sauvegarderTous(List<Map<String, dynamic>> comptes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCle, jsonEncode(comptes));
  }

  /// À appeler après chaque connexion réussie EN LIGNE : mémorise l'email,
  /// l'empreinte du mot de passe, et la session complète (pour pouvoir
  /// reconnecter l'utilisateur hors-ligne avec les mêmes droits).
  static Future<void> enregistrer(String email, String motDePasse, Map<String, dynamic> session) async {
    final comptes = await _tousLesComptes();
    comptes.removeWhere((c) => c['email'] == email);
    comptes.add({
      'email': email,
      'empreinte': _empreinte(motDePasse),
      'session': session,
    });
    await _sauvegarderTous(comptes);
  }

  /// Liste des emails déjà connectés sur cet appareil, pour suggestion à la saisie.
  static Future<List<String>> emailsConnus() async {
    final comptes = await _tousLesComptes();
    return comptes.map((c) => c['email'] as String).toList();
  }

  /// Tente une connexion hors-ligne : renvoie la session mémorisée si
  /// l'email et le mot de passe correspondent à une connexion précédente,
  /// sinon null.
  static Future<Map<String, dynamic>?> tenterConnexionHorsLigne(String email, String motDePasse) async {
    final comptes = await _tousLesComptes();
    final empreinte = _empreinte(motDePasse);
    for (final compte in comptes) {
      if (compte['email'] == email && compte['empreinte'] == empreinte) {
        return Map<String, dynamic>.from(compte['session']);
      }
    }
    return null;
  }
}
