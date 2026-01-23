// ignore_for_file: use_key_in_widget_constructors, unused_local_variable, avoid_print, unused_element, unused_import, unnecessary_null_comparison, deprecated_member_use, sized_box_for_whitespace

import 'package:bluetooth/UI/splashScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ================== VARIABLES GLOBALES ==================
bool gruposExistentes = false;
bool recordarme = false;
String codeUser = "";
String estado = "";

/// 🔒 OBSERVACIÓN GLOBAL DEL ESTADO DE LA APP
bool appInactiva = false;

/// ================== SHARED ==================
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

/// ================== VERIFICACIÓN USUARIO ==================
Future<void> verificarUsuario() async {
  final prefs = await SharedPreferences.getInstance();
  codeUser = prefs.getString('nombreUser') ?? "";

  if (codeUser.isEmpty) {
    estado = "";
    recordarme = false;
    return;
  }

  final tempDoc = await FirebaseFirestore.instance
      .collection('TempUsers')
      .doc(codeUser)
      .get();

  if (tempDoc.exists) {
    Map<String, dynamic> data = tempDoc.data()!;
    estado = data['estado'] ?? "";
  } else {
    estado = "No Existe";

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

/// ================== BORRAR DATOS ==================
Future<void> borrarDatos() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  codeUser = "";
  estado = "";
  recordarme = false;
  print("Datos borrados");
}

/// ================== MAIN ==================
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await Firebase.initializeApp();
    print('Firebase inicializado correctamente');
    await verificarUsuario();
  } catch (e) {
    print('Error al inicializar Firebase: $e');
  }

  runApp(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return const MyApp();
      },
    ),
  );

  Future.delayed(const Duration(milliseconds: 1), () {
    FlutterNativeSplash.remove();
  });
}

/// ================== ROOT APP (OBSERVA LIFECYCLE) ==================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    setState(() {
      appInactiva = state != AppLifecycleState.resumed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),

      builder: (context, child) {
        return Stack(
          children: [
            // 🔹 TODA la app (Navigator incluido)
            child!,

            // 🔒 Overlay global cuando la app está inactiva
            AnimatedPositioned(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              top: appInactiva ? 0 : MediaQuery.of(context).size.height,
              bottom: appInactiva ? 0 : -MediaQuery.of(context).size.height,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 260),
                opacity: appInactiva ? 1 : 0,
                child: AbsorbPointer(
                  absorbing:
                      appInactiva, // 🔒 bloquea interacción solo cuando está visible
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromRGBO(3, 5, 25, 1),
                          Color.fromRGBO(13, 20, 40, 1),
                        ],
                      ),
                    ),
                    child: focusPerdido(),
                  ),
                ),
              ),
            ),
          ],
        );
      },

      home: Splashscreen(),
    );
  }

  //Focus Perdido
  Widget focusPerdido() {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double v) => v / 430 * screenWidth;
    double h(double v) => v / 932 * screenHeight;
    double sp(double v) =>
        v / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return SafeArea(
      child: Container(
        width: screenWidth,
        height: screenHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Image.asset(
                "assets/logoApp.png",
                height: h(83),
                width: w(83),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w(400)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Qore",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "PoppinsBold",
                          fontSize: sp(38),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      TextSpan(
                        text: "X",
                        style: TextStyle(
                          color: Color(0xFF01A571),
                          fontFamily: "PoppinsBold",
                          fontSize: sp(38),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: h(5)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w(300)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Tu dinero, siempre con vos.",
                  style: TextStyle(
                    color: Colors.white60,
                    fontFamily: "PoppinsBold",
                    fontSize: sp(20),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
