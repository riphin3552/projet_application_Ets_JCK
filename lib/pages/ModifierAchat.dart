import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';
import 'package:sale_manager/reference_cache.dart';

class ModifierAchat extends StatefulWidget {
   ModifierAchat({required this.achatData});
  final Map<String, dynamic> achatData;

  @override
  State<ModifierAchat> createState() => _ModifierAchatState();
}

class _ModifierAchatState extends State<ModifierAchat> {

 int? selectedAgriculteurId;
 int? selectedDepotId;
  List<Map<String, dynamic>> agriculteurs=[];
  List<Map<String, dynamic>> depots=[];
 DateTime? DateAchat;

  final _planteurController=TextEditingController();
 TextEditingController _idAchatController= TextEditingController();
 TextEditingController _ancienIdProduit=TextEditingController();
 TextEditingController _quantiteController=TextEditingController();
 TextEditingController _prixUnitaireController=TextEditingController();
 TextEditingController _primeController=TextEditingController();
 TextEditingController _prixtotalController= TextEditingController();
 TextEditingController _dateController=TextEditingController();

final _formUpdateKey=GlobalKey<FormState>();


// Repli sur le cache local si le réseau échoue (hors-ligne sur le terrain)
  Future<void> fetchAgriculteurs() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/get_agriculteurs.php'), headers: await Session.authHeaders())
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final donnees = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        await ReferenceCache.save('agriculteurs', donnees);
        if (mounted) setState(() => agriculteurs = donnees);
        return;
      }
    } catch (_) {}
    final cache = await ReferenceCache.get('agriculteurs');
    if (mounted) setState(() => agriculteurs = cache);
}

Future<void> fetchDepots() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/get_depots.php'), headers: await Session.authHeaders())
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final donnees = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        await ReferenceCache.save('depots', donnees);
        if (mounted) setState(() => depots = donnees);
        return;
      }
    } catch (_) {}
    final cache = await ReferenceCache.get('depots');
    if (mounted) setState(() => depots = cache);
}




void calculateTotalPrice() {
  final quantite = double.tryParse(_quantiteController.text) ?? 0;
  final prixUnitaire = double.tryParse(_prixUnitaireController.text) ?? 0;
  final primeplanteur =double.tryParse(_primeController.text) ?? 0;
  final totalPrice = (quantite * prixUnitaire)+primeplanteur;
  _prixtotalController.text = totalPrice.toStringAsFixed(2); // Met à jour le champ de texte avec le prix total formaté
}

@override
void initState(){
  super.initState();
  fetchAgriculteurs();
  fetchDepots();
  
  _idAchatController.text=widget.achatData['Idachat'].toString();
  _ancienIdProduit.text=widget.achatData['IdProduit'].toString();
  _quantiteController.text=widget.achatData['Quantite_KG'].toString();
  _prixUnitaireController.text=widget.achatData['prixUnitaire'].toString();
  _primeController.text=widget.achatData['PrimePlanteur'].toString();
  _dateController.text=widget.achatData['dateAchat'].toString();
  _prixtotalController.text=widget.achatData['totalPayer'].toString();

  calculateTotalPrice();
  _quantiteController.addListener(calculateTotalPrice); // Recalcule le prix total lorsque la quantité change
  _prixUnitaireController.addListener(calculateTotalPrice); // Recalcule le prix total lorsque le prix unitaire change
  _primeController.addListener(calculateTotalPrice); // Recalcule du total lorsque la prime change

}

Future<void> UpdateAchat(
  BuildContext, //pour le showdialogue lors que les composants sont dans un card()
  int Idachat,
  int ancienIdProduit,
  selectedAgriculteurId,
  selectedDepotId,
  double quantite,
  double prixUnitaire,
  double primeplanteur,
  double prixTotal,
  String dateAchat,

) async{
  try{
    var url= Uri.parse("${AppConfig.apiBaseUrl}/updateAchat.php");
    var response=await http.post(

      url,
      headers: await Session.authHeaders(),
      body: json.encode({
        'idAchat': Idachat.toString(),
        'ancienIdproduit': ancienIdProduit,
        'idcultivateur': selectedAgriculteurId,
        'depot': selectedDepotId,
        'quantite': quantite,
        'prixUnitaire': prixUnitaire,
        'primeplanteur':primeplanteur,
        'date': dateAchat,
        'totalpayer': _prixtotalController.text,
  }),
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
            content: Text('Modification avec succès'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
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

  } catch(e){
      if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Erreur de connexion")));
  }

}


  
// code de verification avant modification
void CodeModification(BuildContext context) {
  TextEditingController _inputController = TextEditingController();
  const String correctCode = 'Ets_JC@Nobili'; // Le code correct prédéfini

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: 
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue),
              SizedBox(width: 10),
              Text('Code de modification'),
            ],
          ),
        content: TextField(
          controller: _inputController,
          decoration: InputDecoration(
            hintText: '********',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Valider'),
            onPressed: () {
              final saisie = _inputController.text.trim();

              // 🔍 Vérification simple
              if (saisie.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Veuillez saisir un code valide')),
                );
              } else if (saisie == correctCode) {
                Navigator.pop(context); // Ferme le popup
                
                // Appel de la fonction de mise à jour  
                UpdateAchat(
                            context,
                            int.parse(_idAchatController.text),
                            int.parse(_ancienIdProduit.text), 
                            selectedAgriculteurId, 
                            selectedDepotId, 
                            double.parse(_quantiteController.text), 
                            double.parse(_prixUnitaireController.text),
                            double.parse(_primeController.text),
                            double.parse(_prixtotalController.text),
                            _dateController.text,

                            );

                
                
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Code incorrect')),
                );
              }
            },
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 63, 129, 86),
        title: Text("Modifier Achat",style: TextStyle(color: Colors.white),),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(padding: EdgeInsets.all(16), //
              
              child: Form(
                key: _formUpdateKey,
                
                child: 
                        
                Card(
                  elevation: 20, // ombre de la carte
                  child: Column(
                    children: [
                      Text("Modifier l'achat", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                      SizedBox(height: 10,),

                                       
                  Padding(padding: EdgeInsets.all(10),
                    child: TextFormField(
                        readOnly: true,
                        
                        controller: _idAchatController,
                        decoration: InputDecoration(
                          labelText: "ID achat",
                          labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                          prefixIcon: Icon(Icons.price_check),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                        ),
                      ),
                  ),

                  Padding(padding: EdgeInsets.all(10),
                    child: 
                      TextFormField(
                        readOnly: true,
                        
                        controller: _ancienIdProduit,
                        decoration: InputDecoration(
                          labelText: "ID Produit",
                          labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                          prefixIcon: Icon(Icons.price_check),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                        ),
                      ),
                      
                  ),

                    Padding(padding: EdgeInsets.all(10),
                      child: 
                     TypeAheadField<Map<String, dynamic>>(
  controller: _planteurController,
  suggestionsCallback: (pattern) {
    // Recherche locale (fonctionne aussi hors-ligne) sur la liste déjà chargée
    if (pattern.isEmpty) return agriculteurs;
    final recherche = pattern.toLowerCase();
    return agriculteurs
        .where((a) => (a['nomAgriculteur'] ?? '').toString().toLowerCase().contains(recherche))
        .toList();
  },
  builder: (context, controller, focusNode) => TextFormField(
    controller: _planteurController,
    focusNode: focusNode,
    decoration: const InputDecoration(
      labelText: 'Rechercher un planteur',
      labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)),
      ),
      prefixIcon: Icon(Icons.search),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return "Veuillez sélectionner un planteur";
      }
      return null;
    },
  ),
  itemBuilder: (context, suggestion) => ListTile(
    title: Text(suggestion['nomAgriculteur']),
  ),
  onSelected: (suggestion) {
    _planteurController.text = suggestion['nomAgriculteur'];
    // ✅ Conversion en int pour éviter les erreurs
    selectedAgriculteurId = int.tryParse(suggestion['idAgriculteur'].toString());
    print('ID sélectionné : $selectedAgriculteurId');
  },
)
                    ),

                      //SizedBox(height: 2,),
                    Padding(padding: EdgeInsets.all(10),
                  child: 
                    DropdownButtonFormField(
                // ignore: deprecated_member_use
                value: selectedDepotId,
                items: depots.map((item){
                  return DropdownMenuItem<int>(
                    value: item['IdStockage'],
                    child: Text(item['CodeDepot']),
                  );
                }).toList(),
               onChanged: (newdepot) {
                  selectedDepotId=newdepot;
                  print(selectedDepotId);
               },
               
               decoration: InputDecoration(
                  labelText: "selectionne une option...",
                  labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                  hintText: "Depots",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if(value == null){
                      return "Veuillez selectionnez un depot";
                  }
                  return null;
                },
                ),
                ),

                  Padding(padding: EdgeInsets.all(10),
                  child: 
                    TextFormField(
                  controller: _quantiteController,
                  decoration: InputDecoration(
                    labelText: "Quantité (Kg)",
                    labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                    hintText: "saisir la quantité achetée",
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                  ),
                  )
                  ),

                  Padding(padding: EdgeInsets.all(10),
                    child: 
                    TextFormField(
                  controller: _prixUnitaireController,
                  decoration: InputDecoration(
                    labelText: "Prix Unitaire (FC)",
                    labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                    hintText: "saisir le prix unitaire",
                    prefixIcon: Icon(Icons.price_change),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                  ),
                ),
                  ),

                
                  Padding(padding: EdgeInsets.all(10),
              child: 
              TextFormField(
                  controller: _dateController,
                  readOnly: true, // Empêche la saisie manuelle
                  decoration: InputDecoration(
                    labelText: "Date d'achat",
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
                        _dateController.text = formattedDate; // Met à jour le champ avec la date sélectionnée
                      });
                    }
                  },

                ),
            ),   

            Padding(padding: EdgeInsets.all(10),
                    child: 
                    TextFormField(
                  controller: _primeController,
                  decoration: InputDecoration(
                    labelText: "Prime (FC)",
                    labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                    hintText: "saisir la prime",
                    prefixIcon: Icon(Icons.price_change),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                  ),
                ),
                  ),

              Padding(padding: EdgeInsets.all(10),
                    child: 
                    TextFormField(
                      readOnly: true,
                  controller: _prixtotalController,
                  decoration: InputDecoration(
                    labelText: "Prix Total (FC)",
                    labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                    hintText: "total à payer",
                    prefixIcon: Icon(Icons.price_change),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                  ),
                ),
                  ),

                Padding(padding: EdgeInsets.all(10),
                  child: ElevatedButton(onPressed: (){
                      if(_formUpdateKey.currentState!.validate()){

                            
                          
                                CodeModification(context); // appel du code de verification
                            }

                            
                                                  
                      },
                      
                   style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 63, 129, 86),
                  padding: EdgeInsets.symmetric(horizontal: 130, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                  child: Text("Appliquer",style: TextStyle(color: Colors.white),)),
                ),


                    ],
                  ),
                  
                ),
              ),

              ),
                
              
            ],
          ),
        )
    )
    );
  }
}