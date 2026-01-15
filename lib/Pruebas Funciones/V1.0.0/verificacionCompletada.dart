// ignore_for_file: file_names, use_key_in_widget_constructors, camel_case_types, deprecated_member_use, avoid_unnecessary_containers, avoid_print, unused_local_variable, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:math';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/registroUI.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class verificacionCompletadaPage extends StatefulWidget {
  @override
  State<verificacionCompletadaPage> createState() =>
      _verificacionCompletadaPageState();
}

class _verificacionCompletadaPageState extends State<verificacionCompletadaPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;

  late AnimationController _controllerIconMovimiento;
  late Animation<double> _animationIconMovimiento;

  late AnimationController _iconAccederController;
  late Animation<double> _iconAccederAnimation;

  String codeUser = "";
  String nameUser = "";
  String emailUser = "";
  String dniUser = "";
  String uidUser = "";
  String cbuUser = "";
  String aliasUser = "";
  String fechaUser = "";
  String passwordUser = "";

  // ----------------- Registrar Firestore -----------------
  Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString('nombreUser') == null) {
      codeUser = "";
    } else {
      codeUser = prefs.getString('nombreUser')!;
    }

    if (prefs.getString('passUser') == null) {
      passwordUser = "";
    } else {
      passwordUser = prefs.getString('passUser')!;
    }
  }

  Future<void> obtenerDatos() async {
    User? user = FirebaseAuth.instance.currentUser;

    await leerShared();

    FirebaseFirestore.instance
        .collection('TempUsers') // colección principal
        .doc(codeUser) // documento del usuario
        .snapshots() // escuchar en tiempo real
        .listen((docSnapshot) async {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              dniUser = data['dni'];
              nameUser = data['nombre'];
              emailUser = data['email'];
              uidUser = user!.uid;
            });

            await generarCbuAlias();

            print(aliasUser);

            DateTime ahora = DateTime.now();

            setState(() {
              fechaUser = DateFormat('dd-MM-yyyy').format(ahora);
            });

            Future.delayed(Duration(seconds: 1), () {
              actualizarFirestoreTemp();
              registrarUsuario();
              habilitarUsuarioTransacciones();
            });
          } else {
            print('El documento no existe');
          }
        });
  }

  Future<void> actualizarFirestoreTemp() async {
    FirebaseFirestore.instance
        .collection("TempUsers") // Ej: 'TempUsers'
        .doc(codeUser) // ID del documento
        .delete();
  }

  Future<void> registrarUsuario() async {
    await leerShared();
    await obtenerDatos();

    try {
      //Iniciar Sesion
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailUser,
        password: passwordUser,
      );

      // Crear documento principal
      await FirebaseFirestore.instance.collection('Usuarios').doc(uidUser).set({
        'Nombre': nameUser,
        'Email': emailUser,
        "Dni": dniUser,
        'Estado': "Verificado",
        "Saldo": 0,
        "CBU": cbuUser,
        "Alias": aliasUser,
        "Registrado": fechaUser,
        "Recordarme": false,
        "Avatar": "",
        "Mostrar Saldo": true,
        "Tarjeta": "No",
      });

      /* Crear subcolección Avisos
    await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(uidUser)
        .collection("Avisos")
        .doc("Microfono")
        .set({'Microfono': true});
        */

      print("Usuario creado correctamente");

      sendEmailBienvenida();
    } on FirebaseException catch (e) {
      print("Error Firestore: ${e.message}");
    }
  }

  Future<void> generarCbuAlias() async {
    Random random = Random();
    cbuUser = '';
    for (int i = 0; i < 22; i++) {
      setState(() {
        cbuUser += random.nextInt(10).toString();
      });
    }

    List<String> sufijos = [
      'ágil',
      'amable',
      'audaz',
      'brillante',
      'cálido',
      'cauteloso',
      'cómodo',
      'compasivo',
      'confiable',
      'creativo',
      'curioso',
      'decidido',
      'diligente',
      'dinámico',
      'disciplinado',
      'eficiente',
      'elocuente',
      'entusiasta',
      'equilibrado',
      'exitoso',
      'expresivo',
      'fácil',
      'fiel',
      'flexible',
      'fuerte',
      'generoso',
      'hábil',
      'honesto',
      'humilde',
      'imaginativo',
      'impresionante',
      'independiente',
      'ingenioso',
      'inteligente',
      'intuitivo',
      'jovial',
      'justo',
      'leal',
      'luminoso',
      'maduro',
      'magnífico',
      'meticuloso',
      'modesto',
      'optimista',
      'organizado',
      'paciente',
      'perseverante',
      'positivo',
      'práctico',
      'proactivo',
      'productivo',
      'profesional',
      'racional',
      'reflexivo',
      'resolutivo',
      'responsable',
      'sabio',
      'sensible',
      'sereno',
      'sincero',
      'sofisticado',
      'solidario',
      'talentoso',
      'tenaz',
      'tranquilo',
      'valiente',
      'vanguardista',
      'vibrante',
      'vigilante',
      'vivo',
      'voluntarioso',
      'vulnerable',
      'zelo',
      'adaptable',
      'afectuoso',
      'alegre',
      'amigable',
      'apasionado',
      'apegado',
      'aplicado',
      'artístico',
      'asertivo',
      'atento',
      'audaz',
      'auténtico',
      'bajo',
      'bello',
      'benévolo',
      'bravo',
      'cálido',
      'cándido',
      'cauteloso',
      'cercano',
      'cínico',
      'cómodo',
      'compasivo',
      'confiado',
      'conservador',
      'constante',
      'creativo',
      'curioso',
      'decidido',
      'delicado',
      'diligente',
      'disciplinado',
      'eficaz',
      'eficiente',
      'elocuente',
      'entusiasta',
      'equilibrado',
      'exitoso',
      'expresivo',
      'fácil',
      'fiel',
      'flexible',
      'fuerte',
      'generoso',
      'hábil',
      'honesto',
      'humilde',
      'imaginativo',
      'impresionante',
      'independiente',
      'ingenioso',
      'inteligente',
      'intuitivo',
      'jovial',
      'justo',
      'leal',
      'luminoso',
      'maduro',
      'magnífico',
      'meticuloso',
      'modesto',
      'optimista',
      'organizado',
      'paciente',
      'perseverante',
      'positivo',
      'práctico',
      'proactivo',
      'productivo',
      'profesional',
      'racional',
      'reflexivo',
      'resolutivo',
      'responsable',
      'sabio',
      'sensible',
      'sereno',
      'sincero',
      'sofisticado',
      'solidario',
      'talentoso',
      'tenaz',
      'tranquilo',
      'valiente',
      'vanguardista',
      'vibrante',
      'vigilante',
      'vivo',
      'voluntarioso',
      'vulnerable',
      'zelo',
      'adaptable',
      'afectuoso',
      'alegre',
      'amigable',
      'apasionado',
      'apegado',
      'aplicado',
      'artístico',
      'asertivo',
      'atento',
      'audaz',
      'auténtico',
      'bajo',
      'bello',
      'benévolo',
      'bravo',
      'cálido',
      'cándido',
      'cauteloso',
      'cercano',
      'cínico',
      'cómodo',
      'compasivo',
      'confiado',
      'conservador',
      'constante',
      'creativo',
      'curioso',
      'decidido',
      'delicado',
      'diligente',
      'disciplinado',
      'eficaz',
      'eficiente',
      'elocuente',
      'entusiasta',
      'equilibrado',
      'exitoso',
      'expresivo',
      'fácil',
      'fiel',
      'flexible',
      'fuerte',
      'generoso',
      'hábil',
      'honesto',
      'humilde',
      'imaginativo',
      'impresionante',
      'independiente',
      'ingenioso',
      'inteligente',
      'intuitivo',
      'jovial',
      'justo',
      'leal',
      'luminoso',
      'maduro',
      'magnífico',
      'meticuloso',
      'modesto',
      'optimista',
      'organizado',
      'paciente',
      'perseverante',
      'positivo',
      'práctico',
      'proactivo',
      'productivo',
      'profesional',
      'racional',
      'reflexivo',
      'resolutivo',
      'responsable',
      'sabio',
      'sensible',
      'sereno',
      'sincero',
      'sofisticado',
      'solidario',
      'talentoso',
      'tenaz',
      'tranquilo',
      'valiente',
      'vanguardista',
      'vibrante',
      'vigilante',
      'vivo',
      'voluntarioso',
      'vulnerable',
      'zelo',
      'adaptable',
      'afectuoso',
      'alegre',
      'amigable',
      'apasionado',
      'apegado',
      'aplicado',
      'artístico',
      'asertivo',
      'atento',
      'audaz',
      'auténtico',
      'bajo',
      'bello',
      'benévolo',
      'bravo',
      'cálido',
      'cándido',
      'cauteloso',
      'cercano',
      'cínico',
      'cómodo',
      'compasivo',
      'confiado',
      'conservador',
      'constante',
      'creativo',
      'curioso',
      'decidido',
      'delicado',
      'diligente',
      'disciplinado',
      'eficaz',
      'eficiente',
      'elocuente',
      'entusiasta',
      'equilibrado',
      'exitoso',
      'expresivo',
      'fácil',
      'fiel',
      'flexible',
      'fuerte',
      'generoso',
      'hábil',
      'honesto',
      'humilde',
      'imaginativo',
      'impresionante',
      'independiente',
      'ingenioso',
      'inteligente',
      'intuitivo',
      'jovial',
      'justo',
      'leal',
      'luminoso',
      'maduro',
      'magnífico',
      'meticuloso',
      'modesto',
      'optimista',
      'organizado',
      'paciente',
      'perseverante',
      'positivo',
      'práctico',
      'proactivo',
      'productivo',
      'profesional',
      'racional',
      'reflexivo',
      'resolutivo',
      'responsable',
      'sabio',
      'sensible',
      'sereno',
      'sincero',
      'sofisticado',
      'solidario',
      'talentoso',
      'tenaz',
      'tranquilo',
      'valiente',
      'vanguardista',
      'vibrante',
      'vigilante',
      'vivo',
      'voluntarioso',
      'vulnerable',
      'zelo',
    ];

    String palabra = sufijos[random.nextInt(sufijos.length)];
    String palabra2 = sufijos[random.nextInt(sufijos.length)];

    setState(() {
      //aliasUser = nameUser.replaceAll(" ", "").toLowerCase() + "." + palabra.toLowerCase();
      aliasUser = palabra.toLowerCase() + "." + palabra2.toLowerCase();
    });
  }

  Future<void> habilitarUsuarioTransacciones() async {
    try {
      FirebaseFirestore.instance.collection("BusquedaUsers").doc(aliasUser).set(
        {"Uid": uidUser, "Nombre": nameUser, "Tipo": "Alias"},
      );

      FirebaseFirestore.instance.collection("BusquedaUsers").doc(cbuUser).set({
        "Uid": uidUser,
        "Nombre": nameUser,
        "Tipo": "CBU",
      });

      FirebaseFirestore.instance.collection("BusquedaUsers").doc(emailUser).set(
        {"Uid": uidUser, "Nombre": nameUser, "Tipo": "Email"},
      );
    } catch (e) {
      print("Error al habilitar usuario: $e");
    }
  }
  // ----------------- Fin Registrar Firestore -----------------

  Future sendEmailBienvenida() async {
    final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");
    const serviceId = "service_hp0bj4v";
    const templateId = "template_2gxche3";
    const userId = "hxl-npJZl6ZirwdKR";
    final response = await http.post(
      url,
      headers: {"origin": "http:localhost", "Content-Type": "application/json"},
      body: json.encode({
        "service_id": serviceId,
        "template_id": templateId,
        "user_id": userId,
        "template_params": {"name": nameUser, "sender_email": emailUser},
      }),
    );
    print("ENVIADO");
    return response.statusCode;
  }

  @override
  void initState() {
    super.initState();

    obtenerDatos();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _controllerContainerMovimiento = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    _animationContainerMovimiento = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_controllerContainerMovimiento);

    _startFloating();

    _controllerIconMovimiento = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    _animationIconMovimiento = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_controllerIconMovimiento);

    _startFloatingIcon();

    _iconAccederController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _iconAccederAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(parent: _iconAccederController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _controllerContainerMovimiento.dispose();
    _controllerIconMovimiento.dispose();
  }

  void _startFloating() {
    final random = Random();

    void animateNext() {
      // Movimiento más amplio: entre -15 y +15 en lugar de -5 a +5
      final double newEnd = -20 + random.nextDouble() * 30;
      // Duración más variada: entre 1.5s y 3s
      final int newDuration = 1500 + random.nextInt(1500);

      final tween =
          Tween<double>(
            begin: _animationContainerMovimiento.value,
            end: newEnd,
          ).animate(
            CurvedAnimation(
              parent: _controllerContainerMovimiento,
              curve: Curves.easeInOutSine,
            ),
          );

      _animationContainerMovimiento = tween;

      _controllerContainerMovimiento.duration = Duration(
        milliseconds: newDuration,
      );
      _controllerContainerMovimiento.forward(from: 0).whenComplete(animateNext);
    }

    animateNext();
  }

  void _startFloatingIcon() {
    final random = Random();

    void animateNext() {
      // Movimiento más amplio: entre -15 y +15 en lugar de -5 a +5
      final double newEnd = -5 + random.nextDouble() * 8;
      // Duración más variada: entre 1.5s y 3s
      final int newDuration = 1500 + random.nextInt(1500);

      final tween =
          Tween<double>(
            begin: _animationIconMovimiento.value,
            end: newEnd,
          ).animate(
            CurvedAnimation(
              parent: _controllerIconMovimiento,
              curve: Curves.easeInOutSine,
            ),
          );

      _animationIconMovimiento = tween;

      _controllerIconMovimiento.duration = Duration(milliseconds: newDuration);
      _controllerIconMovimiento.forward(from: 0).whenComplete(animateNext);
    }

    animateNext();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(3, 5, 25, 1), Color.fromRGBO(13, 20, 40, 1)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [SizedBox(child: verificacionCompletada())]),
      ),
    );
  }

  Widget verificacionCompletada() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Stack(
      children: [
        SingleChildScrollView(
          reverse: true,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: w(18), right: w(18)),
              child: Container(
                padding: EdgeInsets.all(1.3), // grosor del borde degradado
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color.fromRGBO(1, 165, 113, 1).withOpacity(0.3),
                      Color.fromRGBO(33, 13, 243, 1).withOpacity(0.3),
                      Color.fromRGBO(165, 53, 253, 1).withOpacity(0.3),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color.fromRGBO(20, 25, 50, 1),
                        Color.fromRGBO(30, 43, 60, 1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17), // radio interno
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: h(43)),
                      AnimatedBuilder(
                        animation: _controllerContainerMovimiento,
                        builder: (context, child) {
                          final curved = Curves.easeInOut.transform(
                            _controllerContainerMovimiento.value,
                          );
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Onda sincronizada con el botón
                              Transform.scale(
                                scale:
                                    1 +
                                    curved *
                                        0.7, // 🔹 cuando botón crece, onda también
                                child: Opacity(
                                  opacity: 0.15 - (curved * 0.15),
                                  child: Container(
                                    width: w(120),
                                    height: h(120),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          Color.fromRGBO(
                                            1,
                                            165,
                                            113,
                                            1,
                                          ).withOpacity(0.10),
                                          Colors.green.shade600.withOpacity(
                                            0.10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Botón con respiro
                              Transform.scale(
                                scale: 1 + (curved * 0.05),
                                child: AnimatedBuilder(
                                  animation: _animationContainerMovimiento,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                        0,
                                        _animationContainerMovimiento.value,
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    width: w(100),
                                    height: h(100),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color.fromRGBO(1, 165, 113, 1),
                                          Colors.green.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.7),
                                          blurRadius: 20,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(7),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: w(0.1),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ), // radio un poco menor
                                        ),
                                        child: AnimatedBuilder(
                                          animation:
                                              _animationContainerMovimiento,
                                          builder: (context, child) {
                                            return Transform.translate(
                                              offset: Offset(
                                                0,
                                                _animationContainerMovimiento
                                                    .value,
                                              ),
                                              child: child,
                                            );
                                          },
                                          child: Icon(
                                            Icons.thumb_up,
                                            color: Colors.white,
                                            size: sp(43),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: h(33)),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(333)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Center(
                            child: Text(
                              textAlign: TextAlign.center,
                              "¡Bienvenido A Tu Wallet!",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "PoppinsBold",
                                fontSize: sp(30),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h(13)),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(23)),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(450)),
                            child: Text(
                              textAlign: TextAlign.center,
                              "Tu registro ha sido completado exitosamente.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontFamily: "Poppins",
                                fontSize: sp(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h(33)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w(23)),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFF0F1E24), // fondo oscuro
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.greenAccent,
                                    width: w(1),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🔹 Icono de check
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.greenAccent,
                                        size: sp(24),
                                      ),
                                    ),
                                    SizedBox(width: w(13)),
                                    // 🔹 Texto
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(300),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "Verificación completada",
                                                style: TextStyle(
                                                  color: Colors.greenAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: sp(16),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: h(5)),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(300),
                                            ),
                                            child: Text(
                                              "Tu identidad ha sido verificada exitosamente.",
                                              style: TextStyle(
                                                color: Colors.greenAccent,
                                                fontSize: sp(15),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: h(23)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w(23)),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(
                                    255,
                                    15,
                                    22,
                                    36,
                                  ), // fondo oscuro
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blueAccent,
                                    width: w(1),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🔹 Icono de check
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.wallet,
                                        color: Colors.blueAccent,
                                        size: sp(24),
                                      ),
                                    ),
                                    SizedBox(width: w(13)),
                                    // 🔹 Texto
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(300),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "Wallet activada",
                                                style: TextStyle(
                                                  color: Colors.blueAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: sp(16),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: h(5)),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(300),
                                            ),
                                            child: Text(
                                              "Ya puedes realizar transacciones de forma segura.",
                                              style: TextStyle(
                                                color: Colors.blueAccent,
                                                fontSize: sp(15),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: h(23)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w(23)),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(
                                    255,
                                    36,
                                    23,
                                    15,
                                  ), // fondo oscuro
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orangeAccent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🔹 Icono de check
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        LucideIcons.sparkles,
                                        color: Colors.orangeAccent,
                                        size: sp(23),
                                      ),
                                    ),
                                    SizedBox(width: w(13)),
                                    // 🔹 Texto
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(300),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "Acceso completo",
                                                style: TextStyle(
                                                  color: Colors.orangeAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: sp(15),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: h(5)),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(300),
                                            ),
                                            child: Text(
                                              "Todas las funciones están disponibles para ti.",
                                              style: TextStyle(
                                                color: Colors.orangeAccent,
                                                fontSize: sp(15),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: h(33)),
                      GestureDetector(
                        child: Container(
                          height: h(53),
                          width: w(350),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(1, 165, 113, 1),
                                Colors.green.shade600,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.wallet,
                                color: Colors.white,
                                size: sp(20),
                              ),
                              SizedBox(width: w(8)),
                              Text(
                                "Comenzar A Usar Mi Wallet",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "Poppins",
                                  fontSize: sp(17),
                                ),
                              ),
                              SizedBox(width: w(8)),
                              AnimatedBuilder(
                                animation: _iconAccederAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      _iconAccederAnimation.value,
                                      0,
                                    ),
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  LucideIcons.arrowRight,
                                  color: Colors.white,
                                  size: sp(20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Vibration.vibrate(duration: 15);
                          Navigator.pushAndRemoveUntil(
                            context,
                            PageTransition(
                              type: PageTransitionType
                                  .leftToRight, // 👉 derecha a izquierda
                              child: registroPage(),
                            ),
                            (Route<dynamic> route) =>
                                false, // elimina todo el stack
                          );
                        },
                      ),
                      SizedBox(height: h(33)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: _CirclePatternPainter(
                  animationValue: _controller.value,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CirclePatternPainter extends CustomPainter {
  final double animationValue;
  _CirclePatternPainter({this.animationValue = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Recorte para que nada sobresalga
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final circles = [
      Offset(0.2, 0.3),
      Offset(0.7, 0.2),
      Offset(0.8, 0.7),
      Offset(0.3, 0.8),
      Offset(0.5, 0.5),
      Offset(0.15, 0.15),
      Offset(0.6, 0.3),
      Offset(0.7, 0.8),
      Offset(0.1, 0.8),
      Offset(0.8, 0.3),
    ];

    final radii = [10.0, 5.0, 10.0, 8.0, 8.0, 10.0, 8.0, 10.0, 8.0, 10.0];
    final opacities = [
      0.1,
      0.15,
      0.12,
      0.08,
      0.10,
      0.08,
      0.10,
      0.08,
      0.10,
      0.08,
    ];

    for (int i = 0; i < circles.length; i++) {
      // Movimiento vertical
      double dyOffset = sin(animationValue * 2 * pi + i) * 15; // +-10px
      final position = Offset(
        circles[i].dx * size.width, // multiplicamos por ancho
        circles[i].dy * size.height + dyOffset, // multiplicamos por alto
      );
      paint.color = Colors.greenAccent.withOpacity(opacities[i]);
      canvas.drawCircle(position, radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CirclePatternPainter oldDelegate) => true;
}
