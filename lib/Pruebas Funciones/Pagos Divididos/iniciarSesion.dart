// ignore_for_file: use_key_in_widget_constructors, camel_case_types, sized_box_for_whitespace, avoid_print, unused_element, unused_local_variable, unused_import, use_build_context_synchronously

import 'package:bluetooth/Pruebas%20Funciones/Pagos%20Divididos/crearGrupo.dart';
import 'package:bluetooth/Pruebas%20Funciones/Pagos%20Divididos/repartirGastos.dart';
import 'package:bluetooth/Pruebas%20Funciones/Pagos%20Divididos/menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class iniciarSesionPageGrupos extends StatefulWidget {
  @override
  State<iniciarSesionPageGrupos> createState() => _iniciarSesionPageState();
}

class _iniciarSesionPageState extends State<iniciarSesionPageGrupos> {
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerName = TextEditingController();

  int avatarRandom = random.nextInt(10);

  Future<void> guardarDatos(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombreUser', nombre);
  }

  Future<void> crearCuenta() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
      print("Usuario Creado");
      guardarDatos(_controllerName.text);
    } on FirebaseAuthException catch (e) {
      print("Error: ${e.message}");
    }
  }

  Future<void> agregarCuenta() async {
    print("Función agregarCuenta llamada");
    try {
      final dbRef2 = FirebaseDatabase.instance.ref();
      User? usuario = FirebaseAuth.instance.currentUser;

      print("Usuario actual: $usuario");

      if (usuario == null) {
        print("No hay usuario logueado");
        return;
      }

      await dbRef2.child("Usuarios Grupos").child(_controllerName.text).set({
        "Email": _controllerEmail.text,
        "Password": _controllerPassword.text,
        "Nombre": _controllerName.text,
        "Avatar": "https://i.pravatar.cc/150?img=$avatarRandom",
      });

      print("Cuenta agregada correctamente");
    } catch (e) {
      print("Error al agregar cuenta: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Ingresar",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 33),
          Center(
            child: Container(
              width: 300,
              child: TextField(
                controller: _controllerName,
                decoration: InputDecoration(
                  hintText: "Ingresar Nombre",
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 33),
          Center(
            child: Container(
              width: 300,
              child: TextField(
                controller: _controllerEmail,
                decoration: InputDecoration(
                  hintText: "Ingresar E-mail",
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 33),
          Center(
            child: Container(
              width: 300,
              child: TextField(
                controller: _controllerPassword,
                decoration: InputDecoration(
                  hintText: "Ingresar Password",
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 53),
          GestureDetector(
            child: Container(
              height: 53,
              width: 300,
              color: Colors.orange,
              child: Center(
                child: Text(
                  "Crear Cuenta",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            onTap: () {
              crearCuenta();
              Future.delayed(Duration(seconds: 3), () {
                agregarCuenta();
              });
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => crearGrupoPage()),
              );
            },
          ),
          SizedBox(height: 53),
          GestureDetector(
            child: Container(
              height: 53,
              width: 300,
              color: Colors.orange,
              child: Center(
                child: Text(
                  "Iniciar Sesion",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: _controllerEmail.text,
                password: _controllerPassword.text,
              );

              guardarDatos(_controllerName.text);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => dividirGastos()),
              );
            },
          ),
        ],
      ),
    );
  }
}
