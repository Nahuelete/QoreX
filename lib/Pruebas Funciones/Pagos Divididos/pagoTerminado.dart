// ignore_for_file: use_key_in_widget_constructors, camel_case_types

import 'package:bluetooth/Pruebas%20Funciones/Pagos%20Divididos/crearGrupo.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class pagoTerminadoPage extends StatefulWidget {

  @override
  State<pagoTerminadoPage> createState() => _pagoTerminadoPageState();
}

class _pagoTerminadoPageState extends State<pagoTerminadoPage> {

   final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

String id_grupo = "";
String nameUser = "";

Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      id_grupo = prefs.getString('idGrupo')!; // null si no existe
      nameUser = prefs.getString('nombreUser')!; // null si no existe
    });
  }

Future<void> eliminarGrupo() async {
 Future.delayed(Duration(seconds: 3), () {
  dbRef.child("grupos").child(id_grupo).remove();
 });
}

Future<void> eliminarMisGrupos() async {
 Future.delayed(Duration(seconds: 3), () {
  dbRef.child("Usuarios Grupos").child(nameUser).child("mis grupos").child(id_grupo).remove();
 });
}

@override
void initState() {
  super.initState();
  leerShared();
  eliminarGrupo();
  eliminarMisGrupos();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LottieBuilder.asset("assets/yaPagaste.json", height: 550, width: 550, repeat: false),
          SizedBox(height: 53),
          GestureDetector(
            child: Container(
              height: 53,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20)
              ),
              child: Center(
                child: Text("Finalizar", style: TextStyle(color: Colors.white, fontFamily: "Poppins", fontSize: 20)),
              ),
            ),
            onTap: () {
              Navigator.push(
                  context,
                    MaterialPageRoute(
                      builder: (context) => crearGrupoPage()));
            },
          )
        ],
      ),
    );
  }
}