import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime start = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime end = DateTime.now();
  List<Map<String, dynamic>> parDepot = [];
  Map<String, dynamic> totaux = {};
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    setState(() => loading = true);
    final s = DateFormat('yyyy-MM-dd').format(start);
    final e = DateFormat('yyyy-MM-dd').format(end);
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/get_dashboard.php?start=$s&end=$e'),
      headers: await Session.authHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          parDepot = List<Map<String, dynamic>>.from(data['parDepot']);
          totaux = data['totaux'];
        });
      }
    }
    setState(() => loading = false);
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? start : end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          start = picked;
        } else {
          end = picked;
        }
      });
      await fetchDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Tableau de bord", style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: fetchDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDate(true),
                    child: Text("Début: ${DateFormat('yyyy-MM-dd').format(start)}"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDate(false),
                    child: Text("Fin: ${DateFormat('yyyy-MM-dd').format(end)}"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (!loading)
              Card(
                color: const Color.fromARGB(230, 248, 236, 236),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Total entreprise", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text("Nombre d'achats : ${totaux['nombreAchats'] ?? 0}"),
                      Text("Volume acheté : ${totaux['volumeAchete'] ?? 0} kg"),
                      Text("Montant total : ${totaux['montantTotal'] ?? 0} FC", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text("Par dépôt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ...parDepot.map((d) => Card(
                  child: ListTile(
                    title: Text("${d['CodeDepot']} — ${d['DescriptionStockage'] ?? ''}"),
                    subtitle: Text(
                      "Achats: ${d['nombreAchats']} • Volume: ${d['volumeAchete']} kg • Prix moyen: ${double.tryParse(d['prixMoyenPondere'].toString())?.toStringAsFixed(1) ?? 0} FC/kg\nMontant: ${d['montantTotal']} FC • Stock actuel: ${d['QuantiteDisponible']} kg",
                    ),
                    isThreeLine: true,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
