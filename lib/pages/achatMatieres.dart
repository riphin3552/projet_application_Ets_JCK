import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Achatmatieres extends StatefulWidget {
  const Achatmatieres({super.key});

  @override
  State<Achatmatieres> createState() => _AchatmatieresState();
}

class _AchatmatieresState extends State<Achatmatieres> {
  int? selectedAgriculteurId;
  List<Map<String,dynamic>> agricuculteurs=[];  //1. initialisation de la liste

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

//3. appel du chargement dans initState
@override
void initState(){
  super.initState();
  fetchAgriculteurs();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Achat Matières premières"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text("Enregistrer les achats Ici!", style: TextStyle(fontWeight: FontWeight.bold),),
            SizedBox(height: 20,),
            Form(child: 
              DropdownButtonFormField<int>(
                initialValue: selectedAgriculteurId,
                items: agricuculteurs.map((item){
                  return DropdownMenuItem<int>(
                    value: item['idAgriculteur'],
                    child: Text(item['nomAgriculteur']),
                  );
                } ).toList(),
              onChanged: (newvalue){
                selectedAgriculteurId=newvalue;
              },
              decoration: InputDecoration(
                labelText: "selectionne une option...",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if(value == null){
                    return "Veuillez selectionnez un agriculteurs";
                }
                return null;
              },
              ),
            )
          ],
        ),
      ),
    );
  }
}