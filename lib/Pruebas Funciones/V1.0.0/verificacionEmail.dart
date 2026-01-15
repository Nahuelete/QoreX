// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, deprecated_member_use, unused_field, unused_element, avoid_print, use_build_context_synchronously, unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/presentacionUI.dart';
import 'package:bluetooth/UI/ingreso.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/registroUI.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/avisoVerificacion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class verificacionEmailPage extends StatefulWidget {
  @override
  State<verificacionEmailPage> createState() => _verificacionEmailPageState();
}

class _verificacionEmailPageState extends State<verificacionEmailPage>
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

  final TextEditingController _controllerCode = TextEditingController();
  late VoidCallback _controllerCodeListener;

  int _secondsRemaining = 60;
  Timer? _timer;

  String codeUser = "";
  String emailUser = "";
  String nameUser = "";

  Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString('nombreUser') == null) {
      codeUser = "";
      print("CODE: Sin Nombre");
    } else {
      codeUser = prefs.getString('nombreUser')!;
      print("CODE: $codeUser");
    }

    if (prefs.getString('nameUser') == null) {
      nameUser = "";
      print("Nombre: Sin Nombre");
    } else {
      nameUser = prefs.getString('nameUser')!;
      print("Nombre: $nameUser");
    }
  }

  Future<void> obtenerDatosTemp() async {
    await leerShared();

    FirebaseFirestore.instance
        .collection('TempUsers') // colección principal
        .doc(codeUser) // documento del usuario
        .snapshots() // escuchar en tiempo real
        .listen((docSnapshot) {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              emailUser = data['email'];
            });

            sendEmailCode();
          } else {
            print('El documento no existe');
          }
        });
  }

  @override
  void initState() {
    super.initState();

    obtenerDatosTemp();

    startCountdown();

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
  }

  @override
  void dispose() {
    _timer?.cancel();

    // Animations
    _controller.dispose();
    _controllerContainerMovimiento.dispose();
    _controllerContainerNaranjaMovimiento.dispose();
    _controllerIconMovimiento.dispose();
    _controllerColorContainerEmail.dispose();
    _controllerColorContainerReenviar.dispose();

    // Listener seguro
    _controllerCode.removeListener(_controllerCodeListener);
    _controllerCode.dispose();

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

  void startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void showFlushbar(BuildContext context, String message) {
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

    if (_controllerCode.text == codeUser) {
      _timer?.cancel();

      showFlushbar(context, "Email Verificado Correctamente");
      FocusScope.of(context).unfocus();

      Future.delayed(Duration(seconds: 3), () {
        if (!mounted) return;
        FirebaseFirestore.instance
            .collection("TempUsers") // Ej: 'TempUsers'
            .doc(codeUser) // ID del documento
            .update({"estado": "dni"});

        Vibration.vibrate(duration: 15);

        Navigator.pushAndRemoveUntil(
          context,
          PageTransition(
            type: PageTransitionType.leftToRight, // 👉 derecha a izquierda
            child: verificacionDniPage(),
          ),
          (Route<dynamic> route) => false, // elimina todo el stack
        );
      });
    } else {
      //print("Código Incorrecto");
      // 🔹 Volvemos a agregar el listener si fue incorrecto para que pueda volver a intentarlo
      if (mounted) _controllerCode.addListener(_controllerCodeListener);
    }
  }

  Future sendEmailCode() async {
    final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");
    const serviceId = "service_z3hbbeh";
    const templateId = "template_1i3c9qh";
    const userId = "bc4FkZberPqwpjovF";
    final response = await http.post(
      url,
      headers: {"origin": "http:localhost", "Content-Type": "application/json"},
      body: json.encode({
        "service_id": serviceId,
        "template_id": templateId,
        "user_id": userId,
        "template_params": {
          "name": nameUser,
          "codigo": codeUser,
          "sender_email": emailUser,
        },
      }),
    );
    print("ENVIADO");
    return response.statusCode;
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
        body: Stack(children: [SizedBox(child: verificationEmail())]),
      ),
    );
  }

  Widget verificationEmail() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) => size / 430 * screenWidth;

    return Stack(
      children: [
        SingleChildScrollView(
          reverse: true,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: w(18), right: w(18)),
              child: Container(
                padding: EdgeInsets.all(sp(1.3)), // grosor del borde degradado
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: w(18), top: h(18)),
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
                                    LucideIcons.arrowLeft,
                                    color: Colors.white.withOpacity(0.7),
                                    size: sp(20),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ingresoPage(),
                                    ),
                                  );
                                  setState(() {
                                    _timer?.cancel();
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          ),
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
                                  setState(() {
                                    _timer?.cancel();
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          ),
                        ],
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
                                    width: 120,
                                    height: 120,
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
                                      padding: EdgeInsets.all(7),
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
                                            LucideIcons.mailQuestion,
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
                        child: Text(
                          textAlign: TextAlign.center,
                          "Verifica tu Email",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "PoppinsBold",
                            fontSize: sp(30),
                          ),
                        ),
                      ),
                      SizedBox(height: h(33)),
                      Center(
                        child: Text(
                          textAlign: TextAlign.center,
                          "Ingresa el codigo de 5 digitos que te enviamos a tu correo.",
                          style: TextStyle(
                            color: Colors.white60,
                            fontFamily: "Poppins",
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(height: h(33)),
                      IntrinsicWidth(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w(13),
                            vertical: h(8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: w(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min, //Que solo ocupe lo necesario
                            children: [
                              AnimatedBuilder(
                                animation: _colorAnimationEmail,
                                builder: (context, child) {
                                  return Container(
                                    height: h(10),
                                    width: w(10),
                                    decoration: BoxDecoration(
                                      color: _colorAnimationEmail.value,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: w(10)),
                              Text(
                                emailUser,
                                style: TextStyle(
                                  color: Color.fromRGBO(1, 165, 113, 1),
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: h(43)),
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
                          fieldHeight: h(50),
                          fieldWidth: w(45),
                          activeFillColor: Color.fromRGBO(1, 165, 113, 1),
                          inactiveFillColor: Color.fromRGBO(
                            1,
                            165,
                            113,
                            1,
                          ).withOpacity(0.3),
                          selectedFillColor: Colors.transparent,
                          activeColor: Colors.transparent,
                          inactiveColor: Colors.transparent,
                          selectedColor: Color.fromRGBO(1, 165, 113, 1),
                        ),
                        enableActiveFill: true,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      ),
                      SizedBox(height: h(33)),
                      IntrinsicWidth(
                        child: GestureDetector(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: w(13),
                              vertical: h(8),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize
                                  .min, //Que solo ocupe lo necesario
                              children: [
                                AnimatedBuilder(
                                  animation: _colorAnimationReenviar,
                                  builder: (context, child) {
                                    return Container(
                                      height: h(10),
                                      width: w(10),
                                      decoration: BoxDecoration(
                                        color: _colorAnimationReenviar.value,
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(width: w(10)),
                                Text(
                                  _secondsRemaining > 0
                                      ? "Reenviar código en $_secondsRemaining s"
                                      : "Reenviar Código",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: sp(15),
                                    fontFamily: "Poppins",
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            if (_secondsRemaining < 1) {
                              Vibration.vibrate(duration: 5);
                              setState(() {
                                _secondsRemaining = 60;
                                startCountdown();
                                sendEmailCode();
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(height: h(133)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w(23)),
                        child: IntrinsicWidth(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: w(13),
                              vertical: h(8),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.1),
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
                                    height: h(30),
                                    width: w(30),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(200, 90, 0, 1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        LucideIcons.badgeCheck,
                                        color: Colors.white,
                                        size: sp(18),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Detectaremos automaticamente\nel codigo ingresado.",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: sp(16),
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
