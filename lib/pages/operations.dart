
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sale_manager/pages/Get_achats.dart';
//import 'package:sale_manager/pages/TicketAchat.dart';
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';
import 'package:sale_manager/offline_queue.dart';
import 'package:sale_manager/reference_cache.dart';


class Operations extends StatefulWidget {
  const Operations({super.key});

  @override
  State<Operations> createState() => _OperationsState();
}

class _OperationsState extends State<Operations> {
  int? selectedAgriculteurId;
  int? selectedDepotId;
  int? selectedProduitId;
  int? selectedLotId;
  List<Map<String,dynamic>> agricuculteurs=[];  //1. initialisation de la liste
  List<Map<String,dynamic>> depots=[];
  List<Map<String,dynamic>> produits=[];
  List<Map<String,dynamic>> lots=[];

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
  // Nom réellement tapé par l'acheteur quand le planteur de secours est
  // utilisé (planteur introuvable localement, saisi hors-ligne). Sert à
  // créer le vrai planteur au moment de la synchronisation.
  String? _nomPlanteurSaisi;
  final _prixUnitaireController=TextEditingController();
  final _dateController=TextEditingController();
  final _quantiteController=TextEditingController();
  final _primeController= TextEditingController();
  final _prixTotalController=TextEditingController();

// Chargement des données de référence : on tente le réseau, on met en
// cache local dès que ça réussit, et si le réseau échoue (pas de signal sur
// le terrain), on recharge la dernière copie connue au lieu de laisser le
// formulaire vide.
  Future<void> fetchAgriculteurs() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/get_agriculteurs.php'), headers: await Session.authHeaders())
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final donnees = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        await ReferenceCache.save('agriculteurs', donnees);
        if (mounted) setState(() => agricuculteurs = donnees);
        return;
      }
    } catch (_) {
      // pas de réseau : on retombe sur le cache ci-dessous
    }
    final cache = await ReferenceCache.get('agriculteurs');
    if (mounted) setState(() => agricuculteurs = cache);
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

Future<void> fetchProduits() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/getProducts.php'), headers: await Session.authHeaders())
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final donnees = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        await ReferenceCache.save('produits', donnees);
        if (mounted) setState(() => produits = donnees);
        return;
      }
    } catch (_) {}
    final cache = await ReferenceCache.get('produits');
    if (mounted) setState(() => produits = cache);
}

// Lots ouverts, pour rattacher l'achat à un lot (facultatif)
Future<void> fetchLots() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/get_lots.php'), headers: await Session.authHeaders())
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final donnees = List<Map<String, dynamic>>.from(data['data']).where((l) => l['statut'] == 'ouvert').toList();
          await ReferenceCache.save('lots', donnees);
          if (mounted) setState(() => lots = donnees);
          return;
        }
      }
    } catch (_) {}
    final cache = await ReferenceCache.get('lots');
    if (mounted) setState(() => lots = cache.where((l) => l['statut'] == 'ouvert').toList());
}

// L'utilisateur connecté est déjà connu (stocké à la connexion), inutile de
// rappeler validateToken.php.
void loadUserName() async {
  final id = await Session.getIdUtilisateur();
  setState(() {
    IdUtilisateur = id == 0 ? null : id;
  });
}

void loadnomUtilisateur() async {
  final nom = await Session.getNomUtilisateur();
  setState(() {
    nomUtilisateur = nom;
  });
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
  fetchLots();
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
  final achatPayload = {
    'idcultivateur': selectedAgriculteurId,
    'idproduit': selectedProduitId,
    'depot': selectedDepotId,
    'idLot': selectedLotId,
    'quantite': quantite,
    'prixUnitaire': prixUnitaire,
    'primeplanteur':primeplanteur,
    'totalpayer': prixTotal,
    'date': dateAchat,
    'idutilisateur': idUtilisateur,
    'uuidClient': OfflineQueue.generateUuid(),
    'nomPlanteurSaisi': _nomPlanteurSaisi,
  };
  try {
    var url = Uri.parse(
      "${AppConfig.apiBaseUrl}/registerOperations.php",
    );
    var response = await http
        .post(
          url,
          headers: await Session.authHeaders(),
          body: json.encode(achatPayload),
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
    // Pas de réseau (ou serveur injoignable) : on met l'achat en attente
    // localement au lieu de le perdre. Il sera synchronisé plus tard via
    // sync_achats.php (idempotent grâce à uuidClient).
    await OfflineQueue.add(achatPayload);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pas de connexion : achat enregistré localement, il sera synchronisé plus tard")),
    );
    resetFields();
  }
}

void resetFields(){
  _planteurController.clear();
  _nomPlanteurSaisi = null;
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
  suggestionsCallback: (pattern) {
    // Recherche locale sur la liste déjà en mémoire/cache : fonctionne même
    // sans réseau, et plus réactif qu'un appel serveur à chaque lettre tapée.
    final recherche = pattern.toLowerCase();
    final resultats = pattern.isEmpty
        ? agricuculteurs
        : agricuculteurs.where((a) => (a['nomAgriculteur'] ?? '').toString().toLowerCase().contains(recherche)).toList();

    // Si le planteur recherché n'est pas trouvé, on propose toujours le
    // planteur de secours (utilisable hors-ligne, à corriger une fois en ligne).
    final secours = agricuculteurs.where((a) => a['CodePlanteur'] == 'SECOURS').toList();
    if (resultats.isEmpty && secours.isNotEmpty && pattern.isNotEmpty) {
      return secours;
    }
    return resultats;
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
      helperText: "Planteur introuvable ? Choisissez Plant_secours et corrigez plus tard",
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return "Veuillez sélectionner un planteur";
      }
      return null;
    },
  ),
  itemBuilder: (context, suggestion) {
    final estSecours = suggestion['CodePlanteur'] == 'SECOURS';
    return ListTile(
      leading: estSecours ? const Icon(Icons.warning_amber, color: Colors.orange) : null,
      title: Text(suggestion['nomAgriculteur']),
      subtitle: estSecours ? const Text("Planteur temporaire — à corriger une fois en ligne") : null,
    );
  },
  onSelected: (suggestion) {
    final estSecours = suggestion['CodePlanteur'] == 'SECOURS';
    // On garde le nom réellement tapé par l'acheteur avant de le remplacer
    // par l'étiquette du planteur de secours, pour pouvoir créer le vrai
    // planteur avec ce nom lors de la synchronisation.
    if (estSecours) {
      _nomPlanteurSaisi = _planteurController.text.isNotEmpty ? _planteurController.text : null;
    }
    // L'achat hors-ligne est enregistré avec le nom "Plant_secours" tel
    // quel ; le nom réellement tapé reste capturé à part (_nomPlanteurSaisi)
    // pour compléter le vrai planteur au moment de la synchronisation.
    _planteurController.text = suggestion['nomAgriculteur'];
    selectedAgriculteurId = suggestion['idAgriculteur'];
    if (estSecours && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Planteur temporaire utilisé — pensez à corriger cet achat une fois en ligne")),
      );
    }
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
                  setState(() {
                    selectedProduitId = newproduit;
                    // Le prix vient du produit et n'est jamais saisi à la main ici.
                    final produit = produits.firstWhere(
                      (p) => p['IdProduit'] == newproduit,
                      orElse: () => {},
                    );
                    _prixUnitaireController.text = (produit['Prix'] ?? '').toString();
                  });
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
                  readOnly: true, // Prix fixé par le produit ; modifiable uniquement dans l'écran Produits.
                  decoration: InputDecoration(
                    labelText: "Prix Unitaire (FC)",
                    labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                    hintText: "Déterminé par le produit sélectionné",
                    prefixIcon: Icon(Icons.price_change),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Sélectionnez d'abord un produit";
                    }
                    return null;
                  },
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

                if (lots.isNotEmpty)
                Padding(padding: EdgeInsets.all(10),
                  child:
                    DropdownButtonFormField<int>(
                  value: selectedLotId,
                  items: lots.map((item){
                    return DropdownMenuItem<int>(
                      value: item['id_lot'],
                      child: Text(item['code_lot']),
                    );
                  }).toList(),
                 onChanged: (newlot) {
                    setState(() { selectedLotId = newlot; });
                 },
                 decoration: InputDecoration(
                    labelText: "Lot (facultatif)",
                    labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                    hintText: "Rattacher à un lot",
                    border: OutlineInputBorder(),
                  ),
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