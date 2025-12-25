//import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Produits extends StatefulWidget {
  const Produits({super.key});

  @override
  State<Produits> createState() => _ProduitsState();
}

class _ProduitsState extends State<Produits> {

  final _produitFormKey = GlobalKey<FormState>();
  final _nomProduitController = TextEditingController();
  final _descriptionProduitController = TextEditingController();

Future<void> addProduit(
    String nomProduit,
    String descriptionProduit,
    double Quantite,
  ) async {
        // Implémentez la logique pour ajouter un produit ici
        var url = Uri.parse('https://riphin-salemanager.com/Sale_manager_API/registerProducts.php');
        var response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'nameproduct': nomProduit,
            'descriptionproduct': descriptionProduit,
            'availablequantity': Quantite,
          }),
        ).timeout(Duration(seconds: 10));
        if (!mounted) return;
        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);

          if (jsonResponse['error'] == null) {
            // Pas d'erreur = succès
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Produit ajouté avec succès")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Échec: ${jsonResponse['error']}")),
            );
            resetFields(); // Réinitialise les champs après l'échec
          }
  }
  }

// reinitialiser les chmaps
  void resetFields() {
    _nomProduitController.clear();
    _descriptionProduitController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 63, 129, 86),
        title: Text("Produits",style: TextStyle(color: Colors.white),),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _produitFormKey,
            child: Center(
              child: Column(
                children: [
                  Card(
                    elevation: 90,
                    color: Color.fromARGB(230, 248, 236, 236),
                    child: Column(
                        children: [
                            
                            
                              Text(
                    "Ajouter un Produit",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 20),
                    Padding(padding: EdgeInsets.all(10),
                    child: 
                  TextFormField(
                    controller: _nomProduitController,
                    decoration: InputDecoration(
                      labelText: "Nom Produit",
                      hintText: "Sair le nom produit",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                      labelStyle: TextStyle(
                        color: Color.fromARGB(255, 63, 129, 86),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 63, 129, 86),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "saisit le nom du produit svp!";
                      }
                      return null;
                    },
                  ),
                            ),
                            
                    Padding(padding: EdgeInsets.all(10),
                      child: 
                        TextFormField(
                    controller: _descriptionProduitController,
                    decoration: InputDecoration(
                      labelText: "Description Produit",
                      hintText: "Saisir la description produit",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      labelStyle: TextStyle(
                        color: Color.fromARGB(255, 63, 129, 86),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 63, 129, 86),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "saisit la description du produit svp!";
                      }
                      return null;
                    },
                  ),
                    ),
                  
                    Padding(padding: EdgeInsets.all(10),
                      child: 
                        ElevatedButton(
                      onPressed: () {
                        if (_produitFormKey.currentState!.validate()) {
                          // Soumettre le formulaire
                          addProduit(
                            _nomProduitController.text,
                            _descriptionProduitController.text,
                            0.0,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Color.fromARGB(255, 63, 129, 86),
                    padding: EdgeInsets.symmetric(horizontal: 130, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                      child: 
                        
                      FittedBox(
                        fit: BoxFit.scaleDown,  // Ajuste le texte si nécessaire
                        child: Text("Enregistrer",style: TextStyle(color: Colors.white),)),
                    ),
                    ),
                  
                    
                  // Ajoutez ici le reste de votre interface utilisateur pour les produits
                        ],
                      ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}