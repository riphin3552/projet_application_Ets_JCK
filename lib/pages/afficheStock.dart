import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';



class StockProduits extends StatefulWidget {
  const StockProduits({super.key});

  @override
  State<StockProduits> createState() => _StockProduitsState();
}

class StockItem {
  //final String idStockage;
  final String nomDepot;
  //final String designationProduit;
  final String quantiteDisponible;

  StockItem({
    //required this.idStockage,
    required this.nomDepot,
    //required this.designationProduit,
    required this.quantiteDisponible,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      //idStockage: json['IdStockage'].toString(),
      nomDepot: json['CodeDepot'],
      quantiteDisponible: json['QuantiteDisponible'].toString(),
      
    );
  }
}

class StockTable extends StatelessWidget {
  final List<StockItem> stocks;

  const StockTable({required this.stocks});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // ✅ scroll horizontal
      child: DataTable(
        columns: const [
          //DataColumn(label: Text('ID Stockage')),
          DataColumn(label: Text('Nom Dépôt',style: TextStyle(fontWeight: FontWeight.bold),)),
          //DataColumn(label: Text('Produit',style: TextStyle(fontWeight: FontWeight.bold),)),
          DataColumn(label: Text('Quantité',style: TextStyle(fontWeight: FontWeight.bold),)),
        ],
        rows: stocks.map((stock) {
          return DataRow(cells: [
            //DataCell(Text(stock.idStockage)),
            DataCell(Text(stock.nomDepot)),
            //DataCell(Text(stock.designationProduit)),
            DataCell(Text(stock.quantiteDisponible)),
          ]);
        }).toList(),
      ),
    );
  }
}

class _StockProduitsState extends State<StockProduits> {
  late Future<List<StockItem>> FutureStock; 

  @override
  void initState(){

    super.initState();
    FutureStock=fetchStockData();
  }
  
  Future<List<StockItem>> fetchStockData() async {
  final response = await http.get(
    Uri.parse('${AppConfig.apiBaseUrl}/getStock.php'),
    headers: await Session.authHeaders(),
  );

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    if (jsonData['success'] == true) {
      List<dynamic> data = jsonData['data'];
      return data.map((item) => StockItem.fromJson(item)).toList();
    } else {
      throw Exception('Aucune donnée disponible');
    }
  } else {
    throw Exception('Erreur serveur: ${response.statusCode}');
  }
}



  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
      backgroundColor: Color.fromARGB(255, 63, 129, 86),
      title: Text("Notre Stock", style: TextStyle(color: Colors.white)),
    ),

    body: FutureBuilder<List<StockItem>>(
      future: FutureStock,
      builder: (context, snapshot){
        if(snapshot.connectionState==ConnectionState.waiting){
          return Center(
            child: CircularProgressIndicator());
        }else if(snapshot.hasError){
            return Center(child: Text('error:${snapshot.error}'),);
        }else if(!snapshot.hasData || snapshot.data!.isEmpty){
            return Center(child: Text('Aucune donnée disponible'),);
        } else{
          return Padding(padding: const EdgeInsets.all(16.0),
          child: StockTable(stocks: snapshot.data!),);
        }
      },
    )
    


    );
  }
}