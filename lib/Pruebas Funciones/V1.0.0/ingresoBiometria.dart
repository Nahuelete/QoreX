// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, deprecated_member_use, prefer_final_fields, unused_element, avoid_print, use_build_context_synchronously

import 'dart:math';

import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/registroUI.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class ingresoBiometriaPage extends StatefulWidget {
  @override
  State<ingresoBiometriaPage> createState() => _ingresoBiometriaPageState();
}

class _ingresoBiometriaPageState extends State<ingresoBiometriaPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final storage = FlutterSecureStorage();
  final auth = FirebaseAuth.instance;
  final localAuth = LocalAuthentication();

  late AnimationController _controller;

  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;

  late AnimationController _controllerAnimation;
  int _indexAnim = 0;

  String codeUser = "";
  String temaUser = "";

  // Lista de animaciones
  final List<Map<String, dynamic>> animaciones = [
    {
      "path": "assets/awaitUnlockFaceID.json",
      "duracion": Duration(seconds: 5),
      "repeat": true,
      "size": 133.0,
    },
    {
      "path": "assets/unlockFaceID.json",
      "duracion": Duration(seconds: 3),
      "repeat": false,
      "size": 133.0,
    },
  ];

  Future<void> leerShared() async {
    //Datos User
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString('nombreUser') == null) {
      codeUser = "";
    } else {
      codeUser = prefs.getString('nombreUser')!;
    }
  }

  Future<void> verificarTema() async {
    await leerShared();

    final doc = await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(codeUser)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        temaUser = data['Tema'] ?? "";
      });
    }
  }

  @override
  void initState() {
    super.initState();

    verificarTema();

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

    _controllerAnimation = AnimationController(vsync: this);
    _controllerAnimation.duration = animaciones[_indexAnim]["duracion"];
    if (animaciones[_indexAnim]["repeat"] == true) {
      _controllerAnimation.repeat();
    } else {
      _controllerAnimation.forward();
    }

    loginConBiometria();
  }

  @override
  void dispose() {
    _controller.dispose();
    _controllerContainerMovimiento.dispose();
    _controllerAnimation.dispose();
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

  void _cargarAnimacion() {
    _controllerAnimation.reset();
    _controllerAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          animaciones[_indexAnim]["repeat"] == true) {
        setState(() {
          _indexAnim++;
          if (_indexAnim < animaciones.length) {
            _cargarAnimacion();
          }
        });
      }
    });
  }

  void _siguienteAnimacion() {
    if (_indexAnim < animaciones.length - 1) {
      Vibration.vibrate(duration: 10);
      setState(() {
        _indexAnim++;
        _controllerAnimation.reset();
        _controllerAnimation.duration = animaciones[_indexAnim]["duracion"];
        if (animaciones[_indexAnim]["repeat"] == true) {
          _controllerAnimation.repeat();
        } else {
          _controllerAnimation.forward();
        }
      });
    }
  }

  Future<void> loginConBiometria() async {
    bool canCheck = await localAuth.canCheckBiometrics;
    bool authenticated = false;

    if (!canCheck) {
      print('El dispositivo no soporta biometría');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => registroPage()),
        (Route<dynamic> route) => false,
      );
      return;
    }

    try {
      authenticated = await localAuth.authenticate(
        localizedReason: 'Escanea tu huella o Face ID para iniciar sesión',
        options: const AuthenticationOptions(
          stickyAuth: true, // Mantiene la sesión en background
          biometricOnly: true, // Solo biometría
        ),
      );
    } on PlatformException catch (e) {
      print("Error de biometría: ${e.code}");

      if (e.code == "NotEnrolled" ||
          e.code == "LockedOut" ||
          e.code == "PermanentlyLockedOut") {
        // Errores críticos → no reintentar
        return;
      }

      if (e.code == "Canceled") {
        // ✅ Reintentar si el usuario canceló
        print("El usuario canceló, volviendo a solicitar...");
        Future.delayed(const Duration(milliseconds: 300), loginConBiometria);
        return;
      }
    }

    if (authenticated) {
      String? uid = await storage.read(key: 'uidUser');
      if (uid != null) {
        User? currentUser = auth.currentUser;
        if (currentUser != null) {
          //print('Usuario ya autenticado: ${currentUser.uid}');
        } else {
          //print('Autenticación biométrica exitosa para UID: $uid');
        }

        _siguienteAnimacion();
        Future.delayed(const Duration(seconds: 3), () {
          Vibration.vibrate(duration: 10);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MenuPrincipalPage()),
            (Route<dynamic> route) => false,
          );
        });
      } else {
        //print('No se encontró UID almacenado. Debe loguearse con email/contraseña la primera vez.');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => registroPage()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      print('Autenticación biométrica fallida');
      // 🔁 Reintentar automáticamente si simplemente falló (ej: dedo mal puesto)
      Future.delayed(const Duration(milliseconds: 500), loginConBiometria);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      decoration: BoxDecoration(
        gradient: temaUser == "Oscuro" || temaUser == ""
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(3, 5, 25, 1),
                  Color.fromRGBO(13, 20, 40, 1),
                ],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 237, 235, 235),
                  Color.fromARGB(255, 237, 235, 235),
                ],
                stops: const [
                  0.01, // solo 1% verde arriba
                  1.0, // 95% blanco
                ],
              ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [SizedBox(child: ingresoBiometria())]),
      ),
    );
  }

  Widget ingresoBiometria() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    final anim = animaciones[_indexAnim];
    return Visibility(
      visible: temaUser != "",
      child: Stack(
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
                    height: h(800),
                    width: w(400),
                    decoration: BoxDecoration(
                      gradient: temaUser == "Oscuro" || temaUser == ""
                          ? LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Color.fromRGBO(20, 25, 50, 1),
                                Color.fromRGBO(30, 43, 60, 1),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Color.fromRGBO(255, 255, 255, 1),
                                Color.fromRGBO(255, 255, 255, 1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(17), // radio interno
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: h(53)),
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
                                            color: Colors.green.withOpacity(
                                              0.7,
                                            ),
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
                                              LucideIcons.scanFace,
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
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(400)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                textAlign: TextAlign.center,
                                "Face ID",
                                style: TextStyle(
                                  color: temaUser == "Oscuro" || temaUser == ""
                                      ? Colors.white
                                      : Colors.black,
                                  fontFamily: "PoppinsBold",
                                  fontSize: sp(30),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h(8)),
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                textAlign: TextAlign.center,
                                "Usa Face ID para ingresar a tu cuenta.",
                                style: TextStyle(
                                  color: temaUser == "Oscuro" || temaUser == ""
                                      ? Colors.white60
                                      : Colors.black87,
                                  fontFamily: "Poppins",
                                  fontSize: sp(18.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h(183)),
                        Center(
                          child: SizedBox(
                            height: anim["size"],
                            width: anim["size"],
                            child: Lottie.asset(
                              anim["path"],
                              controller: _controllerAnimation,
                              repeat: anim["repeat"],
                              onLoaded: (composition) {
                                _controllerAnimation.duration =
                                    anim["duracion"];
                                _controllerAnimation.forward();
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: h(83)),
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
      ),
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
