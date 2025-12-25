import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/pages/export_pdf_page.dart';
import 'dart:convert';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';


class FicheStockPage extends StatefulWidget {
  @override
  _FicheStockPageState createState() => _FicheStockPageState();
}

class _FicheStockPageState extends State<FicheStockPage> {
  List<dynamic> data = [];
  bool loading = false;
  String nomutilisateur = "";
  int? IdDepot;

  DateTime? startDate;
  DateTime? endDate;

  Future<void> fetchStockData() async {
    if (startDate == null || endDate == null) return;

    setState(() => loading = true);

    final start = startDate!.toIso8601String().split('T').first;
    final end = endDate!.toIso8601String().split('T').first;

    final url = Uri.parse(
      "https://riphin-salemanager.com/Sale_manager_API/ficheStock.php"
      "?id=10&start=$start&end=$end",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final parsed = json.decode(body);
      setState(() {
        data = parsed is List ? parsed : [];
        loading = false;
      });
    } else {
      setState(() => loading = false);
      throw Exception("Erreur API: ${response.statusCode}");
    }
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => endDate = picked);
      await fetchStockData();
    }
  }



  // charger le nom d'utilisateur à partir du token
 void loadUsername() async {

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('Token') ?? '';

  final response = await http.get(
    Uri.parse('https://riphin-salemanager.com/Sale_manager_API/validateToken.php'),
    headers: {
      'Authorization': token,
      'Content-Type': 'application/json',
    },
  );

  final data = jsonDecode(response.body);
  
  if (response.statusCode == 200 && data['success'] == true) {
    if (data['nomutilisateur'] != null) {
      setState(() {
        nomutilisateur = data['nomutilisateur'];
      });
    } else {
       // ignore: use_build_context_synchronously
       ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Échec: Id de depot absent dans la réponse ${data['message']}")),
      );
     }
  } else {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Échec de validation token: ${data['message']}")),
    );
  }
}


// charger IdDepot à partir du token
void loadIdepot() async {

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('Token') ?? '';

  final response = await http.get(
    Uri.parse('https://riphin-salemanager.com/Sale_manager_API/validateToken.php'),
    headers: {
      'Authorization': token,
      'Content-Type': 'application/json',
    },
  );

  final data = jsonDecode(response.body);
  
  if (response.statusCode == 200 && data['success'] == true) {
    if (data['idstockage'] != null) {
      setState(() {
        IdDepot = data['idstockage'];
      });
    } else {
       // ignore: use_build_context_synchronously
       ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Échec: Id de depot absent dans la réponse ${data['message']}")),
      );
     }
  } else {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Échec de validation token: ${data['message']}")),
    );
  }
}


void initState() {
    super.initState();
    loadUsername();
    loadIdepot();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fiche de stock")),
      body: Column(
        children: [
          // 🔹 Zone de sélection des dates
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickStartDate,
                    child: Text(startDate == null
                        ? "Choisir date début"
                        : "${startDate!.toLocal()}".split(' ')[0]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickEndDate,
                    child: Text(endDate == null
                        ? "Choisir date fin"
                        : "${endDate!.toLocal()}".split(' ')[0]),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Tableau des résultats
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Stock Initial')),
                        DataColumn(label: Text('Entrée')),
                        DataColumn(label: Text('Sortie')),
                        DataColumn(label: Text('Stock Final')),
                      ],
                      rows: data.map((row) {
                        final date = row['DateJour'] ?? '';
                        final stockInitial =
                            double.tryParse(row['StockInitial'].toString()) ?? 0.0;
                        final entree =
                            double.tryParse(row['Entree'].toString()) ?? 0.0;
                        final sortie =
                            double.tryParse(row['Sortie'].toString()) ?? 0.0;
                        final stockFinal =
                            double.tryParse(row['StockFinal'].toString()) ?? 0.0;

                        return DataRow(cells: [
                          DataCell(Text(date)),
                          DataCell(Text(stockInitial.toString())),
                          DataCell(Text(entree.toString())),
                          DataCell(Text(sortie.toString())),
                          DataCell(Text(stockFinal.toString())),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),

          // 🔹 Bouton pour exporter en PDF
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Exporter en PDF"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExportPdfPage(
                      data: data,
                      startDate: startDate,
                      endDate: endDate,
                      userName: nomutilisateur,
                      depotId: IdDepot.toString(),
                      companyName: "MD SERVICE SARL",
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}