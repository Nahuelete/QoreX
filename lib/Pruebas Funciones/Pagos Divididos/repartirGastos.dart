// ignore_for_file: use_key_in_widget_constructors, camel_case_types, sized_box_for_whitespace, avoid_print, non_constant_identifier_names, prefer_interpolation_to_compose_strings, unused_local_variable, prefer_adjacent_string_concatenation

import 'package:bluetooth/Pruebas%20Funciones/Pagos%20Divididos/esperaPagos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class dividirGastos extends StatefulWidget {

  @override
  State<dividirGastos> createState() => _dividirGastos();
}

class _dividirGastos extends State<dividirGastos> {

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  User? usuario = FirebaseAuth.instance.currentUser;
  
  List<String> userNames = [];

  Map<String, double> sliderValues = {}; // userId -> porcentaje
  Map<String, dynamic> usersData = {};   // userId -> {nombre, avatar}

  double valor = 0.0;
  double suma = 0.0;

  bool decimales = false;

  String id_grupo = "";
  String nameUser = "";

  Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      id_grupo = prefs.getString('idGrupo')!; // null si no existe
      nameUser = prefs.getString('nombreUser')!; // null si no existe
    });
  }

    // Formatea el número como currency sin símbolo
  String formatCurrency(double value, bool showDecimals) {
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '',
      decimalDigits: showDecimals ? 2 : 0,
    );
    return formatter.format(value);
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

  Future<void> sincronizarMisGrupos() async {
  leerShared();
  final uid = usuario!.uid;

  Future.delayed(Duration(seconds: 1), () async {
    // 1️⃣ Obtener todos los grupos del usuario
  final misGruposSnapshot = await dbRef.child("Usuarios Grupos").child(nameUser).child("mis grupos").once();

  if (misGruposSnapshot.snapshot.exists) {
    final misGrupos = misGruposSnapshot.snapshot.value as Map<dynamic, dynamic>;

    for (var grupoId in misGrupos.keys) {

      // 2️⃣ Obtener datos actualizados del grupo desde "Grupos"
      final grupoSnapshot = await dbRef.child("grupos").child(grupoId.toString()).once();

      if (grupoSnapshot.snapshot.exists) {
        final grupoData = grupoSnapshot.snapshot.value as Map<dynamic, dynamic>;

        // 3️⃣ Actualizar "mis grupos" con los datos actuales
        await dbRef.child("Usuarios Grupos").child(nameUser).child("mis grupos").child(grupoId.toString()).update({
          "Nombre Grupo": grupoData["nombre"] ?? "",
          "Valor del Grupo": grupoData["Valor"] ?? 0,
          "usuarios": grupoData["usuarios"] ?? {},
          "configuracion": grupoData["configuracion"] ?? ""
        });
      }
    }
  }
  });
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
      }
    });
    });
  }

 bool verificarSuma() {
  double suma = 0.0;

  sliderValues.forEach((userId, porcentaje) {
    suma += valor * porcentaje / 100;
  });

  // Permitimos un pequeño margen de error por decimales
  return (suma - valor).abs() < 0.01;
}

 double porcentajeRestante(String userId) {
  double sumaOtros = 0;
  sliderValues.forEach((id, value) {
    if (id != userId) {
      sumaOtros += value;
    }
  });
  return (100 - sumaOtros).clamp(0, 100); // nunca negativo ni mayor a 100
}

  @override
  void initState() {
    super.initState();
    _listenToUsers();
    sincronizarMisGrupos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Repartir gastos", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          SizedBox(height: 13),
          // ignore: unnecessary_brace_in_string_interps
          Text("\$" + formatCurrency(valor, decimales), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          SizedBox(height: 13),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: usersData.entries.map((entry) {
                final userId = entry.key;
                final user = entry.value as Map;
                final nombre = user['nombre'] ?? 'Sin nombre';
                final avatar = user['avatar'] ??
                    "https://i.pravatar.cc/150?u=$userId"; // placeholder
            
                final value = sliderValues[userId] ?? 0.0;
            
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
                          const SizedBox(width: 12),
                    
                          // Nombre + Slider
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Slider(
                                  value: value < 5 ? 5 : value,
                                  min: 5,
                                  max: porcentajeRestante(userId),
                                  divisions: 20, // pasos de 5 en 5
                                  activeColor: Colors.orange,
                                  inactiveColor: Colors.grey,
                                  label: "${value.toInt()}%",
                                  onChanged: (newValue) {
                                    setState(() {
                                      sliderValues[userId] = (newValue / 5).round() * 5; // siempre múltiplo de 5
                                    if (sliderValues[userId]! < 5) {
                                      sliderValues[userId] = 5; // nunca baja de 5
                                      dbRef.child("grupos").child(id_grupo).child("usuarios").child(nombre).update({
                                        "porcentaje": (newValue / 5).round() * 5,
                                        "pagar": double.parse((valor * sliderValues[userId]! / 100).toStringAsFixed(2))
                                      });
                                      }
                                     dbRef.child("grupos").child(id_grupo).child("usuarios").child(nombre).update({
                                        "porcentaje": (newValue / 5).round() * 5,
                                        "pagar": double.parse((valor * sliderValues[userId]! / 100).toStringAsFixed(2))
                                      });
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                    
                          // Porcentaje a la derecha
                          Text(
                            "${value.toInt()}%",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text("Total a pagar: " + "\$" + formatCurrency((valor * value / 100), decimales), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                );
              }).toList(),
            ),
          ),
          GestureDetector(
            child: Container(
              height: 53,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              child: Center(
                child: Text((verificarSuma() ? "Confirmar" : "Falta Dinero"), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
            ),
            onTap: () {
              if (verificarSuma() == true) {
                Navigator.push(
                  context,
                    MaterialPageRoute(
                      builder: (context) => esperaPagosPages()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("⚠️ Falta asignar dinero", style: TextStyle(color: Colors.white, fontFamily: "Poppins", fontSize: 18)),
                    duration: Duration(seconds: 2)));
              }
            },
          ),
          SizedBox(height: 33)
        ],
      ),
    );
  }
}