// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, unused_field, deprecated_member_use, unused_import, sized_box_for_whitespace, use_build_context_synchronously

import 'dart:math';

import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';

class cargaInicioSesionPage extends StatefulWidget {
  @override
  State<cargaInicioSesionPage> createState() => _cargaInicioSesionPageState();
}

class _cargaInicioSesionPageState extends State<cargaInicioSesionPage>
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

    iniciarLaSesion();
  }

  @override
  void dispose() {
    // Animations
    _controller.dispose();
    _controllerContainerMovimiento.dispose();
    _controllerContainerNaranjaMovimiento.dispose();
    _controllerIconMovimiento.dispose();
    _iconSiguienteController.dispose();

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

  Future<void> iniciarLaSesion() async {
    Future.delayed(Duration(milliseconds: 2300), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MenuPrincipalPage()),
        (Route<dynamic> route) => false,
      );
    });
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
        body: Stack(children: [SizedBox(child: cargaInicioSesion())]),
      ),
    );
  }

  Widget cargaInicioSesion() {
    return Stack(
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
                                                    LucideIcons.logIn,
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
                              SizedBox(height: 53),
                              Center(
                                child: Text(
                                  textAlign: TextAlign.center,
                                  "Iniciando Sesión",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "PoppinsBold",
                                    fontSize: 25,
                                  ),
                                ),
                              ),
                              SizedBox(height: 33),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 23,
                                  right: 23,
                                ),
                                child: Center(
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    "Verificando Credenciales...",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 53),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  10,
                                ), // respeta el borde redondeado
                                child: Container(
                                  width: 300,
                                  child: LinearProgressIndicator(
                                    minHeight: 5,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromRGBO(1, 165, 113, 1),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 53),
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
