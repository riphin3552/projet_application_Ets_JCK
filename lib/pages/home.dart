
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
import 'package:sale_manager/pages/entreprise_info.dart';
import 'package:sale_manager/pages/wallet.dart';
import 'package:sale_manager/pages/gestion_wallets.dart';
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
  String roleUtilisateur='';
  List<String> _permissions = [];
  bool _can(String permission) => _permissions.contains(permission);
  bool get _aUnWallet => roleUtilisateur == 'Acheteur' || roleUtilisateur == 'Chef de dépôt' || roleUtilisateur == 'Directeur Général';

  @override
  void initState(){
    super.initState();
     loadUserName();
     loadPermissions();
     loadRole();
  }

  void loadRole() async {
    final role = await Session.getRole();
    setState(() {
      roleUtilisateur = role;
    });
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
            Icon(icon, color: const Color.fromARGB(255, 63, 129, 86)),
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
          'Accueil',
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
      if (value == 'Toutes les opérations') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => GetAll_Achats()));
      } else if (value == 'Tous les Stocks') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => StockProduits()));
      } else if (value == 'Utilisateurs') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Afficher_Utilisateurs()));
      }
    },
    itemBuilder: (BuildContext context) {
      final options = <String>[
        if (_can('achats.voir')) 'Toutes les opérations',
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
              accountEmail: null,
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
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            //color: const Color.fromARGB(255, 250, 212, 212),
            decoration: BoxDecoration(
        color: const Color.fromARGB(255, 250, 212, 212),
        border: Border.all(color: const Color.fromARGB(255, 249, 250, 250)),
        borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
             
            child: Wrap(
        spacing: 12, // espace horizontal entre les containers
        runSpacing: 14, // espace vertical entre les lignes (réduit pour que plus de tuiles tiennent par écran)
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
              Icon(Icons.person_add, color: Color.fromARGB(255, 63, 129, 86)),
              SizedBox(height: 8),
              Text("Ajouter utilisateur", textAlign: TextAlign.center),
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
                  Icon(Icons.agriculture, color: Color.fromARGB(255, 63, 129, 86)),
                  SizedBox(height: 8),
                  Text("Ajouter planteur", textAlign: TextAlign.center),
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
                  Icon(Icons.store_mall_directory, color: Color.fromARGB(255, 63, 129, 86)),
                  SizedBox(height: 8),
                  Text("Ajouter dépôt", textAlign: TextAlign.center),
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
                    Icon(Icons.add_box, color: Color.fromARGB(255, 63, 129, 86)),
                    SizedBox(height: 8),
                    Text("Ajouter produit", textAlign: TextAlign.center),
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
                  Icon(Icons.shopping_cart, color: Color.fromARGB(255, 63, 129, 86)),
                  SizedBox(height: 8),
                  Text("Nouvel\n achat", textAlign: TextAlign.center),
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
                    Icon(Icons.shopping_bag, color: Color.fromARGB(255, 63, 129, 86)),
                    SizedBox(height: 8),
                    Text("Achats", textAlign: TextAlign.center),
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
                  Icon(Icons.storage, color: Color.fromARGB(255, 63, 129, 86)),
                  SizedBox(height: 8),
                  Text("Stock produits", textAlign: TextAlign.center),
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
                    Icon(Icons.local_shipping, color: Color.fromARGB(255, 63, 129, 86)),
                    SizedBox(height: 8),
                    Text("Expedier", textAlign: TextAlign.center),
                  ],)
            ),
          ),
          if (_can('lots.voir')) _tile(Icons.category, "Lots", () => const LotsPage()),
          if (_can('inventaires.voir')) _tile(Icons.fact_check, "Inventaire", () => const InventairePage()),
          if (_can('notifications.voir')) _tile(Icons.notifications, "Notifications", () => const NotificationsPage()),
          if (_can('rapports.voir')) _tile(Icons.dashboard, "Tableau de bord", () => const DashboardPage()),
          if (_can('entreprises.gerer')) _tile(Icons.business, "Entreprise", () => const EntrepriseInfoPage()),
          if (_aUnWallet) _tile(Icons.account_balance_wallet, "Mon Wallet", () => const WalletPage()),
          if (_can('wallets.gerer')) _tile(Icons.account_balance, "Gestion Wallets", () => const GestionWalletsPage()),
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

