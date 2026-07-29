import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class Utilisateurs extends StatefulWidget {
  const Utilisateurs({super.key});

  @override
  State<Utilisateurs> createState() => _UtilisateursState();
}

class _UtilisateursState extends State<Utilisateurs> {
  final _formKey = GlobalKey<FormState>(); // cle du formulaire
  final _nomutilisateurController =
      TextEditingController(); // controlleur du champ nom
  final _emailutilisateurController =
      TextEditingController(); // controlleur du champ email
  final _descriptionController =
      TextEditingController(); // controlleur du champ password
  final _passwordController =
      TextEditingController(); // controlleur du champ confirm password
  final _telephoneUtilisateur =
      TextEditingController(); // controlleur du champ confirm password

    final  FocusNode _myFocusNodeNomutilisateur = FocusNode();
    List<Map<String,dynamic>> depots=[];
    List<Map<String,dynamic>> roles=[];
    int ? selectedDepotId;
    int ? selectedRoleId;


    @override
  void initState() {
    super.initState();
    fetchDepots(); // Charger les données au démarrage
    fetchRoles();
  }

    //2. chargement des donnees dans le dropdowntextformfield
Future<void> fetchDepots() async {
  final response = await http.get(
    Uri.parse('${AppConfig.apiBaseUrl}/get_depots.php'),
    headers: await Session.authHeaders(),
  );
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    setState(() {
      depots=List<Map<String,dynamic>>.from(data);
    });
  }
}

// chargement des rôles disponibles pour l'entreprise
Future<void> fetchRoles() async {
  final response = await http.get(
    Uri.parse('${AppConfig.apiBaseUrl}/get_roles.php'),
    headers: await Session.authHeaders(),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      setState(() {
        roles = List<Map<String, dynamic>>.from(data['data']);
      });
    }
  }
}

     //ramener le focus sur un champ après une action
  Future<void> addUser(
    String nom,
    String email,
    String password,
    String telephone,
    String descriptionUtilisateur,
    SelectedDepotId,
    SelectedRoleId,
  ) async {
    try {
      var url = Uri.parse(
        '${AppConfig.apiBaseUrl}/registerUser.php',
      );

      var response = await http
          .post(
            // ✅ POST method
            url,
            headers: await Session.authHeaders(),
            body: json.encode({
              // ✅ Données dans le body
              'nameUser': nom,
              'emailUser': email,
              'pwdUser': password,
              'phoneUser': telephone,
              'descriptionUser': descriptionUtilisateur,
              'DepotId': SelectedDepotId,
              'idRole': SelectedRoleId,
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
            content: Text('Utilisateur ajouté avec succès'),
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
    _nomutilisateurController.clear();
    _emailutilisateurController.clear();
    _descriptionController.clear();
    _passwordController.clear();
    _telephoneUtilisateur.clear();
    setState(() {
      selectedDepotId = null;
      selectedRoleId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 63, 129, 86),
        title: Text("Utilisateurs", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
        
          child: Form(
            key: _formKey, // assigner la cle au formulaire
            child: Column(
              children: [
                SizedBox(height: 20),
                
                Card(
                  color: Color.fromARGB(230, 248, 236, 236),
                  elevation: 90,
                  child: 
                  Column(
                    children: [
                        Text(
                      "Nouvel utilisateur",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                      ),
                      SizedBox(height: 10,),

                      Padding(padding: EdgeInsets.all(16),
                        child:
                          TextFormField(
                  controller: _nomutilisateurController, // controlleur du champ nom
                  focusNode: _myFocusNodeNomutilisateur,
                  decoration: InputDecoration(
                    labelText: "Nom",
                    hintText: "Enter your name",
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
                      return "Name must not be empty";
                    }
                    return null;
                  },
                ),
                      ),
                      
                     Padding(padding: EdgeInsets.all(10),

                      child: 
                        TextFormField(
                  controller:
                      _emailutilisateurController, // controlleur du champ email
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "enter your mail",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.mail),
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 63, 129, 86),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 63, 129, 86),
                      ),
                    ),
                  ),
                  //const string = ".";
                  validator: (value) {
                    if (value == null ||
                        !value.contains('@') ||
                        !value.contains('.')) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                     ),
                
                
                Padding(padding: EdgeInsets.all(10),
                    child: TextFormField(
                  controller:
                      _passwordController, // controlleur du champ confirm password
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Enter your password, at least 6 characters",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 63, 129, 86),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 63, 129, 86),
                      ),
                    ),
                  ),
        
                  validator: (value) => value != null && value.length < 6
                      ? "the password must be at least 6 characters"
                      : null,
                ),
                ),
        
                Padding(padding: EdgeInsets.all(10),
                  child: 
                    TextFormField(
                  controller: _telephoneUtilisateur, // controlleur du champ email
                  decoration: InputDecoration(
                    labelText: "Telephone",
                    hintText: "enter your telephone",
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
                      return "Telephone must not be empty";
                    }
                    return null;
                  },
                ),
                ),
        
                Padding(padding: EdgeInsets.all(10),
                  child: 
                    TextFormField(
                  controller:
                      _descriptionController, // controlleur du champ description
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Description",
                    hintText: "Describe a bit about yourself",
                    border: OutlineInputBorder(),
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
                    DropdownButtonFormField<int>(
                // ignore: deprecated_member_use
                value: selectedRoleId,
                items: roles.map((item){
                  return DropdownMenuItem<int>(
                    value: item['id_role'],
                    child: Text(item['nom_role']),
                  );
                }).toList(),
               onChanged: (newRole) {
                  setState(() { selectedRoleId = newRole; });
               },
               decoration: InputDecoration(
                  labelText: "Rôle",
                  labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                  hintText: "Rôle de l'utilisateur",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                ),
                validator: (value) {
                  if(value == null){
                      return "Veuillez sélectionner un rôle";
                  }
                  return null;
                },
                ),
                ),

                Padding(padding: EdgeInsets.all(10),
                  child:
                    DropdownButtonFormField<int>(
                // ignore: deprecated_member_use
                value: selectedDepotId,
                items: depots.map((item){
                  return DropdownMenuItem<int>(
                    value: item['IdStockage'],
                    child: Text(item['CodeDepot']),
                  );
                }).toList(),
               onChanged: (newdepot) {
                  setState(() { selectedDepotId = newdepot; });
               },

               decoration: InputDecoration(
                  labelText: "Affectation au dépôt (optionnel pour DG/Caissier/Comptable)",
                  labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
                  hintText: "Depots",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 63, 129, 86)))
                ),
                ),
                ),

                Padding(padding: EdgeInsets.all(10),
                  child:
                    ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                        addUser(
                        _nomutilisateurController.text,
                        _emailutilisateurController.text,
                        _passwordController.text,
                        _telephoneUtilisateur.text,
                        _descriptionController.text,
                        selectedDepotId,
                        selectedRoleId,);
                      }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 63, 129, 86),
                    minimumSize: Size(double.infinity, 50),
                    padding: EdgeInsets.symmetric(horizontal: 130, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Ajouter",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                ),
                
                
                            
                
                    ],
                     
                    ),
                  ),
                
                          
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  
}
