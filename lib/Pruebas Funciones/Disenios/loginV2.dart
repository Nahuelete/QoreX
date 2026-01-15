// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, unused_element, deprecated_member_use, sized_box_for_whitespace, unused_field, prefer_final_fields

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:vibration/vibration.dart';
class menuV2 extends StatefulWidget {

  @override
  State<menuV2> createState() => _menuV2State();
}

class _menuV2State extends State<menuV2> with TickerProviderStateMixin {

  //PageView
  PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  void cambiarPagina() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentIndex < 2) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }

      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    cambiarPagina();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

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
            SizedBox(child: menuWidget()),
          ],
        ),
      ),
    );
  }

  Widget menuWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/overlapping-circles.svg',
          color: Colors.white.withOpacity(0.033), // color del patrón
          fit: BoxFit.cover,
          width: screenWidth,
          height: screenHeight,
        ),
        Column(
          children: [
            SizedBox(height: h(53)),
            SizedBox(
              height: h(350),
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  // ---------------- PÁGINA 1 ----------------
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/img1Bienvenida.png', height: h(180)),
                      SizedBox(height: h(13)),
                      Text(
                        'Pagos fáciles',
                        style: TextStyle(color: Colors.white, fontSize: sp(20), fontFamily: "PoppinsBold"),
                      ),
                      SizedBox(height: h(10)),
                      Text(
                        'Enviá y recibi dinero en segundos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: sp(17),
                          fontFamily: "PoppinsBold",
                        ),
                      ),
                    ],
                  ),
              
                  // ---------------- PÁGINA 2 ----------------
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/img2Bienvenida.png', height: h(180)),
                      SizedBox(height: h(13)),
                      Text(
                        'Seguridad garantizada',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sp(20),
                          fontFamily: "PoppinsBold",
                        ),
                      ),
                      SizedBox(height: h(10)),
                      Text(
                        'Protegemos tu dinero al 100%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: sp(17),
                          fontFamily: "PoppinsBold",
                        ),
                      ),
                    ],
                  ),
              
                  // ---------------- PÁGINA 3 ----------------
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/img3Bienvenida.png', height: h(180)),
                      SizedBox(height: h(13)),
                      Text(
                        'Sin conexion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sp(20),
                          fontFamily: "PoppinsBold",
                        ),
                      ),
                      SizedBox(height: h(10)),
                      Text(
                        'Maneja tu dinero en cualquier contexto',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60,
                          fontSize: sp(17),
                          fontFamily: "PoppinsBold",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedSmoothIndicator(
              activeIndex: _currentIndex,
              count: 3,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: Color.fromRGBO(1, 165, 113, 1),
                dotColor: Colors.white24,
              ),
            ),
            Spacer(),
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w(33)),
                  child: InkWell(
                    onTap: () {
                      Vibration.vibrate(duration: 5);
                    },
                    child: Container(
                      height: h(53),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(1, 165, 113, 1),
                            Colors.green.shade600,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "Crear Cuenta",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sp(15),
                            fontFamily: "PoppinsBold",
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w(33), vertical: h(23)),
                  child: InkWell(
                    onTap: () {
                      Vibration.vibrate(duration: 5);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: h(53),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          "Ingresar",
                          style: TextStyle(
                            color: Colors.white60, 
                            fontSize: sp(17), 
                            fontFamily: "PoppinsBold",
                          ),
                        ),
                      ),
                    ),
                  )
        
                ),
                SizedBox(height: h(23))
              ],
            )
          ],
        ),
      ],
    );
  }
}