// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, avoid_print, deprecated_member_use, unused_import, unused_field

import 'dart:convert';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/cambiarPassword.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/registroUI.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

class restablecerPasswordPage extends StatefulWidget {
  @override
  State<restablecerPasswordPage> createState() =>
      _restablecerPasswordPageState();
}

class _restablecerPasswordPageState extends State<restablecerPasswordPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;
  late AnimationController _controllerContainerNaranjaMovimiento;
  late Animation<double> _animationContainerNaranjaMovimiento;
  late AnimationController _controllerIconMovimiento;
  late Animation<double> _animationIconMovimiento;
  late AnimationController _controllerColorContainerEmail;
  late Animation<Color?> _colorAnimationEmail;
  late AnimationController _controllerColorContainerReenviar;
  late Animation<Color?> _colorAnimationReenviar;
  late AnimationController _iconSiguienteController;
  late Animation<double> _iconSiguienteAnimation;

  final TextEditingController _controllerCode = TextEditingController();
  late VoidCallback _controllerCodeListener;

  final FocusNode _emailFocusNode = FocusNode();
  final TextEditingController _controllerEmail = TextEditingController();

  bool emailValido = false;

  bool ingresarEmailVis = true;
  bool verificarEmailVis = false;

  int code = 0;

  String textEmailInvalido = "Email invalido. Ingresa otra direccion.";

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

    _controllerContainerNaranjaMovimiento = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    _animationContainerNaranjaMovimiento = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_controllerContainerNaranjaMovimiento);
    _startFloatingNaranja();

    _controllerColorContainerEmail = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _colorAnimationEmail = ColorTween(
      begin: Color.fromRGBO(1, 165, 113, 1),
      end: Color.fromRGBO(0, 100, 50, 1),
    ).animate(_controllerColorContainerEmail);

    _controllerColorContainerReenviar = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _colorAnimationReenviar = ColorTween(
      begin: Color.fromRGBO(33, 13, 243, 1),
      end: Colors.blue.shade600,
    ).animate(_controllerColorContainerReenviar);

    // 🔹 Listener seguro para _controllerCode
    _controllerCodeListener = () {
      if (!mounted) return; // protege contra uso después de dispose
      // Removemos el listener inmediatamente antes de usar el controller
      _controllerCode.removeListener(_controllerCodeListener);
      verificarCodigo();
    };
    _controllerCode.addListener(_controllerCodeListener);

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
    _controllerColorContainerEmail.dispose();
    _controllerColorContainerReenviar.dispose();
    _iconSiguienteController.dispose();

    // TextEditingControllers & Listeners
    _controllerCode.removeListener(_controllerCodeListener);
    _controllerCode.dispose();
    _controllerEmail.dispose();

    // FocusNodes
    _emailFocusNode.dispose();

    super.dispose();
  }

  Future<void> generarCode() async {
    Random random = Random();
    setState(() {
      code = 10000 + random.nextInt(90000);
    });
    if (code > 0) {
      sendEmailVerificacion();
    }
  }

  Future sendEmailVerificacion() async {
    final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");
    const serviceId = "service_z3hbbeh";
    const templateId = "template_p29hdhe";
    const userId = "bc4FkZberPqwpjovF";
    final response = await http.post(
      url,
      headers: {"origin": "http:localhost", "Content-Type": "application/json"},
      body: json.encode({
        "service_id": serviceId,
        "template_id": templateId,
        "user_id": userId,
        "template_params": {
          "codigo": code,
          "sender_email": _controllerEmail.text,
        },
      }),
    );
    print("ENVIADO");
    return response.statusCode;
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

  Future<bool> emailYaRegistrado(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Usuarios")
          .where("Email", isEqualTo: email.trim())
          .get();

      if (snapshot.docs.isNotEmpty) {
        print("El email ya está registrado: ${snapshot.docs.first['Email']}");
        return true;
      } else {
        print("El email está disponible");
        return false;
      }
    } catch (e) {
      print("Error buscando el email: $e");
      return false;
    }
  }

  Future<void> verificarEmail() async {
    if (_controllerEmail.text.contains("@live") ||
        _controllerEmail.text.contains("@gmail") ||
        _controllerEmail.text.contains("@yahoo") ||
        _controllerEmail.text.contains("@outlook") ||
        _controllerEmail.text.contains("@icloud") ||
        _controllerEmail.text.contains("@protonmail") ||
        _controllerEmail.text.contains("@zoho") ||
        _controllerEmail.text.contains("@gmx") ||
        _controllerEmail.text.contains("@aol") ||
        _controllerEmail.text.contains("@yandex")) {
      if (_controllerEmail.text.contains(".com") ||
          _controllerEmail.text.contains(".ar") ||
          _controllerEmail.text.contains(".edu") ||
          _controllerEmail.text.contains(".org") ||
          _controllerEmail.text.contains(".es")) {
        bool existe = await emailYaRegistrado(_controllerEmail.text);

        if (existe) {
          setState(() {
            emailValido = true;
          });
          print("valido");
        } else {
          setState(() {
            emailValido = false;
            textEmailInvalido = "Email no registrado. Ingresa otra direccion.";
          });
          print("no valido");
        }
      } else {
        setState(() {
          emailValido = false;
          textEmailInvalido = "Email invalido. Ingresa otra direccion.";
        });
        print("no valido");
      }
    } else {
      setState(() {
        emailValido = false;
        textEmailInvalido = "Email invalido. Ingresa otra direccion.";
      });
      print("no valido");
    }
  }

  Future<void> guardarDatos(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emailUser', email);
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
      icon: Icon(LucideIcons.checkCircle, color: Colors.white),
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

  void showFlushbarVerificado(BuildContext context, String message) {
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
      icon: Icon(LucideIcons.checkCircle, color: Colors.white),
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

  void verificarCodigo() {
    if (!mounted) return;

    if (_controllerCode.text == code.toString()) {
      showFlushbarVerificado(context, "Email Verificado Correctamente");
      FocusScope.of(context).unfocus();
      guardarDatos(_controllerEmail.text);

      Future.delayed(Duration(seconds: 3), () {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => cambiarPasswordPage()),
          (Route<dynamic> route) => false,
        );
      });
    } else {
      print("Código Incorrecto");
      // 🔹 Volvemos a agregar el listener si fue incorrecto para que pueda volver a intentarlo
      if (mounted) _controllerCode.addListener(_controllerCodeListener);
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
            SizedBox(child: ingresarEmailPage()),
            SizedBox(child: verificarEmailPage()),
          ],
        ),
      ),
    );
  }

  Widget ingresarEmailPage() {
    return Visibility(
      visible: (ingresarEmailVis == true),
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              reverse: true,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(left: 18.sp, right: 18.sp),
                  child: Container(
                    padding: EdgeInsets.all(1.3.sp),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.sp),
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
                      child: Container(
                        height: 543.h,
                        width: 360.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Color.fromRGBO(20, 25, 50, 1),
                              Color.fromRGBO(30, 43, 60, 1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(17.sp),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(top: 13.sp),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 18.sp),
                                  child: GestureDetector(
                                    child: Container(
                                      height: 48.h,
                                      width: 48.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.fromRGBO(20, 25, 50, 1),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1.w,
                                        ),
                                      ),
                                      child: Icon(
                                        LucideIcons.arrowLeft,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 20.sp,
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
                                      Transform.scale(
                                        scale: 1 + curved * 0.7,
                                        child: Opacity(
                                          opacity: 0.15 - (curved * 0.15),
                                          child: Container(
                                            width: 100.h,
                                            height: 100.h,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              borderRadius:
                                                  BorderRadius.circular(20.sp),
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
                                            width: 93.w,
                                            height: 93.h,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color.fromRGBO(200, 90, 0, 1),
                                                  Colors.orange.shade600,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20.sp),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Color.fromRGBO(
                                                    200,
                                                    90,
                                                    0,
                                                    1,
                                                  ).withOpacity(0.7),
                                                  blurRadius: 20.sp,
                                                  spreadRadius: 3.sp,
                                                ),
                                              ],
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(7.sp),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 0.1.w,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        15.sp,
                                                      ),
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
                                                    LucideIcons.keyRound,
                                                    color: Colors.white,
                                                    size: 40.sp,
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
                              SizedBox(height: 30.h),
                              Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Recuperar contraseña",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "PoppinsBold",
                                      fontSize: 23.sp,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 13.h),
                              Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Ingresa tu email para recibir un código",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 23.h),
                              Container(
                                width: 300.w,
                                height: 63.h,
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(20, 25, 50, 1),
                                  borderRadius: BorderRadius.circular(15.sp),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                      ),
                                      height: 36.h,
                                      width: 36.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          10.sp,
                                        ),
                                        gradient: LinearGradient(
                                          colors: [
                                            Color.fromRGBO(200, 90, 0, 1),
                                            Colors.orange.shade600,
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.mail_outline,
                                        color: Colors.white,
                                        size: 20.sp,
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
                                            fontSize: 14.sp,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _controllerEmail.text = value;
                                          });
                                          verificarEmail();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Visibility(
                                visible:
                                    (_controllerEmail.text.isNotEmpty &&
                                    emailValido == false),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 33.sp,
                                    top: 13.sp,
                                    right: 33.sp,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.mailWarning,
                                        color: Colors.red,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          textEmailInvalido,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Poppins",
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 33.h),
                              GestureDetector(
                                child: Container(
                                  height: 63.h,
                                  width: 300.w,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors:
                                          (_controllerEmail.text.isNotEmpty &&
                                              emailValido
                                          ? [
                                              Color.fromRGBO(200, 90, 0, 1),
                                              Colors.orange.shade600,
                                            ]
                                          : [
                                              Colors.grey.shade700,
                                              Colors.grey.shade500,
                                            ]),
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(13.sp),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Enviar código",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Poppins",
                                            fontSize: 20.sp,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 13.w),
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
                                          size: 20.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  if (_controllerEmail.text.isNotEmpty) {
                                    if (emailValido) {
                                      setState(() {
                                        ingresarEmailVis = false;
                                        verificarEmailVis = true;
                                        FocusScope.of(context).unfocus();
                                        generarCode();
                                      });
                                    } else {
                                      showFlushbarError(
                                        context,
                                        "Ingresa un email valido.",
                                      );
                                    }
                                  }
                                },
                              ),
                              SizedBox(height: 13.h),
                              GestureDetector(
                                child: Container(
                                  height: 63.h,
                                  width: 300.w,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(13.sp),
                                  ),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Volver al inicio de sesión",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontFamily: "Poppins",
                                          fontSize: 17.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => registroPage(),
                                    ),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                              ),
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

  Widget verificarEmailPage() {
    return Visibility(
      visible: (ingresarEmailVis == true ? false : true),
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
                      child: Container(
                        height: 483,
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
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 18),
                                  child: GestureDetector(
                                    child: Container(
                                      height: 48,
                                      width: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.fromRGBO(20, 25, 50, 1),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        LucideIcons.arrowLeft,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 20,
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
                                                  Color.fromRGBO(200, 90, 0, 1),
                                                  Colors.orange.shade600,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Color.fromRGBO(
                                                    200,
                                                    90,
                                                    0,
                                                    1,
                                                  ).withOpacity(0.7),
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
                                                    LucideIcons.keyRound,
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
                                  "Código de verificación",
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
                                  "Ingresa el código enviado a tu email",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              SizedBox(height: 23),
                              PinCodeTextField(
                                autoDisposeControllers: false,
                                appContext: context,
                                controller: _controllerCode,
                                length: 5,
                                autoFocus: false,
                                keyboardType: TextInputType.number,
                                animationType: AnimationType.fade,
                                pinTheme: PinTheme(
                                  shape: PinCodeFieldShape.box,
                                  borderRadius: BorderRadius.circular(13),
                                  fieldHeight: 50,
                                  fieldWidth: 45,
                                  activeFillColor: Color.fromRGBO(
                                    200,
                                    90,
                                    0,
                                    1,
                                  ),
                                  inactiveFillColor: Color.fromRGBO(
                                    200,
                                    90,
                                    0,
                                    1,
                                  ).withOpacity(0.3),
                                  selectedFillColor: Colors.transparent,
                                  activeColor: Colors.transparent,
                                  inactiveColor: Colors.transparent,
                                  selectedColor: Color.fromRGBO(200, 90, 0, 1),
                                ),
                                enableActiveFill: true,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                              ),
                              SizedBox(height: 33),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 23),
                                child: IntrinsicWidth(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 0.1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize
                                          .min, //Que solo ocupe lo necesario
                                      children: [
                                        AnimatedBuilder(
                                          animation:
                                              _animationContainerNaranjaMovimiento,
                                          builder: (context, child) {
                                            return Transform.translate(
                                              offset: Offset(
                                                0,
                                                _animationContainerNaranjaMovimiento
                                                    .value,
                                              ),
                                              child: child,
                                            );
                                          },
                                          child: Container(
                                            height: 30,
                                            width: 30,
                                            decoration: BoxDecoration(
                                              color: Color.fromRGBO(
                                                200,
                                                90,
                                                0,
                                                1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                LucideIcons.badgeCheck,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          "Detectaremos automaticamente\nel codigo ingresado.",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.8,
                                            fontFamily: "Poppins",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
