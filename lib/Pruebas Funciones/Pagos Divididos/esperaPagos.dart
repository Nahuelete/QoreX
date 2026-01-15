// ignore_for_file: use_key_in_widget_constructors, camel_case_types, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, avoid_print, non_constant_identifier_names, unused_local_variable, unnecessary_brace_in_string_interps, unused_field, avoid_single_cascade_in_expression_statements, use_build_context_synchronously

import 'dart:async';

import 'package:bluetooth/Pruebas%20Funciones/Pagos%20Divididos/pagoTerminado.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class esperaPagosPages extends StatefulWidget {

  @override
  State<esperaPagosPages> createState() => _esperaPagosPagesState();
}

class _esperaPagosPagesState extends State<esperaPagosPages> with TickerProviderStateMixin{

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  User? usuario = FirebaseAuth.instance.currentUser;
  
  StreamSubscription<DatabaseEvent>? usersSubscription;
  late DatabaseReference usersRef;
  
  Map<String, dynamic> usersData = {};
  Map<String, double> sliderValues = {};

  String id_grupo = "";
  String nameUser = "";

  String estadoPago = "";
  String estadoPagoUser = "";

  double valor = 0.0;

  double pagarUser = 0.0;
  double porcentajeUser = 0.0;

  bool decimales = false;
  bool decimalesUser = false;

  bool todosUsuariosPagaron = false;

  Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      id_grupo = prefs.getString('idGrupo')!; // null si no existe
      nameUser = prefs.getString('nombreUser')!; // null si no existe
    });
  }

  Future<void> obtenerValorGrupo() async {
    final snapshot = await dbRef.child("grupos").child(id_grupo).once();
      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

          setState(() {
            valor = double.tryParse(data["Valor"]?.toString() ?? "0") ?? 0;
          });

          if (valor.truncate() == valor) {
           print("No tiene decimales");
           setState(() {
             decimales = false;
           });
          } else {
           print("Tiene decimales");
           setState(() {
             decimales = true;
           });
          }
        } else {
          print("Error al obtener el valor del grupo");
        }
  }
  
  String formatCurrency(double value, bool showDecimals) {
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '',
      decimalDigits: showDecimals ? 2 : 0,
    );
    return formatter.format(value);
  }

  void _listenToUsers() {
    leerShared();
    Future.delayed(Duration(seconds: 1), () {
      obtenerValorGrupo();
      dbRef.child("grupos").child(id_grupo).child("usuarios").onValue.listen((event) {

      final snapshotValue = event.snapshot.value;

      if (snapshotValue != null && snapshotValue is Map) {
        setState(() {
          usersData = snapshotValue.map((key, value) {
            return MapEntry(key.toString(), value);
          });

          // inicializar sliders si no tienen valor
          for (var entry in usersData.entries) {
            sliderValues.putIfAbsent(entry.key, () => 5);
          }
        });

        obtenerPagarUser();
        escucharEstado();
        escucharEstadoUser();
        escucharTodosPagos();
      }

    });
    });
  }

  Future<void> obtenerPagarUser() async {
  try {
    final snapshot = await dbRef
        .child("grupos")
        .child(id_grupo)
        .child("usuarios")
        .child(nameUser)
        .once();

    if (snapshot.snapshot.exists) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        // Asegurarse de que "pagar" existe
        final pagarValue = data["pagar"]?.toString() ?? "0";

        final double parsedPagar = double.tryParse(pagarValue) ?? 0;

        final porcentaje = data["porcentaje"]?.toString() ?? "0";

        final double parsedPorcentaje = double.tryParse(porcentaje) ?? 0;

        // Actualiza el estado
        setState(() {
          pagarUser = parsedPagar;
          porcentajeUser = parsedPorcentaje;
        });

        if (parsedPagar.truncate() != parsedPagar) {
          print("DECIMALES");
          setState(() {
            decimalesUser = true;
          });
        } else {
          print("SIN DECIMALES");
          setState(() {
            decimalesUser = false;
          });
        }

      } else {
        print("No hay datos para este usuario.");
      }
    } else {
      print("Usuario no encontrado en la base de datos.");
    }
  } catch (e) {
    print("Error al obtener pagarUser: $e");
  }
}

  void escucharEstado() {
  // Referencia al nodo "usuarios" del grupo
  usersRef = FirebaseDatabase.instance
      .ref()
      .child("grupos")
      .child(id_grupo)
      .child("usuarios");

  // Listener en tiempo real
  usersSubscription = usersRef.onValue.listen((event) {
    final snapshot = event.snapshot;

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;

      setState(() {
        // Convertir a Map<String, dynamic> para facilitar uso en la UI
        usersData = data.map((key, value) => MapEntry(key.toString(), value));
      });

      print("Usuarios actualizados: $usersData");
    } else {
      setState(() {
        usersData = {};
      });
      print("No hay usuarios en el grupo");
    }
  });
}

  void escucharEstadoUser() {
  final estadoRef = dbRef
      .child("grupos")
      .child(id_grupo)
      .child("usuarios")
      .child(nameUser)
      .child("estado");

  estadoRef.onValue.listen((event) {
    final newEstado = event.snapshot.value?.toString() ?? "pendiente";
    setState(() {
      estadoPagoUser = newEstado;
    });
  });
}

  void escucharTodosPagos() {
  final usuariosRef = dbRef
      .child("grupos")
      .child(id_grupo)
      .child("usuarios");

  usuariosRef.onValue.listen((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data == null) return;

    final todos = data.values.every((userValue) {
      final user = userValue as Map<dynamic, dynamic>;
      return user["estado"]?.toString() == "pago";
    });

    setState(() {
      todosUsuariosPagaron = todos;
    });

    if (todosUsuariosPagaron == true) {
      Future.delayed(Duration(milliseconds: 2300), () {
        Navigator.push(
                  context,
                    MaterialPageRoute(
                      builder: (context) => pagoTerminadoPage()));
      });
    }

    print("Todos pagaron: $todos");
  });
}

  Future<void> pagarUserDB() async {
    dbRef.child("grupos").child(id_grupo).child("usuarios").child(nameUser).update({
      "estado": "pago"
    });

    //Eliminar Saldo
  }

@override
  void initState() {
    _listenToUsers();
    obtenerValorGrupo();
    super.initState();
  }

  @override
void dispose() {
  usersSubscription?.cancel();
  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Espera Pagos", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: usersData.entries.map((entry) {
                final userId = entry.key;
                final user = entry.value as Map;
                final nombre = user['nombre'] ?? 'Sin nombre';
                final avatar = user['avatar'] ??
                    "https://i.pravatar.cc/150?u=$userId"; // placeholder
            
               // Parsear valores de forma segura
      final rawPaga = user['pagar']?.toString() ?? "0";
      final parsedPaga = double.tryParse(rawPaga) ?? 0;

      final rawPorcentaje = user['porcentaje']?.toString() ?? "0";
      final parsedPorcentaje = double.tryParse(rawPorcentaje) ?? 0;

      final estadoPago = user['estado'] ?? 'desconocido';
            
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            backgroundImage: NetworkImage(avatar),
                            radius: 24,
                          ),
                          const SizedBox(width: 13),
                    
                          // Nombre + Slider
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: "Poppins"
                                  ),
                                ),
                                SizedBox(height: 5),
                                Row(
                                  children: [
                                     Text(
                            "\$" + formatCurrency(parsedPaga, decimalesUser),
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: "Poppins")
                          ),
                          SizedBox(width: 5),
                          Text("-", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: "Poppins")),
                          SizedBox(width: 5),
                                    Text(
                            "${rawPorcentaje}%",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              fontFamily: "Poppins"
                            ),
                          ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          LottieBuilder.asset((estadoPago == "pendiente" ? "assets/awaitPay.json" : "assets/paySuccess.json"), height: (estadoPago == "pendiente" ? 43 : 53), width: (estadoPago == "pendiente" ? 43 : 53), repeat: (estadoPago == "pendiente" ? true : false)),
                         SizedBox(width: 13)
                        ],
                      ),
                    ),
                    SizedBox(height: 13),
                    Divider(
                      color: Colors.grey,
                      height: 0.3,
                    ),
                    SizedBox(height: 13),
        ]);
              }).toList(),
            ),
          ),
          GestureDetector(
            child: Container(
              height: 53,
              width: 300,
              decoration: BoxDecoration(
                color: (estadoPagoUser == "pendiente" ? Colors.orange : Colors.green),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Center(
                child: Text((estadoPagoUser == "pendiente" ? "Pagar \$${formatCurrency(pagarUser, decimalesUser)}" : "Pagaste \$${formatCurrency(pagarUser, decimalesUser)}"), style: TextStyle(color: Colors.white, fontFamily: "Poppins", fontSize: 20)),
              ),
            ),
            onTap: () {
              pagarUserDB();
            },
          ),
          SizedBox(height: 33)
        ],
      ),
    );
  }
}