
import 'dart:convert';

import 'package:sale_manager/pages/Dilplay_utilisateurs.dart';
import 'package:sale_manager/pages/Epedition.dart';
import 'package:sale_manager/pages/GetAll_Achats.dart';
import 'package:sale_manager/pages/login.dart';

import 'package:android_intent_plus/android_intent.dart' show AndroidIntent;
import 'package:android_intent_plus/flag.dart' show Flag;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/pages/Get_achats.dart';
import 'package:sale_manager/pages/afficheStock.dart';
import 'package:sale_manager/pages/agriculteurs.dart';
import 'package:sale_manager/pages/registerProducts.dart';
import 'package:sale_manager/pages/stockage.dart';
import 'package:sale_manager/pages/utilisateurs.dart';
import 'package:sale_manager/pages/operations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String nomUtilisateur='';
  String statusUser="";
  bool get isConnected=>nomUtilisateur.trim().isNotEmpty;

  @override
  void initState(){
    super.initState();
     loadUserName();
     
  }

//charger le nom de l'utilisateur depuis les shared preferences
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

//Pour android seulement
void openGmailDirect() {
  if (Platform.isAndroid) {
    final intent = AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: Uri.encodeFull('mailto:heririphin@gmail.com?subject=Assistance technique&body=Contenu du message ici'),
      package: 'com.google.android.gm',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
  } else {
    print('Cette méthode ne fonctionne que sur Android');
  }
}


//pour android et iOS
void sendEmailMultiplatform() async {
  final String to = 'heririphin@gmail.com';
  final String subject = 'Assistance technique';
  final String body = 'Contenu du message';

  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: to,
    query: Uri.encodeFull('subject=$subject&body=$body'),
  );

  if (Platform.isAndroid) {
    // Tentative d'ouverture directe de Gmail
    final intent = AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: Uri.encodeFull('mailto:$to?subject=$subject&body=$body'),
      package: 'com.google.android.gm',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    try {
      await intent.launch();
    } catch (e) {
      // Si Gmail n'est pas disponible, fallback vers mailto
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        print('Aucune application de messagerie disponible');
      }
    }
  } else if (Platform.isIOS) {
    // iOS utilise mailto
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text('Impossible d’ouvrir l’application mail sur iOS'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      //print('Impossible d’ouvrir l’application mail sur iOS');
    }
  } else {
    //print('Plateforme non supportée');
    showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text('Plateforme non supportée'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
  }
}


// code de verification de creation nouvel utilisateur
void showSaisiePopup(BuildContext context) {
  TextEditingController _inputController = TextEditingController();
  const String correctCode = '@2025@'; // Le code correct prédéfini

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Saisir le code d'accès"),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Utilisateurs()),
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


//popup de saisie du code d'accès
void showSaisiePopup_StockProduits(BuildContext context) {
  TextEditingController _inputController = TextEditingController();
  const String correctCode = '@2025@'; // Le code correct prédéfini

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Saisir le code d'accès"),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StockProduits()),
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
        
        title: const Text(
          'Home Page',
          style: TextStyle(
            color: Color.fromARGB(255, 248, 249, 249),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        centerTitle: true,

        actions: [
  PopupMenuButton<String>(
    onSelected: (value) async {
      // 🔹 Affiche un popup pour entrer le mot de passe
      final accessGranted = await showDialog<bool>(
        context: context,
        builder: (context) {
          final TextEditingController passwordController = TextEditingController();
          return AlertDialog(
            title: const Text("Accès sécurisé"),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mot de passe",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () {
                  // 🔹 Vérifie le mot de passe (ici exemple simple)
                  if (passwordController.text == "@2025@") {
                    Navigator.pop(context, true); // accès accordé
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mot de passe incorrect")),
                    );
                  }
                },
                child: const Text("Valider"),
              ),
            ],
          );
        },
      );

      // 🔹 Si mot de passe correct → navigation
      if (accessGranted == true) {
        if (value == 'Operations') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => GetAll_Achats()));
        } else if (value == 'Tous les Stocks') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => StockProduits()));
        } else if (value == 'Utilisateurs') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => Afficher_Utilisateurs()));
        }
      }
    },
    itemBuilder: (BuildContext context) {
      return {'Operations', 'Tous les Stocks', 'Utilisateurs'}.map((String choice) {
        return PopupMenuItem<String>(
          value: choice,
          child: Text(choice),
        );
      }).toList();
    },
  )
],
      ),
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 200, 216, 229),
        child: ListView(
          children: [
            
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage("images/etsJCK.jpg"),
              ),
              
              accountName: Text("$nomUtilisateur"), 
              accountEmail: Text(""),
              otherAccountsPictures: [
                
                SizedBox(
                  height: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      Transform.scale(
                        scale: 0.8,
                        child: Switch( value: isConnected, 
                        
                        activeThumbColor: Colors.green,
                        inactiveThumbColor: Colors.grey,
                        onChanged: (value){
                            setState(() {
                              nomUtilisateur=value? "$nomUtilisateur":"Deconnecté"; 
                              
                            });
                        }),
                      )
                    ],
                  ),
                )
              ],
            ),
            
            // ListTile(
            //   title: Text("Ajouter Utilisateur"),
            //   leading: Icon(Icons.person_add),
            //   onTap: () {
            //     Navigator.push(context, MaterialPageRoute(builder: (context) => Utilisateurs()));
            //   },
            // ),
            // ListTile(title: Text("Ajouter Planteur"),
            // leading: Icon(Icons.person_add),
            // onTap: () {
            //   Navigator.push(context, MaterialPageRoute(builder: (context)=>Agriculteurs()));
            // },),
            // ListTile(title: Text("Actionnaires"), leading: Icon(Icons.group),
            // onTap: () {
            //   Navigator.push(context, MaterialPageRoute(builder:  (context) => Actionnaires()));
            // },
            // ),
            // ListTile(
            //   title: Text("Stockage"),
            //   onTap: () {
            //     Navigator.push(context, MaterialPageRoute(builder: (context) => Stockage()));
            //   },
            // ),
            // ListTile(
            //   title: Text("Operations"),
            //   leading: Icon(Icons.add_business),
            //   onTap: () {
            //     Navigator.push(context, MaterialPageRoute(builder: (context) => Operations()));
            //   },
            // ),
            ListTile(title: Text("Parametres"), leading: Icon(Icons.settings)),
            ListTile(title: Text("Contact"), leading: Icon(Icons.contact_mail),
              onTap: sendEmailMultiplatform,
            ),
            ListTile(title: Text("Deconnexion"), leading: Icon(Icons.logout),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
              },
            ),

            Divider(),
            ListTile(title: Text("Aide"), leading: Icon(Icons.help)),
            ListTile(
              title: Text("F.A.Q"),
              leading: Icon(Icons.question_answer),
            ),
            Divider(),
            ListTile(title: Text("Version 1.0.0"), leading: Icon(Icons.info)),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            //color: const Color.fromARGB(255, 250, 212, 212),
            decoration: BoxDecoration(
        color: const Color.fromARGB(255, 250, 212, 212),
        border: Border.all(color: const Color.fromARGB(255, 249, 250, 250)),
        borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
             
            child: Wrap(
        spacing: 15, // espace horizontal entre les containers
        runSpacing: 30, // espace vertical entre les lignes
        alignment: WrapAlignment.center,
        
        children: [
          // Removed invalid BorderRadius.circular(4.0)
          GestureDetector(
            onTap: () {
              showSaisiePopup(context);
            }, 
            child: 
          Container(
            
            width: 120,
            height: 120,
            
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 245, 244),
              border: Border.all(color: const Color.fromARGB(255, 240, 245, 243)),
              borderRadius: BorderRadius.circular(10),
             boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
             ]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add),
              SizedBox(height: 8),
              Text("Add User", textAlign: TextAlign.center),
            ],
          ),
          ),
          ),
        
        
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Agriculteurs()));
            }, 
            child:
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 245, 244),
              border: Border.all(color: const Color.fromARGB(255, 240, 245, 243)),
              borderRadius: BorderRadius.circular(10),
             boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
             ]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture),
                  SizedBox(height: 8),
                  Text("Add Planteur", textAlign: TextAlign.center),
                ],
          ),
        ),
             ),
        
            GestureDetector(onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Stockage()));
            },
            
        child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 245, 244),
              border: Border.all(color: const Color.fromARGB(255, 240, 245, 243)),
              borderRadius: BorderRadius.circular(10),
             boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
             ]),
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_mall_directory),
                  SizedBox(height: 8),
                  Text("Add store", textAlign: TextAlign.center),
                ],
          ),
          ),
            ),
        
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Produits()));
            }, 
            child:
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 245, 244),
              border: Border.all(color: const Color.fromARGB(255, 240, 245, 243)),
              borderRadius: BorderRadius.circular(10),
             boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
             ]),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_box),
                    SizedBox(height: 8),
                    Text("Add Product", textAlign: TextAlign.center),
                  ],
          ),
          ),
          ),
        
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Operations()));
            }, 
            child:
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 245, 244),
              border: Border.all(color: const Color.fromARGB(255, 240, 245, 243)),
              borderRadius: BorderRadius.circular(10),
             boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
             ]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart),
                  SizedBox(height: 8),
                  Text("Add\n Purchase", textAlign: TextAlign.center),
                ],
                ),
          ),
          ),
        
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => GetAchats(nomUtilisateur: nomUtilisateur,)));
            }, 
            child:Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 245, 244),
              border: Border.all(color: const Color.fromARGB(255, 240, 245, 243)),
              borderRadius: BorderRadius.circular(10),
             boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
             ]),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag),
                    SizedBox(height: 8),
                    Text("Purchases", textAlign: TextAlign.center),
                  ],)
          ),
          ),
          
          GestureDetector(
            onTap: () {
              showSaisiePopup_StockProduits(context);
            },
            child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 245, 244),
              border: Border.all(color: const Color.fromARGB(255, 240, 245, 243)),
              borderRadius: BorderRadius.circular(10),
             boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
             ]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storage),
                  SizedBox(height: 8),
                  Text("Products stock", textAlign: TextAlign.center),
                ]
                ),
          ),
        
          ),
        
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => EXPEDICTION()));
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 243, 245, 244),
                border: Border.all(color: const Color.fromARGB(255, 240, 245, 243)),
                borderRadius: BorderRadius.circular(10),
               boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.grey.withOpacity(0.8),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // changes position of shadow
                ),
               ]),
               child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping),
                    SizedBox(height: 8),
                    Text("Expedier", textAlign: TextAlign.center),
                  ],)
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 245, 244),
              border: Border.all(color: const Color.fromARGB(255, 240, 245, 243)),
              borderRadius: BorderRadius.circular(10),
             boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
             ]),
             child: Text("Soon...", textAlign: TextAlign.center,style: TextStyle(color: Colors.red),),
          ),
          
        ],
            ),
            ),
            
          )
        
            ),
      ),
    bottomNavigationBar: NavigationBar(
      destinations: 
      const [
        NavigationDestination(icon: Icon(Icons.home), label: "Home"),
        NavigationDestination(icon: Icon(Icons.import_export), label: "Exportations"),
        NavigationDestination(icon: Icon(Icons.report), label: "Rapports"),
      ],
    )
    );
  }
}

