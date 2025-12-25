import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Afficher_Utilisateurs extends StatefulWidget {
  const Afficher_Utilisateurs({super.key});

  @override
  State<Afficher_Utilisateurs> createState() => _Afficher_UtilisateursState();
}

class UtilisateursSysteme {
  final String nomUtilisateur;
  final String emailUtilisateur;
  final String motDePasseUtilisateur;
  final String telephoneUtilisateur;
  final String descriptionUtilisateur;
  final String affectationUtilisateur;

  UtilisateursSysteme({
    required this.nomUtilisateur,
    required this.emailUtilisateur,
    required this.motDePasseUtilisateur,
    required this.telephoneUtilisateur,
    required this.descriptionUtilisateur,
    required this.affectationUtilisateur,
  });

  factory UtilisateursSysteme.fromJson(Map<String, dynamic> json) {
    return UtilisateursSysteme(
      nomUtilisateur: json['nomutilisateur']?.toString() ?? "",
      emailUtilisateur: json['Email']?.toString() ?? "",
      motDePasseUtilisateur: json['Motdepass']?.toString() ?? "",
      telephoneUtilisateur: json['phoneUser']?.toString() ?? "",
      descriptionUtilisateur: json['DescriptionUtilisateur']?.toString() ?? "",
      affectationUtilisateur: json['CodeDepot']?.toString() ?? "",
    );
  }
}

class UtilisateursTable extends StatelessWidget {
  final List<UtilisateursSysteme> utilisateurs;

  const UtilisateursTable({required this.utilisateurs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // ✅ scroll horizontal
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Password', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Affectation', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: utilisateurs.map((utilisateur) {
          return DataRow(cells: [
            DataCell(Text(utilisateur.nomUtilisateur.isNotEmpty ? utilisateur.nomUtilisateur : "N/A")),
            DataCell(Text(utilisateur.emailUtilisateur.isNotEmpty ? utilisateur.emailUtilisateur : "N/A")),
            DataCell(Text(utilisateur.motDePasseUtilisateur.isNotEmpty ? utilisateur.motDePasseUtilisateur : "N/A")),
            DataCell(Text(utilisateur.telephoneUtilisateur.isNotEmpty ? utilisateur.telephoneUtilisateur : "N/A")),
            DataCell(Text(utilisateur.descriptionUtilisateur.isNotEmpty ? utilisateur.descriptionUtilisateur : "N/A")),
            DataCell(Text(utilisateur.affectationUtilisateur.isNotEmpty ? utilisateur.affectationUtilisateur : "N/A")),
          ]);
        }).toList(),
      ),
    );
  }
}

class _Afficher_UtilisateursState extends State<Afficher_Utilisateurs> {
  late Future<List<UtilisateursSysteme>> utilisateurs;

  @override
  void initState() {
    super.initState();
    utilisateurs = fetchUtilisateurs();
  }

  Future<List<UtilisateursSysteme>> fetchUtilisateurs() async {
    final response = await http.get(
      Uri.parse('https://riphin-salemanager.com/Sale_manager_API/Get_Utilisateurs.php'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success'] == true) {
        List<dynamic> data = jsonData['data'];
        return data.map((item) => UtilisateursSysteme.fromJson(item)).toList();
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
      body: FutureBuilder<List<UtilisateursSysteme>>(
        future: utilisateurs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun utilisateur trouvé.'));
          } else {
            return UtilisateursTable(utilisateurs: snapshot.data!);
          }
        },
      ),
    );
  }
}