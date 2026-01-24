// ignore_for_file: use_key_in_widget_constructors, camel_case_types, deprecated_member_use, prefer_final_fields, unused_field, sized_box_for_whitespace, avoid_print, use_build_context_synchronously, prefer_interpolation_to_compose_strings, unnecessary_import, avoid_unnecessary_containers, unused_element

import 'package:bluetooth/UI/iniciarSesion.dart';
import 'package:bluetooth/UI/registrarse.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:vibration/vibration.dart';

class inicioPage extends StatefulWidget {
  @override
  State<inicioPage> createState() => _inicioPageState();
}

class _inicioPageState extends State<inicioPage> with TickerProviderStateMixin {
  // ================= CONTROLLERS =================
  late final PageController _pageController;
  late final AnimationController _progressController;

  // ================= STATE =================
  int _currentPage = 0;
  final int _pageCount = 3;

  // ================= ANIMACION INICIAL =================
  late AnimationController _controllerInicial1;

  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<Offset> _slideHeader;
  late Animation<Offset> _slideContent;

  //Container 2
  late AnimationController _controllerInicial2;

  //Container 3
  late AnimationController _controllerInicial3;

  //Container 4
  late AnimationController _controllerInicial4;

  //Container 5
  late AnimationController _controllerInicial5;

  //Page View
  late final List<
    Widget Function(
      double Function(double),
      double Function(double),
      double Function(double),
    )
  >
  _pages;

  void _nextPage() {
    // Evita crash si el PageView todavía no está montado
    if (!_pageController.hasClients) return;

    setState(() {
      _currentPage = (_currentPage + 1) % _pageCount;
    });

    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _progressController
      ..reset()
      ..forward();

    Vibration.vibrate(duration: 3);
  }

  @override
  void initState() {
    super.initState();

    // ================= PAGE =================
    _pageController = PageController(initialPage: 1000);

    _pages = [_pageFacilidad, _pageVelocidad, _pageComodidad];

    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _nextPage();
            }
          });

    // ================= ANIMACIÓN INICIAL =================
    _controllerInicial1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controllerInicial1, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 1.05, end: 1).animate(
      CurvedAnimation(parent: _controllerInicial1, curve: Curves.easeOutCubic),
    );

    _slideHeader =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controllerInicial1,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _slideContent =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controllerInicial1,
            curve: const Interval(0.4, 1, curve: Curves.easeOut),
          ),
        );

    // 🚀 DISPARAR TODO DESPUÉS DEL PRIMER FRAME
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _controllerInicial1.forward();
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.stop();
    _progressController.reset();
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1117), Color(0xFF0F1117)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            backgroundColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Center(
              child: Image.asset(
                "assets/logoAppCompleto.png",
                height: h(100),
                width: w(100),
              ),
            ),
          ),
        ),
        body: Stack(children: [SizedBox(child: ingreso())]),
      ),
    );
  }

  Widget ingreso() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return SizedBox(
      height: screenHeight,
      width: screenWidth,
      child: Stack(
        children: [
          /// ================= FONDO BLANCO =================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(screenWidth, screenHeight * 0.35),
              painter: BrokenSheetPainter(color: Colors.white),
            ),
          ),

          /// ================= CONTENIDO =================
          SafeArea(
            child: Column(
              children: [
                /// ================= HEADER =================
                Padding(
                  padding: EdgeInsets.only(top: h(5)),
                  child: SlideTransition(
                    position: _slideHeader,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          SizedBox(height: h(53)),
                          Text(
                            "Bienvenido",
                            style: TextStyle(
                              fontSize: sp(23),
                              fontFamily: "PoppinsBold",
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: h(3)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w(46)),
                            child: Text(
                              "Tu billetera digital para manejar tu dinero de forma simple y segura",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: sp(13),
                                height: 1.25,
                                fontFamily: "Poppins",
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h(43)),

                /// ================= INDICADORES =================
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w(60)),
                  child: Row(
                    children: List.generate(_pageCount, (index) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(5)),
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (_, __) {
                              double value = 0;
                              if (index < _currentPage) value = 1;
                              if (index == _currentPage) {
                                value = _progressController.value;
                              }

                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 3,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation(
                                  Color.fromRGBO(1, 165, 113, 1),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                /// ================= PAGE VIEW =================
                SizedBox(
                  height: h(300),
                  child: SlideTransition(
                    position: _slideContent,
                    child: FadeTransition(
                      opacity: _fade,
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          Vibration.vibrate(duration: 3);

                          final realIndex = index % _pageCount;

                          setState(() {
                            _currentPage = realIndex;
                          });

                          _progressController
                            ..reset()
                            ..forward();
                        },
                        itemBuilder: (context, index) {
                          final realIndex = index % _pageCount;
                          return _pages[realIndex](w, h, sp);
                        },
                      ),
                    ),
                  ),
                ),

                /// ================= TEXTO ACCIÓN =================
                SizedBox(height: h(133)),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w(55)),
                  child: Column(
                    children: [
                      Text(
                        "¿Cómo querés empezar hoy?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: sp(15),
                          fontFamily: "PoppinsBold",
                          color: Colors.black.withOpacity(0.85),
                        ),
                      ),
                      SizedBox(height: h(5)),
                      Text(
                        "Creá tu cuenta o ingresá para continuar",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: sp(13),
                          fontFamily: "Poppins",
                          height: 1.3,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                Spacer(),

                /// ================= BOTONES =================
                SlideTransition(
                  position: _slideContent,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: h(23)),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Vibration.vibrate(duration: 5);
                              Navigator.pushAndRemoveUntil(
                                context,
                                PageTransition(
                                  type: PageTransitionType.leftToRight,
                                  child: registrarsePage(pasoGuardado: 0),
                                ),
                                (_) => false,
                              );
                            },
                            child: Container(
                              height: h(54),
                              width: w(350),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(1, 165, 113, 1),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ).withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Crear una cuenta",
                                  style: TextStyle(
                                    fontSize: sp(17),
                                    fontFamily: "PoppinsBold",
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: h(28)),

                          GestureDetector(
                            onTap: () {
                              Vibration.vibrate(duration: 5);
                              Navigator.pushAndRemoveUntil(
                                context,
                                PageTransition(
                                  type: PageTransitionType.leftToRight,
                                  child: iniciarSesionPage(),
                                ),
                                (_) => false,
                              );
                            },
                            child: Text(
                              "Ingresar a mi cuenta",
                              style: TextStyle(
                                fontSize: sp(15.5),
                                fontFamily: "PoppinsBold",
                                color: Colors.black87,
                              ),
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
        ],
      ),
    );
  }

  //Paginas Page View
  Widget _pageFacilidad(
    double Function(double) w,
    double Function(double) h,
    double Function(double) sp,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w(33)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/imgPresentacion1.png",
            height: h(200),
            width: w(260),
            fit: BoxFit.contain,
          ),
          SizedBox(height: h(18)),
          Text(
            "Facilidad",
            style: TextStyle(
              fontSize: sp(22),
              fontFamily: "PoppinsBold",
              color: Colors.white,
            ),
          ),
          SizedBox(height: h(6)),
          Text(
            "Menos tiempo pensando,\nmás disfrutando",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: sp(14.5),
              fontFamily: "Poppins",
              height: 1.35,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageVelocidad(
    double Function(double) w,
    double Function(double) h,
    double Function(double) sp,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w(33)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/imgPresentacion2.png",
            height: h(200),
            width: w(260),
            fit: BoxFit.contain,
          ),
          SizedBox(height: h(18)),
          Text(
            "Velocidad",
            style: TextStyle(
              fontSize: sp(22),
              fontFamily: "PoppinsBold",
              color: Colors.white,
            ),
          ),
          SizedBox(height: h(6)),
          Text(
            "Mové tu dinero al instante,\nsin complicaciones",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: sp(14.5),
              fontFamily: "Poppins",
              height: 1.35,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageComodidad(
    double Function(double) w,
    double Function(double) h,
    double Function(double) sp,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w(33)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/imgPresentacion3.png",
            height: h(200),
            width: w(260),
            fit: BoxFit.contain,
          ),
          SizedBox(height: h(18)),
          Text(
            "Comodidad",
            style: TextStyle(
              fontSize: sp(22),
              fontFamily: "PoppinsBold",
              color: Colors.white,
            ),
          ),
          SizedBox(height: h(6)),
          Text(
            "Todo lo que necesitás,\nen un solo lugar",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: sp(14.5),
              fontFamily: "Poppins",
              height: 1.35,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class BrokenSheetPainter extends CustomPainter {
  final Color color;

  BrokenSheetPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // 🔼 Línea recta superior (más alta)
    path.moveTo(0, size.height * 0.20);
    path.lineTo(size.width, size.height * 0.20);

    // 🔽 Cierre inferior
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
