// ignore_for_file: use_key_in_widget_constructors, camel_case_types, unused_element, deprecated_member_use, prefer_final_fields, unused_field, sized_box_for_whitespace, unused_local_variable, avoid_print, body_might_complete_normally_nullable, prefer_typing_uninitialized_variables, unnecessary_to_list_in_spreads

import 'dart:math';

import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/registroUI.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:vibration/vibration.dart';

class presentacionPage extends StatefulWidget {
  @override
  State<presentacionPage> createState() => _presentacionPageState();
}

class _presentacionPageState extends State<presentacionPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  late AnimationController _controllerContainer;

  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;

  late AnimationController _controllerMiniContainerMovimiento;
  late Animation<double> _animationMiniContainerMovimiento;

  late AnimationController _controllerSmooth;
  late Animation<Offset> _offsetAnimationSmooth;

  late AnimationController _controllerContainerCentral;
  late Animation<Offset> _offsetAnimationContainerCentral;

  late AnimationController _controllerText1;
  late Animation<Offset> _offsetAnimationText1;

  late AnimationController _controllerText2;
  late Animation<Offset> _offsetAnimationText2;

  late AnimationController _controllerAnuncio1;
  late Animation<Offset> _offsetAnimationAnuncio1;

  late AnimationController _controllerAnuncio2;
  late Animation<Offset> _offsetAnimationAnuncio2;

  late AnimationController _controllerAnuncio3;
  late Animation<Offset> _offsetAnimationAnuncio3;

  late AnimationController _controllerNavigatorBottom;
  late Animation<Offset> _offsetAnimationNavigatorBottom;

  late AnimationController _respiroSmoothController;
  late Animation<double> _respiroSmoothAnimation;

  final Color inactiveColorStart = Colors.grey.shade800;
  final Color inactiveColorEnd = Colors.grey.shade400;

  late AnimationController _iconSiguienteController;
  late Animation<double> _iconSiguienteAnimation;

  final PageController _controllerPages = PageController();
  int _currentPage = 0;
  final int totalPages = 4;

  @override
  void initState() {
    super.initState();

    // Actualizar currentPage al hacer scroll
    _controllerPages.addListener(() {
      final page = _controllerPages.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });

    // Controladores de animaciones generales
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _controllerContainer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _controllerContainerMovimiento = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    _animationContainerMovimiento = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -8,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -8,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controllerContainerMovimiento);

    _controllerContainerMovimiento.repeat();

    _controllerSmooth = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final double offsetY = 3.0;

    _offsetAnimationSmooth =
        Tween<Offset>(begin: Offset(0, offsetY), end: Offset.zero).animate(
          CurvedAnimation(parent: _controllerSmooth, curve: Curves.decelerate),
        );

    _offsetAnimationContainerCentral =
        Tween<Offset>(begin: Offset(0, offsetY), end: Offset.zero).animate(
          CurvedAnimation(parent: _controllerSmooth, curve: Curves.decelerate),
        );

    _offsetAnimationText1 =
        Tween<Offset>(begin: Offset(0, offsetY), end: Offset.zero).animate(
          CurvedAnimation(parent: _controllerSmooth, curve: Curves.decelerate),
        );

    _offsetAnimationText2 =
        Tween<Offset>(begin: Offset(0, offsetY), end: Offset.zero).animate(
          CurvedAnimation(parent: _controllerSmooth, curve: Curves.decelerate),
        );

    _offsetAnimationAnuncio1 =
        Tween<Offset>(begin: Offset(0, offsetY), end: Offset.zero).animate(
          CurvedAnimation(parent: _controllerSmooth, curve: Curves.decelerate),
        );

    _offsetAnimationAnuncio2 =
        Tween<Offset>(begin: Offset(0, offsetY), end: Offset.zero).animate(
          CurvedAnimation(parent: _controllerSmooth, curve: Curves.decelerate),
        );

    _offsetAnimationAnuncio3 =
        Tween<Offset>(begin: Offset(0, offsetY), end: Offset.zero).animate(
          CurvedAnimation(parent: _controllerSmooth, curve: Curves.decelerate),
        );

    _offsetAnimationNavigatorBottom =
        Tween<Offset>(begin: Offset(0, offsetY), end: Offset.zero).animate(
          CurvedAnimation(parent: _controllerSmooth, curve: Curves.decelerate),
        );

    _controllerSmooth.forward();

    // Inicialización de todos los controllers "faltantes"
    _controllerContainerCentral = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _controllerText1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _controllerText2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _controllerAnuncio1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _controllerAnuncio2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _controllerAnuncio3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _controllerNavigatorBottom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _controllerMiniContainerMovimiento = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    _animationMiniContainerMovimiento = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -3,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controllerMiniContainerMovimiento);

    _controllerMiniContainerMovimiento.repeat();

    _respiroSmoothController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _respiroSmoothAnimation = Tween<double>(begin: 2.0, end: 3.8).animate(
      CurvedAnimation(
        parent: _respiroSmoothController,
        curve: Curves.easeInOut,
      ),
    );

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
    _controller.dispose();
    _controllerSmooth.dispose();
    _controllerContainerCentral.dispose();
    _controllerText1.dispose();
    _controllerText2.dispose();
    _controllerAnuncio1.dispose();
    _controllerAnuncio2.dispose();
    _controllerAnuncio3.dispose();
    _controllerNavigatorBottom.dispose();
    _controllerContainer.dispose();
    _iconSiguienteController.dispose();
    _controllerMiniContainerMovimiento.dispose();
    _controllerPages.dispose();
    _respiroSmoothController.dispose();
    _controllerContainerMovimiento.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2735), Color(0xFF0D1421)],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _CirclePatternPainter(
                    animationValue: _controller.value,
                    currentPage: _currentPage,
                  ),
                );
              },
            ),
            SlideTransition(
              position: _offsetAnimationSmooth,
              child: GestureDetector(
                onTap: () =>
                    SystemChannels.textInput.invokeMethod('TextInput.hide'),
                child: SizedBox(
                  height: screenHeight,
                  child: PageView.builder(
                    controller: _controllerPages,
                    onPageChanged: (value) {
                      _controllerPages.animateToPage(
                        value,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    },
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return presentacion1();
                        case 1:
                          return presentacion2();
                        case 2:
                          return presentacion3();
                        case 3:
                          return presentacion4();
                        default:
                          return Container();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget presentacion1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 73),
          child: Center(
            child: SlideTransition(
              position: _offsetAnimationSmooth,
              child: SmoothPageIndicator(
                controller: _controllerPages,
                count: 4,
                effect: CustomizableEffect(
                  activeDotDecoration: DotDecoration(
                    width: 70,
                    height: 7,
                    color: Color.fromRGBO(1, 165, 113, 1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  dotDecoration: DotDecoration(
                    width: 70,
                    height: 7,
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  spacing: 7,
                  inActiveColorOverride: (i) => Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 33),
        SlideTransition(
          position: _offsetAnimationContainerCentral,
          child: AnimatedBuilder(
            animation: _controllerContainer,
            builder: (context, child) {
              final curved = Curves.easeInOut.transform(
                _controllerContainer.value,
              );
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Onda sincronizada con el botón
                  Transform.scale(
                    scale:
                        1 + curved * 0.7, // 🔹 cuando botón crece, onda también
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
                              Color.fromRGBO(1, 165, 113, 1).withOpacity(0.10),
                              Colors.green.shade600.withOpacity(0.10),
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
                        width: 100,
                        height: 100,
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
                                width: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                15,
                              ), // radio un poco menor
                            ),
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
                              child: Icon(
                                Icons.credit_card,
                                color: Colors.white,
                                size: 43,
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
        ),
        SizedBox(height: 18),

        Center(
          child: SlideTransition(
            position: _offsetAnimationText1,
            child: Text(
              textAlign: TextAlign.center,
              "Bienvenido a tu\nnueva billetera\ndigital",
              style: TextStyle(
                color: Colors.white,
                fontFamily: "PoppinsBold",
                fontSize: 33,
              ),
            ),
          ),
        ),
        SizedBox(height: 13),
        Center(
          child: SlideTransition(
            position: _offsetAnimationText2,
            child: Text(
              textAlign: TextAlign.center,
              "Experimenta una nueva era en pagos digitales con tecnología de vanguardia y seguridad bancaria.",
              style: TextStyle(
                color: Colors.white60,
                fontFamily: "Poppins",
                fontSize: 20,
              ),
            ),
          ),
        ),
        SizedBox(height: 23),
        Center(
          child: SlideTransition(
            position: _offsetAnimationAnuncio1,
            child: Container(
              height: 63,
              width: 350,
              decoration: BoxDecoration(
                color: Color.fromRGBO(20, 30, 48, 1),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 13,
                    offset: Offset(0, 1),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    miniContainers(),
                    SizedBox(width: 13),
                    Text(
                      "Pagos instantáneos 24/7",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 23),
        Center(
          child: SlideTransition(
            position: _offsetAnimationAnuncio2,
            child: Container(
              height: 63,
              width: 350,
              decoration: BoxDecoration(
                color: Color.fromRGBO(20, 30, 48, 1),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 13,
                    offset: Offset(0, 1),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    miniContainers(),
                    SizedBox(width: 13),
                    Text(
                      "Seguridad de nivel bancario",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 23),
        Center(
          child: SlideTransition(
            position: _offsetAnimationAnuncio3,
            child: Container(
              height: 63,
              width: 350,
              decoration: BoxDecoration(
                color: Color.fromRGBO(20, 30, 48, 1),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 13,
                    offset: Offset(0, 1),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    miniContainers(),
                    SizedBox(width: 13),
                    Text(
                      "Sin comisiones ocultas",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 33),
        Expanded(
          child: SlideTransition(
            position: _offsetAnimationNavigatorBottom,
            child: Container(
              height: 53,
              width: 350,
              child: Padding(
                padding: EdgeInsets.only(left: 13),
                child: Row(
                  children: [
                    SizedBox(
                      width: 73,
                      child: Visibility(
                        visible: (_currentPage == 0 ? false : true),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.arrowLeft,
                              color: Colors.grey,
                              size: 15,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Anterior",
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: "Poppins",
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 33),
                    SizedBox(
                      width: 113,
                      child: AnimatedBuilder(
                        animation: _respiroSmoothAnimation,
                        builder: (context, child) {
                          // Color interpolado para inactivos
                          final inactiveColor = Color.lerp(
                            inactiveColorStart,
                            inactiveColorEnd,
                            (_respiroSmoothAnimation.value - 1.2) / (2.2 - 1.2),
                          );
                          return SmoothPageIndicator(
                            controller: _controllerPages,
                            count: 4,
                            effect: CustomizableEffect(
                              spacing: 4,
                              activeDotDecoration: DotDecoration(
                                width: 13 * _respiroSmoothAnimation.value,
                                height: 8,
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              dotDecoration: DotDecoration(
                                width: 8,
                                height: 8,
                                color: inactiveColor!,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    GestureDetector(
                      child: Container(
                        height: 43,
                        width: 113,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(1, 165, 113, 1),
                              Colors.green.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Siguiente",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "Poppins",
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 5),
                            AnimatedBuilder(
                              animation: _iconSiguienteAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    _iconSiguienteAnimation.value,
                                    0,
                                  ), // se mueve a la derecha
                                  child: child,
                                );
                              },
                              child: Icon(
                                LucideIcons.arrowRight,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        if (_currentPage + 1 < totalPages) {
                          _controllerPages.animateToPage(
                            _currentPage + 1,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 13),
      ],
    );
  }

  Widget presentacion2() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 73.h),
          child: Center(
            child: SmoothPageIndicator(
              controller: _controllerPages,
              count: 4,
              effect: CustomizableEffect(
                activeDotDecoration: DotDecoration(
                  width: 70.w,
                  height: 7.h,
                  color: Color.fromRGBO(33, 13, 243, 1),
                  borderRadius: BorderRadius.circular(3.r),
                ),
                dotDecoration: DotDecoration(
                  width: 70.w,
                  height: 7.h,
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(3.r),
                ),
                spacing: 7.w,
                inActiveColorOverride: (i) => Colors.grey.shade800,
              ),
            ),
          ),
        ),
        SizedBox(height: 33.h),
        AnimatedBuilder(
          animation: _controllerContainer,
          builder: (context, child) {
            final curved = Curves.easeInOut.transform(
              _controllerContainer.value,
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
                        borderRadius: BorderRadius.circular(20.r),
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(33, 13, 243, 1).withOpacity(0.10),
                            Colors.blue.shade600.withOpacity(0.10),
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
                        offset: Offset(0, _animationContainerMovimiento.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(33, 13, 243, 1),
                            Colors.blue.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(
                              33,
                              13,
                              243,
                              1,
                            ).withOpacity(0.7),
                            blurRadius: 20.r,
                            spreadRadius: 3.r,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(7.r),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: Colors.white,
                              width: 0.1.w,
                            ),
                            borderRadius: BorderRadius.circular(15.r),
                          ),
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
                            child: Icon(
                              Icons.security,
                              color: Colors.white,
                              size: 43.r,
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
        SizedBox(height: 18.h),
        Center(
          child: Text(
            "Seguridad en la que puedes confiar",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: "PoppinsBold",
              fontSize: 33.sp,
            ),
          ),
        ),
        SizedBox(height: 13.h),
        Center(
          child: Padding(
            padding: EdgeInsets.only(left: 23.w, right: 23.w),
            child: Text(
              "Utilizamos encriptación de grado militar y autenticación biométrica para mantener tu dinero seguro.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontFamily: "Poppins",
                fontSize: 20.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 23.h),
        Center(
          child: Container(
            height: 63.h,
            width: 350.w,
            decoration: BoxDecoration(
              color: Color.fromRGBO(20, 30, 48, 1),
              borderRadius: BorderRadius.circular(13.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 13.r,
                  offset: Offset(0, 1.h),
                  spreadRadius: 1.r,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 13.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  miniContainers(),
                  SizedBox(width: 13.w),
                  Flexible(
                    child: Text(
                      "Encriptación de extremo a extremo",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 23.h),
        Center(
          child: Container(
            height: 63.h,
            width: 350.w,
            decoration: BoxDecoration(
              color: Color.fromRGBO(20, 30, 48, 1),
              borderRadius: BorderRadius.circular(13.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 13.r,
                  offset: Offset(0, 1.h),
                  spreadRadius: 1.r,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 13.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  miniContainers(),
                  SizedBox(width: 13.w),
                  Flexible(
                    child: Text(
                      "Autenticación biométrica",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 23.h),
        Center(
          child: Container(
            height: 63.h,
            width: 350.w,
            decoration: BoxDecoration(
              color: Color.fromRGBO(20, 30, 48, 1),
              borderRadius: BorderRadius.circular(13.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 13.r,
                  offset: Offset(0, 1.h),
                  spreadRadius: 1.r,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 13.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  miniContainers(),
                  SizedBox(width: 13.w),
                  Flexible(
                    child: Text(
                      "Monitoreo de fraudes",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 33.h),
        Expanded(
          child: Container(
            height: 53.h,
            width: 350.w,
            child: Padding(
              padding: EdgeInsets.only(left: 13.w),
              child: Row(
                children: [
                  GestureDetector(
                    child: IntrinsicWidth(
                      // <-- ajusta al contenido
                      child: Container(
                        height: 43.h,
                        color: Colors.transparent,
                        child: Visibility(
                          visible: (_currentPage == 0 ? false : true),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min, // ajusta al contenido
                            children: [
                              Icon(
                                LucideIcons.arrowLeft,
                                color: Colors.grey,
                                size: 15.r,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                "Anterior",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: "Poppins",
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      Vibration.vibrate(duration: 5);
                      if (_currentPage - 1 >= 0) {
                        _controllerPages.animateToPage(
                          _currentPage - 1,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                  ),

                  SizedBox(width: 23.w),
                  SizedBox(
                    width: 113.w,
                    child: AnimatedBuilder(
                      animation: _respiroSmoothAnimation,
                      builder: (context, child) {
                        final inactiveColor = Color.lerp(
                          inactiveColorStart,
                          inactiveColorEnd,
                          (_respiroSmoothAnimation.value - 1.2) / (2.2 - 1.2),
                        );
                        return SmoothPageIndicator(
                          controller: _controllerPages,
                          count: 4,
                          effect: CustomizableEffect(
                            spacing: 4.w,
                            activeDotDecoration: DotDecoration(
                              width: 13 * _respiroSmoothAnimation.value,
                              height: 8.h,
                              color: Color.fromRGBO(33, 13, 243, 1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            dotDecoration: DotDecoration(
                              width: 8.w,
                              height: 8.h,
                              color: inactiveColor!,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  GestureDetector(
                    child: IntrinsicWidth(
                      child: Container(
                        height: 43.h,
                        width: 113.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(33, 13, 243, 1),
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Siguiente",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "Poppins",
                                fontSize: 15.sp,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            AnimatedBuilder(
                              animation: _iconSiguienteAnimation,
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
                                size: 15.r,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    onTap: () {
                      Vibration.vibrate(duration: 5);
                      if (_currentPage + 1 < totalPages) {
                        _controllerPages.animateToPage(
                          _currentPage + 1,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 13.h),
      ],
    );
  }

  Widget presentacion3() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 73.h),
          child: Center(
            child: SmoothPageIndicator(
              controller: _controllerPages,
              count: 4,
              effect: CustomizableEffect(
                activeDotDecoration: DotDecoration(
                  width: 70.w,
                  height: 7.h,
                  color: Color.fromRGBO(165, 53, 253, 1),
                  borderRadius: BorderRadius.circular(3.r),
                ),
                dotDecoration: DotDecoration(
                  width: 70.w,
                  height: 7.h,
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(3.r),
                ),
                spacing: 7.w,
                inActiveColorOverride: (i) => Colors.grey.shade800,
              ),
            ),
          ),
        ),
        SizedBox(height: 33.h),
        AnimatedBuilder(
          animation: _controllerContainer,
          builder: (context, child) {
            final curved = Curves.easeInOut.transform(
              _controllerContainer.value,
            );
            return Stack(
              alignment: Alignment.center,
              children: [
                // Onda sincronizada con el botón
                Transform.scale(
                  scale: 1 + curved * 0.7,
                  child: Opacity(
                    opacity: 0.15 - (curved * 0.15),
                    child: Container(
                      width: 120.w,
                      height: 120.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(20.r),
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(165, 53, 253, 1).withOpacity(0.10),
                            Colors.purple.shade600.withOpacity(0.10),
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
                        offset: Offset(0, _animationContainerMovimiento.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(165, 53, 253, 1),
                            Colors.purple.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(
                              165,
                              53,
                              253,
                              1,
                            ).withOpacity(0.7),
                            blurRadius: 20.r,
                            spreadRadius: 3.r,
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
                            borderRadius: BorderRadius.circular(15.r),
                          ),
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
                            child: Icon(
                              LucideIcons.zap,
                              color: Colors.white,
                              size: 43.sp,
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
        SizedBox(height: 18.h),
        Center(
          child: Text(
            "Velocidad sin límites",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: "PoppinsBold",
              fontSize: 33.sp,
            ),
          ),
        ),
        SizedBox(height: 13.h),
        Center(
          child: Padding(
            padding: EdgeInsets.only(left: 23.w, right: 23.w),
            child: Text(
              "Envía y recibe dinero al instante, sin esperas ni complicaciones. Tu dinero se mueve a la velocidad de la luz.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontFamily: "Poppins",
                fontSize: 20.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 23.h),
        // Anuncios
        ...[
          "Transferencias instantáneas",
          "Pagos con QR en segundos",
          "Notificaciones en tiempo real",
        ].map((text) {
          return Padding(
            padding: EdgeInsets.only(bottom: 23.h),
            child: Center(
              child: Container(
                height: 63.h,
                width: 350.w,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(20, 30, 48, 1),
                  borderRadius: BorderRadius.circular(13.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 13.r,
                      offset: Offset(0, 1.h),
                      spreadRadius: 1.r,
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 13.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      miniContainers(),
                      SizedBox(width: 13.w),
                      Text(
                        text,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Poppins",
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        SizedBox(height: 33.h),
        Expanded(
          child: Container(
            height: 53.h,
            width: 350.w,
            child: Padding(
              padding: EdgeInsets.only(left: 13.w),
              child: Row(
                children: [
                  GestureDetector(
                    child: Container(
                      width: 85.w,
                      height: 43.h,
                      color: Colors.transparent,
                      child: Visibility(
                        visible: (_currentPage == 0 ? false : true),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.arrowLeft,
                              color: Colors.grey,
                              size: 15.sp,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              "Anterior",
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: "Poppins",
                                fontSize: 15.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    onTap: () {
                      Vibration.vibrate(duration: 5);
                      if (_currentPage - 1 >= 0) {
                        _controllerPages.animateToPage(
                          _currentPage - 1,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                  ),
                  SizedBox(width: 23.w),
                  SizedBox(
                    width: 113.w,
                    child: AnimatedBuilder(
                      animation: _respiroSmoothAnimation,
                      builder: (context, child) {
                        final inactiveColor = Color.lerp(
                          inactiveColorStart,
                          inactiveColorEnd,
                          (_respiroSmoothAnimation.value - 1.2) / (2.2 - 1.2),
                        );
                        return SmoothPageIndicator(
                          controller: _controllerPages,
                          count: 4,
                          effect: CustomizableEffect(
                            spacing: 4.w,
                            activeDotDecoration: DotDecoration(
                              width: 13 * _respiroSmoothAnimation.value,
                              height: 8.h,
                              color: Color.fromRGBO(165, 53, 253, 1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            dotDecoration: DotDecoration(
                              width: 8.w,
                              height: 8.h,
                              color: inactiveColor!,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  GestureDetector(
                    child: Container(
                      height: 43.h,
                      width: 113.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(165, 53, 253, 1),
                            Colors.purple.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Siguiente",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "Poppins",
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          AnimatedBuilder(
                            animation: _iconSiguienteAnimation,
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
                              size: 15.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Vibration.vibrate(duration: 5);
                      if (_currentPage + 1 < totalPages) {
                        _controllerPages.animateToPage(
                          _currentPage + 1,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget presentacion4() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 73.h),
          child: Center(
            child: SmoothPageIndicator(
              controller: _controllerPages,
              count: 4,
              effect: CustomizableEffect(
                activeDotDecoration: DotDecoration(
                  width: 70.w,
                  height: 7.h,
                  color: Color.fromRGBO(200, 90, 0, 1),
                  borderRadius: BorderRadius.circular(3.r),
                ),
                dotDecoration: DotDecoration(
                  width: 70.w,
                  height: 7.h,
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(3.r),
                ),
                spacing: 7.w,
                inActiveColorOverride: (i) => Colors.grey.shade800,
              ),
            ),
          ),
        ),
        SizedBox(height: 33.h),
        AnimatedBuilder(
          animation: _controllerContainer,
          builder: (context, child) {
            final curved = Curves.easeInOut.transform(
              _controllerContainer.value,
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
                        borderRadius: BorderRadius.circular(20.r),
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(200, 90, 0, 1).withOpacity(0.10),
                            Colors.orange.shade600.withOpacity(0.10),
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
                        offset: Offset(0, _animationContainerMovimiento.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(200, 90, 0, 1),
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(
                              200,
                              90,
                              0,
                              1,
                            ).withOpacity(0.7),
                            blurRadius: 20.r,
                            spreadRadius: 3.r,
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
                            borderRadius: BorderRadius.circular(15.r),
                          ),
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
                            child: Icon(
                              LucideIcons.wifi,
                              color: Colors.white,
                              size: 43.sp,
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
        SizedBox(height: 18.h),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 13.w),
            child: Text(
              "Transacciones sin internet",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: "PoppinsBold",
                fontSize: 33.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 13.h),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 23.w),
            child: Text(
              "Realiza transacciones de forma segura aunque no tengas conexión a internet. Tu dinero siempre disponible.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontFamily: "Poppins",
                fontSize: 20.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 23.h),
        // Anuncios
        ...[
          "Pagos offline seguros",
          "Sincronización automática",
          "Cualquier metodo de pago",
        ].map((text) {
          return Padding(
            padding: EdgeInsets.only(bottom: 23.h),
            child: Center(
              child: Container(
                height: 63.h,
                width: 350.w,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(20, 30, 48, 1),
                  borderRadius: BorderRadius.circular(13.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 13.r,
                      offset: Offset(0, 1.h),
                      spreadRadius: 1.r,
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 13.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      miniContainers(),
                      SizedBox(width: 13.w),
                      Text(
                        text,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Poppins",
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        Expanded(
          child: Container(
            height: 53.h,
            width: 350.w,
            child: Padding(
              padding: EdgeInsets.only(left: 13.w),
              child: Row(
                children: [
                  GestureDetector(
                    child: Container(
                      width: 85.w,
                      height: 43.h,
                      color: Colors.transparent,
                      child: Visibility(
                        visible: (_currentPage == 0 ? false : true),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.arrowLeft,
                              color: Colors.grey,
                              size: 15.sp,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              "Anterior",
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: "Poppins",
                                fontSize: 15.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    onTap: () {
                      Vibration.vibrate(duration: 5);
                      if (_currentPage - 1 >= 0) {
                        _controllerPages.animateToPage(
                          _currentPage - 1,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                  ),
                  SizedBox(width: 23.w),
                  SizedBox(
                    width: 113.w,
                    child: AnimatedBuilder(
                      animation: _respiroSmoothAnimation,
                      builder: (context, child) {
                        final inactiveColor = Color.lerp(
                          inactiveColorStart,
                          inactiveColorEnd,
                          (_respiroSmoothAnimation.value - 1.2) / (2.2 - 1.2),
                        );
                        return SmoothPageIndicator(
                          controller: _controllerPages,
                          count: 4,
                          effect: CustomizableEffect(
                            spacing: 4.w,
                            activeDotDecoration: DotDecoration(
                              width: 13 * _respiroSmoothAnimation.value,
                              height: 8.h,
                              color: Color.fromRGBO(200, 90, 0, 1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            dotDecoration: DotDecoration(
                              width: 8.w,
                              height: 8.h,
                              color: inactiveColor!,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  GestureDetector(
                    child: Container(
                      height: 43.h,
                      width: 113.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(200, 90, 0, 1),
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage + 1 == totalPages
                                ? "Comenzar"
                                : "Siguiente",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "Poppins",
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          AnimatedBuilder(
                            animation: _iconSiguienteAnimation,
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
                              _currentPage + 1 == totalPages
                                  ? LucideIcons.checkCircle2
                                  : LucideIcons.arrowRight,
                              color: Colors.white,
                              size: 15.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Vibration.vibrate(duration: 5);
                      if (_currentPage + 1 < totalPages) {
                        _controllerPages.animateToPage(
                          _currentPage + 1,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        );
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          PageTransition(
                            type: PageTransitionType.leftToRight,
                            child: registroPage(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget miniContainers() {
    return AnimatedBuilder(
      animation: _controllerMiniContainerMovimiento,
      builder: (context, child) {
        final curved = Curves.easeInOut.transform(
          _controllerMiniContainerMovimiento.value,
        );
        return Stack(
          alignment: Alignment.center,
          children: [
            // Onda más sutil
            Transform.scale(
              scale: 1 + curved * 0.2, // 🔹 menor crecimiento
              child: Opacity(
                opacity: 0.05, // 🔹 menos visible
                child: Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                      colors: (() {
                        switch (_currentPage) {
                          case 0:
                            return [
                              Color.fromRGBO(1, 165, 113, 1).withOpacity(0.05),
                              Colors.green.shade600.withOpacity(0.05),
                            ];
                          case 1:
                            return [
                              Color.fromRGBO(33, 13, 243, 1).withOpacity(0.05),
                              Colors.blue.shade600.withOpacity(0.05),
                            ];
                          case 2:
                            return [
                              Color.fromRGBO(165, 53, 253, 1).withOpacity(0.05),
                              Colors.purple.shade600.withOpacity(0.05),
                            ];
                          case 3:
                            return [
                              Color.fromRGBO(200, 90, 0, 1).withOpacity(0.05),
                              Colors.orange.shade600.withOpacity(0.05),
                            ];
                          default:
                            return [Colors.grey.shade200, Colors.grey.shade400];
                        }
                      })(),
                    ),
                  ),
                ),
              ),
            ),
            // Botón con respiro más suave
            Transform.scale(
              scale: 1 + (curved * 0.02), // 🔹 menos “respiración”
              child: AnimatedBuilder(
                animation: _animationMiniContainerMovimiento,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      _animationMiniContainerMovimiento.value * 0.5,
                    ), // 🔹 menos movimiento vertical
                    child: child,
                  );
                },
                child: Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: (() {
                        switch (_currentPage) {
                          case 0:
                            return [
                              Color.fromRGBO(1, 165, 113, 1).withOpacity(0.05),
                              Colors.green.shade600.withOpacity(0.05),
                            ];
                          case 1:
                            return [
                              Color.fromRGBO(33, 13, 243, 1).withOpacity(0.05),
                              Colors.blue.shade600.withOpacity(0.05),
                            ];
                          case 2:
                            return [
                              Color.fromRGBO(165, 53, 253, 1).withOpacity(0.05),
                              Colors.purple.shade600.withOpacity(0.05),
                            ];
                          case 3:
                            return [
                              Color.fromRGBO(200, 90, 0, 1).withOpacity(0.05),
                              Colors.orange.shade600.withOpacity(0.05),
                            ];
                          default:
                            return [Colors.grey.shade200, Colors.grey.shade400];
                        }
                      })(),
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: (() {
                      switch (_currentPage) {
                        case 0:
                          return [
                            BoxShadow(
                              color: Color.fromRGBO(
                                1,
                                165,
                                113,
                                1,
                              ).withOpacity(0.5),
                              blurRadius: 23,
                              spreadRadius: 3,
                            ),
                          ];
                        case 1:
                          return [
                            BoxShadow(
                              color: Color.fromRGBO(
                                33,
                                13,
                                243,
                                1,
                              ).withOpacity(0.5),
                              blurRadius: 23,
                              spreadRadius: 2,
                            ),
                          ];
                        case 2:
                          return [
                            BoxShadow(
                              color: Color.fromRGBO(
                                165,
                                53,
                                253,
                                1,
                              ).withOpacity(0.5),
                              blurRadius: 23,
                              spreadRadius: 2,
                            ),
                          ];
                        case 3:
                          return [
                            BoxShadow(
                              color: Color.fromRGBO(
                                200,
                                90,
                                0,
                                1,
                              ).withOpacity(0.4),
                              blurRadius: 23,
                              spreadRadius: 1,
                            ),
                          ];
                        default:
                          return [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ];
                      }
                    })(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.white, width: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.checkCircle,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CirclePatternPainter extends CustomPainter {
  final double animationValue;
  final int currentPage; // 🔹 se recibe como parámetro

  _CirclePatternPainter({this.animationValue = 0, required this.currentPage});

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
      Offset(0.1, 0.1),
      Offset(0.6, 0.3),
      Offset(0.7, 0.8),
      Offset(0.1, 0.8),
      Offset(0.8, 0.3),
    ];

    final radii = [10.0, 5.0, 10.0, 8.0, 8.0, 10.0, 8.0, 10.0, 8.0, 10.0];
    final opacities = [0.5, 0.5, 0.8, 0.5, 0.7, 0.8, 0.7, 0.8, 0.5, 0.8];

    for (int i = 0; i < circles.length; i++) {
      double speed = 0.5 + (i * 0.1);
      double dxOffset = cos(animationValue * 2 * pi * speed) * 30;
      double dyOffset = sin(animationValue * 2 * pi * speed) * 30;

      final position = Offset(
        circles[i].dx * size.width + dxOffset,
        circles[i].dy * size.height + dyOffset,
      );

      paint.color = (() {
        final opacity = opacities[i];
        switch (currentPage) {
          case 0:
            return Color.fromRGBO(1, 165, 113, 1).withOpacity(opacity);
          case 1:
            return Color.fromRGBO(33, 13, 243, 1).withOpacity(opacity);
          case 2:
            return Color.fromRGBO(165, 53, 253, 1).withOpacity(opacity);
          case 3:
            return Color.fromRGBO(200, 90, 0, 1).withOpacity(opacity);
          default:
            return Colors.grey.withOpacity(opacity);
        }
      })();

      canvas.drawCircle(position, radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CirclePatternPainter oldDelegate) => true;
}

class CustomScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const PageScrollPhysics().applyTo(
      const ClampingScrollPhysics(), // o Bouncing en iOS
    );
  }
}
