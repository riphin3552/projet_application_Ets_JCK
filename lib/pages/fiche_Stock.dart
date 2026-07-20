import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/pages/export_pdf_page.dart';
import 'dart:convert';
import 'dart:async';

import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';


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
    if (startDate == null || endDate == null || IdDepot == null) return;

    setState(() => loading = true);

    final start = startDate!.toIso8601String().split('T').first;
    final end = endDate!.toIso8601String().split('T').first;

    final url = Uri.parse(
      "${AppConfig.apiBaseUrl}/ficheStock.php"
      "?id=$IdDepot&start=$start&end=$end",
    );

    final response = await http.get(url, headers: await Session.authHeaders());

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



  // L'utilisateur connecté et son dépôt sont déjà connus depuis la connexion.
  void loadUsername() async {
    final nom = await Session.getNomUtilisateur();
    setState(() => nomutilisateur = nom);
  }

  void loadIdepot() async {
    final idDepot = await Session.getIdStockage();
    setState(() => IdDepot = idDepot);
    fetchStockData();
  }

  @override
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