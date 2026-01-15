// ignore_for_file: use_key_in_widget_constructors, file_names, camel_case_types, deprecated_member_use, prefer_final_fields, unused_field, avoid_print, avoid_unnecessary_containers, use_build_context_synchronously

import 'dart:math';
import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class activarTarjetaPage extends StatefulWidget {
  @override
  State<activarTarjetaPage> createState() => _ActivarTarjetaPageState();
}

class _ActivarTarjetaPageState extends State<activarTarjetaPage>
    with TickerProviderStateMixin {
  //Fondo Circulos
  late AnimationController _controller;

  //Icono Acceder
  late AnimationController _iconAccederController;
  late Animation<double> _iconAccederAnimation;

  //Muestra Activar Tarjeta
  bool muestraVis = true;

  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;

  late AnimationController _controllerIconMovimiento;
  late Animation<double> _animationIconMovimiento;

  //Escaner QR
  late MobileScannerController scannerController;

  bool _isScanned = false;
  String dataQR = "";

  //Ingresar Manualmente
  bool manual = false;

  final TextEditingController _controllerCodeTarjeta1 = TextEditingController();
  final TextEditingController _controllerCodeTarjeta2 = TextEditingController();

  final FocusNode _focus1 = FocusNode();
  final FocusNode _focus2 = FocusNode();

  String codeIngresado = "";

  //Tarjeta Activada
  bool activada = false;

  //Control Scroll
  late ScrollController _scrollController = ScrollController();

  //Animaciones Tarjeta
  late AnimationController _controllerSlideTarjeta;

  late Animation<double> codeTarjetaOpacity;
  late Animation<Offset> codeTarjetaOffset;

  late Animation<double> tarjetaOpacity;
  late Animation<Offset> tarjetaOffset;

  late Animation<double> numeroOpacity;
  late Animation<Offset> numeroOffset;

  late Animation<double> vencimientoOpacity;
  late Animation<Offset> vencimientoOffset;

  late Animation<double> nombreOpacity;
  late Animation<Offset> nombreOffset;

  late AnimationController _controllerSlideTexto;

  late Animation<double> animOpacity;
  late Animation<Offset> animOffset;

  late Animation<double> tituloOpacity;
  late Animation<Offset> tituloOffset;

  late Animation<double> cuerpoOpacity;
  late Animation<Offset> cuerpoOffset;

  late AnimationController _controllerSlideBoton;

  late Animation<double> botonOpacity;
  late Animation<Offset> botonOffset;

  //Animacion Icon Finalizar
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  //Datos Usuario
  String uidUser = "";
  String tarjetaCodeUser = "";
  String nombreUser = "";
  String avatarUser = "";

  //Datos Tarjeta
  String numeroTarjeta = "";
  String vencimientoTarjeta = "";
  String cvvTarjeta = "";

  void modificarTexto() {
    setState(() {
      _controllerCodeTarjeta1.text = _controllerCodeTarjeta1.text.toUpperCase();
      _controllerCodeTarjeta2.text = _controllerCodeTarjeta2.text.toUpperCase();
      codeIngresado = codeIngresado.toUpperCase();
    });

    //Primeros 4
    if (4 - _controllerCodeTarjeta1.text.length != 0) {
      int restantes = 8 - _controllerCodeTarjeta1.text.length;

      setState(() {
        codeIngresado = _controllerCodeTarjeta1.text + ("-" * restantes);
      });
    } else {
      setState(() {
        codeIngresado = _controllerCodeTarjeta1.text;
      });
    }

    //Segundos 4
    if (4 - _controllerCodeTarjeta2.text.length != 0) {
      int restantes =
          (8 - _controllerCodeTarjeta1.text.length) -
          _controllerCodeTarjeta2.text.length;

      setState(() {
        codeIngresado =
            _controllerCodeTarjeta1.text +
            _controllerCodeTarjeta2.text +
            ("-" * restantes);
      });
    } else {
      setState(() {
        codeIngresado =
            _controllerCodeTarjeta1.text + _controllerCodeTarjeta2.text;
      });
    }
  }

  Future<void> verificarTarjeta() async {
    uidUser = FirebaseAuth.instance.currentUser!.uid;

    setState(() {
      _isScanned = true;
    });

    Future.delayed(Duration(milliseconds: 3500), () {
      setState(() {
        _isScanned = false;
      });
    });

    final docSnapshot = await FirebaseFirestore.instance
        .collection("Usuarios")
        .doc(uidUser)
        .get();

    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

      tarjetaCodeUser = data["Tarjeta"] ?? "";
      nombreUser = data["Nombre"] ?? "";
      avatarUser = data["Avatar"] ?? "";

      // ------------------ CÓDIGO QR ------------------
      if (manual == false) {
        if (tarjetaCodeUser == dataQR) {
          print("Tarjeta Activada");

          Vibration.vibrate(duration: 5);

          // Activar Tarjeta
          activarTarjeta();

          Future.delayed(Duration(seconds: 3), () {
            setState(() {
              activada = true;
              _controllerSlideTexto.forward();
            });

            Future.delayed(Duration(milliseconds: 2300), () {
              _controllerSlideTarjeta.forward();

              Future.delayed(Duration(milliseconds: 3300), () {
                _controllerSlideBoton.forward();
              });
            });
          });
        } else {
          print("Tarjeta Incorrecta. Prueba Con Otra");
          Vibration.vibrate(duration: 10);
          showFlushbarError(
            context,
            "Algo salió mal. El código escaneado no coincide con tu tarjeta. Inténtalo de nuevo.",
          );
        }
      }

      // ------------------ CÓDIGO MANUAL ------------------
      if (manual == true) {
        if (codeIngresado.length == 8) {
          if (tarjetaCodeUser == codeIngresado) {
            print("Tarjeta Activada");

            Vibration.vibrate(duration: 5);

            // Activar Tarjeta
            activarTarjeta();

            Future.delayed(Duration(seconds: 3), () {
              setState(() {
                activada = true;
                _controllerSlideTexto.forward();
              });

              Future.delayed(Duration(milliseconds: 2300), () {
                _controllerSlideTarjeta.forward();

                Future.delayed(Duration(milliseconds: 3300), () {
                  _controllerSlideBoton.forward();
                });
              });
            });
          } else {
            print("Tarjeta Incorrecta. Prueba Con Otra");
            Vibration.vibrate(duration: 10);
            showFlushbarError(
              context,
              "Algo salió mal. El código ingresado no coincide con tu tarjeta. Inténtalo de nuevo.",
            );

            setState(() {
              _controllerCodeTarjeta1.clear();
              _controllerCodeTarjeta2.clear();
              codeIngresado = "";
            });
          }
        }
      }
    } else {
      print("No existe el usuario");
      Vibration.vibrate(duration: 10);
      showFlushbarError(
        context,
        "Algo salió mal. Inténtalo de nuevo más tarde.",
      );

      setState(() {
        _isScanned = false;
      });
    }
  }

  Future<void> activarTarjeta() async {
    generarDatosTarjeta();

    //Verificar En Firebase
    final tarjetas = await FirebaseFirestore.instance
        .collection("Tarjetas")
        .where("NumeroTarjeta", isEqualTo: numeroTarjeta)
        .get();

    if (tarjetas.docs.isNotEmpty) {
      generarDatosTarjeta();
    } else {
      //Eliminar Solicitud Tarjeta
      FirebaseFirestore.instance
          .collection("SolicitudesTarjetas")
          .doc("Solicitud $uidUser")
          .delete();

      //Eliminar Notificacion Solicitud Tarjeta
      FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc("Notificacion Solicitud Tarjeta #$uidUser")
          .delete();

      //Guardar Tarjeta
      FirebaseFirestore.instance
          .collection("Tarjetas")
          .doc(tarjetaCodeUser)
          .set({
            "NumeroTarjeta": numeroTarjeta,
            "Vencimiento": vencimientoTarjeta,
            "Estado": "Habilitada",
            "CVV": cvvTarjeta,
            "Uid": uidUser,
            "Codigo": tarjetaCodeUser,
            "Nombre": nombreUser,
            "Tipo": "Original",
            "Alta": DateTime.now(),
          });

      //Crear Notificacion
      crearNotificacion();
    }
  }

  void generarDatosTarjeta() {
    //Generar Numero
    final random = Random();

    numeroTarjeta = "";

    for (int i = 0; i < 16; i++) {
      numeroTarjeta += random.nextInt(10).toString();
    }

    numeroTarjeta = numeroTarjeta.replaceAllMapped(
      RegExp(r'.{4}'),
      (m) => '${m.group(0)} ',
    );

    //Generar Vencimiento
    int mes = random.nextInt(12) + 1;
    int anioActual = DateTime.now().year;
    int anio = anioActual + 4 + random.nextInt(3);

    String mesStr = mes.toString().padLeft(2, '0');
    String anioStr = (anio % 100).toString().padLeft(2, '0');

    vencimientoTarjeta = "$mesStr/$anioStr";

    //Generar CVV
    cvvTarjeta = (100 + random.nextInt(900)).toString();

    //Guardar Datos Completos
    guardarTarjetaCompleta(
      numeroTarjeta,
      cvvTarjeta,
      vencimientoTarjeta,
      tarjetaCodeUser,
    );
  }

  Future<void> crearNotificacion() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Tarjeta Activada #$uidUser")
        .set({
          "Avatar": avatarUser,
          "De": nombreUser,
          "De uid": uidUser,
          "FechaTime": DateTime.now(),
          "Fecha": fecha,
          "Hora": horaActual,
          "Estado": "Habilitada",
          "Involucra": [uidUser],
          "Leida": {uidUser: false},
          "Tipo": "Tarjeta Activada",
        });
  }

  Future<void> guardarTarjetaCompleta(
    String tarjetaUser,
    String cvvUser,
    String vencimientoUser,
    String codeTarjeta,
  ) async {
    final prefsTarjeta = await SharedPreferences.getInstance();
    await prefsTarjeta.setString("codeTarjetaUser", codeTarjeta);
    await prefsTarjeta.setString("tarjetaUser", tarjetaUser);
    await prefsTarjeta.setString("cvvUser", cvvUser);
    await prefsTarjeta.setString("vencimientoUser", vencimientoUser);
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
        colors: [Colors.red, Colors.red.shade600],
      ),
      icon: Icon(LucideIcons.alertCircle, color: Colors.white),
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
      final double newEnd = -3 + random.nextDouble() * 5;
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
  void initState() {
    super.initState();

    //Muestra Activar Tarjeta
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

    //Texto Codigo
    codeIngresado = _controllerCodeTarjeta1.text + _controllerCodeTarjeta2.text;

    //Control Scroll
    _scrollController = ScrollController();

    //Enviar Scroll Arriba
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });

    //Fondo Circulos
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    //Icono Acceder
    _iconAccederController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _iconAccederAnimation = Tween<double>(begin: -5.0, end: 3.0).animate(
      CurvedAnimation(parent: _iconAccederController, curve: Curves.easeInOut),
    );

    //Escaner QR
    scannerController = MobileScannerController();

    //Animaciones Tarjeta
    _controllerSlideTarjeta = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3300),
    );

    tarjetaOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controllerSlideTarjeta,
        curve: Interval(0.00, 0.20),
      ),
    );
    tarjetaOffset = Tween(begin: Offset(0, 0.8), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controllerSlideTarjeta,
        curve: Interval(0.00, 0.20),
      ),
    );

    codeTarjetaOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controllerSlideTarjeta,
        curve: Interval(0.20, 0.40),
      ),
    );
    codeTarjetaOffset = Tween(begin: Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controllerSlideTarjeta,
        curve: Interval(0.20, 0.40),
      ),
    );

    numeroOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controllerSlideTarjeta,
        curve: Interval(0.40, 0.60),
      ),
    );
    numeroOffset = Tween(begin: Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controllerSlideTarjeta,
        curve: Interval(0.40, 0.60),
      ),
    );

    nombreOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controllerSlideTarjeta,
        curve: Interval(0.60, 0.80),
      ),
    );
    nombreOffset = Tween(begin: Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controllerSlideTarjeta,
        curve: Interval(0.60, 0.80),
      ),
    );

    vencimientoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controllerSlideTarjeta,
        curve: Interval(0.80, 1.00),
      ),
    );
    vencimientoOffset = Tween(begin: Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controllerSlideTarjeta,
        curve: Interval(0.80, 1.00),
      ),
    );

    _controllerSlideTexto = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2300),
    );

    animOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controllerSlideTexto,
        curve: Interval(0.00, 0.33),
      ),
    );
    animOffset = Tween(begin: Offset(0, 0.8), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controllerSlideTexto,
        curve: Interval(0.00, 0.33),
      ),
    );

    tituloOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controllerSlideTexto,
        curve: Interval(0.33, 0.66),
      ),
    );
    tituloOffset = Tween(begin: Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controllerSlideTexto,
        curve: Interval(0.33, 0.66),
      ),
    );

    cuerpoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controllerSlideTexto,
        curve: Interval(0.66, 1.00),
      ),
    );
    cuerpoOffset = Tween(begin: Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controllerSlideTexto,
        curve: Interval(0.66, 1.00),
      ),
    );

    _controllerSlideBoton = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1300),
    );

    botonOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controllerSlideBoton,
        curve: Interval(0.00, 1.00),
      ),
    );
    botonOffset = Tween(begin: Offset(0, 0.8), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controllerSlideBoton,
        curve: Interval(0.00, 1.00),
      ),
    );

    //Animacion Icon Finalizar
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _iconAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconAccederController.dispose();
    _controllerSlideBoton.dispose();
    _controllerSlideTarjeta.dispose();
    _controllerSlideTexto.dispose();
    _controllerContainerMovimiento.dispose();
    _controllerIconMovimiento.dispose();
    _iconController.dispose();
    scannerController.stop();
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
        appBar: activada
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Visibility(
                  visible: activada == false,
                  child: Row(
                    children: [
                      SizedBox(width: w(13)),
                      GestureDetector(
                        child: Container(
                          width: w(40),
                          height: h(40),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(1, 165, 113, 1),
                                Colors.green.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            LucideIcons.arrowLeft,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () {
                          Vibration.vibrate(duration: 5);
                          FocusScope.of(context).unfocus();
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.rightToLeft,
                              child: MenuPrincipalPage(),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: w(10)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Activar Tarjeta",
                                style: TextStyle(
                                  fontSize: sp(18),
                                  color: Colors.white,
                                  fontFamily: "PoppinsBold",
                                ),
                              ),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Activala para comenzar a utilizarla",
                                style: TextStyle(
                                  fontSize: sp(13),
                                  color: Colors.grey,
                                  fontFamily: "Poppins",
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
        body: Stack(
          children: [
            SizedBox(child: muestraActivarTarjeta()),
            SizedBox(child: activarTarjetaWidget()),
          ],
        ),
      ),
    );
  }

  Widget muestraActivarTarjeta() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: (muestraVis == true ? true : false),
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
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
                        Padding(
                          padding: EdgeInsets.only(top: h(43)),
                          child: AnimatedBuilder(
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                                                Icons.credit_card,
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
                        ),
                        SizedBox(height: h(13)),
                        Center(
                          child: Text(
                            textAlign: TextAlign.center,
                            "Cómo Activar Tu Tarjeta",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "PoppinsBold",
                              fontSize: sp(28),
                            ),
                          ),
                        ),
                        SizedBox(height: h(13)),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: w(43)),
                            child: Text(
                              textAlign: TextAlign.center,
                              "Tu tarjeta física ha llegado. Actívala ahora para comenzar a usarla de forma segura.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontFamily: "Poppins",
                                fontSize: sp(18),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h(33)),
                        Center(
                          child: Container(
                            width: w(300),
                            height: h(180),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color.fromRGBO(
                                  1,
                                  165,
                                  113,
                                  1,
                                ), // contorno verde
                                width: w(1),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                20,
                              ), // mismo radio que el contenedor
                              child: Container(
                                width: w(300),
                                height: h(180),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color.fromRGBO(3, 5, 25, 1),
                                      Color.fromRGBO(13, 20, 40, 1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: LottieBuilder.asset(
                                    "assets/activarTarjetaAnim.json",
                                    repeat: true,
                                    width: w(170),
                                    height: h(170),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h(33)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(23)),
                          child: Container(
                            height: h(100),
                            width: w(300),
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
                                          Icons.qr_code_scanner_outlined,
                                          color: Colors.white,
                                          size: sp(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: w(5)),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(213),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Escanea el código QR",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: sp(18),
                                            fontFamily: "Poppins",
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(213),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Opción rápida y segura.",
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: sp(15),
                                            fontFamily: "Poppins",
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
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(23)),
                          child: Container(
                            height: h(100),
                            width: w(300),
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
                                          LucideIcons.keyRound,
                                          color: Colors.white,
                                          size: sp(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: w(5)),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(213),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Código manual",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: sp(18),
                                            fontFamily: "Poppins",
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(213),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Ingresa 8 caracteres.",
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: sp(15),
                                            fontFamily: "Poppins",
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
                                  "Entendido",
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
                                    LucideIcons.checkCheck,
                                    color: Colors.white,
                                    size: sp(20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              muestraVis = false;

                              _controllerContainerMovimiento.stop();
                              _controllerContainerMovimiento.dispose();
                            });
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
      ),
    );
  }

  Widget activarTarjetaWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Visibility(
      visible: (muestraVis == true ? false : true),
      child: Stack(
        children: [
          if (activada == false) ...[
            if (manual == false) ...[
              Center(
                child: Container(
                  height: h(523),
                  width: w(400),
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
                  child: Padding(
                    padding: EdgeInsets.only(top: h(33)),
                    child: Column(
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                textAlign: TextAlign.center,
                                _isScanned
                                    ? "Verificando Código QR"
                                    : "Activa Tu Tarjeta",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "PoppinsBold",
                                  fontSize: sp(25),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h(13)),
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: Text(
                              textAlign: TextAlign.center,
                              _isScanned
                                  ? "Esto puede tardar unos segundos..."
                                  : "Escanea el código QR del reverso de tu tarjeta física para activarla.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontFamily: "PoppinsBold",
                                fontSize: sp(18),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h(33)),

                        Visibility(
                          visible: _isScanned == false,
                          child: Container(
                            height: h(250),
                            width: w(250),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(23),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.3),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(23),
                              child: MobileScanner(
                                controller: scannerController,
                                fit: BoxFit.cover,
                                onDetect: (capture) {
                                  Vibration.vibrate(duration: 15);
                                  final List<Barcode> barcodes =
                                      capture.barcodes;
                                  for (final barcode in barcodes) {
                                    dataQR = "${barcode.rawValue}";

                                    verificarTarjeta();

                                    setState(() {
                                      _isScanned = true;
                                    });

                                    Future.delayed(
                                      Duration(milliseconds: 3800),
                                      () {
                                        setState(() {
                                          _isScanned = false;
                                        });
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _isScanned == true,
                          child: SizedBox(
                            height: h(150),
                            width: w(150),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromRGBO(1, 165, 113, 1),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                        SizedBox(height: h(33)),
                        Visibility(
                          visible: _isScanned == false,
                          child: GestureDetector(
                            child: Container(
                              height: h(43),
                              width: w(300),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white60,
                                  width: 0.3,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.keyRound,
                                    color: Colors.white60,
                                    size: sp(15),
                                  ),
                                  SizedBox(width: w(8)),
                                  Text(
                                    "Ingresar código manualmente",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                manual = true;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              SingleChildScrollView(
                controller: _scrollController,
                child: Center(
                  child: Container(
                    height: h(733),
                    width: w(400),
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
                    child: Padding(
                      padding: EdgeInsets.only(top: h(33)),
                      child: Column(
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  textAlign: TextAlign.center,
                                  _isScanned
                                      ? "Verificando Código"
                                      : "Ingresa El Código",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "PoppinsBold",
                                    fontSize: sp(25),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: h(13)),
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                textAlign: TextAlign.center,
                                _isScanned
                                    ? "Esto puede tardar unos segundos..."
                                    : "Encuentra el código de 8 dígitos en el reverso de tu tarjeta física.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(20),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: h(53)),
                          Visibility(
                            visible: _isScanned == false,
                            child: Column(
                              children: [
                                Container(
                                  height: 230,
                                  width: 250,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F182A),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 0.1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.35),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      // ESPACIO SUPERIOR
                                      SizedBox(height: h(20)),

                                      // ICONO QR CON BORDE BLANCO
                                      Container(
                                        height: h(100),
                                        width: h(100),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: Icon(
                                            LucideIcons.qrCode,
                                            color: Colors.white,
                                            size: sp(80),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: h(30)),

                                      // LÍNEA BRILLANTE
                                      Container(
                                        height: h(3),
                                        width: w(300),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Color(0xFF00F7A1),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: h(20)),

                                      // GUIONES VERDES
                                      Text(
                                        codeIngresado.isEmpty
                                            ? "--------"
                                            : codeIngresado,
                                        style: TextStyle(
                                          color: Color(0xFF00F7A1),
                                          fontFamily: "PoppinsBold",
                                          fontSize: sp(23),
                                          letterSpacing: 8,
                                        ),
                                      ),

                                      SizedBox(height: h(13)),

                                      // TEXTO INFERIOR
                                      Text(
                                        "CÓDIGO DE ACTIVACIÓN",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: sp(13),
                                          fontFamily: "Poppins",
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: h(50)),
                                PinCodeTextField(
                                  focusNode: _focus1,
                                  autoDisposeControllers: false,
                                  appContext: context,
                                  controller: _controllerCodeTarjeta1,
                                  length: 4,
                                  autoFocus: codeIngresado.isEmpty
                                      ? true
                                      : false,
                                  keyboardType: TextInputType.visiblePassword,
                                  animationType: AnimationType.fade,
                                  pinTheme: PinTheme(
                                    shape: PinCodeFieldShape.box,
                                    borderRadius: BorderRadius.circular(13),
                                    fieldHeight: h(50),
                                    fieldWidth: w(45),
                                    activeFillColor: Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ),
                                    inactiveFillColor: Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ).withOpacity(0.3),
                                    selectedFillColor: Colors.transparent,
                                    activeColor: Colors.transparent,
                                    inactiveColor: Colors.transparent,
                                    selectedColor: Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ),
                                    fieldOuterPadding: EdgeInsets.symmetric(
                                      horizontal: w(13),
                                    ),
                                  ),
                                  enableActiveFill: true,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  autoDismissKeyboard: false,
                                  onCompleted: (value) {
                                    _focus2.requestFocus();
                                    _scrollController.animateTo(
                                      _scrollController
                                          .position
                                          .maxScrollExtent,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  onChanged: (value) {
                                    setState(() {});
                                    modificarTexto();
                                    if (value.isEmpty) {
                                      _focus1.unfocus();
                                    }
                                  },
                                ),
                                SizedBox(height: h(8)),
                                PinCodeTextField(
                                  focusNode: _focus2,
                                  autoDisposeControllers: false,
                                  appContext: context,
                                  controller: _controllerCodeTarjeta2,
                                  length: 4,
                                  autoFocus: false,
                                  keyboardType: TextInputType.visiblePassword,
                                  animationType: AnimationType.fade,
                                  pinTheme: PinTheme(
                                    shape: PinCodeFieldShape.box,
                                    borderRadius: BorderRadius.circular(13),
                                    fieldHeight: h(50),
                                    fieldWidth: w(45),
                                    activeFillColor: Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ),
                                    inactiveFillColor: Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ).withOpacity(0.3),
                                    selectedFillColor: Colors.transparent,
                                    activeColor: Colors.transparent,
                                    inactiveColor: Colors.transparent,
                                    selectedColor: Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ),
                                    fieldOuterPadding: EdgeInsets.symmetric(
                                      horizontal: w(13),
                                    ),
                                  ),
                                  enableActiveFill: true,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  onChanged: (value) {
                                    setState(() {
                                      value.toUpperCase();
                                    });
                                    modificarTexto();
                                    if (value.isEmpty) {
                                      _focus1.requestFocus();
                                    }
                                  },
                                  onCompleted: (value) {
                                    verificarTarjeta();
                                  },
                                ),
                                SizedBox(height: h(33)),
                                GestureDetector(
                                  child: Container(
                                    height: h(43),
                                    width: w(300),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white60,
                                        width: 0.3,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.qrCode,
                                          color: Colors.white60,
                                          size: sp(15),
                                        ),
                                        SizedBox(width: w(8)),
                                        Text(
                                          "Escanear Código QR",
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontFamily: "Poppins",
                                            fontSize: sp(15),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      manual = false;
                                      _controllerCodeTarjeta1.clear();
                                      _controllerCodeTarjeta2.clear();
                                      codeIngresado = "";
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: h(33)),
                          Visibility(
                            visible: _isScanned == true,
                            child: Center(
                              child: SizedBox(
                                height: h(150),
                                width: w(150),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.fromRGBO(1, 165, 113, 1),
                                  ),
                                  backgroundColor: Colors.transparent,
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
            ],
          ] else ...[
            Center(
              child: Column(
                children: [
                  SizedBox(height: h(113)),
                  FadeTransition(
                    opacity: animOpacity,
                    child: SlideTransition(
                      position: animOffset,
                      child: LottieBuilder.asset(
                        "assets/tarjetaActivadaAnim.json",
                        repeat: false,
                        width: w(100),
                        height: h(100),
                      ),
                    ),
                  ),
                  SizedBox(height: h(13)),
                  FadeTransition(
                    opacity: tituloOpacity,
                    child: SlideTransition(
                      position: tituloOffset,
                      child: Text(
                        "¡Tarjeta Activada!",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "PoppinsBold",
                          fontSize: sp(30),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h(13)),
                  FadeTransition(
                    opacity: cuerpoOpacity,
                    child: SlideTransition(
                      position: cuerpoOffset,
                      child: Text(
                        "Tu tarjeta física está lista para usar.",
                        style: TextStyle(
                          color: Colors.white60,
                          fontFamily: "PoppinsBold",
                          fontSize: sp(20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h(63)),
                  FadeTransition(
                    opacity: tarjetaOpacity,
                    child: SlideTransition(
                      position: tarjetaOffset,
                      child: Container(
                        width: w(350),
                        height: h(200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(1, 165, 113, 0.878),
                              Color.fromARGB(228, 67, 160, 72),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  FadeTransition(
                                    opacity: codeTarjetaOpacity,
                                    child: SlideTransition(
                                      position: codeTarjetaOffset,
                                      child: Text(
                                        "SendPay",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: sp(23),
                                          fontFamily: "PoppinsBold",
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  FadeTransition(
                                    opacity: codeTarjetaOpacity,
                                    child: SlideTransition(
                                      position: codeTarjetaOffset,
                                      child: Icon(
                                        Icons.credit_card,
                                        color: Colors.white,
                                        size: sp(28),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: h(38)),

                              // Número de tarjeta
                              FadeTransition(
                                opacity: numeroOpacity,
                                child: SlideTransition(
                                  position: numeroOffset,
                                  child: Text(
                                    "**** **** ****${numeroTarjeta.substring(numeroTarjeta.length - 6).trimRight()}",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: sp(23),
                                      fontFamily: "PoppinsBold",
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: h(20)),

                              /// Nombre + fecha
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FadeTransition(
                                        opacity: nombreOpacity,
                                        child: SlideTransition(
                                          position: nombreOffset,
                                          child: Text(
                                            "NOMBRE",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: sp(13),
                                              fontFamily: "PoppinsNormal",
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      FadeTransition(
                                        opacity: nombreOpacity,
                                        child: SlideTransition(
                                          position: nombreOffset,
                                          child: Text(
                                            nombreUser,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: sp(18),
                                              fontFamily: "PoppinsBold",
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FadeTransition(
                                        opacity: vencimientoOpacity,
                                        child: SlideTransition(
                                          position: vencimientoOffset,
                                          child: Text(
                                            "VENCE",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: sp(13),
                                              fontFamily: "PoppinsNormal",
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      FadeTransition(
                                        opacity: vencimientoOpacity,
                                        child: SlideTransition(
                                          position: vencimientoOffset,
                                          child: Text(
                                            vencimientoTarjeta,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: sp(18),
                                              fontFamily: "PoppinsBold",
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h(83)),
                  FadeTransition(
                    opacity: botonOpacity,
                    child: SlideTransition(
                      position: botonOffset,
                      child: GestureDetector(
                        child: Container(
                          height: h(53),
                          width: w(350),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            gradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(1, 165, 113, 0.878),
                                Color.fromARGB(228, 67, 160, 72),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(350)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Finalizar",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "PoppinsBold",
                                      fontSize: sp(18),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: w(23)),
                              AnimatedBuilder(
                                animation: _iconAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(_iconAnimation.value, 0),
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  LucideIcons.checkCircle,
                                  color: Colors.white,
                                  size: sp(20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Vibration.vibrate(duration: 5);
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.rightToLeft,
                              child: MenuPrincipalPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          IgnorePointer(
            ignoring: true,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _CirclePatternPainter(
                    animationValue: _controller.value,
                  ),
                );
              },
            ),
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
    ];

    final radii = [10.0, 5.0, 10.0, 8.0, 8.0];
    final opacities = [0.1, 0.15, 0.12, 0.08, 0.10];

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
