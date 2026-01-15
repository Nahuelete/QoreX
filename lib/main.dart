// ignore_for_file: use_key_in_widget_constructors, unused_local_variable, avoid_print, unused_element, unused_import, unnecessary_null_comparison, deprecated_member_use

import 'package:bluetooth/Pruebas%20Funciones/Disenios/loginV2.dart';
import 'package:bluetooth/Pruebas%20Funciones/Disenios/notifcationScroll.dart';
import 'package:bluetooth/Pruebas%20Funciones/Reconocimiento%20Voz/reconocimientoVoz.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/avisoVerificacion.dart';
import 'package:bluetooth/UI/confirmacionPago.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/escanearDni.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/escaneoFacial.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/ingresoBiometria.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/presentacionUI.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/registroUI.dart';
import 'package:bluetooth/Pruebas%20Funciones/Pagos%20Divididos/crearGrupo.dart';
import 'package:bluetooth/Pruebas%20Funciones/Pagos%20Divididos/iniciarSesion.dart';
import 'package:bluetooth/Pruebas%20Funciones/Pagos%20Divididos/repartirGastos.dart';
import 'package:bluetooth/Pruebas%20Funciones/Pagos%20Divididos/menu.dart';
import 'package:bluetooth/UI/solicitarTarjeta.dart';
import 'package:bluetooth/UI/splashScreen.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/verificacionCompletada.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/verificacionEmail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool gruposExistentes = false;

bool recordarme = false;

String codeUser = "";

String estado = "";

Future<void> leerShared() async {
  final prefs = await SharedPreferences.getInstance();

  if (prefs.getString('nombreUser') == null) {
    codeUser = "";
    print("SHARED: Usuario Nuevo");
  } else {
    codeUser = prefs.getString('nombreUser')!;
    print("SHARED: $codeUser");
  }
}

Future<void> verificarUsuario() async {
  final prefs = await SharedPreferences.getInstance();
  codeUser = prefs.getString('nombreUser') ?? "";

  if (codeUser.isEmpty) {
    estado = "";
    recordarme = false;
    return;
  }

  // Revisar TempUsers
  final tempDoc = await FirebaseFirestore.instance
      .collection('TempUsers')
      .doc(codeUser)
      .get();

  if (tempDoc.exists) {
    Map<String, dynamic> data = tempDoc.data()!;
    estado = data['estado'] ?? "";
  } else {
    estado = "No Existe";
    // Revisar Usuarios
    final userDoc = await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(codeUser)
        .get();

    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data()!;
      recordarme = data['Recordarme'] ?? false;

      if (!recordarme) {
        await FirebaseAuth.instance.signOut();
        await borrarDatos();
        estado = "";
      }
    } else {
      estado = "";
    }
  }
}

Future<void> borrarDatos() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  codeUser = "";
  estado = "";
  recordarme = false;
  print("Datos borrados");
}

void main() async {
  // === Preserve el native splash desde el principio ===
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await Firebase.initializeApp();
    print('Firebase inicializado correctamente');
    await verificarUsuario();
  } catch (e) {
    print('Error al inicializar Firebase: $e');
  }

  User? user = FirebaseAuth.instance.currentUser;

  // Lanzamos la app inmediatamente
  runApp(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: true,
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          home: Splashscreen(),
        );
      },
    ),
  );

  // === Aquí quitamos el native splash ===
  Future.delayed(const Duration(milliseconds: 1), () {
    FlutterNativeSplash.remove();
  });
}
