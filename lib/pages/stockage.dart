import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';


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
  // final _QuantityDisponibleController=TextEditingController();
  
  // quantityDisponible(){
  //   _QuantityDisponibleController.text="0";
  //   int quantiteInitial=int.parse(_QuantityDisponibleController.text);
  // }
  final FocusNode _focusNodeStockage=FocusNode();

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

    var url=Uri.parse('https://riphin-salemanager.com/Sale_manager_API/stockage.php');

  var response= await http.post(
    url,
    headers: {'Content-Type':'application/json'},
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
      ).showSnackBar(SnackBar(content: Text("Erreur de connexion: $e")));
      
  }
  
}

//reinitialiser les chmaps
void resetFieldsStorage(){
    _codeStockageController.clear();
    _capacityStockageController.clear();
    _stockageDescriptionCOntroller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 63, 129, 86),
        title: Text("Stockage",style: TextStyle(color: Colors.white),),
      ),
      
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Center(
             child: Form(
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
                  )
            ],)),
          )
        ),
      ),
    );
  }
}