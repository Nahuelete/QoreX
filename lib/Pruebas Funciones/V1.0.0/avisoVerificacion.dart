// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, deprecated_member_use

import 'dart:math';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/escanearDni.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/registroUI.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';

class verificacionDniPage extends StatefulWidget {
  @override
  State<verificacionDniPage> createState() => _verificacionDniPageState();
}

class _verificacionDniPageState extends State<verificacionDniPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;

  late AnimationController _controllerIconMovimiento;
  late Animation<double> _animationIconMovimiento;

  late AnimationController _iconAccederController;
  late Animation<double> _iconAccederAnimation;

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
        body: Stack(children: [SizedBox(child: verificationDni())]),
      ),
    );
  }

  Widget verificationDni() {
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
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: w(18), top: h(18)),
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
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: registroPage(),
                                ),
                              );
                              FocusScope.of(context).unfocus();
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
                                            Icons.security,
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
                          "Verificación de Identidad",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "PoppinsBold",
                            fontSize: sp(33),
                          ),
                        ),
                      ),
                      SizedBox(height: h(33)),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(23)),
                          child: Text(
                            textAlign: TextAlign.center,
                            "Para tu seguridad, necesitamos verificar tu identidad. Este proceso es rápido y seguro.",
                            style: TextStyle(
                              color: Colors.white60,
                              fontFamily: "Poppins",
                              fontSize: sp(18),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h(43)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w(23)),
                        child: Container(
                          height: h(93),
                          width: w(280),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: w(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: w(13),
                                ),
                                child: Container(
                                  height: h(43),
                                  width: w(43),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromRGBO(1, 165, 113, 1),
                                        Colors.green.shade600,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: AnimatedBuilder(
                                      animation: _animationIconMovimiento,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            _animationIconMovimiento.value,
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: Icon(
                                        LucideIcons.creditCard,
                                        color: Colors.white,
                                        size: sp(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: w(10)),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "1. Escanea tu DNI",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: sp(18),
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Documento de identidad\nválido.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: sp(15),
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: h(23)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w(23)),
                        child: Container(
                          height: h(93),
                          width: w(280),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: w(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: w(13),
                                ),
                                child: Container(
                                  height: h(43),
                                  width: w(43),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromRGBO(33, 13, 243, 1),
                                        Colors.blue,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: AnimatedBuilder(
                                      animation: _animationIconMovimiento,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            _animationIconMovimiento.value,
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: Icon(
                                        LucideIcons.scanFace,
                                        color: Colors.white,
                                        size: sp(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: w(10)),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "2. Verificación facial",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: sp(18),
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Confirma que eres tú.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: sp(15),
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: h(33)),
                      GestureDetector(
                        child: Container(
                          height: h(53),
                          width: w(300),
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
                              Text(
                                "Comenzar Verificacion",
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
                                  LucideIcons.arrowRight,
                                  color: Colors.white,
                                  size: sp(20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.leftToRight,
                              child: escanearDniPage(),
                            ),
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
