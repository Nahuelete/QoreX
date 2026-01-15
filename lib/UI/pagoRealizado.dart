// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, deprecated_member_use, unused_element_parameter, unrelated_type_equality_checks, unused_field, prefer_interpolation_to_compose_strings, avoid_print, unused_element, use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:another_flushbar/flushbar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart' show Lottie;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';

class pagoRealizadoPage extends StatefulWidget {
  final int paginaActual;
  final String qrData;
  final String nameUserExterno;
  final String uidUserExterno;
  final String metodo;
  final String avatarUserExterno;
  final String nombreExtension;
  final int codeQR;
  final double montoQR;
  final double saldoUser;
  final double saldoUserExterno;
  final double valorLimiteExtension;
  final String codeTarjetaExterno;
  final bool limiteExterno;
  final double limiteGastadoExterno;
  final double saldoOriginarioExtension;
  final String uidOriginarioExtension;
  final String medioPago;

  const pagoRealizadoPage({
    super.key,
    required this.qrData,
    required this.paginaActual,
    required this.nameUserExterno,
    required this.uidUserExterno,
    required this.avatarUserExterno,
    required this.codeQR,
    required this.metodo,
    required this.montoQR,
    required this.saldoUser,
    required this.saldoUserExterno,
    required this.codeTarjetaExterno,
    required this.limiteExterno,
    required this.limiteGastadoExterno,
    required this.nombreExtension,
    required this.saldoOriginarioExtension,
    required this.uidOriginarioExtension,
    required this.medioPago,
    required this.valorLimiteExtension,
  });

  @override
  State<pagoRealizadoPage> createState() => _pagoRealizadoPageState();
}

class _pagoRealizadoPageState extends State<pagoRealizadoPage>
    with TickerProviderStateMixin {
  ScreenshotController screenshotController = ScreenshotController();

  final GlobalKey _reciboKey = GlobalKey();

  late AnimationController _controller;

  late AnimationController _controllerContainer;

  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;

  late AnimationController _controllerSmooth;

  late Animation<Offset> _offsetAnimationContainerCentral;
  final double offsetY = 3.0;

  late AnimationController _controllerAnimPago;

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool animMarcarFavoritoVis = true;
  bool animDesmarcarFavoritoVis = false;

  bool playAnimacionMarcarFavorito = false;
  bool playAnimacionDesmarcarFavorito = false;

  //QR
  String uidUser = "";
  String nameUser = "";
  String dniUser = "";
  String avatarUser = "";
  double saldoUser = 0.0;
  String fecha = "";
  String hora = "";
  String codeTarjetaUser = "";

  bool isFinished = false;
  bool descargando = false;
  bool descargado = false;
  bool errorDescarga = false;
  //Fin QR

  //Configuracion Tarjeta
  bool limiteActivado = false;
  double limite = 0.0;
  double limiteGastado = 0.0;

  Future<void> _playStepAudio(int step) async {
    String assetPath = "";
    switch (step) {
      case 0:
        assetPath = "audios/pagoCompletado.mp3";
        break;
    }

    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print("Error reproduciendo audio: $e");
    }
  }

  Future<void> obtenerDatos() async {
    setState(() {
      uidUser = FirebaseAuth.instance.currentUser!.uid;
    });

    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(uidUser)
        .get();

    if (docSnapshot.exists) {
      Map<String, dynamic> data2 = docSnapshot.data() as Map<String, dynamic>;

      setState(() {
        saldoUser = (data2["Saldo"] as num).toDouble();
        nameUser = data2["Nombre"] ?? "";
        dniUser = data2["Dni"] ?? "";
        avatarUser = data2["Avatar"] ?? "";
        codeTarjetaUser = data2["Tarjeta"] ?? "";
      });

      //Verificar Limite
      verificarLimiteTarjeta();

      final ahoraNow = DateTime.now();
      fecha = DateFormat('dd-MM-yyyy').format(ahoraNow);
      hora =
          "${ahoraNow.hour.toString().padLeft(2, '0')}:${ahoraNow.minute.toString().padLeft(2, '0')}";
    }
  }

  Future<void> verificarLimiteTarjeta() async {
    FirebaseFirestore.instance
        .collection("Tarjetas")
        .doc(codeTarjetaUser)
        .snapshots()
        .listen((docSnapshot) {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              limiteActivado = data["Limite Estado"] ?? false;
              limite = (data["Limite"] != null)
                  ? (data["Limite"] as num).toDouble()
                  : 0.0;
              limiteGastado = (data["Limite Usado"] != null)
                  ? (data["Limite Usado"] as num).toDouble()
                  : 0.0;
            });
          }
        });
  }

  Future<void> verificarFavoritos() async {
    await obtenerDatos();

    final doc = await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(uidUser)
        .collection("Favoritos")
        .doc(widget.uidUserExterno)
        .get();

    if (doc.exists) {
      setState(() {
        animDesmarcarFavoritoVis = false;
        animMarcarFavoritoVis = true;
        playAnimacionMarcarFavorito = true;
      });
    } else {
      setState(() {
        animMarcarFavoritoVis = false;
        animDesmarcarFavoritoVis = true;
        playAnimacionDesmarcarFavorito = true;
        playAnimacionMarcarFavorito = false;
      });
    }
  }

  Future<void> realizarTransaccion() async {
    // Esperar a obtener los datos
    await obtenerDatos();
    await verificarLimiteTarjeta();

    try {
      if (widget.paginaActual < 2) {
        //Usuario Envia
        //Actualizar saldo
        await FirebaseFirestore.instance
            .collection("Usuarios")
            .doc(uidUser)
            .update({"Saldo": saldoUser - widget.montoQR});

        //Actualiza Recibo
        await FirebaseFirestore.instance
            .collection("Recibos")
            .doc(widget.qrData)
            .update({"Estado": "Pago"});

        if (limiteActivado == true) {
          //Actualiza Limite Usado
          await FirebaseFirestore.instance
              .collection("Tarjetas")
              .doc(codeTarjetaUser)
              .update({"Limite Usado": limiteGastado + widget.montoQR});
        }

        //Usuario Recibe
        await FirebaseFirestore.instance
            .collection("Usuarios")
            .doc(widget.uidUserExterno)
            .update({"Saldo": widget.saldoUserExterno + widget.montoQR});

        notificacionMovimiento();
        actualizarMovimientos();
      } else {
        //Extension
        //Actualizar saldo
        await FirebaseFirestore.instance
            .collection("Usuarios")
            .doc(widget.uidOriginarioExtension)
            .update({
              "Saldo": widget.saldoOriginarioExtension - widget.montoQR,
            });

        //Actualiza Recibo
        await FirebaseFirestore.instance
            .collection("Recibos")
            .doc(widget.qrData)
            .update({"Estado": "Pago"});

        if (widget.limiteExterno == true) {
          //Actualiza Limite Usado
          await FirebaseFirestore.instance
              .collection("Extensiones")
              .doc("Extension ${widget.nombreExtension}")
              .update({
                "Limite Usado": widget.limiteGastadoExterno + widget.montoQR,
              });
        }

        //Usuario Recibe
        await FirebaseFirestore.instance
            .collection("Usuarios")
            .doc(widget.uidUserExterno)
            .update({"Saldo": widget.saldoUserExterno + widget.montoQR});

        notificacionMovimiento();
        notificacionGastoExtension();
        actualizarMovimientos();
      }

      _playStepAudio(0);
    } catch (e) {
      print("Error al realizar la transaccion: $e");
    }
  }

  Future<void> notificacionMovimiento() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    String horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    try {
      await FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc("Notificacion Transaccion #${widget.qrData}")
          .set({
            "Tipo": "Movimiento",
            "De": nameUser,
            "De uid": uidUser,
            "Avatar Envia": avatarUser,
            "Avatar Recibe": widget.avatarUserExterno,
            "Para": widget.nameUserExterno,
            "Para uid": widget.uidUserExterno,
            "Monto": widget.montoQR,
            "Medio De Pago": widget.medioPago,
            "Fecha": fecha, // 🔹 string solo para mostrar (dd-MM-yyyy)
            "Hora": horaActual, // 🔹 string solo para mostrar
            "FechaTime": Timestamp.fromDate(
              ahora,
            ), // 🔹 este es el que se usa en queries
            "ID Recibo": widget.qrData,
            "Metodo": widget.metodo,
            "Leida": {uidUser: false, widget.uidUserExterno: false},
            "Involucra": [uidUser, widget.uidUserExterno],
          });

      if (widget.paginaActual > 1) {
        await FirebaseFirestore.instance
            .collection("Notificaciones")
            .doc("Notificacion Transaccion #${widget.qrData}")
            .update({
              "Nombre Extension": widget.nombreExtension,
              "Originario": widget.uidOriginarioExtension,
            });
      }

      print("Notificacion Movimiento creadas ✅");
    } catch (e, st) {
      print("Error al crear la notificacion: $e");
      print(st);
    }
  }

  Future<void> notificacionGastoExtension() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    String horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    try {
      await FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc("Notificacion Gasto Extension #${widget.qrData}")
          .set({
            "Tipo": "Gasto Virtual Extension",
            "De": nameUser,
            "De uid": uidUser,
            "Avatar Envia": avatarUser,
            "Avatar Recibe": widget.avatarUserExterno,
            "Para": widget.nameUserExterno,
            "Para uid": widget.uidUserExterno,
            "Monto": widget.montoQR,
            "Medio De Pago": widget.medioPago,
            "Fecha": fecha, // 🔹 string solo para mostrar (dd-MM-yyyy)
            "Hora": horaActual, // 🔹 string solo para mostrar
            "FechaTime": Timestamp.fromDate(
              ahora,
            ), // 🔹 este es el que se usa en queries
            "ID": widget.codeQR,
            "Metodo": widget.metodo,
            "Leida": {widget.uidOriginarioExtension: false},
            "Involucra": [widget.uidOriginarioExtension],
          });

      if (widget.paginaActual > 1) {
        await FirebaseFirestore.instance
            .collection("Notificaciones")
            .doc("Notificacion Gasto Extension #${widget.qrData}")
            .update({
              "Nombre Extension": widget.nombreExtension,
              "Originario": widget.uidOriginarioExtension,
              "Limite Restante":
                  widget.valorLimiteExtension -
                  (widget.limiteGastadoExterno + widget.montoQR),
              "De Dni": dniUser,
            });
      }

      print("Notificacion Movimiento creadas ✅");
    } catch (e, st) {
      print("Error al crear la notificacion: $e");
      print(st);
    }
  }

  Future<void> actualizarMovimientos() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    String horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";
    try {
      await FirebaseFirestore.instance
          .collection("Transacciones")
          .doc("Transaccion #" + widget.codeQR.toString())
          .set({
            "De": nameUser,
            "De uid": uidUser,
            "Para": widget.nameUserExterno,
            "Para uid": widget.uidUserExterno,
            "Monto": widget.montoQR,
            "Estado": "Pago",
            "Fecha": fecha,
            "Hora": horaActual,
            "Metodo": widget.metodo,
            "ID": widget.codeQR,
            "Medio De Pago": widget.medioPago,
          });

      if (widget.paginaActual > 1) {
        await FirebaseFirestore.instance
            .collection("Transacciones")
            .doc("Transaccion #" + widget.codeQR.toString())
            .update({
              "Nombre Extension": widget.nombreExtension,
              "Originario": widget.uidOriginarioExtension,
            });
      }
    } catch (e) {
      print("Error al actualizar movimientos: $e");
    }
  }

  Future<void> marcarFavorito() async {
    FirebaseFirestore.instance
        .collection("Usuarios")
        .doc(uidUser)
        .collection("Favoritos")
        .doc(widget.uidUserExterno)
        .set({
          "Uid": widget.uidUserExterno,
          "Nombre": widget.nameUserExterno,
          "Avatar": widget.avatarUserExterno,
        }, SetOptions(merge: true));
  }

  Future<void> desmarcarFavorito() async {
    FirebaseFirestore.instance
        .collection("Usuarios")
        .doc(uidUser)
        .collection("Favoritos")
        .doc(widget.uidUserExterno)
        .delete();
  }

  Future<void> capturarYCompartir() async {
    try {
      // Capturamos el widget
      final image = await screenshotController.capture();
      if (image == null) return;

      // Guardamos en archivo temporal
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/captura.png');
      await file.writeAsBytes(image);

      // Compartimos el archivo
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: "Te comparto el comprobante.");
    } catch (e) {
      print("❌ Error capturando/compartiendo: $e");
      showFlushbarError(context, "Error al compartir el recibo.");
    }
  }

  Future<File?> _guardarTemporal(Uint8List image) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/captura.png');
    await file.writeAsBytes(image);
    return file;
  }

  Future<void> capturarYDescargar() async {
    try {
      RenderRepaintBoundary boundary =
          _reciboKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: "recibo_${DateTime.now().millisecondsSinceEpoch}",
      );

      print("Resultado: $result");
    } catch (e) {
      print("❌ Error al capturar: $e");
      showFlushbarError(context, "Error al descargar el recibo.");
      setState(() {
        errorDescarga = true;
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
        colors: [Colors.red, Colors.redAccent],
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

    realizarTransaccion();

    verificarFavoritos();

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        isFinished = true;
      });
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _controllerAnimPago = AnimationController(vsync: this);

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

    _controllerSmooth = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _controllerContainerMovimiento.repeat();

    _offsetAnimationContainerCentral =
        Tween<Offset>(begin: Offset(0, offsetY), end: Offset.zero).animate(
          CurvedAnimation(parent: _controllerSmooth, curve: Curves.decelerate),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    _controllerContainer.dispose();
    _controllerContainerMovimiento.dispose();
    _controllerSmooth.dispose();
    _controllerAnimPago.dispose();
    _audioPlayer.dispose();
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
          colors: [Color(0xFF1B2735), Color(0xFF0D1421)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: !isFinished
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        "Recibo",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "PoppinsBold",
                          fontSize: sp(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        body: Stack(
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
            SizedBox(
              child: Align(alignment: Alignment.topCenter, child: reciboPago()),
            ),
            // Capa verde animada
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: Duration(seconds: 1),
                curve: Curves.easeOut,
                width: double.infinity,
                height: !isFinished
                    ? screenHeight
                    : 0, // empieza en 0 y crece hasta pantalla completa
                color: (widget.paginaActual == 0
                    ? Color.fromRGBO(1, 165, 113, 1)
                    : widget.paginaActual == 1
                    ? Colors.blue
                    : Colors.purpleAccent),
                child: Center(
                  child: SizedBox(
                    height: h(200),
                    child: Lottie.asset(
                      (widget.paginaActual == 0
                          ? "assets/pagoRealizadoVerde.json"
                          : widget.paginaActual == 1
                          ? "assets/pagoRealizadoAzul.json"
                          : "assets/pagoRealizadoVioleta.json"),
                      controller: _controllerAnimPago,
                      repeat: false,
                      fit: BoxFit.contain,
                      onLoaded: (composition) {
                        _controllerAnimPago.duration = composition.duration;
                        _controllerAnimPago.value = 1.0;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget reciboPago() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Stack(
      children: [
        compartirRecibo(),
        Column(
          children: [
            SizedBox(height: h(13)),
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
                          curved * 0.7, // 🔹 cuando botón crece, onda también
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
                                  width: w(0.1),
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
                                  LucideIcons.checkCircle,
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
            SizedBox(height: h(8)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w(400)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Pago Exitoso",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "PoppinsBold",
                    fontSize: sp(25),
                  ),
                ),
              ),
            ),
            SizedBox(height: h(8)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w(400)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Tu pago se realizó correctamente.",
                  style: TextStyle(
                    color: Colors.white60,
                    fontFamily: "Poppins",
                    fontSize: sp(18),
                  ),
                ),
              ),
            ),
            SizedBox(height: h(23)),
            Container(
              width: w(350),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color.fromRGBO(28, 33, 53, 1), // fondo oscuro
                borderRadius: BorderRadius.circular(23),
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
                  // MONTO
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: h(8)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(330)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: MoneyCounter(
                              amount: widget.montoQR,
                              showBalance: true,
                            ),
                          ),
                        ),
                        SizedBox(height: h(3)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(330)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "ARS",
                              style: TextStyle(
                                fontSize: sp(13),
                                color: Colors.white60,
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h(10)),
                  Divider(color: Colors.white60, thickness: h(1)),
                  SizedBox(height: h(10)),

                  // CAMPOS DENTRO DEL MISMO CONTAINER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(250)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Para",
                            style: TextStyle(
                              fontSize: sp(14),
                              color: Colors.white60,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(250)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.nameUserExterno,
                            style: TextStyle(
                              fontSize: sp(14),
                              color: Colors.white,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h(13)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(250)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Método",
                            style: TextStyle(
                              fontSize: sp(14),
                              color: Colors.white60,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(250)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.metodo,
                            style: TextStyle(
                              fontSize: sp(14),
                              fontFamily: "Poppins",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h(13)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(250)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Pago",
                            style: TextStyle(
                              fontSize: sp(14),
                              color: Colors.white60,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(250)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.paginaActual == 0
                                ? "Fondos de cuenta"
                                : widget.paginaActual == 1
                                ? "Mi Tarjeta"
                                : widget.paginaActual > 1
                                ? "Extension"
                                : "",
                            style: TextStyle(
                              fontSize: sp(14),
                              fontFamily: "Poppins",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h(13)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(250)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Fecha",
                            style: TextStyle(
                              fontSize: sp(14),
                              color: Colors.white60,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(250)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "$fecha, $hora",
                            style: TextStyle(
                              fontSize: sp(14),
                              fontFamily: "Poppins",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h(13)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(250)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "ID Transacción",
                            style: TextStyle(
                              fontSize: sp(14),
                              color: Colors.white60,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(250)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "#${widget.qrData.replaceAll(RegExp(r'[^0-9]'), '')}",
                            style: TextStyle(
                              fontSize: sp(14),
                              fontFamily: "Poppins",
                              color: Color.fromRGBO(
                                1,
                                165,
                                113,
                                1,
                              ), // verde especial
                            ),
                          ),
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
                      color: Color.fromRGBO(28, 33, 53, 1),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6), // sombra oscura
                          blurRadius: 15, // qué tan difusa es
                          offset: Offset(0, 8), // desplazamiento (x, y)
                          spreadRadius: 1, // qué tanto se expande
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.share2,
                          color: Colors.white,
                          size: sp(18),
                        ),
                        SizedBox(width: w(13)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(100)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Compartir",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "Poppins",
                                fontSize: sp(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Vibration.vibrate(duration: 5);
                    capturarYCompartir();
                  },
                ),
                GestureDetector(
                  child: Container(
                    height: h(53),
                    width: w(150),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(28, 33, 53, 1),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6), // sombra oscura
                          blurRadius: 15, // qué tan difusa es
                          offset: Offset(0, 8), // desplazamiento (x, y)
                          spreadRadius: 1, // qué tanto se expande
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            AbsorbPointer(
                              absorbing: !animMarcarFavoritoVis,
                              child: Visibility(
                                visible: animMarcarFavoritoVis,
                                child: Transform.scale(
                                  scale: 2.3,
                                  child: Lottie.asset(
                                    "assets/animMarcarFavorito.json",
                                    height: h(33),
                                    width: w(33),
                                    fit: BoxFit.contain,
                                    repeat: false,
                                    animate: playAnimacionMarcarFavorito,
                                  ),
                                ),
                              ),
                            ),
                            AbsorbPointer(
                              absorbing: !animDesmarcarFavoritoVis,
                              child: Visibility(
                                visible: animDesmarcarFavoritoVis,
                                child: Transform.scale(
                                  scale: 1.5,
                                  child: Lottie.asset(
                                    "assets/animDesmarcarFavorito.json",
                                    height: h(33),
                                    width: w(33),
                                    fit: BoxFit.contain,
                                    repeat: false,
                                    animate: playAnimacionDesmarcarFavorito,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: w(13)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(100)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Favorito",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "Poppins",
                                fontSize: sp(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Vibration.vibrate(duration: 5);
                    if (playAnimacionMarcarFavorito == false) {
                      setState(() {
                        animDesmarcarFavoritoVis = false;
                        animMarcarFavoritoVis = true;
                        playAnimacionMarcarFavorito = true;
                      });
                      marcarFavorito();
                    } else if (playAnimacionMarcarFavorito == true) {
                      setState(() {
                        animMarcarFavoritoVis = false;
                        animDesmarcarFavoritoVis = true;
                        playAnimacionDesmarcarFavorito = true;
                        playAnimacionMarcarFavorito = false;
                      });
                      desmarcarFavorito();
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: h(23)),
            GestureDetector(
              child: Container(
                width: w(350),
                height: h(53),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    (descargado == false
                        ? (descargando == false
                              ? Icon(
                                  LucideIcons.download,
                                  color: Colors.white,
                                  size: sp(18),
                                )
                              : Lottie.asset(
                                  "assets/descargandoRecibo.json",
                                  repeat: false,
                                ))
                        : Icon(LucideIcons.check, color: Colors.white)),
                    SizedBox(width: w(13)),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w(300)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          (descargado == false
                              ? (descargando == false
                                    ? "Descargar Recibo"
                                    : "Descargando...")
                              : "Descargado"),
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "Poppins",
                            fontSize: sp(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);
                setState(() {
                  descargando = true;
                });

                Future.delayed(Duration(milliseconds: 4500), () {
                  Vibration.vibrate(duration: 15);
                  capturarYDescargar();
                  setState(() {
                    descargando = false;
                    descargado = true;
                  });
                });
              },
            ),
            SizedBox(height: h(23)),
            GestureDetector(
              child: Container(
                width: w(350),
                height: h(53),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(1, 165, 113, 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(300)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Finalizar",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "PoppinsBold",
                          fontSize: sp(20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);
                Navigator.pushAndRemoveUntil(
                  context,
                  PageTransition(
                    type: PageTransitionType.leftToRight,
                    child: MenuPrincipalPage(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget compartirRecibo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Opacity(
      opacity: 0.01,
      child: RepaintBoundary(
        key: _reciboKey,
        child: Screenshot(
          controller: screenshotController,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: EdgeInsets.symmetric(horizontal: w(20), vertical: h(25)),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono check
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: sp(40), color: Colors.white),
                  ),
                  SizedBox(height: h(20)),

                  // Título
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(300)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Pago Exitoso",
                        style: TextStyle(
                          fontSize: sp(22),
                          fontFamily: "PoppinsBold",
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: h(8)),

                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(300)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Transacción completada",
                        style: TextStyle(
                          fontSize: sp(16),
                          fontFamily: "PoppinsBold",
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h(25)),

                  // Monto
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(300)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "\$${widget.montoQR}",
                        style: TextStyle(
                          fontSize: sp(40),
                          fontFamily: "PoppinsBold",
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h(5)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(300)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "ARS",
                        style: TextStyle(
                          fontSize: sp(16),
                          fontFamily: "PoppinsBold",
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: h(23)),
                  Divider(color: Colors.white60, thickness: h(0.5)),

                  // Info detalle (con más espacio)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "De",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: sp(15),
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          nameUser,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sp(15),
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h(15)),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Para",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: sp(15),
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          widget.nameUserExterno,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sp(15),
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h(15)),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Método",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: sp(15),
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          widget.metodo,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sp(15),
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h(15)),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Fecha y hora",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: sp(15),
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          "$fecha a las $hora hs",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sp(15),
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h(15)),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "ID de transacción",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: sp(15),
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          "#${widget.codeQR}",
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: sp(15),
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ],
                  ),

                  Divider(color: Colors.white60, thickness: h(0.5)),
                  SizedBox(height: h(20)),

                  // Botón verde de estado
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w(25),
                      vertical: h(15),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF22C55E)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: sp(13),
                          color: Color(0xFF22C55E),
                        ),
                        SizedBox(width: w(10)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(150)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Pago completado",
                              style: TextStyle(
                                color: Color(0xFF22C55E),
                                fontSize: sp(15),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MoneyCounter extends StatelessWidget {
  final double amount;
  final bool showBalance;
  final ValueChanged<double>?
  onUpdate; // 🔹 callback opcional para devolver el double

  const MoneyCounter({
    super.key,
    required this.amount,
    this.onUpdate,
    this.showBalance = true,
  });

  Duration get duration {
    double seconds = 3 - (amount / 1000) * 2; // fórmula simple
    if (seconds < 0.5) seconds = 0.5;
    return Duration(seconds: seconds.toInt());
  }

  // 🔹 Función para formatear como currency sin símbolo
  String formatCurrency(double value, {bool showDecimals = true}) {
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '', // sin símbolo
      decimalDigits: showDecimals ? 2 : 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        // 🔹 llamamos al callback con el valor animado
        if (onUpdate != null) onUpdate!(value);

        // Determina si mostrar decimales según el valor final
        final showDecimals = amount % 1 != 0;

        // Formateamos el valor como string con 2 decimales
        String formatted = formatCurrency(value, showDecimals: showDecimals);

        // Separar parte entera y decimales
        List<String> parts = formatted.split(',');
        String integerPart = parts[0];
        String decimalPart = parts.length > 1 ? "," + parts[1] : '';

        if (showBalance == true) {
          return Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "\$" + integerPart,
                  style: const TextStyle(
                    fontSize: 33,
                    color: Colors.white,
                    fontFamily: "PoppinsBold",
                  ),
                ),
                if (decimalPart.isNotEmpty)
                  WidgetSpan(
                    child: Transform.translate(
                      offset: const Offset(0, 0),
                      child: Text(
                        decimalPart,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white60,
                          fontFamily: "PoppinsBold",
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return Text(
          "\$·····",
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontFamily: "PoppinsBold",
          ),
        );
      },
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
