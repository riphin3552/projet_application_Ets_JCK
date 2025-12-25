import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sale_manager/pages/ModifierAchat.dart';
import 'package:sale_manager/pages/TicketAchat.dart';
import 'package:sale_manager/pages/deleteAchat.dart';




class GetAll_Achats extends StatefulWidget {
  const GetAll_Achats({super.key});
  

   
  @override
  State<GetAll_Achats> createState() {
    return _GetAll_AchatsState();
  }
}
class _GetAll_AchatsState extends State<GetAll_Achats> {

  DateTime? dateDebut;
  DateTime? dateFin;
  bool isLoading = false;
  String errorMessage = '';
  List<dynamic> achats = [];
  String nomUtilisateur='';
  int? selectedDepotId;
  List<Map<String,dynamic>> depots = [];

  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allAchats=[]; // Liste complète des achats
  List<Map<String, dynamic>> _filteredAchats = []; // Liste pour les achats filtrés

  @override
  void initState() {
    super.initState();
    loadAchats();
    fetchDepots();
    //fetchAchats();
    _searchController.addListener(() {
      
    });
  }




// Future<void> fetchAchats() async {
//     final url = Uri.parse('https://riphin-salemanager.com/Sale_manager_API/GetAchatBy_planteur.php');
//       setState(() {
//       isLoading = true;
//       });
//     try {
//       final response = await http.get(url);

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         if (data['success'] == true) {
//           setState(() {
//             achats = data['data'];

//             _allAchats = List<Map<String, dynamic>>.from(data['data']);
//             _filteredAchats = _allAchats; // Initialement, tous les achats sont
//             isLoading = false;
//           });
//         } else {
//           setState(() {
//             errorMessage = data['message'];
//             isLoading = false;
//           });
//         }
//       } else {
//         setState(() {
//           errorMessage = 'Erreur serveur: ${response.statusCode}';
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Erreur de connexion: $e';
//         isLoading = false;
//       });
//     }
//   }


//chargement des donnees dans le dropdowntextformfield
Future<void> fetchDepots() async {
  final response = await http.get(Uri.parse('https://riphin-salemanager.com/Sale_manager_API/get_depots.php'));
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    setState(() {
      depots=List<Map<String,dynamic>>.from(data);
    });
  }
}


Future<void> loadAchats() async {
  setState(() {
    isLoading = true; // 🔹 active le spinner
  });

  try {
    final response = await http.post(
      Uri.parse('https://riphin-salemanager.com/Sale_manager_API/GetAll_Achats.php'),
      headers: {'Content-Type': 'application/json'},
      
      
    ).timeout(const Duration(seconds: 3));

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      // 🔹 garde le spinner actif pendant 2 secondes avant d'afficher les données
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        achats = data['data'];
        _allAchats = List<Map<String, dynamic>>.from(data['data']);
        _filteredAchats = _allAchats;
        isLoading = false; // 🔹 désactive le spinner après le délai
        
      });
    } else {
      await Future.delayed(const Duration(seconds: 2));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${data['error']}")),
      );
      setState(() {
        isLoading = false;
      });
    }
  } catch (e) {
    await Future.delayed(const Duration(seconds: 2));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur de connexion: $e")),
    );
    setState(() {
      isLoading = false;
    });
  }
}




List<dynamic> achatsFiltres() {
  // 🔹 Commence avec tous les achats
  var result = achats;

  // 🔹 Filtre par dépôt si un dépôt est sélectionné
  if (selectedDepotId != null) {
    result = result.where((achat) {
      return achat['IdStockage'] == selectedDepotId;
    }).toList();
  }

  // 🔹 Filtre par date si une période est définie
  if (dateDebut != null && dateFin != null) {
    result = result.where((achat) {
      final date = DateTime.tryParse(achat['dateAchat']);
      return date != null &&
          date.isAfter(dateDebut!.subtract(const Duration(days: 1))) &&
          date.isBefore(dateFin!.add(const Duration(days: 1)));
    }).toList();
  }

  // 🔹 Retourne la liste filtrée
  return result;
}



@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Color.fromARGB(255, 63, 129, 86),
      title: Text("Achats", style: TextStyle(color: Colors.white)),
    ),

    body: Column(
      children: [

        // 🔶 ZONE DE FILTRAGE PAR DATE
        Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // 🔹 Bouton date début
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => dateDebut = picked);
                        }
                      },
                      child: Text(dateDebut == null
                          ? 'Choisir date début'
                          : 'Début: ${dateDebut!.toLocal().toString().split(' ')[0]}'),
                    ),
                  ),
                  SizedBox(width: 8),
                  // 🔹 Bouton date fin (filtre automatique)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => dateFin = picked); // 🔄 Filtrage immédiat
                        }
                      },
                      child: Text(dateFin == null
                          ? 'Choisir date fin'
                          : 'Fin: ${dateFin!.toLocal().toString().split(' ')[0]}'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              Row(
                
                children: [
                    Expanded(
  child: Padding(
    padding: const EdgeInsets.all(10),
    child: DropdownButtonFormField<int>(
      // ignore: deprecated_member_use
      value: depots.any((item) => item['IdStockage'] == selectedDepotId)
          ? selectedDepotId
          : null, // 🔹 évite RangeError si l'ID n'existe pas
      items: depots.map<DropdownMenuItem<int>>((item) {
        return DropdownMenuItem<int>(
          value: item['IdStockage'],
          child: Text(item['CodeDepot']),
        );
      }).toList(),
      onChanged: (newDepot) {
        setState(() {
          selectedDepotId = newDepot;
        });
      },
      decoration: const InputDecoration(
        labelText: "Sélectionne une option...",
        labelStyle: TextStyle(color: Color.fromARGB(255, 63, 129, 86)),
        hintText: "Depots",
        border: OutlineInputBorder(),
      ),
    ),
  ),
)
,

                    // 🔹 Bouton réinitialiser
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                onPressed: () {
                  setState(() {
                    dateDebut = null;
                    dateFin = null;
                  });
                },
                child: Text('Réinitialiser', style: TextStyle(color: Colors.black)),
              ),
                ],
              ),
              
            ],
          ),
        ),

        // 🔶 Résumé du nombre d’achats affichés
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
              'Nbre achats : ${achatsFiltres().length}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
                SizedBox(width: 20),
                // Calcul de la somme des quantités
                Builder(
                  builder: (context) {
                    double sommeQuantite = 0;
                    for (var achat in achatsFiltres()) {
                      sommeQuantite += double.tryParse(achat['Quantite_KG'].toString()) ?? 0;
                    }
                    return
            Text("Stock disponible: $sommeQuantite Kg", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16));
                  },
                )
              ],
            ),
          ),
        ),

        // 🔶 ZONE D’AFFICHAGE DES DONNÉES
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator()) // 🔄 Chargement
              : errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : achatsFiltres().isEmpty
                      ? Center(child: Text('Aucun achat trouvé pour cette période'))
                      : ListView.builder(
                          itemCount: achatsFiltres().length,
                          itemBuilder: (context, index) {
                            final achat = achatsFiltres()[index];
                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(

                                onLongPress: () {
                                  showBottomSheet(context: context, builder: (BuildContext conttext){
                                    return Container(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: Icon(Icons.edit, color: Colors.blue),
                                            title: Text('Modifier cet achat', style: TextStyle(color: Colors.blue),),
                                            onTap: () {
                                              // Implémentez la logique de suppression ici
                    
                                              //Navigator.pop(context);                // pour fermer le menu contextuel
                                            Navigator.push(context, MaterialPageRoute(builder: (context)=>ModifierAchat(achatData: achat)),);

                                            },
                                          ),

                                          ListTile(
                                            leading: Icon(Icons.delete, color: Colors.red),
                                            title: Text('Supprimer cet achat', style: TextStyle(color: Colors.red),),
                                            onTap: () {
                                              // Implémentez la logique de suppression ici
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=>DeleteAchat(achatData: achat)),);
                                            },
                                          ),

                                          ListTile(
                                            leading: Icon(Icons.print, color: Colors.black),
                                            title: Text('Imprimer le ticket', style: TextStyle(color: Colors.black),),
                                            onTap: () async {
                                              // Implémentez la logique d'impression ici
                                              //Navigator.pop(conttext);
                                              await generateAchatPdf(achat);

                                              
                                            },
                                          ),

                                          ListTile(
                                            leading: Icon(Icons.close, color: Colors.grey),
                                            title: Text('Fermer', style: TextStyle(color: Colors.grey),),
                                            onTap: () {
                                              Navigator.pop(conttext);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                                },

                                title: Text(
                                  '${achat['dateAchat']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID achat: ${achat['Idachat']}'),
                                    Text('Nom produit: ${achat['designationProduit']}'),
                                    Text('Quantité (KG): ${achat['Quantite_KG']}'),
                                    Text('Date: ${achat['dateAchat']}'),
                                    Text('Planteur: ${achat['nomAgriculteur']}'),
                                    Text('Code planteur: ${achat['CodePlanteur']}'),
                                    Text('Nom dépôt: ${achat['CodeDepot']}'),
                                    Text('Prix Unitaire: ${achat['prixUnitaire']}'), 
                                    Text('Prime: ${achat['PrimePlanteur']}'),
                                    Text('Cheft depôt: ${achat['nomutilisateur']}'),
                                    Text(
                                      'Total: ${achat['totalPayer']} FC',
                                      style: TextStyle(
                                          color: Color.fromARGB(255, 174, 82, 25),
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    ),
  );
}


}