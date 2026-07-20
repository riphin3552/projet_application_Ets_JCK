import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sale_manager/pages/afficheStock.dart';
import 'package:sale_manager/pages/fiche_Stock.dart';
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class EXPEDICTION extends StatefulWidget {
  const EXPEDICTION({super.key});

  @override
  State<EXPEDICTION> createState() => _EXPEDICTIONState();
}

class _EXPEDICTIONState extends State<EXPEDICTION> {
  int? selectedProduitId;
  
  List<Map<String, dynamic>> produits = [];
  int? IdDepot;
  

  final _formKey = GlobalKey<FormState>();
  final _dateExpeditionController = TextEditingController();
  final _transporteurController = TextEditingController();
  final _quantiteController = TextEditingController();


    Future<void> fetchProduits() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/getProducts.php'),
      headers: await Session.authHeaders(),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        produits=List<Map<String,dynamic>>.from(data);
      });
    }
  }

  // Le dépôt de l'utilisateur connecté est déjà connu depuis la connexion.
  void loadIdepot() async {
    final idDepot = await Session.getIdStockage();
    setState(() => IdDepot = idDepot);
  }



// enregistrer l'expédition

Future<void> saveExpedition(
  String dateExpedition,
  int? selectedProduitId,
  int? idDepot,
  int quantite,
  String transporteur,
  
) async {
  try{
  final response = await http.post(
    Uri.parse('${AppConfig.apiBaseUrl}/Expedier.php'),
    headers: await Session.authHeaders(),
    body: jsonEncode({
      'dateExpedition': dateExpedition,
      'idproduit': selectedProduitId,
      'iddepot': idDepot,
      'quantite': quantite,
      'transporteur': transporteur,
      
    }),
  );

  final data = jsonDecode(response.body);
  
  if (response.statusCode == 200 && data['success'] == true) {
    var jsonResponse = jsonDecode(response.body);
    if (jsonResponse['error'] == null) {
      // ✅ Appelle le dialogue dans un délai pour éviter les conflits
      Future.delayed(Duration.zero, () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Text('Expédition enregistrée avec succès et stock mis à jour'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
            
          );
          resetFieldsExpedition(); // Réinitialise les champs après l'enregistrement
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec d'enregistrement: ${jsonResponse['error']}", textAlign: TextAlign.center)),
        );
      }
    }
  }else {
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


@override
  void initState() {
    super.initState();
    fetchProduits();
    loadIdepot();
  }

void resetFieldsExpedition(){
    _dateExpeditionController.clear();
    _quantiteController.clear();
    _transporteurController.clear();
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 63, 129, 86),
        title: Text('Expédition',style: TextStyle(color: Colors.white),),

        actions: [
          PopupMenuButton<String>(
            onSelected: (value){
              if(value=='Mon stock'){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>StockProduits()));
              }else if(value=='Fiche de stockage'){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>FicheStockPage()));
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Mon stock',
                  child: Text('Mon stock'),
                ),
                PopupMenuItem<String>(
                  value: 'Fiche de stockage',
                  child: Text('Fiche de stockage'),
                ),
              ];
            },
          )
          ],
      ),
      body: Center(
        child: SingleChildScrollView(
          
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: 
            Column(
              children: [
                Card(
                  elevation: 80,
                  color: Color.fromARGB(230, 248, 236, 236),
                  
                  child: Column(
                    children: [
                      Text("Expéditier au dépôt central",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Color.fromARGB(255, 7, 7, 7)),),
                      SizedBox(height: 10,),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: 
                      TextFormField(
                      controller: _dateExpeditionController,
                      readOnly: true, // Empêche la saisie manuelle
                      decoration: InputDecoration(
                        labelText: "Date d'Expédition",
                        labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                        hintText: "Sélectionner la date",
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000), // Date de début
                          lastDate: DateTime(2101), // Date de fin
                        );
                        if (pickedDate != null) {
                          String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                          setState(() {
                            _dateExpeditionController.text = formattedDate; // Met à jour le champ avec la date sélectionnée
                          });
                        }
                      },
                  
                    ),
                    ),
        
                    Padding(padding: EdgeInsets.all(8),
                      child: DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Produit',
                          labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                        ),
                        items: produits.map((produit) {
                          return DropdownMenuItem<int>(
                            value: produit['IdProduit'],
                            child: Text(produit['designationProduit']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedProduitId = value;
                          });
                        },
                        // ignore: deprecated_member_use
                        value: selectedProduitId,
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: _quantiteController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantité',
                        prefixIcon: Icon(Icons.numbers),
                        labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                      ),
                    ),
                  ),


                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: _transporteurController,
                      decoration: InputDecoration(
                        labelText: 'Transporteur',
                        prefixIcon: Icon(Icons.local_shipping),
                        labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                      ),
                    ),
                  ),

                  
                  Padding(padding: EdgeInsets.all(10),
                  child: 
                    ElevatedButton(onPressed: (){
                  if(_formKey.currentState!.validate()){
                    // Soumettre le formulaire
                   
                    saveExpedition(
                      _dateExpeditionController.text, 
                      selectedProduitId, 
                      IdDepot,
                      int.parse(_quantiteController.text), 
                      _transporteurController.text
                      );
                    

                  }
                },style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50), // Largeur du bouton
                  backgroundColor: Color.fromARGB(255, 63, 129, 86),
                  padding: EdgeInsets.symmetric(horizontal: 130, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                 child: 
                 FittedBox(
                  fit: BoxFit.scaleDown,  // Ajuste le texte si nécessaire
                  child: Text("Soumettre",style: TextStyle(color: Colors.white),)))
                )
                  
                  ],
                  )
                    
                  ),
        
                  
                
              ],
            )
        ),
            ),
      )
    );
  }
}