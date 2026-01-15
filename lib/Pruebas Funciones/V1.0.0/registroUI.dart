// ignore_for_file: use_key_in_widget_constructors, camel_case_types, deprecated_member_use, prefer_final_fields, unused_field, sized_box_for_whitespace, avoid_print, use_build_context_synchronously, prefer_interpolation_to_compose_strings

import 'dart:math';
import 'dart:math' as math;

import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/cargaInicioSesion.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/presentacionUI.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/restablecerPassword.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/verificacionEmail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class registroPage extends StatefulWidget {
  @override
  State<registroPage> createState() => _registroPageState();
}

class _registroPageState extends State<registroPage>
    with TickerProviderStateMixin {
  final storage = FlutterSecureStorage();
  final auth = FirebaseAuth.instance;
  final localAuth = LocalAuthentication();

  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;

  late AnimationController _controllerIconMovimiento;
  late Animation<double> _animationIconMovimiento;

  late AnimationController _iconAccederController;
  late Animation<double> _iconAccederAnimation;

  late AnimationController _arrowController;
  late Animation<double> _arrowAnimation;

  late AnimationController _controllerInsert;
  late Animation<Offset> _offsetAnimationInsert;

  late AnimationController _controller;

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerName = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;

  bool isLoginSelected = true;

  bool emailValido = false;

  bool inicioSesionVis = true;
  bool cargaVis = false;

  bool seguridadPasswordVis = false;

  double seguridadPassword = 0.0;

  String seguridadPasswordText = "Muy Débil";

  Color seguridadPasswordColorText = Colors.red;

  bool recordarme = false;

  String textEmailInvalido = "Email invalido. Ingresa otra direccion.";

  Future<void> verificarPassword() async {
    if (isLoginSelected != true) {
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
  }

  Future<bool> emailYaRegistrado(String email) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("Usuarios")
        .where("Email", isEqualTo: email.trim())
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> verificarEmail() async {
    String email = _controllerEmail.text.trim();
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.(com|ar|edu|org|es)$');

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        emailValido = false;
        textEmailInvalido = "Email inválido. Ingresa otra dirección.";
      });
      return;
    }

    bool existe = await emailYaRegistrado(email);

    setState(() {
      if (isLoginSelected) {
        emailValido = existe;
        textEmailInvalido = existe
            ? ""
            : "Email no registrado. Ingresa otra dirección.";
      } else {
        emailValido = !existe;
        textEmailInvalido = existe
            ? "Email ya registrado. Ingresa otra dirección."
            : "";
      }
    });
  }

  @override
  void initState() {
    super.initState();

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

    _arrowController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _arrowAnimation = Tween<double>(begin: 0, end: -math.pi / 1.57).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );

    _controllerInsert = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _offsetAnimationInsert =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controllerInsert,
            curve: Curves.easeOutCubic,
          ),
        );

    // dispara la animación al montar la pantalla
    _controller.forward();

    // Listeners seguros para los FocusNode
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
  }

  void _onEmailFocusChange() {
    if (!_emailFocusNode.hasFocus) {
      if (mounted) verificarEmail();
    }
  }

  void _onPasswordFocusChange() {
    if (mounted) {
      setState(() {
        seguridadPasswordVis = _passwordFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    // Animaciones
    _controller.dispose();
    _controllerContainerMovimiento.dispose();
    _controllerIconMovimiento.dispose();
    _arrowController.dispose();
    _iconAccederController.dispose();
    _controllerInsert.dispose();

    // Remover listeners y disposar FocusNodes
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    // TextEditingControllers
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    _controllerName.dispose();

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

  void showFlushbar(BuildContext context, String message) {
    Vibration.vibrate(duration: 10);
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

  void irVerificarEmail() {
    Future.delayed(Duration(milliseconds: 800), () {
      setState(() {
        inicioSesionVis = false;
        cargaVis = true;
      });
      Future.delayed(Duration(seconds: 3), () {
        Vibration.vibrate(duration: 15);
        Navigator.pushAndRemoveUntil(
          context,
          PageTransition(
            type: PageTransitionType.leftToRight,
            child: verificacionEmailPage(),
          ),
          (Route<dynamic> route) => false,
        );
      });
    });
  }

  Future<void> guardarDatos(String code, String name, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombreUser', code);
    await prefs.setString('nameUser', name);
    await prefs.setString('passUser', password);
  }

  Future<void> registrarUsuario() async {
    Random random = Random();
    int code = 10000 + random.nextInt(90000);

    try {
      // Crear usuario en Firebase Auth
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _controllerEmail.text.trim(),
        password: _controllerPassword.text.trim(),
      );
      print("Usuario Temporal Creado");

      // Guardar datos localmente
      guardarDatos(
        code.toString(),
        _controllerName.text,
        _controllerPassword.text,
      );
      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('TempUsers')
          .doc(code.toString())
          .set({
            'nombre': _controllerName.text.trim(),
            'email': _controllerEmail.text.trim(),
            'estado': "email",
          });

      irVerificarEmail();

      print("Documento TempUsers creado con código: $code");
    } on FirebaseAuthException catch (e) {
      print("Error Auth: ${e.message}");
      showFlushbar(context, "Error al registrar usuario. Intenta mas tarde.");
    } on FirebaseException catch (e) {
      print("Error Firestore: ${e.message}");
      showFlushbar(
        context,
        "Error al conectar con la base de datos. Intenta mas tarde.",
      );
    } catch (e) {
      print("Error general: $e");
      showFlushbar(context, "Error al crear la cuenta. Intenta mas tarde.");
    }
  }

  Future<void> iniciarSesion() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _controllerEmail.text.trim(),
        password: _controllerPassword.text.trim(),
      );

      final user = credential.user; // ⚡ usuario recién autenticado

      if (user == null) {
        print("Error: usuario nulo después de iniciar sesión");
        return;
      }

      print("Sesión Iniciada");

      // Guardar datos localmente
      guardarDatos(user.uid, "", _controllerPassword.text);

      // Guardamos el UID de forma segura para logins futuros con biometría
      await storage.write(key: 'uidUser', value: user.uid);

      // Actualizar Firestore
      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user.uid)
          .update({"Recordarme": recordarme});

      Vibration.vibrate(duration: 15);

      // Navegar a la página siguiente
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          type: PageTransitionType.leftToRight,
          child: cargaInicioSesionPage(),
        ),
        (Route<dynamic> route) => false, // elimina todo el stack
      );
    } on FirebaseAuthException catch (e) {
      showFlushbar(context, "No existe una cuenta con esas credenciales.");
      print("Error: ${e.message}");
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
        appBar: AppBar(
          toolbarHeight: 13,
          backgroundColor: Color.fromRGBO(3, 5, 25, 1),
        ),
        body: Stack(
          children: [
            SizedBox(child: ingresar()),
            SizedBox(child: carga()),
          ],
        ),
      ),
    );
  }

  Widget ingresar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Visibility(
      visible: inicioSesionVis,
      child: Stack(
        children: [
          SingleChildScrollView(
            reverse: true,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: w(18), right: w(18)),
                child: Container(
                  padding: EdgeInsets.all(h(1.3)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(sp(20)),
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
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
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
                        borderRadius: BorderRadius.circular(sp(17)),
                      ),
                      child: Column(
                        children: [
                          // Botón cerrar
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: w(18),
                                top: h(18),
                              ),
                              child: GestureDetector(
                                child: Container(
                                  height: h(48),
                                  width: w(48),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.fromRGBO(20, 25, 50, 1),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: w(1),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white.withOpacity(0.7),
                                    size: sp(20),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => presentacionPage(),
                                    ),
                                  );
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          ),

                          // Animación del avatar
                          AnimatedBuilder(
                            animation: _controllerContainerMovimiento,
                            builder: (context, child) {
                              final curved = Curves.easeInOut.transform(
                                _controllerContainerMovimiento.value,
                              );
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.scale(
                                    scale: 1 + curved * 0.7,
                                    child: Opacity(
                                      opacity: 0.15 - (curved * 0.15),
                                      child: Container(
                                        width: h(120),
                                        height: h(120),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          borderRadius: BorderRadius.circular(
                                            sp(20),
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromRGBO(
                                                1,
                                                165,
                                                113,
                                                1,
                                              ).withOpacity(0.1),
                                              Colors.green.shade600.withOpacity(
                                                0.1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 1 + curved * 0.05,
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
                                          borderRadius: BorderRadius.circular(
                                            sp(20),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(
                                                0.7,
                                              ),
                                              blurRadius: sp(20),
                                              spreadRadius: sp(3),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(sp(7)),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 0.1.w,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(sp(15)),
                                            ),
                                            child: Icon(
                                              LucideIcons.user,
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

                          SizedBox(height: h(33)),

                          // Título
                          Center(
                            child: Text(
                              textAlign: TextAlign.center,
                              isLoginSelected
                                  ? "Bienvenido De Vuelta"
                                  : "Crear Cuenta",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "PoppinsBold",
                                fontSize: sp(28),
                              ),
                            ),
                          ),
                          SizedBox(height: h(8)),
                          Center(
                            child: Text(
                              textAlign: TextAlign.center,
                              isLoginSelected
                                  ? "Accede a tu billetera virtual"
                                  : "Únete a la revolución financiera",
                              style: TextStyle(
                                color: Colors.white60,
                                fontFamily: "Poppins",
                                fontSize: sp(18),
                              ),
                            ),
                          ),

                          SizedBox(height: h(23)),

                          // Switch login / registro
                          Center(
                            child: Container(
                              width: w(280),
                              height: h(63),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 0.1.w,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(sp(5)),
                                    child: AnimatedAlign(
                                      alignment: isLoginSelected
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        width: w(140),
                                        height: h(83),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            sp(13),
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromRGBO(1, 165, 113, 1),
                                              Colors.green.shade600,
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              isLoginSelected = true;
                                              _controllerEmail.clear();
                                              _controllerPassword.clear();
                                              _controllerName.clear();
                                              FocusScope.of(context).unfocus();
                                            });
                                          },
                                          child: Center(
                                            child: AnimatedDefaultTextStyle(
                                              duration: Duration(
                                                milliseconds: 300,
                                              ),
                                              style: TextStyle(
                                                color: isLoginSelected
                                                    ? Colors.white
                                                    : Colors.white60,
                                                fontSize: sp(17),
                                                fontFamily: "Poppins",
                                                fontWeight: FontWeight.w600,
                                              ),
                                              child: Text("Ingresar"),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              isLoginSelected = false;
                                              _controllerEmail.clear();
                                              _controllerPassword.clear();
                                              _controllerName.clear();
                                              FocusScope.of(context).unfocus();
                                            });
                                          },
                                          child: Center(
                                            child: AnimatedDefaultTextStyle(
                                              duration: Duration(
                                                milliseconds: 300,
                                              ),
                                              style: TextStyle(
                                                color: isLoginSelected
                                                    ? Colors.white60
                                                    : Colors.white,
                                                fontSize: sp(17),
                                                fontFamily: "Poppins",
                                                fontWeight: FontWeight.w600,
                                              ),
                                              child: Text("Registrarse"),
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

                          SizedBox(height: h(23)),

                          // Campo Nombre
                          Visibility(
                            visible: !isLoginSelected,
                            child: Column(
                              children: [
                                SizedBox(height: h(33)),
                                Container(
                                  width: w(300),
                                  height: h(63),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(20, 25, 50, 1),
                                    borderRadius: BorderRadius.circular(sp(15)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: w(12),
                                        ),
                                        height: h(36),
                                        width: w(36),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            sp(10),
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromRGBO(200, 90, 0, 1),
                                              Colors.orange.shade600,
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: sp(20),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          keyboardType: TextInputType.text,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[a-zA-Z áéíóúÁÉÍÓÚñÑ]'),
                                            ),
                                          ],
                                          textCapitalization:
                                              TextCapitalization.words,
                                          controller: _controllerName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Poppins",
                                          ),
                                          cursorColor: Colors.white,
                                          decoration: InputDecoration(
                                            hintText: "Nombre Completo",
                                            hintStyle: TextStyle(
                                              color: Colors.grey.shade400,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _controllerName.text = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: h(23)),

                          // Campo Email
                          Container(
                            width: w(300),
                            height: h(63),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(20, 25, 50, 1),
                              borderRadius: BorderRadius.circular(sp(15)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: w(12),
                                  ),
                                  height: h(36),
                                  width: w(36),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(sp(10)),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromRGBO(1, 165, 113, 1),
                                        Colors.green.shade600,
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.mail_outline,
                                    color: Colors.white,
                                    size: sp(20),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    focusNode: _emailFocusNode,
                                    controller: _controllerEmail,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Poppins",
                                    ),
                                    cursorColor: Colors.white,
                                    decoration: InputDecoration(
                                      hintText: "Correo electrónico",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _controllerEmail.text = value;
                                        verificarEmail();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /*
                        // Validación email
                        Visibility(
                          visible: _controllerEmail.text.isNotEmpty && !emailValido,
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: w(33), top: h(13), right: w(33)),
                            child: Row(
                              children: [
                                Icon(LucideIcons.mailWarning,
                                    color: Colors.red, size: sp(18)),
                                SizedBox(width: w(8)),
                                Text(
                                  textEmailInvalido,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Poppins",
                                      fontSize: sp(13)),
                                ),
                              ],
                            ),
                          ),
                        ),

                        */
                          SizedBox(height: h(23)),

                          // Campo Contraseña
                          Container(
                            width: w(300),
                            height: h(63),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(20, 25, 50, 1),
                              borderRadius: BorderRadius.circular(sp(15)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: w(12),
                                  ),
                                  height: h(36),
                                  width: w(36),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(sp(10)),
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
                                    size: sp(20),
                                  ),
                                ),
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
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration: InputDecoration(
                                      hintText: "Contraseña",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                      border: InputBorder.none,
                                      suffixIcon: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        child: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color:
                                              _controllerPassword.text.isEmpty
                                              ? Colors.transparent
                                              : Colors.white70,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _controllerPassword.text = value;
                                        verificarPassword();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (seguridadPasswordVis)
                            Visibility(
                              visible: (isLoginSelected == true
                                  ? false
                                  : _controllerPassword.text.isNotEmpty
                                  ? true
                                  : false),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: w(33),
                                  vertical: h(13),
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
                                            fontSize: sp(15),
                                          ),
                                        ),
                                        Text(
                                          seguridadPasswordText,
                                          style: TextStyle(
                                            color: seguridadPasswordColorText,
                                            fontFamily: "Poppins",
                                            fontSize: sp(15),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: h(13)),
                                    Container(
                                      width: w(300),
                                      height: h(8),
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(
                                          150,
                                          60,
                                          0,
                                          1,
                                        ).withOpacity(0.5), // fondo más oscuro
                                        borderRadius: BorderRadius.circular(
                                          sp(13),
                                        ),
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
                                                Color.fromRGBO(200, 90, 0, 1),
                                                Colors.orange.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              sp(13),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h(13)),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: h(33),
                                          width: w(133),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              sp(10),
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: w(0.1),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Minimo 8 caracteres",
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontFamily: "Poppins",
                                                fontSize: sp(11),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: w(13)),
                                        Container(
                                          height: h(33),
                                          width: w(93),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              sp(10),
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: w(0.1),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Mayusculas",
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontFamily: "Poppins",
                                                fontSize: sp(13),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: h(8)),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: h(33),
                                          width: w(83),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              sp(10),
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: w(0.1),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Números",
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontFamily: "Poppins",
                                                fontSize: sp(13),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: w(13)),
                                        Container(
                                          height: h(33),
                                          width: w(93),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              sp(10),
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: w(0.1),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Caracteres",
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontFamily: "Poppins",
                                                fontSize: sp(13),
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
                          SizedBox(
                            height: (isLoginSelected == true
                                ? (_controllerEmail.text.isNotEmpty == true &&
                                          _controllerPassword.text.isNotEmpty ==
                                              true
                                      ? (emailValido == true
                                            ? (_controllerPassword
                                                          .text
                                                          .length >=
                                                      8
                                                  ? 33
                                                  : 0)
                                            : 0)
                                      : 0)
                                : 0),
                          ),
                          Visibility(
                            visible: (isLoginSelected == true
                                ? (_controllerEmail.text.isNotEmpty == true &&
                                          _controllerPassword.text.isNotEmpty ==
                                              true
                                      ? (emailValido == true
                                            ? (_controllerPassword
                                                          .text
                                                          .length >=
                                                      8
                                                  ? true
                                                  : false)
                                            : false)
                                      : false)
                                : false),
                            child: Container(
                              height: h(90),
                              width: w(300), // ancho fijo proporcional
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(20, 25, 50, 1),
                                borderRadius: BorderRadius.circular(sp(13)),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(sp(13)),
                                    child: Container(
                                      height: h(43),
                                      width: w(43),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color.fromRGBO(165, 53, 253, 1),
                                            Colors.purple.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          sp(13),
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          LucideIcons.clock3,
                                          color: Colors.white,
                                          size: sp(23),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: w(10)),
                                  // FittedBox adapta el tamaño del texto al espacio disponible
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            "Recordar sesión",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: "Poppins",
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: h(5)),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            "Mantener sesión activa\nal cerrar la app.",
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontFamily: "Poppins",
                                            ),
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: w(8)),
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Switch(
                                      thumbColor:
                                          MaterialStateProperty.resolveWith<
                                            Color
                                          >((states) {
                                            if (states.contains(
                                              MaterialState.selected,
                                            )) {
                                              return Colors.purple;
                                            }
                                            return Colors.white;
                                          }),
                                      trackColor:
                                          MaterialStateProperty.resolveWith<
                                            Color
                                          >((states) {
                                            if (states.contains(
                                              MaterialState.selected,
                                            )) {
                                              return Colors.purple.shade200;
                                            }
                                            return Colors.white60;
                                          }),
                                      value: recordarme,
                                      onChanged: (value) {
                                        setState(() {
                                          recordarme = value;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: w(12)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: (isLoginSelected == true
                                ? (_controllerEmail.text.isNotEmpty == true &&
                                          _controllerPassword.text.isNotEmpty ==
                                              true
                                      ? (emailValido == true
                                            ? (_controllerPassword
                                                          .text
                                                          .length >=
                                                      8
                                                  ? ((recordarme == true
                                                        ? 23
                                                        : 0))
                                                  : 0)
                                            : 0)
                                      : 0)
                                : 0),
                          ),
                          Visibility(
                            visible: (isLoginSelected == true
                                ? (_controllerEmail.text.isNotEmpty == true &&
                                          _controllerPassword.text.isNotEmpty ==
                                              true
                                      ? (emailValido == true
                                            ? (_controllerPassword
                                                          .text
                                                          .length >=
                                                      8
                                                  ? (recordarme == true
                                                        ? true
                                                        : false)
                                                  : false)
                                            : false)
                                      : false)
                                : false),
                            child: Container(
                              width: w(300),
                              padding: EdgeInsets.all(sp(16)),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2A2451,
                                ), // fondo violeta oscuro
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors
                                      .purple
                                      .shade300, // borde violeta suave
                                  width: w(1),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.purple.shade300,
                                  ),
                                  SizedBox(width: w(13)),
                                  Expanded(
                                    child: Text(
                                      "Tu sesión permanecerá activa hasta que decidas cerrarla manualmente desde configuración.",
                                      style: TextStyle(
                                        color: Colors.purple.shade100,
                                        fontSize: sp(13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: h(23)),
                          GestureDetector(
                            child: Container(
                              height: h(63),
                              width: w(300),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isLoginSelected
                                      ? (_controllerEmail.text.isNotEmpty &&
                                                _controllerPassword
                                                    .text
                                                    .isNotEmpty &&
                                                emailValido == true &&
                                                _controllerPassword
                                                        .text
                                                        .length >=
                                                    8
                                            ? [
                                                Color.fromRGBO(1, 165, 113, 1),
                                                Colors.green.shade600,
                                              ] // Ambos campos completos
                                            : [
                                                Colors.grey.shade700,
                                                Colors.grey.shade500,
                                              ]) // Algún campo vacío
                                      : (_controllerName.text.isNotEmpty &&
                                                emailValido == true &&
                                                seguridadPasswordText !=
                                                    "Muy Débil" &&
                                                _controllerPassword
                                                    .text
                                                    .isNotEmpty &&
                                                _controllerEmail.text.isNotEmpty
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
                                borderRadius: BorderRadius.circular(sp(13)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (isLoginSelected == true
                                        ? "Ingresar"
                                        : "Continuar"),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Poppins",
                                      fontSize: sp(20),
                                    ),
                                  ),
                                  SizedBox(width: w(13)),
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
                                      (isLoginSelected == true
                                          ? LucideIcons.logIn
                                          : LucideIcons.arrowRight),
                                      color: Colors.white,
                                      size: sp(20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              isLoginSelected
                                  ? (_controllerEmail.text.isNotEmpty &&
                                            _controllerPassword.text.isNotEmpty
                                        ? {
                                            iniciarSesion(),
                                            FocusScope.of(context).unfocus(),
                                          }
                                        : showFlushbar(
                                            context,
                                            "Completa todos los campos",
                                          )) // Ingresar
                                  : (_controllerName.text.isNotEmpty &&
                                            _controllerPassword
                                                .text
                                                .isNotEmpty &&
                                            _controllerEmail.text.isNotEmpty
                                        ? (emailValido == true &&
                                                  seguridadPasswordText !=
                                                      "Muy Débil"
                                              ? {
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus(),
                                                  registrarUsuario(),
                                                }
                                              : showFlushbar(
                                                  context,
                                                  "Email o Contraseña invalidos",
                                                ))
                                        : showFlushbar(
                                            context,
                                            "Completa todos los campos",
                                          )); // Registrarse
                            },
                          ),
                          SizedBox(height: h(23)),
                          Visibility(
                            visible: (isLoginSelected == true ? true : false),
                            child: GestureDetector(
                              child: Container(
                                height: h(43),
                                width: w(300),
                                color: Colors.transparent,
                                child: Center(
                                  child: Container(
                                    width: w(300),
                                    height: h(43),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(
                                        20,
                                        25,
                                        50,
                                        1,
                                      ), // fondo oscuro del TextField
                                      borderRadius: BorderRadius.circular(
                                        sp(15),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.keySquare,
                                          color: Color.fromRGBO(1, 165, 113, 1),
                                          size: sp(18),
                                        ),
                                        SizedBox(width: w(13)),
                                        Text(
                                          "¿Olvidaste tu contraseña?",
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontFamily: "Poppins",
                                            fontSize: sp(18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        restablecerPasswordPage(),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              },
                            ),
                          ),
                          SizedBox(height: h(23)),
                        ],
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

  Widget carga() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: cargaVis,
      child: Stack(
        children: [
          SingleChildScrollView(
            reverse: true,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: sp(18), right: sp(18)),
                child: Container(
                  padding: EdgeInsets.all(sp(1.3)),
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
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
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
                        borderRadius: BorderRadius.circular(sp(18)),
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
                                  Transform.scale(
                                    scale: 1 + curved * 0.7,
                                    child: Opacity(
                                      opacity: 0.15 - (curved * 0.15),
                                      child: Container(
                                        width: 120.w,
                                        height: 120.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(
                                                0.7,
                                              ),
                                              blurRadius: sp(20),
                                              spreadRadius: sp(3),
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
                                              borderRadius:
                                                  BorderRadius.circular(15),
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
                                                LucideIcons.userCheck,
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Autenticando",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "PoppinsBold",
                                  fontSize: sp(30),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: h(8)),
                          Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Verificando credenciales",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(20),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: h(33)),
                          Container(
                            height: h(58),
                            width: w(213),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(30, 43, 63, 1),
                              borderRadius: BorderRadius.circular(sp(10)),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: h(23),
                                  width: w(23),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromRGBO(1, 165, 113, 1),
                                    ),
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                                SizedBox(width: w(23)),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Procesando datos",
                                    style: TextStyle(
                                      color: Color.fromRGBO(1, 165, 113, 1),
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: h(53)),
                          Container(
                            height: h(48),
                            width: w(223),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.1),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: sp(13)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: h(23),
                                    width: w(23),
                                    child: Icon(
                                      LucideIcons.checkCircle,
                                      color: Color.fromRGBO(1, 165, 113, 1),
                                    ),
                                  ),
                                  SizedBox(width: w(23)),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "Cuenta Creada",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "Poppins",
                                        fontSize: sp(15),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: h(23)),
                          Container(
                            height: h(48),
                            width: w(223),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.1),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: sp(13)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: h(23),
                                    width: w(23),
                                    child: Icon(
                                      LucideIcons.checkCircle,
                                      color: Color.fromRGBO(1, 165, 113, 1),
                                    ),
                                  ),
                                  SizedBox(width: w(23)),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 150),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Contraseña Asegurada",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "Poppins",
                                          fontSize: sp(15),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: h(23)),
                          Container(
                            height: h(48),
                            width: w(223),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.1),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: w(13)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: h(18),
                                    width: w(18),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromRGBO(33, 13, 243, 1),
                                      ),
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                  SizedBox(width: w(13)),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 160),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Preparando Verificacion",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "Poppins",
                                          fontSize: sp(15),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: h(53)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(sp(10)),
                            child: Container(
                              width: w(300),
                              child: LinearProgressIndicator(
                                minHeight: 5,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.fromRGBO(1, 165, 113, 1),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: h(23)),
                          Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Esto puede tomar unos segundos",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: h(53)),
                        ],
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
