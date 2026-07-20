
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
import 'package:sale_manager/pages/lots.dart';
import 'package:sale_manager/pages/inventaire.dart';
import 'package:sale_manager/pages/notifications.dart';
import 'package:sale_manager/pages/dashboard.dart';
import 'package:sale_manager/pages/export_csv.dart';
import 'package:sale_manager/pages/securite_2fa.dart';
import 'package:sale_manager/pages/changer_mot_de_passe.dart';
import 'package:sale_manager/pages/synchronisation.dart';
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';
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
  List<String> _permissions = [];
  bool get isConnected=>nomUtilisateur.trim().isNotEmpty;
  bool _can(String permission) => _permissions.contains(permission);

  @override
  void initState(){
    super.initState();
     loadUserName();
     loadPermissions();
  }

  // L'utilisateur connecté est déjà connu depuis la connexion, inutile de
  // rappeler validateToken.php.
  void loadUserName() async {
    final nom = await Session.getNomUtilisateur();
    setState(() {
      nomUtilisateur = nom;
    });
  }

  void loadPermissions() async {
    final perms = await Session.getPermissions();
    setState(() {
      _permissions = perms;
    });
  }

  Future<void> logout() async {
    final headers = await Session.authHeaders();
    try {
      await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/deconnexion.php'),
        headers: headers,
      );
    } catch (_) {
      // La déconnexion locale doit réussir même si l'appel réseau échoue
    }
    await Session.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login()),
      (route) => false,
    );
  }

  Widget _tile(IconData icon, String label, Widget Function() pageBuilder) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => pageBuilder()));
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
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
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
    onSelected: (value) {
      // L'accès est déjà garanti par le filtrage des options ci-dessous
      // (chaque entrée n'apparaît que si l'utilisateur a le privilège requis).
      if (value == 'Operations') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => GetAll_Achats()));
      } else if (value == 'Tous les Stocks') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => StockProduits()));
      } else if (value == 'Utilisateurs') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Afficher_Utilisateurs()));
      }
    },
    itemBuilder: (BuildContext context) {
      final options = <String>[
        if (_can('achats.voir')) 'Operations',
        if (_can('depots.voir')) 'Tous les Stocks',
        if (_can('utilisateurs.voir')) 'Utilisateurs',
      ];
      return options.map((String choice) {
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
            
            ListTile(title: Text("Parametres"), leading: Icon(Icons.settings)),
            ListTile(title: Text("Contact"), leading: Icon(Icons.contact_mail),
              onTap: sendEmailMultiplatform,
            ),
            ListTile(title: Text("Deconnexion"), leading: Icon(Icons.logout),
              onTap: () {
                Navigator.pop(context);
                logout();
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
          if (_can('utilisateurs.gerer'))
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Utilisateurs()));
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
        
        
          if (_can('agriculteurs.gerer'))
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
        
            if (_can('depots.gerer'))
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
        
          if (_can('produits.gerer'))
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
        
          if (_can('achats.creer'))
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
        
          if (_can('achats.voir'))
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
          
          if (_can('depots.voir'))
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => StockProduits()));
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
        
          if (_can('expeditions.gerer'))
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
          if (_can('lots.voir')) _tile(Icons.category, "Lots", () => const LotsPage()),
          if (_can('inventaires.voir')) _tile(Icons.fact_check, "Inventaire", () => const InventairePage()),
          if (_can('notifications.voir')) _tile(Icons.notifications, "Notifications", () => const NotificationsPage()),
          if (_can('rapports.voir')) _tile(Icons.dashboard, "Tableau de bord", () => const DashboardPage()),
          if (_can('export.voir')) _tile(Icons.file_download, "Export CSV", () => const ExportCsvPage()),
          _tile(Icons.security, "Sécurité (2FA)", () => const Securite2FAPage()),
          _tile(Icons.password, "Mot de passe", () => const ChangerMotDePassePage()),
          _tile(Icons.sync, "Synchronisation", () => const SynchronisationPage()),
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

