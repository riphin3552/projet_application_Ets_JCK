//import 'package:dropdown_search/dropdown_search.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sale_manager/pages/Get_achats.dart';
//import 'package:sale_manager/pages/TicketAchat.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Operations extends StatefulWidget {
  const Operations({super.key});

  @override
  State<Operations> createState() => _OperationsState();
}

class _OperationsState extends State<Operations> {
  int? selectedAgriculteurId;
  int? selectedDepotId;
  int? selectedProduitId;
  List<Map<String,dynamic>> agricuculteurs=[];  //1. initialisation de la liste
  List<Map<String,dynamic>> depots=[];
  List<Map<String,dynamic>> produits=[];

  int Quantite=0;
  int PrixUnitaire=0;
  int PrixTotal=0;
  DateTime? DateAchat;
  int? IdUtilisateur;
  String nomUtilisateur='';
  
  

  //la cle du formulaire
  final _operationFormKey=GlobalKey<FormState>();

  //les controlleurs
  final _planteurController=TextEditingController();
  final _prixUnitaireController=TextEditingController();
  final _dateController=TextEditingController();
  final _quantiteController=TextEditingController();
  final _primeController= TextEditingController();
  final _prixTotalController=TextEditingController();

//2. chargement des donnees dans le dropdowntextformfield
  Future<void> fetchAgriculteurs() async {
  final response = await http.get(Uri.parse('https://riphin-salemanager.com/Sale_manager_API/get_agriculteurs.php'));
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    setState(() {
      agricuculteurs=List<Map<String,dynamic>>.from(data);
    });
  }
}

//2. chargement des donnees dans le dropdowntextformfield
Future<void> fetchDepots() async {
  final response = await http.get(Uri.parse('https://riphin-salemanager.com/Sale_manager_API/get_depots.php'));
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    setState(() {
      depots=List<Map<String,dynamic>>.from(data);
    });
  }
}

Future<void> fetchProduits() async {
  final response = await http.get(Uri.parse('https://riphin-salemanager.com/Sale_manager_API/getProducts.php'));
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    setState(() {
      produits=List<Map<String,dynamic>>.from(data);
    });
  }
}

//charger l'id de l'utilisateur depuis les shared preferences
  void loadUserName() async {
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
    if (data['idutilisateur'] != null) {
      setState(() {
        IdUtilisateur = data['idutilisateur'];
      });
    } else {
       // ignore: use_build_context_synchronously
       ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Échec: Id utilisateur absent dans la réponse ${data['message']}")),
      );
     }
  } else {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Échec de validation token: ${data['message']}")),
    );
  }
}



//charger le nom de l'utilisateur depuis les shared preferences
  void loadnomUtilisateur() async {
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
        nomUtilisateur = data['nomutilisateur'];
      });
    } else {
       // ignore: use_build_context_synchronously
       ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Échec: nomutilisateur absent dans la réponse ${data['message']}")),
      );
     }
  } else {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Échec: ${data['message']}")),
    );
  }
}


// calcul du prix total
void calculateTotalPrice() {
  final quantite = double.tryParse(_quantiteController.text) ?? 0;
  final prixUnitaire = double.tryParse(_prixUnitaireController.text) ?? 0;
  final primeplanteur=double.tryParse(_primeController.text) ?? 0;
  final totalPrice = (quantite * prixUnitaire)+primeplanteur;
  _prixTotalController.text = totalPrice.toStringAsFixed(2); // Met à jour le champ de texte avec le prix total formaté
}

// Libérer les controlleurs
@override
void dispose() {
  _quantiteController.dispose();
  _prixUnitaireController.dispose();
  _dateController.dispose();
  _prixTotalController.dispose();
  super.dispose();
}

//3. appel du chargement dans initState
@override
void initState(){
  super.initState();
  fetchAgriculteurs();
  fetchDepots();
  fetchProduits();
  loadUserName();
  loadnomUtilisateur();
  calculateTotalPrice();
  _quantiteController.addListener(calculateTotalPrice); // Recalcule le prix total lorsque la quantité change
  _prixUnitaireController.addListener(calculateTotalPrice); // Recalcule le prix total lorsque le prix unitaire change
  _primeController.addListener(calculateTotalPrice);
}


// enregistrer l'achat
Future<void> enregistrerAchat(
   selectedAgriculteurId,
   selectedProduitId,
   selectedDepotId,
  double quantite,
  double prixUnitaire,
  double primeplanteur,
  double prixTotal,
  String dateAchat,
  int? idUtilisateur,
  String nomUtilisateur,
  
) async {
  try {
    var url = Uri.parse(
      "https://riphin-salemanager.com/Sale_manager_API/registerOperations.php",
    );
    var response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'idcultivateur': selectedAgriculteurId,
            'idproduit': selectedProduitId,
            'depot': selectedDepotId,
            'quantite': quantite,
            'prixUnitaire': prixUnitaire,
            'primeplanteur':primeplanteur,
            'totalpayer': prixTotal,
            'date': dateAchat,
            'idutilisateur': idUtilisateur,
            
          }),
        )
        .timeout(Duration(seconds: 10));

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
            content: Text('Operations enregisrtée avec succès'),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GetAchats(nomUtilisateur: nomUtilisateur,))), 
                
                child: Text('OK'),
                               
              ),
            ],
          ),
           
        );
        resetFields(); // Réinitialise les champs après l'enregistrement
      }
    });
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec d'enregistrement: ${jsonResponse['error']}", textAlign: TextAlign.center)),
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
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Erreur de connexion: $e")));
  }
}

void resetFields(){
  _planteurController.clear();
  _quantiteController.clear();
  _prixUnitaireController.clear();
  _primeController.clear();
  _prixTotalController.clear();
  _dateController.clear();
  selectedAgriculteurId = null;
  selectedProduitId = null;
  selectedDepotId = null;
  
  _operationFormKey.currentState?.reset();

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 63, 129, 86),
        title: Text("Achat Matières premières",style: TextStyle(color: Colors.white),),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _operationFormKey,
          child: Column(
            children: [
              Card(
                elevation: 90,
                color: Color.fromARGB(230, 248, 236, 236),
                child: Column(
                  children: [
                    SizedBox(height: 20,),
              Text("Enregistrer les achats Ici!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                           
                Padding(padding: EdgeInsets.all(10),
                  child: 
                    

                //   DropdownButtonFormField<int>(     //4. utilisation de la liste dans le dropdown
                //   value: selectedAgriculteurId,   // valeur selectionnée
                //   items: agricuculteurs.map((item){  // pour chaque element de la liste
                //     return DropdownMenuItem<int>(   // on cree un DropdownMenuItem
                //       value: item['idAgriculteur'], // valeur de l'item
                //       child: Text(item['nomAgriculteur']), // texte affiché
                //     );
                //   } ).toList(),
                // onChanged: (newvalue){
                //   selectedAgriculteurId=newvalue;
                //   //print(selectedAgriculteurId);
                // },
                // decoration: InputDecoration(
                //   labelText: "selectionne un planteur...",
                //   labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                //   hintText: "Planteurs",
                //   border: OutlineInputBorder(),
                // ),
                // validator: (value) {
                //   if(value == null){
                //       return "Veuillez selectionnez un planteur";
                //   }
                //   return null;
                // },
                      TypeAheadField<Map<String, dynamic>>(
  controller: _planteurController,
  suggestionsCallback: (pattern) async {
    if (pattern.isEmpty || pattern.length < 2) return []; // ✅ évite les requêtes inutiles
    
    final response = await http.post(
      Uri.parse("https://riphin-salemanager.com/Sale_manager_API/Get_agriculteurBuy_name.php"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nomplanteur': pattern}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> data = json['data'];
      return List<Map<String, dynamic>>.from(data);
    } else {
      return [];
    }
  },
  builder: (context, controller, focusNode) => TextFormField(
    controller: _planteurController,
    focusNode: focusNode,
    decoration: const InputDecoration(
      labelText: 'Rechercher un planteur',
      labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86))),
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
    selectedAgriculteurId = suggestion['idAgriculteur'];
    print('ID sélectionné : $selectedAgriculteurId');
  },
)

                 ),
               
                
                Padding(padding: EdgeInsets.all(10),
                  child: 
                    DropdownButtonFormField<int>(     //4. utilisation de la liste dans le dropdown
                  // ignore: deprecated_member_use
                  value: selectedProduitId,   // valeur selectionnée
                  items: produits.map((item){  // pour chaque element de la liste
                    return DropdownMenuItem<int>(   // on cree un DropdownMenuItem
                      value: item['IdProduit'], // valeur de l'item
                      child: Text(item['designationProduit']), // texte affiché
                    );
                  } ).toList(),
                onChanged: (newproduit) { 
                  selectedProduitId=newproduit;
                },
                decoration: InputDecoration(
                  labelText: "selectionne un produit",
                  labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                  hintText: "Produits",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                ),
                validator: (value) {
                  if(value == null){
                      return "Veuillez selectionnez un produit";
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
                  
                ),
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
                  child: TextFormField(
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
                  
                  controller: _primeController,
                  decoration: InputDecoration(
                    labelText: "Prime ",
                    hintText: "Saisir la prime ici",
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
                  controller: _prixTotalController,
                  decoration: InputDecoration(
                    labelText: "Prix Total (FC)",
                    labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                    prefixIcon: Icon(Icons.price_check),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                  ),
                ),
                ),
                
                Padding(padding: EdgeInsets.all(10),
                  child: 
                    ElevatedButton(onPressed: (){
                  if(_operationFormKey.currentState!.validate()){
                    // Soumettre le formulaire
                    enregistrerAchat(
                      selectedAgriculteurId,
                      selectedProduitId,
                      selectedDepotId,
                      double.parse(_quantiteController.text),
                      double.parse(_prixUnitaireController.text),
                      ( _primeController.text.isEmpty)? 0.0 : double.parse(_primeController.text),
                      double.parse(_prixTotalController.text),
                      _dateController.text,
                      IdUtilisateur,
                      nomUtilisateur,
                      
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
                  child: Text("Enregistrer",style: TextStyle(color: Colors.white),)))
                )

                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}