// ignore_for_file: use_key_in_widget_constructors, file_names, avoid_print, use_build_context_synchronously, unused_field, deprecated_member_use, unused_local_variable, sized_box_for_whitespace, unused_element

import 'dart:math';
import 'package:bluetooth/UI/ingresoCuenta.dart';
import 'package:bluetooth/UI/inicio.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/registroUI.dart';
import 'package:bluetooth/UI/registrarse.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class Splashscreen extends StatefulWidget {
  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  late AnimationController _controllerSlide;
  late Animation<Offset> _slideAnimation;

  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;

  bool recordarme = false;

  String codeUser = "";

  int paso = 0;

  Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString('codeUser') == null) {
      codeUser = "";
      print("SHARED: Usuario Nuevo");
    } else {
      codeUser = prefs.getString('codeUser')!;
      print("SHARED: $codeUser");
    }
  }

  Future<void> verificarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    codeUser = prefs.getString('codeUser') ?? "";

    paso = 0;
    recordarme = false;

    if (codeUser.isEmpty) return;

    // 🔹 TempUsers (flujo en curso)
    final tempDoc = await FirebaseFirestore.instance
        .collection('TempUsers')
        .doc(codeUser)
        .get();

    if (tempDoc.exists) {
      final data = tempDoc.data()!;
      paso = data['paso'] ?? 0;
      return;
    }

    // 🔹 Usuarios definitivos
    final userDoc = await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(codeUser)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      recordarme = data['Recordarme'] ?? false;

      if (recordarme) {
        // ✅ Usuario existe y pidió recordarme
        paso = -1;
      } else {
        // ❌ Usuario existe pero NO pidió recordarme → como si no existiera
        await FirebaseAuth.instance.signOut();
        await borrarDatos();
        paso = 0;
      }
    } else {
      // ❌ Usuario no existe
      paso = 0;
    }
  }

  Future<void> borrarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    codeUser = "";
    paso = 0;
    recordarme = false;
    print("Datos borrados");
  }

  Future<void> redireccionarUsuario() async {
    User? user = FirebaseAuth.instance.currentUser;

    Future.delayed(Duration(milliseconds: 1800), () {
      Navigator.of(context).pushAndRemoveUntil(
        PageTransition(
          type: PageTransitionType.rightToLeft,
          duration: const Duration(milliseconds: 430),
          reverseDuration: const Duration(milliseconds: 300),
          child: paso == 0
              ? inicioPage()
              : paso == -1
              ? ingresoPage()
              : paso > 0
              ? registrarsePage(pasoGuardado: paso)
              : registroPage(),
        ),
        (Route<dynamic> route) => false,
      );
      Vibration.vibrate(duration: 5);
    });

    /*Redireccion Vieja
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushAndRemoveUntil(
        PageTransition(
          type: PageTransitionType
              .rightToLeft, // 🔹 animación de derecha a izquierda
          duration: const Duration(milliseconds: 430), // velocidad
          reverseDuration: const Duration(milliseconds: 300),
          child: estado == ""
              ? ingresoPage() //presentacionPage()
              : estado == "email"
              ? verificacionEmailPage()
              : estado == "dni"
              ? escanearDniPage()
              : estado == "face"
              ? escaneoFacialPage()
              : estado == "finalizado"
              ? verificacionCompletadaPage()
              : estado == "No Existe"
              ? (user != null
                    ? (recordarme ? ingresoBiometriaPage() : registroPage())
                    : registroPage())
              : registroPage(),
        ),
        (Route<dynamic> route) => false,
      );
      Vibration.vibrate(duration: 5);
    });

    //Fin Redireccion Vieja */
  }

  Future<void> _inicializar() async {
    await leerShared();
    if (!mounted) return;
    await verificarUsuario();
    if (!mounted) return;
    await redireccionarUsuario();
  }

  @override
  void initState() {
    super.initState();

    _inicializar();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _controllerContainerMovimiento = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animationContainerMovimiento = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_controllerContainerMovimiento);

    _startFloating();

    _controllerSlide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controllerSlide, curve: Curves.easeOutCubic),
        );

    _controllerSlide.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _controllerContainerMovimiento.dispose();
    _controllerSlide.dispose();
    super.dispose();
  }

  void _startFloating() {
    final random = Random();

    void animateNext() {
      // Movimiento más amplio: entre -15 y +15 en lugar de -5 a +5
      final double newEnd = -30 + random.nextDouble() * 60;
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Stack(
      children: [
        // Fondo gradiente que cubre toda la pantalla
        Container(
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
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AppBar(
              backgroundColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
            ),
          ),
          body: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: splashScreen(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget splashScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Stack(
      children: [
        /*
        // 🔹 Fondo animado con patrón circular
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _CirclePatternPainter(animationValue: _controller.value),
            );
          },
        ),
        */

        // 🔹 Contenido principal
        SafeArea(
          child: Container(
            width: screenWidth,
            height: screenHeight,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // centra horizontalmente
              children: [
                SizedBox(
                  height: h(200),
                ), // 🔹 distancia desde arriba (ajustá a gusto)
                SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: Image.asset(
                      "assets/logoApp.png",
                      height: h(83),
                      width: w(83),
                    ),
                    /*AnimatedBuilder(
                      animation: _controllerContainerMovimiento,
                      builder: (context, child) {
                        final curved = Curves.easeInOut.transform(
                          _controllerContainerMovimiento.value,
                        );
                        return Stack(
                          alignment: Alignment.center,
                          children: [

                            // 🔹 Onda animada
                            Transform.scale(
                              scale: 1 + curved * 0.7,
                              child: Opacity(
                                opacity: 0.15 - (curved * 0.15),
                                child: Container(
                                  width: w(120),
                                  height: h(120),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromRGBO(
                                          1,
                                          165,
                                          113,
                                          1,
                                        ).withOpacity(0.10),
                                        Colors.green.shade600.withOpacity(0.10),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 🔹 Contenedor principal con el ícono
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
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        LucideIcons.creditCard,
                                        color: Colors.white,
                                        size: sp(43),
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
                    */
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(400)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Qore",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "PoppinsBold",
                                fontSize: sp(38),
                              ),
                            ),
                            TextSpan(
                              text: "X",
                              style: TextStyle(
                                color: Color(0xFF01A571),
                                fontFamily: "PoppinsBold",
                                fontSize: sp(38),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h(5)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(300)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        "Tu dinero, siempre con vos.",
                        style: TextStyle(
                          color: Colors.white60,
                          fontFamily: "PoppinsBold",
                          fontSize: sp(20),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: LottieBuilder.asset(
                        "assets/cargando.json",
                        height: h(333),
                        width: w(333),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
