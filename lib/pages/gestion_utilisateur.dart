import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

/// Écran d'édition d'un utilisateur existant : changer son rôle, son dépôt,
/// son plafond journalier, et accorder/révoquer des privilèges individuels
/// en plus de ceux fournis par son rôle.
class GestionUtilisateurPage extends StatefulWidget {
  final Map<String, dynamic> utilisateur;
  const GestionUtilisateurPage({super.key, required this.utilisateur});

  @override
  State<GestionUtilisateurPage> createState() => _GestionUtilisateurPageState();
}

class _GestionUtilisateurPageState extends State<GestionUtilisateurPage> {
  int? selectedRoleId;
  int? selectedDepotId;
  final _plafondController = TextEditingController();
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> depots = [];
  List<Map<String, dynamic>> permissions = [];
  Set<int> permissionsDuRole = {};
  Map<int, String> overrides = {}; // idPermission -> 'accorder' | 'refuser'
  bool loading = true;

  @override
  void initState() {
    super.initState();
    selectedRoleId = widget.utilisateur['id_role'];
    selectedDepotId = widget.utilisateur['IdStockage'];
    if (widget.utilisateur['PlafondJournalier'] != null) {
      _plafondController.text = widget.utilisateur['PlafondJournalier'].toString();
    }
    _init();
  }

  Future<void> _init() async {
    final headers = await Session.authHeaders();
    final resRoles = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/get_roles.php'), headers: headers);
    final resDepots = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/get_depots.php'), headers: headers);
    final resPerms = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/get_permissions.php?idRole=$selectedRoleId'), headers: headers);

    if (resRoles.statusCode == 200) {
      final data = jsonDecode(resRoles.body);
      if (data['success'] == true) roles = List<Map<String, dynamic>>.from(data['data']);
    }
    if (resDepots.statusCode == 200) {
      depots = List<Map<String, dynamic>>.from(jsonDecode(resDepots.body));
    }
    if (resPerms.statusCode == 200) {
      final data = jsonDecode(resPerms.body);
      if (data['success'] == true) {
        permissions = List<Map<String, dynamic>>.from(data['data']);
        permissionsDuRole = Set<int>.from(List<int>.from(data['idRolePermissions']));
      }
    }
    setState(() => loading = false);
  }

  Future<void> enregistrerRoleDepot() async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/update_user_role.php'),
      headers: await Session.authHeaders(),
      body: jsonEncode({
        'idUtilisateur': widget.utilisateur['Idutilsateur'],
        'idRole': selectedRoleId,
        'idStockage': selectedDepotId,
        'plafondJournalier': _plafondController.text.trim().isEmpty ? null : double.tryParse(_plafondController.text.trim()),
      }),
    );
    final data = jsonDecode(response.body);
    if (!mounted) return;
    if (data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Utilisateur mis à jour")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec')));
    }
  }

  Future<void> togglePermission(int idPermission, bool accorderMaintenant) async {
    final effet = accorderMaintenant ? 'accorder' : 'refuser';
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/update_user_privileges.php'),
      headers: await Session.authHeaders(),
      body: jsonEncode({
        'idUtilisateur': widget.utilisateur['Idutilsateur'],
        'idPermission': idPermission,
        'effet': effet,
      }),
    );
    final data = jsonDecode(response.body);
    if (!mounted) return;
    if (data['success'] == true) {
      setState(() => overrides[idPermission] = effet);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec')));
    }
  }

  Future<void> reinitialiserMotDePasse() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Réinitialiser le mot de passe ?"),
        content: Text(
          "Un nouveau mot de passe temporaire sera généré pour ${widget.utilisateur['nomutilisateur']}. "
          "L'ancien mot de passe ne fonctionnera plus, et l'utilisateur devra se reconnecter.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Réinitialiser")),
        ],
      ),
    );
    if (confirme != true) return;

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/reset_user_password.php'),
      headers: await Session.authHeaders(),
      body: jsonEncode({'idUtilisateur': widget.utilisateur['Idutilsateur']}),
    );
    final data = jsonDecode(response.body);
    if (!mounted) return;

    if (data['success'] == true) {
      final motDePasse = data['motDePasseTemporaire'] as String;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Mot de passe temporaire"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Communiquez ce mot de passe à ${data['nomUtilisateur']} — il ne sera plus jamais affiché :"),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  motDePasse,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: motDePasse));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copié")));
              },
              icon: const Icon(Icons.copy),
              label: const Text("Copier"),
            ),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Fermé, c'est noté")),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec')));
    }
  }

  bool _estActuellementAccorde(int idPermission) {
    final override = overrides[idPermission];
    if (override == 'accorder') return true;
    if (override == 'refuser') return false;
    return permissionsDuRole.contains(idPermission);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: Text(widget.utilisateur['nomutilisateur'] ?? 'Utilisateur', style: const TextStyle(color: Colors.white)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  value: selectedRoleId,
                  items: roles.map((r) => DropdownMenuItem<int>(value: r['id_role'], child: Text(r['nom_role']))).toList(),
                  onChanged: (v) async {
                    setState(() => selectedRoleId = v);
                    final headers = await Session.authHeaders();
                    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/get_permissions.php?idRole=$v'), headers: headers);
                    if (res.statusCode == 200) {
                      final data = jsonDecode(res.body);
                      if (data['success'] == true) {
                        setState(() {
                          permissionsDuRole = Set<int>.from(List<int>.from(data['idRolePermissions']));
                          overrides.clear();
                        });
                      }
                    }
                  },
                  decoration: const InputDecoration(labelText: "Rôle", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: depots.any((d) => d['IdStockage'] == selectedDepotId) ? selectedDepotId : null,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text("Aucun (DG/Caissier/Comptable)")),
                    ...depots.map((d) => DropdownMenuItem<int>(value: d['IdStockage'], child: Text(d['CodeDepot']))),
                  ],
                  onChanged: (v) => setState(() => selectedDepotId = v),
                  decoration: const InputDecoration(labelText: "Dépôt affecté", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _plafondController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Plafond journalier (FC, vide = illimité)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: enregistrerRoleDepot,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 63, 129, 86), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                  child: const Text("Enregistrer"),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: reinitialiserMotDePasse,
                  icon: const Icon(Icons.lock_reset, color: Colors.red),
                  label: const Text("Réinitialiser le mot de passe", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45), side: const BorderSide(color: Colors.red)),
                ),
                const Divider(height: 40),
                const Text("Privilèges individuels", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text("Ajuste les droits de cet utilisateur en plus de ceux de son rôle.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                ...permissions.map((p) => SwitchListTile(
                      title: Text(p['code']),
                      subtitle: Text(p['description'] ?? ''),
                      value: _estActuellementAccorde(p['id_permission']),
                      onChanged: (v) => togglePermission(p['id_permission'], v),
                    )),
              ],
            ),
    );
  }
}
