import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';
import 'package:sale_manager/pages/gestion_utilisateur.dart';

class Afficher_Utilisateurs extends StatefulWidget {
  const Afficher_Utilisateurs({super.key});

  @override
  State<Afficher_Utilisateurs> createState() => _Afficher_UtilisateursState();
}

class UtilisateursTable extends StatelessWidget {
  final List<Map<String, dynamic>> utilisateurs;
  final void Function(Map<String, dynamic>) onTapUser;

  const UtilisateursTable({super.key, required this.utilisateurs, required this.onTapUser});

  String _s(Map<String, dynamic> u, String key) => (u[key]?.toString().isNotEmpty ?? false) ? u[key].toString() : "N/A";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // ✅ scroll horizontal
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Rôle', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Affectation', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: utilisateurs.map((u) {
          return DataRow(
            onSelectChanged: (_) => onTapUser(u),
            cells: [
              DataCell(Text(_s(u, 'nomutilisateur'))),
              DataCell(Text(_s(u, 'Email'))),
              DataCell(Text(_s(u, 'nom_role'))),
              DataCell(Text(_s(u, 'phoneUser'))),
              DataCell(Text(_s(u, 'DescriptionUtilisateur'))),
              DataCell(Text(_s(u, 'CodeDepot'))),
              DataCell(Text(_s(u, 'Statut'))),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _Afficher_UtilisateursState extends State<Afficher_Utilisateurs> {
  late Future<List<Map<String, dynamic>>> utilisateurs;

  @override
  void initState() {
    super.initState();
    utilisateurs = fetchUtilisateurs();
  }

  Future<List<Map<String, dynamic>>> fetchUtilisateurs() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/Get_Utilisateurs.php'),
      headers: await Session.authHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success'] == true) {
        return List<Map<String, dynamic>>.from(jsonData['data']);
      } else {
        throw Exception('Aucune donnée disponible');
      }
    } else {
      throw Exception('Erreur du serveur: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 63, 129, 86),
        title: const Text('Liste des Utilisateurs',style: TextStyle(color: Colors.white),),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: utilisateurs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun utilisateur trouvé.'));
          } else {
            return UtilisateursTable(
              utilisateurs: snapshot.data!,
              onTapUser: (u) async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => GestionUtilisateurPage(utilisateur: u)));
                setState(() {
                  utilisateurs = fetchUtilisateurs();
                });
              },
            );
          }
        },
      ),
    );
  }
}
