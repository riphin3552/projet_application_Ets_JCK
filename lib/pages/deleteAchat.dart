import 'dart:convert';

import'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


class DeleteAchat extends StatefulWidget {
   DeleteAchat({required this.achatData});
  final Map<String,dynamic>achatData;

  
 





  @override
  State<DeleteAchat> createState() => _DeleteAchatState();
}

class _DeleteAchatState extends State<DeleteAchat> {

  DateTime? DateAchat;
  final _formDeleteAchatKey=GlobalKey<FormState>();

 TextEditingController _idAchatController= TextEditingController();
 TextEditingController _ancienIdProduit=TextEditingController();
 TextEditingController _planteur=TextEditingController();
 TextEditingController _Depot=TextEditingController();
 TextEditingController _quantiteController=TextEditingController();
 TextEditingController _prixUnitaireController=TextEditingController();
 TextEditingController _prixtotalController= TextEditingController();
 TextEditingController _dateController=TextEditingController();

@override
void initState(){
  super.initState();
  _idAchatController.text=widget.achatData['Idachat'].toString();
  _ancienIdProduit.text=widget.achatData['IdProduit'].toString();
  _planteur.text=widget.achatData['nomAgriculteur'].toString();
  _Depot.text=widget.achatData['CodeDepot'].toString();
  _quantiteController.text=widget.achatData['Quantite_KG'].toString();
  _prixUnitaireController.text=widget.achatData['prixUnitaire'].toString();
  _dateController.text=widget.achatData['dateAchat'].toString();
  _prixtotalController.text=widget.achatData['totalPayer'].toString();
}

Future<void> DeleteAchat(
  BuildContext, //pour le showdialogue lors que les composants sont dans un card()
  int Idachat,
  int ancienIdProduit,
  

) async{
  try{
    var url= Uri.parse("https://riphin-salemanager.com/Sale_manager_API/deleteAchat.php");
    var response=await http.post(
      
      url,
      headers: {'Content-Type':'application/json'},
      body: json.encode({
        'idAchat': Idachat,
        'ancienIdproduit': ancienIdProduit,
    
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
            content: Text('Suppression reussi avec succès'),
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
        SnackBar(content: Text("Échec de suppression: ${jsonResponse['error']}", textAlign: TextAlign.center)),
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
    ).showSnackBar(SnackBar(content: Text("Erreur de connexion: $e")));
  }

}


  // code de verification avant suppression
void CodeSuppression(BuildContext context) {
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
              Text('Code de suppression'),
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
                
                // Appel de la fonction de suppression  
                DeleteAchat(
                            context,
                            int.parse(_idAchatController.text),
                            int.parse(_ancienIdProduit.text)
                            

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
    return  Scaffold(
       appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 63, 129, 86),
        title: Text("Suprimer l'achat",style: TextStyle(color: Colors.white),),
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(padding: EdgeInsets.all(16),
              
              child: Form(
                key: _formDeleteAchatKey,
                
                child: 
                        
                Card(
                  elevation: 20,
                  child: Column(
                    children: [
                      Text("Supprimer l'achat", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                      SizedBox(height: 10,),

                    
                   

                  Padding(padding: EdgeInsets.all(10),
                    child: 
                       TextFormField(
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
                       TextFormField(
                        readOnly: true,
                        
                        controller: _planteur,
                        decoration: InputDecoration(
                          labelText: "Planteur",
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
                        
                        controller: _Depot,
                        decoration: InputDecoration(
                          labelText: "Depot",
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
                      if(_formDeleteAchatKey.currentState!.validate()){
                          
                              CodeSuppression(context);
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
    ),

    );
  }
}