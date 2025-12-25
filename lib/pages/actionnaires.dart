import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Actionnaires extends StatefulWidget {
  const Actionnaires({super.key});

  @override
  State<Actionnaires> createState() => _ActionnairesState();
}

class _ActionnairesState extends State<Actionnaires> {
  final _nomActionnaireController = TextEditingController();
  final _descriptionActionnaireController = TextEditingController();
  final _actionnaireformKey = GlobalKey<FormState>();

  Future<void> ajouterActionnaire(
    String nomActionnaire,
    String descriptionActionnaire,
  ) async {
    try {
      var url = Uri.parse(
        'https://riphin-salemanager.com/Sale_manager_API/registerActionnaire.php',
      );

      var response = await http
          .post(
            // ✅ POST method
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              // ✅ Données dans le body
              'nameActionnaire': nomActionnaire,
              'descriptionActionnaire': descriptionActionnaire,
            }),
          )
          .timeout(Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['error'] == null) {
          // Pas d'erreur = succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Actionnaire ajouté avec succès")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Échec: ${jsonResponse['error']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Échec de la requête: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur de connexion: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 63, 129, 86),
        title: const Text(
          'Actionnaires',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _actionnaireformKey,
          child: Column(
            children: [
              SizedBox(height: 20),
              Text(
                "Nouvel actionnaire",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              TextFormField(
                controller: _nomActionnaireController,
                decoration: InputDecoration(
                  labelText: "Nom actionnaire",
                  hintText: "enter the name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name'; // validation message
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionActionnaireController,
                decoration: InputDecoration(
                  labelText: "Description",
                  hintText: "other details",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please give a description';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_actionnaireformKey.currentState!.validate()) {
                    ajouterActionnaire(
                      _nomActionnaireController.text,
                      _descriptionActionnaireController.text,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 63, 129, 86),
                  padding: EdgeInsets.symmetric(horizontal: 152, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text("Ajouter", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
