// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, deprecated_member_use, avoid_print, unused_element, unused_local_variable, avoid_init_to_null

import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/registroUI.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class cambiarPasswordPage extends StatefulWidget {
  @override
  State<cambiarPasswordPage> createState() => _cambiarPasswordPageState();
}

class _cambiarPasswordPageState extends State<cambiarPasswordPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;
  late AnimationController _controllerContainerNaranjaMovimiento;
  late Animation<double> _animationContainerNaranjaMovimiento;
  late AnimationController _controllerIconMovimiento;
  late Animation<double> _animationIconMovimiento;
  late AnimationController _iconSiguienteController;
  late Animation<double> _iconSiguienteAnimation;

  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerPasswordConfirmar =
      TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();

  bool seguridadPasswordVis = false;

  double seguridadPassword = 0.0;

  String seguridadPasswordText = "Muy Débil";

  Color seguridadPasswordColorText = Colors.red;

  bool passwordCoinciden = false;

  bool _obscurePassword = true;

  bool _obscurePasswordConfirmar = true;

  bool changePasswordVis = true;

  bool passwordDistintas = false;

  String passwordActualUser = "";
  String emailActualUser = "";

  Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString('emailUser') == null) {
      emailActualUser = "";
    } else {
      emailActualUser = prefs.getString('emailUser')!;
      print(emailActualUser);
    }
  }

  Future<void> inicarSesion() async {
    await leerShared();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailActualUser,
      );
      print("Correo de restablecimiento enviado");
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuth error: ${e.code} - ${e.message}");
    } catch (e) {
      print("Otro error: $e");
    }
  }

  Future<void> verificarPassword() async {
    String pass = _controllerPassword.text;
    double score = 0;

    // Criterios
    if (pass.length >= 8) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(pass) && pass.length >= 8) score += 0.25;
    if (RegExp(r'[0-9]').hasMatch(pass) && pass.length >= 8) score += 0.25;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pass) && pass.length >= 8)
      score += 0.25;

    // Determinar texto y color según el puntaje
    String texto;
    Color color;

    if (score == 0) {
      texto = "Muy Débil";
      color = Colors.red;
    } else if (score <= 0.25) {
      texto = "Débil";
      color = Colors.orange;
    } else if (score <= 0.5) {
      texto = "Aceptable";
      color = Colors.yellow;
    } else if (score <= 0.75) {
      texto = "Buena";
      color = Colors.blue;
    } else {
      texto = "Excelente";
      color = Colors.green;
    }

    setState(() {
      seguridadPassword = score; // Barra de progreso
      seguridadPasswordText = texto; // Texto
      seguridadPasswordColorText = color; // Color
    });
  }

  Future<void> verificarCoincidenciaLive() async {
    if (_controllerPassword.text.isNotEmpty &&
        _controllerPasswordConfirmar.text.isNotEmpty) {
      if (_controllerPasswordConfirmar.text != _controllerPassword.text) {
        setState(() {
          passwordDistintas = true;
        });
      } else {
        setState(() {
          passwordDistintas = false;
        });
      }
    }
  }

  Future<void> changePassword() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.updatePassword(_controllerPasswordConfirmar.text);
        print("Contraseña actualizada correctamente");
      } else {
        print("No hay usuario logueado");
      }
    } on FirebaseAuthException catch (e) {
      print("Error: ${e.message}");
    }
  }

  @override
  void initState() {
    super.initState();

    leerShared();

    inicarSesion();

    _passwordFocusNode.addListener(_onPasswordFocusChange);

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

    _controllerContainerNaranjaMovimiento = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    _animationContainerNaranjaMovimiento = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_controllerContainerNaranjaMovimiento);
    _startFloatingNaranja();

    _iconSiguienteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _iconSiguienteAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _iconSiguienteController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    // Animations
    _controller.dispose();
    _controllerContainerMovimiento.dispose();
    _controllerContainerNaranjaMovimiento.dispose();
    _controllerIconMovimiento.dispose();
    _iconSiguienteController.dispose();

    _passwordFocusNode.dispose();

    super.dispose();
  }

  void _startFloating() {
    final random = Random();

    void animateNext() {
      // Movimiento más amplio: entre -15 y +15 en lugar de -5 a +5
      final double newEnd = -10 + random.nextDouble() * 40;
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

  void _startFloatingNaranja() {
    final random = Random();

    void animateNext() {
      final double newEnd = -3 + random.nextDouble() * 7;
      final int newDuration = 1000 + random.nextInt(1000);

      final tween =
          Tween<double>(
            begin: _animationContainerNaranjaMovimiento.value,
            end: newEnd,
          ).animate(
            CurvedAnimation(
              parent: _controllerContainerNaranjaMovimiento,
              curve: Curves.easeInOutSine,
            ),
          );

      _animationContainerNaranjaMovimiento = tween;

      _controllerContainerNaranjaMovimiento.duration = Duration(
        milliseconds: newDuration,
      );
      _controllerContainerNaranjaMovimiento
          .forward(from: 0)
          .whenComplete(animateNext);
    }

    animateNext();
  }

  void _startFloatingIcon() {
    final random = Random();

    void animateNext() {
      // Movimiento más amplio: entre -15 y +15 en lugar de -5 a +5
      final double newEnd = -8 + random.nextDouble() * 15;
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

  void verificarCoincidenciaPassword() {
    if (_controllerPassword.text.isNotEmpty &&
        _controllerPasswordConfirmar.text.isNotEmpty) {
      if (_controllerPassword.text == _controllerPasswordConfirmar.text) {
        if (seguridadPasswordText != "Muy Débil") {
          if (_controllerPassword.text != "ActualPass") {
            //showFlushbarCambiada(context, "Contraseña Actualizada.");
            FocusScope.of(context).unfocus();
            setState(() {
              changePasswordVis = false;
            });
          } else {
            showFlushbarError(
              context,
              "La Contraseña Debe Ser Distinta A La Actual.",
            );
          }
        } else {
          showFlushbarError(context, "La Contraseña Es Muy Facil.");
        }
      } else {
        showFlushbarError(context, "Las Contraseñas No Coinciden.");
      }
    } else {
      showFlushbarError(context, "Completa Los 2 Campos.");
    }
  }

  void showFlushbarError(BuildContext context, String message) {
    Flushbar(
      maxWidth: 350,
      isDismissible: false,
      flushbarStyle: FlushbarStyle.FLOATING,
      mainButton: SizedBox.shrink(),
      flushbarPosition: FlushbarPosition.TOP,
      margin: EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(13),
      backgroundGradient: LinearGradient(
        colors: [Colors.red, Colors.redAccent],
      ),
      icon: Icon(LucideIcons.xCircle, color: Colors.white),
      duration: Duration(seconds: 3),
      messageText: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: "Poppins",
            ),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              10,
            ), // respeta el borde redondeado
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    ).show(context);
  }

  void showFlushbarCambiada(BuildContext context, String message) {
    Flushbar(
      maxWidth: 350,
      isDismissible: false,
      flushbarStyle: FlushbarStyle.FLOATING,
      mainButton: SizedBox.shrink(),
      flushbarPosition: FlushbarPosition.TOP,
      margin: EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(13),
      backgroundGradient: LinearGradient(
        colors: [Color.fromRGBO(1, 165, 113, 1), Colors.green.shade600],
      ),
      icon: Icon(LucideIcons.xCircle, color: Colors.white),
      duration: Duration(seconds: 3),
      messageText: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: "Poppins",
            ),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              10,
            ), // respeta el borde redondeado
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    ).show(context);
  }

  void _onPasswordFocusChange() {
    if (mounted) {
      setState(() {
        seguridadPasswordVis = _passwordFocusNode.hasFocus;
      });
    }
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
        body: Stack(
          children: [
            SizedBox(child: cambiarPassword()),
            SizedBox(child: passwordActualizada()),
          ],
        ),
      ),
    );
  }

  Widget cambiarPassword() {
    return Visibility(
      //visible: changePasswordVis,
      visible: false,
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              reverse: true,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 18, right: 18),
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
                    child: Center(
                      child: AnimatedSize(
                        duration: Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        child: Container(
                          //height: 713,
                          width: 360,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Color.fromRGBO(20, 25, 50, 1),
                                Color.fromRGBO(30, 43, 60, 1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              17,
                            ), // radio interno
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 13),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 18),
                                    child: GestureDetector(
                                      child: Container(
                                        height: 48,
                                        width: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color.fromRGBO(20, 25, 50, 1),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.x,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 20,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                registroPage(),
                                          ),
                                          (Route<dynamic> route) => false,
                                        );
                                      },
                                    ),
                                  ),
                                ),
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
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.rectangle,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color.fromRGBO(
                                                      200,
                                                      90,
                                                      0,
                                                      1,
                                                    ).withOpacity(0.10),
                                                    Colors.orange.shade600
                                                        .withOpacity(0.10),
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
                                            child: Container(
                                              width: 93,
                                              height: 93,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color.fromRGBO(
                                                      1,
                                                      165,
                                                      113,
                                                      1,
                                                    ),
                                                    Colors.green.shade600,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color.fromRGBO(
                                                      1,
                                                      165,
                                                      113,
                                                      1,
                                                    ).withOpacity(0.7),
                                                    blurRadius: 20,
                                                    spreadRadius: 3,
                                                  ),
                                                ],
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  7,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.transparent,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 0.1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
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
                                                      LucideIcons.lock,
                                                      color: Colors.white,
                                                      size: 40,
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
                                SizedBox(height: 33),
                                Center(
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    "Nueva Contraseña",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "PoppinsBold",
                                      fontSize: 25,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 13),
                                Center(
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    "Crea una contraseña segura",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 33),
                                Container(
                                  width: 300,
                                  height: 63,
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(
                                      20,
                                      25,
                                      50,
                                      1,
                                    ), // fondo oscuro del TextField
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    children: [
                                      // Icono con fondo y borde redondeado
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        height: 36,
                                        width: 36,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromRGBO(1, 165, 113, 1),
                                              Colors.green.shade600,
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.lock,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      // TextField
                                      Expanded(
                                        child: TextField(
                                          focusNode: _passwordFocusNode,
                                          obscureText: _obscurePassword,
                                          controller: _controllerPassword,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Poppins",
                                          ),
                                          cursorColor: Colors.white,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          decoration: InputDecoration(
                                            hintText: "Nueva contraseña",
                                            hintStyle: TextStyle(
                                              color: Colors.grey.shade400,
                                            ),
                                            border: InputBorder.none,
                                            suffixIcon: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword; // alterna visibilidad
                                                });
                                              },
                                              child: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color:
                                                    (_controllerPassword
                                                        .text
                                                        .isEmpty
                                                    ? Colors.transparent
                                                    : Colors.white70),
                                              ),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _controllerPassword.text = value;
                                              verificarPassword();
                                              verificarCoincidenciaLive();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (seguridadPasswordVis)
                                  Visibility(
                                    visible:
                                        (_controllerPassword.text.isNotEmpty
                                        ? true
                                        : false),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 33,
                                        vertical: 13,
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Seguridad",
                                                style: TextStyle(
                                                  color: Colors.white60,
                                                  fontFamily: "Poppins",
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                seguridadPasswordText,
                                                style: TextStyle(
                                                  color:
                                                      seguridadPasswordColorText,
                                                  fontFamily: "Poppins",
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 13),
                                          Container(
                                            width: 300,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color:
                                                  Color.fromRGBO(
                                                    150,
                                                    60,
                                                    0,
                                                    1,
                                                  ).withOpacity(
                                                    0.5,
                                                  ), // fondo más oscuro
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                            child: FractionallySizedBox(
                                              widthFactor:
                                                  seguridadPassword, // cuánto se llena
                                              alignment: Alignment
                                                  .centerLeft, // empieza desde la izquierda
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color.fromRGBO(
                                                        200,
                                                        90,
                                                        0,
                                                        1,
                                                      ),
                                                      Colors.orange.shade600,
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(13),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 13),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 33,
                                                width: 133,
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 0.1,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "Minimo 8 caracteres",
                                                    style: TextStyle(
                                                      color: Colors.white60,
                                                      fontFamily: "Poppins",
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 13),
                                              Container(
                                                height: 33,
                                                width: 93,
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 0.1,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "Mayusculas",
                                                    style: TextStyle(
                                                      color: Colors.white60,
                                                      fontFamily: "Poppins",
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 33,
                                                width: 83,
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 0.1,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "Números",
                                                    style: TextStyle(
                                                      color: Colors.white60,
                                                      fontFamily: "Poppins",
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 13),
                                              Container(
                                                height: 33,
                                                width: 93,
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 0.1,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "Caracteres",
                                                    style: TextStyle(
                                                      color: Colors.white60,
                                                      fontFamily: "Poppins",
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 23),
                                Container(
                                  width: 300,
                                  height: 63,
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(
                                      20,
                                      25,
                                      50,
                                      1,
                                    ), // fondo oscuro del TextField
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    children: [
                                      // Icono con fondo y borde redondeado
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        height: 36,
                                        width: 36,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromRGBO(33, 13, 243, 1),
                                              Colors.blue.shade600,
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.lock,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      // TextField
                                      Expanded(
                                        child: TextField(
                                          obscureText:
                                              _obscurePasswordConfirmar,
                                          controller:
                                              _controllerPasswordConfirmar,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Poppins",
                                          ),
                                          cursorColor: Colors.white,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          decoration: InputDecoration(
                                            hintText: "Confirmar contraseña",
                                            hintStyle: TextStyle(
                                              color: Colors.grey.shade400,
                                            ),
                                            border: InputBorder.none,
                                            suffixIcon: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _obscurePasswordConfirmar =
                                                      !_obscurePasswordConfirmar; // alterna visibilidad
                                                });
                                              },
                                              child: Icon(
                                                _obscurePasswordConfirmar
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color:
                                                    (_controllerPasswordConfirmar
                                                        .text
                                                        .isEmpty
                                                    ? Colors.transparent
                                                    : Colors.white70),
                                              ),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _controllerPasswordConfirmar
                                                      .text =
                                                  value;

                                              verificarCoincidenciaLive();

                                              if (value ==
                                                  _controllerPassword.text) {
                                                passwordCoinciden = true;
                                              } else {
                                                passwordCoinciden = false;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Visibility(
                                  visible: (passwordDistintas == true
                                      ? true
                                      : false),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 23),
                                    child: Center(
                                      child: Text(
                                        "Las Contraseñas No Coinciden",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontFamily: "Poppins",
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 33),
                                GestureDetector(
                                  child: Container(
                                    height: 63,
                                    width: 300,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors:
                                            (passwordCoinciden == true &&
                                                _controllerPassword
                                                    .text
                                                    .isNotEmpty &&
                                                _controllerPasswordConfirmar
                                                    .text
                                                    .isNotEmpty &&
                                                seguridadPasswordText !=
                                                    "Muy Débil"
                                            ? [
                                                Color.fromRGBO(1, 165, 113, 1),
                                                Colors.green.shade600,
                                              ]
                                            : [
                                                Colors.grey.shade700,
                                                Colors.grey.shade500,
                                              ]), // Registrarse,
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Restablecer contraseña",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Poppins",
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(width: 13),
                                        AnimatedBuilder(
                                          animation: _iconSiguienteController,
                                          builder: (context, child) {
                                            return Transform.translate(
                                              offset: Offset(
                                                _iconSiguienteAnimation.value,
                                                0,
                                              ),
                                              child: child,
                                            );
                                          },
                                          child: Icon(
                                            LucideIcons.checkCircle,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    verificarCoincidenciaPassword();
                                  },
                                ),
                                SizedBox(height: 23),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Widget passwordActualizada() {
    return Visibility(
      //visible: (changePasswordVis == true ? false : true),
      visible: true,
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              reverse: true,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 18, right: 18),
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
                    child: Center(
                      child: AnimatedSize(
                        duration: Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        child: Container(
                          //height: 713,
                          width: 360,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Color.fromRGBO(20, 25, 50, 1),
                                Color.fromRGBO(30, 43, 60, 1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              17,
                            ), // radio interno
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 13),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 18),
                                    child: GestureDetector(
                                      child: Container(
                                        height: 48,
                                        width: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color.fromRGBO(20, 25, 50, 1),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.x,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 20,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                registroPage(),
                                          ),
                                          (Route<dynamic> route) => false,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Center(
                                  child: LottieBuilder.asset(
                                    "assets/sendEmailChange.json",
                                    height: 183,
                                    width: 183,
                                    repeat: false,
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    "¡Email Enviado!",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "PoppinsBold",
                                      fontSize: 25,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 13),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 23,
                                    right: 23,
                                  ),
                                  child: Center(
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      "Se envio un correo al email verificado para modificar la contraseña.",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontFamily: "Poppins",
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 33),

                                SizedBox(height: 13),
                                GestureDetector(
                                  child: Container(
                                    height: 63,
                                    width: 300,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Iniciar Sesion",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Poppins",
                                            fontSize: 20,
                                          ),
                                        ),
                                        SizedBox(width: 13),
                                        AnimatedBuilder(
                                          animation: _iconSiguienteController,
                                          builder: (context, child) {
                                            return Transform.translate(
                                              offset: Offset(
                                                _iconSiguienteAnimation.value,
                                                0,
                                              ),
                                              child: child,
                                            );
                                          },
                                          child: Icon(
                                            LucideIcons.arrowRight,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => registroPage(),
                                      ),
                                      (Route<dynamic> route) => false,
                                    );
                                  },
                                ),
                                SizedBox(height: 23),
                              ],
                            ),
                          ),
                        ),
                      ),
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
