import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class Agriculteurs extends StatefulWidget {
  const Agriculteurs({super.key});

  @override
  State<Agriculteurs> createState() => _AgriculteursState();
}

class _AgriculteursState extends State<Agriculteurs> {
  final _agriculteurFormKey = GlobalKey<FormState>();
  final _nomAgriculteurController = TextEditingController();
  final _codeplanteurController= TextEditingController();
  final _adresseAgriculteurController = TextEditingController();
  final _contactAgriculteurController = TextEditingController();
  final _nombreChampsAgriculteurController = TextEditingController();

  Future<void> addAgriculteur(
    String nom,
    String codeplanteur,
    String adresse,
    String contact,
    String nbreDeChamps,
  ) async {
   try{

       var url = Uri.parse(
      "${AppConfig.apiBaseUrl}/registerAgriculteur.php",
    );
    var response = await http
        .post(
          url,
          headers: await Session.authHeaders(),
          body: json.encode({
            'nameAgricultor': nom,
            'codeplanteur': codeplanteur,
            'adressAgricultor': adresse,
            'contactAgricultor': contact,
            'nmberOfifeldsAgricultor': nbreDeChamps,
          }),
        )
        .timeout(Duration(seconds: 10));

    if (!mounted) return;
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['error'] == null) {
    // ✅ Appelle le dialogue dans un délai pour éviter les conflits
    Future.delayed(Duration.zero, () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text('Planteur ajouté avec succès'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
      ).showSnackBar(SnackBar(content: Text("Erreur de connexion")));
    }
  }

// reset fields
  void resetFields() {
    _nomAgriculteurController.clear();
    _codeplanteurController.clear();
    _adresseAgriculteurController.clear();
    _contactAgriculteurController.clear();
    _nombreChampsAgriculteurController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 63, 129, 86),
        title: Text("Planteurs", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _agriculteurFormKey,
            child: 
            Card(
              
              color: Color.fromARGB(230, 248, 236, 236),
              elevation: 30,
              child: Column(
                children: [
                    
                  Text(
                  "Nouveau Planteur",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(height: 20,),

                Padding(padding: EdgeInsets.all(10),
                  child: 
                    TextFormField(
                  controller: _nomAgriculteurController,
                  decoration: InputDecoration(
                    labelText: "Nom",
                    hintText: "Sair nom agriculteur",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
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
                      return "Put the name please!";
                    }
                    return null;
                  },
                ),
                ),
                
        
                Padding(padding: EdgeInsets.all(10),
                  child: 
                    TextFormField(
                  controller: _codeplanteurController,
                  decoration: InputDecoration(
                    labelText: "Code planteur",
                    hintText: "Sair le code du planteur",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.code),
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 63, 129, 86),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 63, 129, 86),
                      ),
                    ),
                  ),
                  
                ),
                ),
        
                
                Padding(padding: EdgeInsets.all(10),
                  child: 
                      TextFormField(
                  controller: _adresseAgriculteurController,
                  decoration: InputDecoration(
                    labelText: "Addresse",
                    hintText: "Saisir Addresse agriculteur",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
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
                      return "Put the adress please!";
                    }
                    return null;
                  },
                ),
                ),
                
                Padding(padding: EdgeInsets.all(10),
                  child: 
                    TextFormField(
                  controller: _contactAgriculteurController,
                  decoration: InputDecoration(
                    labelText: "Contact",
                    hintText: "Sair numero de conact",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
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
                      return "Put the name please!";
                    }
                    return null;
                  },
                ),
                ),
                
                Padding(padding: EdgeInsets.all(10),
                  child: 
                    TextFormField(
                  controller: _nombreChampsAgriculteurController,
                  decoration: InputDecoration(
                    labelText: "Champs",
                    hintText: "Nombre de champs",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 63, 129, 86),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 63, 129, 86),
                      ),
                    ),
                  ),
                ),
                ),
                

                Padding(padding: EdgeInsets.all(10),
                  child: 
                    ElevatedButton(
                  onPressed: () {
                    addAgriculteur(
                      _nomAgriculteurController.text,
                      _codeplanteurController.text,
                     _adresseAgriculteurController.text,
                     _contactAgriculteurController.text,
                     _nombreChampsAgriculteurController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 63, 129, 86),
                    padding: EdgeInsets.symmetric(horizontal: 130, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Ajouter",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                ),
                
               
                ],
              ),

            )
          ),
        ),
      ),
    );
  }
}
