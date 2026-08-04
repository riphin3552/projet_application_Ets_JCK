import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';


class Stockage extends StatefulWidget {
  const Stockage({super.key});

  @override
  State<Stockage> createState() => _StockageState();
}

class _StockageState extends State<Stockage> {
  final _formKeyStockage = GlobalKey<FormState>();
  final _codeStockageController=TextEditingController();
  final _capacityStockageController=TextEditingController();
  final _stockageDescriptionCOntroller=TextEditingController();
  final FocusNode _focusNodeStockage=FocusNode();

  List<Map<String, dynamic>> depots = [];
  bool chargement = false;
  bool peutGerer = false;

  @override
  void initState() {
    super.initState();
    chargerPermission();
    fetchDepots();
  }

  Future<void> chargerPermission() async {
    final peut = await Session.can('depots.gerer');
    if (mounted) setState(() => peutGerer = peut);
  }

  Future<void> fetchDepots() async {
    setState(() => chargement = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/get_depots.php'),
        headers: await Session.authHeaders(),
      );
      if (response.statusCode == 200) {
        setState(() => depots = List<Map<String, dynamic>>.from(jsonDecode(response.body)));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    }
    if (mounted) setState(() => chargement = false);
  }

  //reinitialiser les chmaps
  void resetFields(){
    _codeStockageController.clear();
    _capacityStockageController.clear();
    _stockageDescriptionCOntroller.clear();
  }

Future<void> addStorage(
  String codeDepot,
  String capaciteDepot,
  String descriptionDepot

) async{
  try{

    var url=Uri.parse('${AppConfig.apiBaseUrl}/stockage.php');

  var response= await http.post(
    url,
    headers: await Session.authHeaders(),
    body: json.encode({
      'namestorage':codeDepot,
      'storageCapacity':capaciteDepot,
      'Storedescription':descriptionDepot,
      'InitialQuantiy':0,
      })
  ).timeout(Duration(seconds: 10));
    if (!mounted) return; // ✅ vérifie que le widget est encore actif

if (response.statusCode == 200) {
  var jsonResponse = jsonDecode(response.body);
  if (jsonResponse['error'] == null) {
    // ✅ Appelle le dialogue dans un délai pour éviter les conflits
    Future.delayed(Duration.zero, () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text('Dépot ajouté avec succès'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),

        );
        resetFieldsStorage(); // Réinitialise les champs après l'enregistrement
        fetchDepots();
      }
    });
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec de modification: ${jsonResponse['error']}", textAlign: TextAlign.center)),
      );
    }
  }
} else {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Échec de la requête: ${response.statusCode}", textAlign: TextAlign.center)),
    );
  }
}
  }catch(e){
    if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur de connexion")));

  }

}

//reinitialiser les chmaps
void resetFieldsStorage(){
    _codeStockageController.clear();
    _capacityStockageController.clear();
    _stockageDescriptionCOntroller.clear();
  }

  /// Ouvre un formulaire pré-rempli pour modifier un dépôt existant.
  Future<void> modifierDepot(Map<String, dynamic> depot) async {
    final codeController = TextEditingController(text: depot['CodeDepot'] ?? '');
    final capaciteController = TextEditingController(text: (depot['CapaciteStockage_KG'] ?? '').toString());
    final seuilController = TextEditingController(text: (depot['SeuilAlerteKG'] ?? '').toString());
    final descriptionController = TextEditingController(text: depot['DescriptionStockage'] ?? '');
    final formKey = GlobalKey<FormState>();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier le dépôt"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: "Code dépôt", border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? "Requis" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capaciteController,
                  decoration: const InputDecoration(labelText: "Capacité (kg)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: seuilController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Seuil d'alerte (kg)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/update_depot.php'),
        headers: await Session.authHeaders(),
        body: jsonEncode({
          'idStockage': depot['IdStockage'],
          'codeDepot': codeController.text,
          'capacite': capaciteController.text,
          'seuilAlerte': seuilController.text,
          'description': descriptionController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dépôt mis à jour")));
        await fetchDepots();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Échec de la mise à jour')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 63, 129, 86),
        title: Text("Stockage",style: TextStyle(color: Colors.white),),
      ),

      body: RefreshIndicator(
        onRefresh: fetchDepots,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child:
             Form(
              key: _formKeyStockage,
              child: Column(
                children: [
                  Card(
                    color: Color.fromARGB(230, 248, 236, 236),
                    elevation: 90,
                    child: Column(
                      children: [
                        Text("Ajouter un dépôt de stockage ici!",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                  SizedBox(height: 20,),

                    Padding(padding: EdgeInsets.all(10),
                      child:
                        TextFormField(
                    focusNode: _focusNodeStockage,
                    controller: _codeStockageController,
                    decoration: InputDecoration(
                      labelText: "Code depôt",
                      labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                      hintText: "saisir le nom du depot",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                    ),
                  ),
                    ),

                    Padding(padding: EdgeInsets.all(10),
                    child:
                      TextFormField(
                    controller: _stockageDescriptionCOntroller,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Description",
                      labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                      hintText: "Ajouter un peu de detail...",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.outbox_sharp),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 118, 189, 247)))
                    ),
                  ),
                    ),

                    Padding(padding: EdgeInsets.all(10),
                      child:
                        TextFormField(
                    controller: _capacityStockageController,
                    decoration: InputDecoration(
                      labelText: "Capacité",
                      labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                      hintText: "Capacité de stockage",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                    ),
                  ),
                    ),

                    Padding(padding: EdgeInsets.all(10),
                      child:
                        TextFormField(
                    //controller: _QuantityDisponibleController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Quantité disponible",
                      labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                      hintText: "000 kg",
                      prefixIcon: Icon(Icons.calculate),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                    ),
                  ),
                    ),


                    Padding(padding: EdgeInsets.all(10),
                      child: ElevatedButton(onPressed: (){
                      addStorage(
                        _codeStockageController.text,
                        _capacityStockageController.text,
                        _stockageDescriptionCOntroller.text,
                      );
                  },style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 63, 129, 86),
                    padding: EdgeInsets.symmetric(horizontal: 130, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                   child: Text("Ajouter",style: TextStyle(color: Colors.white),))
                    ),



                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Liste des dépôts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(height: 8),
                  if (chargement) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
                  if (!chargement && depots.isEmpty) const Text("Aucun dépôt enregistré"),
                  ...depots.map((d) => Card(
                        child: ListTile(
                          title: Text(d['CodeDepot'] ?? ''),
                          subtitle: Text(
                            "Capacité : ${d['CapaciteStockage_KG'] ?? '—'} kg • Seuil alerte : ${d['SeuilAlerteKG'] ?? '—'} kg\n"
                            "Stock actuel : ${d['QuantiteDisponible'] ?? 0} kg"
                            "${(d['DescriptionStockage'] ?? '').toString().isNotEmpty ? '\n${d['DescriptionStockage']}' : ''}",
                          ),
                          isThreeLine: true,
                          trailing: peutGerer
                              ? IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                  onPressed: () => modifierDepot(d),
                                )
                              : null,
                        ),
                      )),
            ],)),
          )
        ),
      );
  }
}
