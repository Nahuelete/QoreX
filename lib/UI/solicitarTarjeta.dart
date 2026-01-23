// ignore_for_file: deprecated_member_use, unused_element_parameter, camel_case_types, use_key_in_widget_constructors, file_names, sized_box_for_whitespace, unused_field, avoid_print, prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation

import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:vibration/vibration.dart';

class solicitarTarjetaPage extends StatefulWidget {
  @override
  State<solicitarTarjetaPage> createState() => _solicitarTarjetaPageState();
}

class _solicitarTarjetaPageState extends State<solicitarTarjetaPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  late AnimationController _controllerTarjetas;

  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  late AnimationController _controllerContainer;
  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;

  final TextEditingController _controllerAddress = TextEditingController();
  final TextEditingController _controllerCodigoPostal = TextEditingController();

  Map<String, List<String>> provinciasYCiudades = {
    'Buenos Aires': [
      'La Plata',
      'Mar del Plata',
      'Bahía Blanca',
      'Tandil',
      'Junín',
    ],
    'Ciudad Autónoma de Buenos Aires': ['Buenos Aires'],
    'Catamarca': [
      'San Fernando del Valle de Catamarca',
      'Belén',
      'Tinogasta',
      'Andalgalá',
    ],
    'Chaco': [
      'Resistencia',
      'Presidencia Roque Sáenz Peña',
      'Charata',
      'Villa Ángela',
    ],
    'Chubut': ['Rawson', 'Trelew', 'Comodoro Rivadavia', 'Puerto Madryn'],
    'Córdoba': [
      'Córdoba',
      'Villa Carlos Paz',
      'Río Cuarto',
      'Villa María',
      'San Francisco',
    ],
    'Corrientes': ['Corrientes', 'Goya', 'Mercedes', 'Paso de los Libres'],
    'Entre Ríos': ['Paraná', 'Concordia', 'Gualeguaychú', 'Villaguay'],
    'Formosa': ['Formosa', 'Clorinda', 'Pirané', 'Las Lomitas'],
    'Jujuy': ['San Salvador de Jujuy', 'Palpalá', 'Perico', 'La Quiaca'],
    'La Pampa': ['Santa Rosa', 'General Pico', 'Toay', 'Realicó'],
    'La Rioja': ['La Rioja', 'Chilecito', 'Aimogasta', 'Famatina'],
    'Mendoza': ['Mendoza', 'San Rafael', 'San Martín', 'Tunuyán'],
    'Misiones': ['Posadas', 'Eldorado', 'Oberá', 'Puerto Iguazú'],
    'Neuquén': ['Neuquén', 'San Martín de los Andes', 'Zapala', 'Cutral Có'],
    'Río Negro': [
      'Viedma',
      'San Carlos de Bariloche',
      'General Roca',
      'Cipolletti',
    ],
    'Salta': ['Salta', 'San Ramón de la Nueva Orán', 'Tartagal', 'Metán'],
    'San Juan': ['San Juan', 'Rivadavia', 'Chimbas'],
    'San Luis': ['San Luis', 'Villa Mercedes', 'Merlo', 'La Punta'],
    'Santa Cruz': [
      'Río Gallegos',
      'El Calafate',
      'Caleta Olivia',
      'Puerto Deseado',
    ],
    'Santa Fe': ['Santa Fe', 'Rosario', 'Rafaela', 'Venado Tuerto'],
    'Santiago del Estero': [
      'Santiago del Estero',
      'La Banda',
      'Termas de Río Hondo',
      'Añatuya',
    ],
    'Tierra del Fuego': ['Ushuaia', 'Río Grande', 'Tolhuin'],
    'Tucumán': [
      'San Miguel de Tucumán',
      'Concepción',
      'Yerba Buena',
      'Tafí Viejo',
    ],
  };

  String? provinciaSeleccionada;
  String? ciudadSeleccionada;

  bool presentacionVis = true;
  bool paso1Vis = false;
  bool paso2Vis = false;
  bool confirmarDatosVis = false;
  bool solicitudConfirmadaVis = false;
  bool solicitudRealizadaVis = false;

  bool esperando = false;

  int currentStep = 1;

  String userUid = "";
  String nameUser = "";
  String emailUser = "";
  String dniUser = "";

  Future<void> obtenerDatos() async {
    userUid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection("Usuarios")
        .doc(userUid)
        .snapshots()
        .listen((docSnapshot) {
          if (!mounted) return;

          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            nameUser = data["Nombre"] ?? "";
            emailUser = data["Email"] ?? "";
            dniUser = data["Dni"] ?? "";
          }
        });
  }

  Future<void> crearSolicitud() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);

    //Calcular Fecha Entrega Estimada
    String fechaOriginal = fecha;

    // Sumar 7 días
    DateTime fecha7 = DateFormat("dd-MM-yyyy").parse(fechaOriginal);

    DateTime nuevaFecha7 = fecha7.add(Duration(days: 7));

    String fechaEstimada7 = DateFormat("dd").format(nuevaFecha7);

    // Sumar 10 días
    DateTime fecha10 = DateFormat("dd-MM-yyy").parse(fechaOriginal);

    DateTime nuevaFecha10 = fecha10.add(Duration(days: 10));

    String fechaEstimada10 = DateFormat("dd").format(nuevaFecha10);

    String mesFechaEstimada = "";

    switch (DateFormat("MM").format(fecha7)) {
      case "01":
        mesFechaEstimada = "Ene" + " " + DateFormat("yyyy").format(fecha7);
        break;
      case "02":
        mesFechaEstimada = "Feb" + " " + DateFormat("yyyy").format(fecha7);
        break;
      case "03":
        mesFechaEstimada = "Mar" + " " + DateFormat("yyyy").format(fecha7);
        break;
      case "04":
        mesFechaEstimada = "Abr" + " " + DateFormat("yyyy").format(fecha7);
        break;
      case "05":
        mesFechaEstimada = "May" + " " + DateFormat("yyyy").format(fecha7);
        break;
      case "06":
        mesFechaEstimada = "Jun" + " " + DateFormat("yyyy").format(fecha7);
        break;
      case "07":
        mesFechaEstimada = "Jul" + " " + DateFormat("yyyy").format(fecha7);
        break;
      case "08":
        mesFechaEstimada = "Ago" + " " + DateFormat("yyyy").format(fecha7);
        break;
      case "09":
        mesFechaEstimada = "Sep" + " " + DateFormat("yyyy").format(fecha7);
        break;
      case "10":
        mesFechaEstimada = "Oct" + " " + DateFormat("yyyy").format(fecha7);
        break;
      case "11":
        mesFechaEstimada = "Nov" + " " + DateFormat("yyyy").format(fecha7);
        break;
      case "12":
        mesFechaEstimada = "Dic" + " " + DateFormat("yyyy").format(fecha7);
        break;
    }

    //Eliminar Notificacion Tarjeta Cancelada
    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Tarjeta Cancelada #$userUid")
        .delete();

    FirebaseFirestore.instance
        .collection("SolicitudesTarjetas")
        .doc("Solicitud $userUid")
        .set({
          "User ID": userUid,
          "Tipo": "Original",
          "Estado": "Solicitada",
          "Fecha Solicitud": fecha,
          "Entrega Estimada":
              "$fechaEstimada7 - $fechaEstimada10 de $mesFechaEstimada",
          "Direccion":
              "${_controllerAddress.text}, ${ciudadSeleccionada!}, ${provinciaSeleccionada!}",
          "Nombre": nameUser,
          "Dni": dniUser,
        });
  }

  Future<void> crearNotificacionSolicitud() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    try {
      await FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc("Notificacion Solicitud Tarjeta #$userUid")
          .set({
            "Tipo": "Solicitud Tarjeta",
            "Nombre": nameUser,
            "Uid": userUid,
            "Fecha": fecha,
            "Hora": horaActual,
            "FechaTime": Timestamp.fromDate(ahora),
            "ID Solicitud Tarjeta": userUid,
            "Leida": {userUid: false},
            "Involucra": [userUid],
          });

      print("Notificacion Solicitud Tarjeta creadas ✅");
    } catch (e, st) {
      print("Error al crear la notificacion: $e");
      print(st);
    }
  }

  Future<void> actualizarTarjetaUser() async {
    FirebaseFirestore.instance.collection("Usuarios").doc(userUid).update({
      "Tarjeta": "Solicitada",
    });
  }

  void nextStep() {
    if (currentStep < 2) {
      setState(() {
        currentStep++;
      });
    } else {
      setState(() {
        currentStep = 1;
      });
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

  @override
  void initState() {
    super.initState();

    obtenerDatos();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _iconAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _controllerTarjetas = AnimationController(
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
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconController.dispose();
    _controllerTarjetas.dispose();
    _controllerContainer.dispose();
    _controllerContainerMovimiento.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        body: Stack(
          children: [
            SizedBox(child: presentacion()),
            SizedBox(child: paso1()),
            SizedBox(child: paso2()),
            SizedBox(child: confirmarDatos()),
            SizedBox(child: solicitudRealizada()),
          ],
        ),
      ),
    );
  }

  Widget presentacion() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: presentacionVis,
      child: Center(
        child: Container(
          width: w(400),
          height: h(630),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF1B2735), Color(0xFF0D1421)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 15,
                offset: Offset(0, 8),
                spreadRadius: 1,
              ),
            ],
            border: Border.all(color: Color.fromRGBO(1, 165, 113, 1), width: 1),
          ),
          child: Stack(
            children: [
              Opacity(
                opacity: 0.3,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _TarjetasPatternPainter(
                        animationValue: _controllerTarjetas.value,
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.transparent),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tarjeta
                    LottieBuilder.asset(
                      "assets/tarjetaPresentacion.json",
                      height: h(153),
                      width: w(153),
                      repeat: false,
                    ),
                    SizedBox(height: h(15)),
                    // Envio gratuito
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w(10),
                        vertical: h(5),
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: Colors.green,
                            size: sp(15),
                          ),
                          SizedBox(width: w(5)),
                          Text(
                            'ENVÍO GRATUITO',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: sp(13),
                              fontFamily: "Poppins",
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: h(15)),
                    // Texto principal
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Tu tarjeta física\n',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sp(20),
                          fontFamily: "PoppinsBold",
                        ),
                        children: [
                          TextSpan(
                            text: 'sin costo alguno',
                            style: TextStyle(
                              color: Color(0xFF00D395),
                              fontFamily: "PoppinsBold",
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: h(23)),
                    Text(
                      'Lleva tu wallet a todos lados. Paga, move y compra en cualquier parte del mundo con total seguridad.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: sp(13),
                        fontFamily: "Poppins",
                      ),
                    ),
                    SizedBox(height: h(33)),
                    // Iconos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _featureIcon(
                          Icons.flash_on,
                          'Pagos NFC',
                          'Sin contacto',
                          Colors.orange,
                        ),
                        _featureIcon(
                          Icons.account_balance,
                          'Retiros ATM',
                          'En todo el país',
                          Colors.blue,
                        ),
                        _featureIcon(
                          Icons.public,
                          'Internacional',
                          'Compras globales',
                          Colors.purple,
                        ),
                        _featureIcon(
                          Icons.shield,
                          'Seguridad',
                          'Protección total',
                          Colors.red,
                        ),
                      ],
                    ),
                    SizedBox(height: h(33)),
                    // Boton principal
                    SizedBox(
                      width: double.infinity,
                      child: Container(
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
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Vibration.vibrate(duration: 5);
                            setState(() {
                              presentacionVis = false;
                              paso1Vis = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: h(15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Solicitar mi tarjeta',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: sp(15),
                                  fontFamily: "PoppinsBold",
                                ),
                              ),
                              SizedBox(width: 13),
                              AnimatedBuilder(
                                animation: _iconAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(_iconAnimation.value, 0),
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
                      ),
                    ),
                    SizedBox(height: h(20)),
                    GestureDetector(
                      child: Container(
                        height: 33,
                        width: 300,
                        child: Center(
                          child: Text(
                            'Tal vez después',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: sp(15),
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 30,
                right: 30,
                child: GestureDetector(
                  child: Container(
                    width: w(30),
                    height: h(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: sp(18)),
                  ),
                  onTap: () {
                    Vibration.vibrate(duration: 5);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget paso1() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: (paso1Vis == true && currentStep == 1),
      child: Center(
        child: Container(
          width: w(400),
          height: h(688),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF1B2735), Color(0xFF0D1421)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 15,
                offset: Offset(0, 8),
                spreadRadius: 1,
              ),
            ],
            border: Border.all(color: Color.fromRGBO(1, 165, 113, 1), width: 1),
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
                    ),
                  );
                },
              ),
              Container(
                width: w(400),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.transparent),
                child: Column(
                  children: [
                    SizedBox(height: h(13)),
                    // Indicador de pasos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          width: w(40),
                          height: h(40),
                          decoration: BoxDecoration(
                            color: currentStep == 1
                                ? Color.fromRGBO(1, 165, 113, 1)
                                : Colors.green.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: currentStep == 1
                                ? Text(
                                    "1",
                                    style: TextStyle(
                                      color: currentStep == 1
                                          ? Colors.white
                                          : Colors.white60,
                                      fontFamily: "PoppinsBold",
                                    ),
                                  )
                                : Icon(LucideIcons.check, color: Colors.white),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: w(13)),
                          height: h(3),
                          width: w(40),
                          color: (currentStep == 1
                              ? Colors.white60
                              : Color.fromRGBO(1, 165, 113, 1)),
                        ),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          width: w(40),
                          height: h(40),
                          decoration: BoxDecoration(
                            color: currentStep == 2
                                ? Color.fromRGBO(1, 165, 113, 1)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "2",
                              style: TextStyle(
                                color: currentStep == 2
                                    ? Colors.white
                                    : Colors.white60,
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h((33))),
                    Text(
                      "Confirma tus datos",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "PoppinsBold",
                        fontSize: sp(23),
                      ),
                    ),
                    SizedBox(height: h((8))),
                    Text(
                      "Verifica que tu información sea correcta.",
                      style: TextStyle(
                        color: Colors.white60,
                        fontFamily: "PoppinsBold",
                        fontSize: sp(15),
                      ),
                    ),
                    SizedBox(height: h(23)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w(20),
                        vertical: h(13),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent, // Fondo oscuro
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Etiqueta con ícono
                          Text(
                            "Nombre completo",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: sp(15),
                              fontFamily: "Poppins",
                            ),
                          ),
                          SizedBox(height: h(8)),

                          // Texto mostrado (simula el contenido del TextField)
                          Container(
                            width: w(350),
                            height: 43,
                            padding: EdgeInsets.symmetric(
                              horizontal: w(10),
                              vertical: h(13),
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  nameUser,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: sp(15),
                                    fontFamily: "Poppins",
                                  ),
                                ),
                                Icon(
                                  LucideIcons.lock,
                                  color: Colors.white60,
                                  size: sp(15),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 23),
                          Text(
                            "Email",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: sp(15),
                              fontFamily: "Poppins",
                            ),
                          ),
                          SizedBox(height: h(8)),

                          // Texto mostrado (simula el contenido del TextField)
                          Container(
                            width: w(350),
                            height: 43,
                            padding: EdgeInsets.symmetric(
                              horizontal: w(10),
                              vertical: h(13),
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  emailUser,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: sp(15),
                                    fontFamily: "Poppins",
                                  ),
                                ),
                                Icon(
                                  LucideIcons.lock,
                                  color: Colors.white60,
                                  size: sp(15),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 23),
                          Text(
                            "DNI",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: sp(15),
                              fontFamily: "Poppins",
                            ),
                          ),
                          SizedBox(height: h(8)),

                          // Texto mostrado (simula el contenido del TextField)
                          Container(
                            width: w(350),
                            height: 43,
                            padding: EdgeInsets.symmetric(
                              horizontal: w(10),
                              vertical: h(13),
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dniUser,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: sp(15),
                                    fontFamily: "Poppins",
                                  ),
                                ),
                                Icon(
                                  LucideIcons.lock,
                                  color: Colors.white60,
                                  size: sp(15),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 13),
                    Container(
                      width: w(333),
                      height: h(93),
                      padding: EdgeInsets.symmetric(
                        horizontal: w(13),
                        vertical: h(15),
                      ),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 31, 39, 53),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: Colors.white, width: w(0.1)),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(333)),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    "💡 Estos datos fueron obtenidos de tu\nregistro. Si necesitas actualizarlos, puedes\nhacerlo desde ",
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontFamily: "Poppins",
                                  fontSize: sp(13),
                                ),
                              ),
                              TextSpan(
                                text: "Tu Perfil (👤).",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontFamily: "Poppins",
                                  fontSize: sp(13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 23),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          child: Container(
                            height: h(53),
                            width: w(150),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.1),
                              ),
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(100)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Atras",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            Vibration.vibrate(duration: 5);
                            setState(() {
                              paso1Vis = false;
                              presentacionVis = true;
                              currentStep = 1;
                            });
                          },
                        ),
                        GestureDetector(
                          child: Container(
                            height: h(53),
                            width: w(150),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromRGBO(1, 165, 113, 1),
                                  Colors.green.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Center(
                              child: (esperando == false
                                  ? Text(
                                      "Confirmar y continuar",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "Poppins",
                                        fontSize: sp(13),
                                        decoration: TextDecoration.none,
                                      ),
                                    )
                                  : SizedBox(
                                      height: h(23),
                                      width: w(23),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 1,
                                      ),
                                    )),
                            ),
                          ),
                          onTap: () {
                            Vibration.vibrate(duration: 5);
                            setState(() {
                              esperando = true;
                            });
                            Future.delayed(Duration(seconds: 2), () {
                              nextStep();
                              setState(() {
                                paso1Vis = false;
                                paso2Vis = true;
                                esperando = false;
                              });
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 30,
                right: 30,
                child: GestureDetector(
                  child: Container(
                    width: w(30),
                    height: h(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: sp(18)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      paso1Vis = false;
                      presentacionVis = true;
                      currentStep = 1;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget paso2() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: (paso2Vis == true && currentStep == 2),
      child: Center(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            width: w(400),
            height: h(753),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF1B2735), Color(0xFF0D1421)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: Color.fromRGBO(1, 165, 113, 1),
                width: 1,
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
                      ),
                    );
                  },
                ),
                Container(
                  width: w(400),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: h(13)),
                        // Indicador de pasos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              width: w(40),
                              height: h(40),
                              decoration: BoxDecoration(
                                color: currentStep == 1
                                    ? Color.fromRGBO(1, 165, 113, 1)
                                    : Colors.green.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: currentStep == 1
                                    ? Text(
                                        "1",
                                        style: TextStyle(
                                          color: currentStep == 1
                                              ? Colors.white
                                              : Colors.white60,
                                          fontFamily: "PoppinsBold",
                                        ),
                                      )
                                    : Icon(
                                        LucideIcons.check,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: w(13)),
                              height: h(3),
                              width: w(40),
                              color: (currentStep == 1
                                  ? Colors.white60
                                  : Color.fromRGBO(1, 165, 113, 1)),
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              width: w(40),
                              height: h(40),
                              decoration: BoxDecoration(
                                color: currentStep == 2
                                    ? Color.fromRGBO(1, 165, 113, 1)
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "2",
                                  style: TextStyle(
                                    color: currentStep == 2
                                        ? Colors.white
                                        : Colors.white60,
                                    fontFamily: "PoppinsBold",
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: h((33))),
                        Text(
                          "Dirección de envío",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "PoppinsBold",
                            fontSize: sp(23),
                          ),
                        ),
                        SizedBox(height: h((8))),
                        Text(
                          "¿Dónde quieres recibir tu tarjeta?",
                          style: TextStyle(
                            color: Colors.white60,
                            fontFamily: "PoppinsBold",
                            fontSize: sp(15),
                          ),
                        ),
                        SizedBox(height: h(23)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w(20),
                            vertical: h(13),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent, // Fondo oscuro
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Etiqueta con ícono
                              Text(
                                "Direccion",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: sp(15),
                                  fontFamily: "Poppins",
                                ),
                              ),
                              SizedBox(height: h(8)),
                              Container(
                                width: w(350),
                                height: h(53),
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(
                                    20,
                                    25,
                                    50,
                                    1,
                                  ), // fondo oscuro del TextField
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: TextField(
                                    textCapitalization:
                                        TextCapitalization.words,
                                    controller: _controllerAddress,
                                    keyboardType: TextInputType.streetAddress,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Poppins",
                                    ),
                                    cursorColor: Colors.white,
                                    decoration: InputDecoration(
                                      hintText: "Ej: Av. Corrientes 123",
                                      hintStyle: TextStyle(
                                        color: Colors.white60,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: 23),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Provincia
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Provincia",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: sp(15),
                                          fontFamily: "Poppins",
                                        ),
                                      ),
                                      SizedBox(height: h(8)),
                                      Container(
                                        width: w(150),
                                        height: h(53),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 13,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(20, 25, 50, 1),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: provinciaSeleccionada,
                                            hint: Text(
                                              "Eligir Provincia",
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: sp(13),
                                              ),
                                            ),
                                            dropdownColor: Color.fromRGBO(
                                              20,
                                              25,
                                              50,
                                              1,
                                            ),
                                            iconEnabledColor: Colors.white,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: "Poppins",
                                            ),
                                            isExpanded: true,
                                            items: provinciasYCiudades.keys
                                                .map(
                                                  (provincia) =>
                                                      DropdownMenuItem<String>(
                                                        value: provincia,
                                                        child: Text(provincia),
                                                      ),
                                                )
                                                .toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                provinciaSeleccionada = value;
                                                ciudadSeleccionada = null;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(width: w(13)),

                                  // Ciudad
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Ciudad",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: sp(15),
                                          fontFamily: "Poppins",
                                        ),
                                      ),
                                      SizedBox(height: h(8)),
                                      Container(
                                        width: w(150),
                                        height: h(53),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 13,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(20, 25, 50, 1),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: ciudadSeleccionada,
                                            hint: Text(
                                              "Eligir Ciudad",
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: sp(13),
                                              ),
                                            ),
                                            dropdownColor: Color.fromRGBO(
                                              20,
                                              25,
                                              50,
                                              1,
                                            ),
                                            iconEnabledColor: Colors.white,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: "Poppins",
                                            ),
                                            isExpanded: true,
                                            items: provinciaSeleccionada == null
                                                ? []
                                                : provinciasYCiudades[provinciaSeleccionada!]!
                                                      .map(
                                                        (ciudad) =>
                                                            DropdownMenuItem<
                                                              String
                                                            >(
                                                              value: ciudad,
                                                              child: Text(
                                                                ciudad,
                                                              ),
                                                            ),
                                                      )
                                                      .toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                ciudadSeleccionada = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 23),
                              Text(
                                "Codigo Postal",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: sp(15),
                                  fontFamily: "Poppins",
                                ),
                              ),
                              SizedBox(height: h(8)),
                              Container(
                                width: w(350),
                                height: h(53),
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(
                                    20,
                                    25,
                                    50,
                                    1,
                                  ), // fondo oscuro del TextField
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: TextField(
                                    controller: _controllerCodigoPostal,
                                    keyboardType: TextInputType.streetAddress,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Poppins",
                                    ),
                                    cursorColor: Colors.white,
                                    decoration: InputDecoration(
                                      hintText: "Ej: C1043",
                                      hintStyle: TextStyle(
                                        color: Colors.white60,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: h(23)),
                              Text(
                                "Pais",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: sp(15),
                                  fontFamily: "Poppins",
                                ),
                              ),
                              SizedBox(height: h(8)),
                              Container(
                                width: w(350),
                                height: h(43),
                                padding: EdgeInsets.symmetric(
                                  horizontal: w(10),
                                  vertical: h(13),
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Argentina",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: sp(15),
                                    fontFamily: "Poppins",
                                  ),
                                ),
                              ),
                              SizedBox(height: h(23)),
                              Visibility(
                                visible:
                                    _controllerAddress.text.isNotEmpty &&
                                    provinciaSeleccionada != null &&
                                    ciudadSeleccionada != null &&
                                    _controllerCodigoPostal.text.isNotEmpty,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w(15),
                                    vertical: h(13),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1B4332),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: Color.fromRGBO(1, 165, 113, 1),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "📦",
                                        style: TextStyle(fontSize: sp(20)),
                                      ),
                                      SizedBox(
                                        width: w(8),
                                      ), // espacio entre icono y texto
                                      Expanded(
                                        child: Text(
                                          "Envío gratuito a tu domicilio.",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "PoppinsBold",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 13),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              child: Container(
                                height: h(53),
                                width: w(150),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: w(0.1),
                                  ),
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: w(100),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Atras",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "Poppins",
                                          fontSize: sp(15),
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () {
                                Vibration.vibrate(duration: 5);
                                setState(() {
                                  paso2Vis = false;
                                  paso1Vis = true;
                                  currentStep = 1;
                                });
                              },
                            ),
                            GestureDetector(
                              child: Container(
                                height: h(53),
                                width: w(150),
                                decoration: BoxDecoration(
                                  gradient:
                                      (_controllerAddress.text.isNotEmpty &&
                                          provinciaSeleccionada != null &&
                                          ciudadSeleccionada != null &&
                                          _controllerCodigoPostal
                                              .text
                                              .isNotEmpty)
                                      ? LinearGradient(
                                          colors: [
                                            Color.fromRGBO(1, 165, 113, 1),
                                            Colors.green.shade600,
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.grey.shade700,
                                            Colors.grey,
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Center(
                                  child: (esperando == false
                                      ? Text(
                                          "Ir a solicitar",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Poppins",
                                            fontSize: sp(17),
                                            decoration: TextDecoration.none,
                                          ),
                                        )
                                      : SizedBox(
                                          height: h(23),
                                          width: w(23),
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 1,
                                          ),
                                        )),
                                ),
                              ),
                              onTap: () {
                                if (_controllerAddress.text.isNotEmpty &&
                                    provinciaSeleccionada != null &&
                                    ciudadSeleccionada != null &&
                                    _controllerCodigoPostal.text.isNotEmpty) {
                                  Vibration.vibrate(duration: 5);
                                  setState(() {
                                    esperando = true;
                                  });
                                  Future.delayed(Duration(seconds: 2), () {
                                    setState(() {
                                      paso2Vis = false;
                                      confirmarDatosVis = true;
                                      esperando = false;
                                    });
                                  });
                                } else {
                                  Vibration.vibrate(duration: 15);
                                  showFlushbarError(
                                    context,
                                    "Completa todos los campos.",
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 30,
                  right: 30,
                  child: GestureDetector(
                    child: Container(
                      width: w(30),
                      height: h(30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white24,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: sp(18),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        paso1Vis = false;
                        presentacionVis = true;
                        currentStep = 1;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget confirmarDatos() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Stack(
      children: [
        if (solicitudConfirmadaVis == true) ...[
          Center(
            child: Container(
              height: h(453),
              width: w(350),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color.fromRGBO(20, 25, 50, 1),
                    Color.fromRGBO(30, 43, 60, 1),
                  ],
                ),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: Colors.green, width: w(1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Center(
                    child: LottieBuilder.asset(
                      "assets/solicitudTarjeta.json",
                      height: h(183),
                      width: w(183),
                      repeat: false,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(200)),
                    child: Text(
                      textAlign: TextAlign.center,
                      "Generando Tu\nTarjeta Prepaga",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "PoppinsBold",
                        fontSize: sp(23),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  SizedBox(height: h(23)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(200)),
                    child: Text(
                      textAlign: TextAlign.center,
                      "Por favor espera un momento...",
                      style: TextStyle(
                        color: Colors.white60,
                        fontFamily: "Poppins",
                        fontSize: sp(18),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  Center(
                    child: LottieBuilder.asset(
                      "assets/cargando.json",
                      height: h(148),
                      width: w(148),
                      repeat: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        Visibility(
          visible: confirmarDatosVis,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: h(83)),
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
                          scale:
                              1 +
                              curved *
                                  0.7, // 🔹 cuando botón crece, onda también
                          child: Opacity(
                            opacity: 0.15 - (curved * 0.15),
                            child: Container(
                              width: w(100),
                              height: h(100),
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
                              width: w(83),
                              height: h(83),
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
                                      size: sp(33),
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
                SizedBox(height: h(13)),
                Text(
                  "Confirma tu solicitud",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "PoppinsBold",
                    fontSize: sp(23),
                  ),
                ),
                SizedBox(height: h((8))),
                Text(
                  "Revisa que toda la información sea correcta.",
                  style: TextStyle(
                    color: Colors.white60,
                    fontFamily: "PoppinsBold",
                    fontSize: sp(15),
                  ),
                ),
                SizedBox(height: h(23)),
                Container(
                  width: w(350),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14223B),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6), // sombra oscura
                        blurRadius: 15, // qué tan difusa es
                        offset: Offset(0, 8), // desplazamiento (x, y)
                        spreadRadius: 1, // qué tanto se expande
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.white, size: sp(23)),
                          SizedBox(width: w(10)),
                          Text(
                            "Datos personales",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(18),
                              fontFamily: "Poppins",
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Nombre completo
                      Row(
                        children: [
                          Container(
                            width: w(43),
                            height: h(43),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1A31),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              color: Color(0xFF21E38F),
                              size: sp(23),
                            ),
                          ),
                          SizedBox(width: w(13)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Nombre completo",
                                  style: TextStyle(
                                    color: Color(0xFF8A97B0),
                                    fontSize: sp(13),
                                    fontFamily: "Poppins",
                                  ),
                                ),
                                SizedBox(height: h(3)),
                                Text(
                                  nameUser,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: sp(15),
                                    fontFamily: "Poppins",
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF21E38F),
                            size: sp(20),
                          ),
                        ],
                      ),

                      SizedBox(height: h(10)),
                      Divider(color: Colors.white.withOpacity(0.1)),
                      SizedBox(height: h(10)),

                      // Email
                      Row(
                        children: [
                          Container(
                            width: w(43),
                            height: h(43),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1A31),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.email_outlined,
                              color: Color(0xFF21E38F),
                              size: sp(23),
                            ),
                          ),
                          SizedBox(width: w(13)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Email",
                                  style: TextStyle(
                                    color: Color(0xFF8A97B0),
                                    fontSize: sp(13),
                                  ),
                                ),
                                SizedBox(height: h(3)),
                                Text(
                                  emailUser,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: sp(15),
                                    fontFamily: "Poppins",
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF21E38F),
                            size: sp(20),
                          ),
                        ],
                      ),

                      SizedBox(height: h(10)),
                      Divider(color: Colors.white.withOpacity(0.1)),
                      SizedBox(height: h(10)),

                      // DNI
                      Row(
                        children: [
                          Container(
                            width: w(43),
                            height: h(43),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1A31),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              LucideIcons.fileText,
                              color: Color(0xFF21E38F),
                              size: sp(23),
                            ),
                          ),
                          SizedBox(width: w(13)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "DNI",
                                  style: TextStyle(
                                    color: Color(0xFF8A97B0),
                                    fontSize: sp(13),
                                  ),
                                ),
                                SizedBox(height: h(3)),
                                Text(
                                  dniUser,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: sp(15),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF21E38F),
                            size: sp(20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h(33)),
                Container(
                  width: w(350),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14223B),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6), // sombra oscura
                        blurRadius: 15, // qué tan difusa es
                        offset: Offset(0, 8), // desplazamiento (x, y)
                        spreadRadius: 1, // qué tanto se expande
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            color: Colors.white,
                            size: sp(23),
                          ),
                          SizedBox(width: w(10)),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(350)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Dirección de envío",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: sp(18),
                                  fontFamily: "Poppins",
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: w(43),
                            height: h(43),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1A31),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.home_outlined,
                              color: Colors.blue,
                              size: sp(23),
                            ),
                          ),
                          SizedBox(width: w(13)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Dirección",
                                style: TextStyle(
                                  color: const Color(0xFF8A97B0),
                                  fontSize: sp(13),
                                  fontFamily: "Poppins",
                                ),
                              ),
                              SizedBox(height: h(3)),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(300)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _controllerAddress.text,
                                    style: TextStyle(
                                      color: Colors.white,
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
                      SizedBox(height: h(10)),
                      Divider(color: Colors.white.withOpacity(0.1)),
                      SizedBox(height: h(10)),

                      // Ciudad y Provincia (dos columnas)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: w(43),
                                  height: h(43),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1A31),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.location_city_outlined,
                                    color: Colors.blue,
                                    size: sp(23),
                                  ),
                                ),
                                SizedBox(width: w(13)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Ciudad",
                                      style: TextStyle(
                                        color: const Color(0xFF8A97B0),
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                      ),
                                    ),
                                    SizedBox(height: h(3)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(73),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          (ciudadSeleccionada ?? ""),
                                          style: TextStyle(
                                            color: Colors.white,
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
                          SizedBox(width: w(16)),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: w(43),
                                  height: h(43),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1A31),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.map_outlined,
                                    color: Colors.blue,
                                    size: sp(23),
                                  ),
                                ),
                                SizedBox(width: w(13)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Provincia",
                                      style: TextStyle(
                                        color: const Color(0xFF8A97B0),
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                      ),
                                    ),
                                    SizedBox(height: h(3)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(73),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          (provinciaSeleccionada ?? ""),
                                          style: TextStyle(
                                            color: Colors.white,
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
                        ],
                      ),

                      SizedBox(height: h(10)),
                      Divider(color: Colors.white.withOpacity(0.1)),
                      SizedBox(height: h(10)),

                      // C.P. y País (dos columnas)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: w(43),
                                  height: h(43),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1A31),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.abc,
                                    color: Colors.blue,
                                    size: sp(23),
                                  ),
                                ),
                                SizedBox(width: w(13)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Cod. Postal",
                                      style: TextStyle(
                                        color: const Color(0xFF8A97B0),
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                      ),
                                    ),
                                    SizedBox(height: h(3)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(73),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _controllerCodigoPostal.text,
                                          style: TextStyle(
                                            color: Colors.white,
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
                          SizedBox(width: w(16)),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: w(43),
                                  height: h(43),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1A31),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.public,
                                    color: Colors.blue,
                                    size: sp(23),
                                  ),
                                ),
                                SizedBox(width: w(13)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "País",
                                      style: TextStyle(
                                        color: const Color(0xFF8A97B0),
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                      ),
                                    ),
                                    SizedBox(height: h(3)),
                                    Text(
                                      "Argentina",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: sp(15),
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h(23)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      child: Container(
                        height: h(53),
                        width: w(150),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white,
                            width: w(0.1),
                          ),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(100)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Atras",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        setState(() {
                          confirmarDatosVis = false;
                          paso2Vis = true;
                        });
                      },
                    ),
                    GestureDetector(
                      child: Container(
                        height: h(53),
                        width: w(150),
                        decoration: BoxDecoration(
                          gradient:
                              (_controllerAddress.text.isNotEmpty &&
                                  provinciaSeleccionada != null &&
                                  ciudadSeleccionada != null &&
                                  _controllerCodigoPostal.text.isNotEmpty)
                              ? LinearGradient(
                                  colors: [
                                    Color.fromRGBO(1, 165, 113, 1),
                                    Colors.green.shade600,
                                  ],
                                )
                              : LinearGradient(
                                  colors: [Colors.grey.shade700, Colors.grey],
                                ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(
                          child: (esperando == false
                              ? Text(
                                  "Solicitar",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(17),
                                    decoration: TextDecoration.none,
                                  ),
                                )
                              : SizedBox(
                                  height: h(23),
                                  width: w(23),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 1,
                                  ),
                                )),
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 15);
                        setState(() {
                          esperando = true;
                        });
                        Future.delayed(Duration(seconds: 3), () {
                          setState(() {
                            confirmarDatosVis = false;
                            solicitudConfirmadaVis = true;
                            esperando = false;
                          });
                          crearSolicitud();
                          crearNotificacionSolicitud();
                          actualizarTarjetaUser();
                        });
                        //Crear Solicitud FIRESTORE
                        Future.delayed(Duration(seconds: 8), () {
                          Vibration.vibrate(duration: 15);
                          setState(() {
                            solicitudConfirmadaVis = false;
                            solicitudRealizadaVis = true;
                          });
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: h(53)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget solicitudRealizada() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: solicitudRealizadaVis,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              //height: h(500),
              width: w(350),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color.fromRGBO(20, 25, 50, 1),
                    Color.fromRGBO(30, 43, 60, 1),
                  ],
                ),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: Colors.green, width: w(1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: h(23)),
                  LottieBuilder.asset(
                    "assets/solicitudTarjetaRealizada.json",
                    height: h(133),
                    width: w(133),
                    repeat: false,
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(300)),
                    child: Text(
                      textAlign: TextAlign.center,
                      "¡Solicitud exitosa!",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "PoppinsBold",
                        fontSize: sp(25),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  SizedBox(height: h(8)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(200)),
                    child: Text(
                      textAlign: TextAlign.center,
                      "Tu tarjeta física ha sido solicitada correctamente y será enviada a tu domicilio.",
                      style: TextStyle(
                        color: Colors.white60,
                        fontFamily: "Poppins",
                        fontSize: sp(18),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  SizedBox(height: h(33)),
                  Container(
                    width: w(300),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(
                        0xFF1E2A3A,
                      ), // Fondo oscuro similar a la imagen
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white, width: 0.1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: w(40),
                              height: h(40),
                              decoration: BoxDecoration(
                                color: Color(0xFF008060), // Verde del icono
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons
                                    .home, // Reemplazar con el icono correcto si tenés
                                color: Colors.white,
                                size: sp(20),
                              ),
                            ),
                            SizedBox(width: w(13)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Direccion De Envio",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: sp(13),
                                    fontFamily: "Poppins",
                                  ),
                                ),
                                SizedBox(height: h(5)),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(250)),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _controllerAddress.text,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: sp(15),
                                        fontFamily: "PoppinsBold",
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: h(15)),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        SizedBox(height: h(15)),
                        Row(
                          children: [
                            Container(
                              width: w(40),
                              height: h(40),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A4B8D), // Azul del icono
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons
                                    .local_shipping, // Reemplazar con el icono correcto si tenés
                                color: Colors.white,
                                size: sp(20),
                              ),
                            ),
                            SizedBox(width: w(13)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Tiempo estimado de entrega",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: sp(13),
                                    fontFamily: "Poppins",
                                  ),
                                ),
                                SizedBox(height: h(5)),
                                Text(
                                  "7-10 días hábiles",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: sp(15),
                                    fontFamily: "PoppinsBold",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: h(23)),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF0C2C36,
                      ), // Fondo verde azulado oscuro
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF1EE3B2), // Borde verde agua
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      "💡 Recibiste un email con los detalles de tu solicitud.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9CF6E9),
                        fontSize: 15,
                        fontFamily: "Poppins",
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: h(33)),
                  GestureDetector(
                    child: Container(
                      height: h(63),
                      width: w(300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(1, 165, 113, 1),
                            Colors.green.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          "Finalizar",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "PoppinsBold",
                            fontSize: 18,
                          ),
                        ),
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
                      setState(() {
                        presentacionVis = true;
                        solicitudRealizadaVis = false;
                        currentStep = 1;
                      });
                    },
                  ),
                  SizedBox(height: 23),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureIcon(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}

class _TarjetasPatternPainter extends CustomPainter {
  final double animationValue;
  _TarjetasPatternPainter({this.animationValue = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cards = [Offset(0.1, 0.2), Offset(0.6, 0.4), Offset(0.1, 0.7)];

    final cardSizes = [Size(83, 50), Size(110, 60), Size(110, 65)];

    for (int i = 0; i < cards.length; i++) {
      double dyOffset = sin(animationValue * 2 * pi + i) * 10;
      final pos = Offset(
        cards[i].dx * size.width,
        cards[i].dy * size.height + dyOffset,
      );

      // Determinar ángulo de rotación
      double angle = 0;
      if (i == 0) angle = 0.1; // Arriba izquierda -> rotar a la derecha
      if (i == 2) angle = -0.1; // Abajo izquierda -> rotar a la izquierda

      canvas.save();
      canvas.translate(
        pos.dx + cardSizes[i].width / 2,
        pos.dy + cardSizes[i].height / 2,
      );
      canvas.rotate(angle);

      // Dibujar tarjeta (más transparente)
      paint.color = Color.fromRGBO(35, 65, 75, 1).withOpacity(1); // antes 0.8
      Rect cardRect = Rect.fromLTWH(
        -cardSizes[i].width / 2,
        -cardSizes[i].height / 2,
        cardSizes[i].width,
        cardSizes[i].height,
      );

      final cardRRect = RRect.fromRectAndRadius(
        cardRect,
        Radius.circular(cardSizes[i].width * 0.1),
      );
      canvas.drawRRect(cardRRect, paint);

      // ➕ Dibujar borde de la tarjeta
      paint
        ..color = Colors.green.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(cardRRect, paint);

      // Restaurar estilo fill para el resto
      paint.style = PaintingStyle.fill;

      // Dibujar chip proporcional (más transparente)
      paint.color = Color.fromRGBO(85, 97, 67, 1).withOpacity(0.5); // antes 0.8
      double chipWidth = cardSizes[i].width * 0.18;
      double chipHeight = cardSizes[i].height * 0.25;
      Rect chipRect = Rect.fromLTWH(
        -cardSizes[i].width / 2 + cardSizes[i].width * 0.08,
        -cardSizes[i].height / 2 + cardSizes[i].height * 0.12,
        chipWidth,
        chipHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chipRect, Radius.circular(chipWidth * 0.05)),
        paint,
      );

      final chipRRect = RRect.fromRectAndRadius(
        chipRect,
        Radius.circular(cardSizes[i].width * 0.07),
      );
      canvas.drawRRect(chipRRect, paint);

      // ➕ Dibujar borde de la tarjeta
      paint
        ..color = Colors.yellow.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(chipRRect, paint);

      // Restaurar estilo fill para el resto
      paint.style = PaintingStyle.fill;

      // Líneas grises (más transparentes)
      paint.color = Colors.white.withOpacity(0.3); // antes 0.4
      double lineY = -cardSizes[i].height / 2 + cardSizes[i].height * 0.65;
      double lineHeight = cardSizes[i].height * 0.06;
      double lineSpacing = cardSizes[i].width * 0.05;
      double lineWidth = cardSizes[i].width * 0.18;
      for (int j = 0; j < 4; j++) {
        double lineX =
            -cardSizes[i].width / 2 +
            cardSizes[i].width * 0.08 +
            j * (lineWidth + lineSpacing);
        canvas.drawRect(
          Rect.fromLTWH(lineX, lineY, lineWidth, lineHeight),
          paint,
        );
      }

      // Línea del nombre del dueño (más transparente)
      paint.color = Colors.grey.withOpacity(0.3); // antes 0.4
      double nameY = -cardSizes[i].height / 2 + cardSizes[i].height * 0.85;
      double nameWidth = cardSizes[i].width * 0.45;
      double nameHeight = cardSizes[i].height * 0.06;
      canvas.drawRect(
        Rect.fromLTWH(
          -cardSizes[i].width / 2 + cardSizes[i].width * 0.08,
          nameY,
          nameWidth,
          nameHeight,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _TarjetasPatternPainter oldDelegate) => true;
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
