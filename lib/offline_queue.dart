import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// File d'attente locale pour les achats saisis sans réseau. Chaque entrée
/// porte un uuidClient généré sur l'appareil, que sync_achats.php utilise
/// comme clé d'idempotence pour ne jamais créer de doublon côté serveur.
class OfflineQueue {
  static const _key = 'pendingAchats';

  static String generateUuid() {
    final rand = Random();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final suffix = List.generate(8, (_) => rand.nextInt(16).toRadixString(16)).join();
    return 'local-$ts-$suffix';
  }

  static Future<void> add(Map<String, dynamic> achat) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    list.add(achat);
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> removeByUuid(List<String> uuids) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    list.removeWhere((a) => uuids.contains(a['uuidClient']));
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<int> count() async {
    return (await getAll()).length;
  }
}
