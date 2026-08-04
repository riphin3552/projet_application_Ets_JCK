import 'package:flutter/material.dart';
import 'package:sale_manager/pages/login.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      debugShowCheckedModeBanner: false,
      home:  Login(),
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 34, 146, 238),
        ),
        // Bordure verte au focus par défaut pour tous les champs de saisie
        // de l'app, même ceux qui ne définissent pas leur propre focusedBorder.
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color.fromARGB(255, 63, 129, 86), width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          focusColor: const Color.fromARGB(255, 63, 129, 86),
        ),
      ),
    );
  }
}

