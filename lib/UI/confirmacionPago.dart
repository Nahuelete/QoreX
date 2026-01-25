// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, deprecated_member_use, prefer_interpolation_to_compose_strings, avoid_print, unnecessary_brace_in_string_interps, sized_box_for_whitespace, use_build_context_synchronously, unused_field, unused_local_variable, unrelated_type_equality_checks, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/UI/pagoRealizado.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:vibration/vibration.dart';

class confirmacionPage extends StatefulWidget {
  final String qrData;
  final String userUid;

  const confirmacionPage({
    super.key,
    required this.qrData,
    required this.userUid,
  });

  @override
  State<confirmacionPage> createState() => _confirmacionPageState();
}

class _confirmacionPageState extends State<confirmacionPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  StreamSubscription? _tarjetaSubscription;

  late AnimationController _controller;

  late AnimationController _controllerAnimPago;

  PageController? _pageController;

  int _paginaActual = 0;
  int _ultimaCantidadMetodos = 0;

  final ScrollController _scrollController = ScrollController();

  List<String> metodos = ["Cuenta"];

  //Verificar Metodos
  List<Map<String, dynamic>> datosMetodos = [];
  late Map<String, dynamic> tarjetaActual;
  Map<String, dynamic>? extensionActiva;
  late bool necesitaVerificacion;

  //Suscripcion
  StreamSubscription? _soliSub;

  //QR
  String nameUserExterno = "";
  String apellidoUserExterno = "";
  String avatarUserExterno = "";
  String inicialesUserExterno = "";
  String uidUserExterno = "";
  String dniUserExterno = "";
  String metodo = "";
  String fecha = "";
  String hora = "";
  String tarjetaUser = "";
  String colorUserExterno = "";
  Color colorUI = Color.fromRGBO(1, 165, 113, 1);
  int codeQR = 0;
  double montoQR = 0.0;
  double saldoUser = 0.0;
  double saldoUserExterno = 0.0;

  bool isFinished = false;
  //Fin QR

  //Datos User
  String nameUser = "";
  String apellidoUser = "";
  String avatarUser = "";

  //Tarjeta User
  String numeroTarjetaUser = "";
  String codeTarjetaUser = "";
  String estadoTarjetaUser = "";

  bool mismoUsuario = false;

  //Configuracion Tarjeta
  bool limiteActivo = false;
  double limite = 0.0;
  double limiteGastado = 0.0;

  //Datos Extension
  String estadoExtension = "";
  String originarioExtension = "";
  String originarioNombreExtension = "";
  String codeTarjetaExtension = "";
  String nombreExtension = "";
  String numeroExtension = "";
  double saldoOriginarioExtension = 0.0;

  //Configuracion Tarjeta
  //limite
  double limiteExtension = 0.0;
  double limiteGastadoExtension = 0.0;
  bool limiteExtensionActivo = false;
  bool verificacionExtension = false;
  bool sinSaldoExtension = false;

  //Umbral
  double umbral = 0.0;
  bool umbralActivo = false;
  String accionUmbral = "";

  //Aviso Activado
  bool avisoUmbral = false;

  //Verificacion Umbral
  final localAuth = LocalAuthentication();

  bool verificarUmbral = false;

  //Verificacion Activada
  bool esperandoAprobacion = false;
  bool deseasCancelar = false;

  Future<void> leerShared() async {
    //Tarjeta User
    final prefsTarjeta = await SharedPreferences.getInstance();

    if (prefsTarjeta.getString('codeTarjetaUser') == null) {
      codeTarjetaUser = "";
    } else {
      codeTarjetaUser = prefsTarjeta.getString('codeTarjetaUser')!;
    }
  }

  Future<void> obtenerDatos() async {
    final reciboRef = FirebaseFirestore.instance
        .collection("Recibos")
        .doc(widget.qrData);

    // Listener principal del recibo
    reciboRef.snapshots().listen((reciboSnap) async {
      if (!reciboSnap.exists) {
        showFlushbarError(context, "El Emisor Cancelo El Pago.");
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            child: MenuPrincipalPage(),
          ),
        );
        return;
      }

      final data = reciboSnap.data()!;

      // ================================
      //      DATOS BASE RECIBO
      // ================================
      final ahora = DateTime.now();
      fecha = DateFormat('dd-MM-yyyy').format(ahora);
      hora =
          "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

      final uidExterno = data["Recibe"];
      if (uidExterno == null || uidExterno.isEmpty) {
        return;
      }

      setState(() {
        uidUserExterno = uidExterno;
        montoQR = (data["Cantidad"] as num?)?.toDouble() ?? 0.0;
        metodo = data["Metodo"] ?? "";
        codeQR = data["ID"] ?? "";
      });

      // ================================
      //      OBTENER DATOS RECIBE
      // ================================

      final emisorSnap = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(uidUserExterno)
          .get();

      if (!mounted) return;

      if (!emisorSnap.exists) {
        return;
      }

      final dataEmisor = emisorSnap.data()!;

      setState(() {
        nameUserExterno = dataEmisor["Nombre"] ?? "";
        apellidoUserExterno = dataEmisor["Apellido"] ?? "";
        avatarUserExterno = dataEmisor["Avatar"] ?? "";
        dniUserExterno = dataEmisor["Dni"] ?? "";
        colorUserExterno = dataEmisor["Color"] ?? "";
        saldoUserExterno = (dataEmisor["Saldo"] as num?)?.toDouble() ?? 0.0;
        inicialesUserExterno =
            nameUserExterno.isNotEmpty && apellidoUserExterno.isNotEmpty
            ? "${nameUserExterno[0]}${apellidoUserExterno[0]}".toUpperCase()
            : "";
        colorUI = obtenerColor(colorUserExterno);
      });

      // ================================
      //      OBTENER DATOS ENVIA
      // ================================

      final receptorSnap = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(widget.userUid)
          .get();

      if (!mounted) return;

      if (!receptorSnap.exists) {
        return;
      }

      final dataReceptor = receptorSnap.data()!;

      setState(() {
        nameUser = dataReceptor["Nombre"] ?? "";
        apellidoUser = dataReceptor["Apellido"] ?? "";
        avatarUser = dataReceptor["Avatar"] ?? "";
        saldoUser = (dataReceptor["Saldo"] as num?)?.toDouble() ?? 0.0;
        tarjetaUser = dataReceptor["Tarjeta"] ?? "";
      });

      // Tarjeta
      if (tarjetaUser != "No" && tarjetaUser != "Solicitada") {
        if (!metodos.contains("Tarjeta")) {
          metodos.add("Tarjeta");
        }
        obtenerTarjeta();
      } else {
        metodos.remove("Tarjeta");
      }

      // Extensiones
      FirebaseFirestore.instance
          .collection("Extensiones")
          .where("Para", isEqualTo: widget.userUid)
          .snapshots()
          .listen((querySnapshot) {
            if (querySnapshot.docs.isNotEmpty) {
              if (!metodos.contains("Extensiones")) {
                metodos.add("Extensiones");
              }
            } else {
              metodos.remove("Extensiones");
            }
          });
    });
  }

  Future<void> obtenerTarjeta() async {
    FirebaseFirestore.instance
        .collection("Tarjetas")
        .doc(codeTarjetaUser)
        .snapshots()
        .listen((docSnapshot) {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              numeroTarjetaUser = data["NumeroTarjeta"] ?? "";
              estadoTarjetaUser = data["Estado"] ?? "";
            });
          }

          //Verificar Limite
          verificarLimiteTarjeta();

          //Verificar Umbra;
          verificarUmbralTarjeta();
        });
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
              limiteActivo = data["Limite Estado"] ?? false;
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

  Future<void> verificarUmbralTarjeta() async {
    FirebaseFirestore.instance
        .collection("Tarjetas")
        .doc(codeTarjetaUser)
        .snapshots()
        .listen((docSnapshot) {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              umbralActivo = data["Umbral Estado"] ?? false;
              umbral = (data["Umbral"] != null)
                  ? (data["Umbral"] as num).toDouble()
                  : 0.0;
              accionUmbral = data["Accion Umbral"] ?? "";
            });
          }
        });
  }

  Future<double> obtenerDatosExtension(uidOriginario) async {
    final doc = await FirebaseFirestore.instance
        .collection("Usuarios")
        .doc(uidOriginario)
        .get();

    if (!doc.exists) return 0.0;

    final data = doc.data()!;
    return (data["Saldo"] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> cargarExtensiones(
    QuerySnapshot snap,
  ) async {
    List<Map<String, dynamic>> lista = [];

    for (var doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // UID del originario para obtener saldo
      final String uidOriginario = data["Originario"] ?? "";

      // Codigo de la tarjeta
      final String codeTarjeta = data["Codigo"] ?? "";

      // 🚀 Obtener saldo real del originario
      final double saldoOriginario = await obtenerDatosExtension(uidOriginario);

      // 🚀 Obtener número de tarjeta SI EXISTE
      final String numeroTarjeta = data["NumeroTarjeta"] ?? "";

      // 🚀 Obtener nombre extension
      final String nombreExtension = data["NombreExtension"] ?? "";

      // 🚀 Obtener nombre extension
      final String nombreOriginarioExtension = data["De Nombre"] ?? "";

      // Guardamos TODO en el mapa
      lista.add({
        "tipo": "extension",
        "originario": data["Originario"] ?? "",
        "verificacion": data["Verificacion"] ?? false,
        "saldoOriginario": saldoOriginario,
        "limite": data.containsKey("Limite")
            ? (data["Limite"] is int
                  ? (data["Limite"] as int).toDouble()
                  : data["Limite"] is double
                  ? data["Limite"]
                  : double.tryParse(data["Limite"].toString()) ?? 0.0)
            : 0.0,
        "limiteGastado": data.containsKey("LimiteGastado")
            ? (data["LimiteGastado"] is int
                  ? (data["LimiteGastado"] as int).toDouble()
                  : data["LimiteGastado"] is double
                  ? data["LimiteGastado"]
                  : double.tryParse(data["LimiteGastado"].toString()) ?? 0.0)
            : 0.0,
        "estado": data["Estado"] ?? "Habilitada",
        "numeroTarjeta": numeroTarjeta,
        "nombreExtension": nombreExtension,
        "nombreOriginarioExtension": nombreOriginarioExtension,
        "codigo": codeTarjeta,
      });
    }

    return lista;
  }

  Future<void> cancelarConfirmacion() async {
    FirebaseFirestore.instance.collection("Recibos").doc(widget.qrData).update({
      "Estado": "Pendiente",
      "Paga": FieldValue.delete(),
      "AvatarPaga": FieldValue.delete(),
      "Paga uid": FieldValue.delete(),
    });
  }

  //Verificacion Activada
  Future<void> solicitarGasto() async {
    //Enviar Notificacion Solicitud Gasto
    notificacionVerificacion();

    _soliSub = FirebaseFirestore.instance
        .collection('Notificaciones')
        .doc("Notificacion Solicitud Gasto Extension #$codeQR")
        .snapshots()
        .listen((docSnapshot) async {
          if (!mounted) return; // <- Evita setState si el widget ya no existe

          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            String estadoTransaccion = data["Estado"] ?? "";

            // Pago
            if (estadoTransaccion == "Pago") {
              obtenerDatosExtension(originarioExtension);
              Future.delayed(Duration(milliseconds: 1800), () {
                Vibration.vibrate(duration: 20);
                setState(() {
                  isFinished = true;
                });
              });
            }
          } else {
            print('El documento no existe');
            Vibration.vibrate(duration: 10);
          }
        });
  }

  Future<void> notificacionVerificacion() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final hora =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    try {
      await FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc(
            "Notificacion Solicitud Gasto Extension #${widget.qrData.replaceAll(RegExp(r'[^0-9]'), '')}",
          )
          .set({
            "Tipo": "Solicitud Gasto Extension",
            "Nombre Extension": extensionActiva!["nombreExtension"],
            "De": nameUser + " " + apellidoUser,
            "De uid": widget.userUid,
            "Avatar": avatarUser,
            "Monto": montoQR,
            "Fecha": fecha,
            "Hora": hora,
            "FechaTime": Timestamp.fromDate(
              ahora,
            ), // 🔹 este es el que se usa en queries
            "Estado": "Pendiente",
            "ID Recibo": codeQR,
            "Leida": {extensionActiva!["originario"]: false},
            "Involucra": [extensionActiva!["originario"]],
          });

      print("Notificación Solicitud Gasto Creada ✅");
    } catch (e, st) {
      print("Error al crear la notificación: $e");
      print(st);
    }
  }

  Future<void> cancelarSolicitudAprobacion() async {
    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc(
          "Notificacion Solicitud Gasto Extension #${widget.qrData.replaceAll(RegExp(r'[^0-9]'), '')}",
        )
        .delete();
  }
  //Fin Verificacion Activada

  Future<void> solicitarBiometria() async {
    bool canCheck = await localAuth.canCheckBiometrics;
    bool authenticated = false;

    if (!canCheck) {
      print('El dispositivo no soporta biometría');

      Future.delayed(Duration(milliseconds: 100), () {
        Vibration.vibrate(duration: 5);
        setState(() {
          verificarUmbral = false;
        });

        Future.delayed(Duration(seconds: 3), () {
          setState(() {
            isFinished = true;
          });
        });
      });
      return;
    }

    try {
      authenticated = await localAuth.authenticate(
        localizedReason: 'Escanea tu huella o Face ID para iniciar sesión',
        options: const AuthenticationOptions(
          stickyAuth: true, // Mantiene la sesión en background
          biometricOnly: true, // Solo biometría
        ),
      );
    } on PlatformException catch (e) {
      print("Error de biometría: ${e.code}");

      if (e.code == "NotEnrolled" ||
          e.code == "LockedOut" ||
          e.code == "PermanentlyLockedOut") {
        setState(() {
          avisoUmbral = false;
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  confirmacionPage(
                    qrData: widget.qrData,
                    userUid: widget.userUid,
                  ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
            (Route<dynamic> route) => false,
          );
        });

        return;
      }

      if (e.code == "Canceled") {
        print("El usuario canceló la autenticación");

        setState(() {
          avisoUmbral = false;
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  confirmacionPage(
                    qrData: widget.qrData,
                    userUid: widget.userUid,
                  ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
            (Route<dynamic> route) => false,
          );
        });

        showFlushbarError(
          context,
          "Error en la Autenticación. Intenta nuevamente.",
        );
        return;
      }
    }

    if (authenticated) {
      Future.delayed(Duration(milliseconds: 100), () {
        Vibration.vibrate(duration: 5);
        setState(() {
          verificarUmbral = false;
        });

        Future.delayed(Duration(seconds: 3), () {
          setState(() {
            isFinished = true;
          });
        });
      });
    } else {
      print('Autenticación biométrica fallida');

      setState(() {
        avisoUmbral = false;
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                confirmacionPage(
                  qrData: widget.qrData,
                  userUid: widget.userUid,
                ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
          (Route<dynamic> route) => false,
        );
      });

      showFlushbarError(
        context,
        "Error en la Autenticación. Intenta nuevamente.",
      );
    }
  }

  Color obtenerColor(String color) {
    switch (color) {
      case "Verde":
        return const Color.fromRGBO(1, 165, 113, 1);
      case "Azul":
        return const Color.fromRGBO(33, 13, 243, 1);
      case "Naranja":
        return const Color.fromRGBO(200, 90, 0, 1);
      case "Violeta":
        return const Color.fromRGBO(165, 53, 253, 1);
      default:
        return const Color.fromRGBO(1, 165, 113, 1);
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

    leerShared();

    obtenerDatos();

    _pageController = PageController(viewportFraction: 0.90, initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    //Verificacion Metodos
    tarjetaActual = datosMetodos.isNotEmpty ? datosMetodos[0] : {};
    necesitaVerificacion = tarjetaActual["verificacion"] ?? false;

    // Controladores de animaciones generales
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _controllerAnimPago = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _controllerAnimPago.dispose();
    _scrollController.dispose();
    _pageController?.dispose();
    _tarjetaSubscription?.cancel();
    _soliSub?.cancel();
    super.dispose();
  }

  String formatMoney(double value) {
    // Si es entero, devolvemos sin decimales
    if (value % 1 == 0) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );
    }
    // Default return for non-integer values
    return value
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

  double safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String safeLastDigits(String str, int length) {
    String cleanStr = str.replaceAll(" ", ""); // quitar todos los espacios
    if (cleanStr.isEmpty) return "0"; // al menos un dígito
    if (length > cleanStr.length) length = cleanStr.length;
    return cleanStr.substring(cleanStr.length - length);
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
          colors: [Color(0xFF0F1117), Color(0xFF0F1117)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: isFinished
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Stack(
                  alignment: Alignment.center,
                  children: [
                    Visibility(
                      visible: !deseasCancelar,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
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
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              LucideIcons.arrowLeft,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            if (esperandoAprobacion == false) {
                              Vibration.vibrate(duration: 5);
                              cancelarConfirmacion();
                              Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: MenuPrincipalPage(),
                                ),
                              );
                            } else {
                              setState(() {
                                deseasCancelar = true;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        deseasCancelar
                            ? "Cancelar Pago"
                            : avisoUmbral
                            ? "Umbral Superado"
                            : verificarUmbral
                            ? "Umbral Superado"
                            : "Confirmar Pago",
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
            SizedBox(child: confirmacionQR()),
            // Capa verde animada
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: Duration(seconds: 1),
                curve: Curves.easeOut,
                width: double.infinity,
                height: isFinished
                    ? screenHeight
                    : 0, // empieza en 0 y crece hasta pantalla completa
                color: (_paginaActual == 0
                    ? Color.fromRGBO(1, 165, 113, 1)
                    : _paginaActual == 1
                    ? Colors.blue
                    : Colors.purpleAccent),
                child: Center(
                  child: SizedBox(
                    height: h(200),
                    child: Lottie.asset(
                      (_paginaActual == 0
                          ? "assets/pagoRealizadoVerde.json"
                          : _paginaActual == 1
                          ? "assets/pagoRealizadoAzul.json"
                          : "assets/pagoRealizadoVioleta.json"),
                      controller: _controllerAnimPago,
                      repeat: false,
                      fit: BoxFit.contain,
                      onLoaded: (composition) {
                        _controllerAnimPago.duration = composition.duration;
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

  Widget confirmacionQR() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: h(33)),
            Center(
              child: avatarUserExterno != ""
                  ? CircleAvatar(
                      radius: sp(33),
                      backgroundColor: Colors.blue,
                      child: Image.asset(avatarUserExterno),
                    )
                  : Container(
                      height: h(73),
                      width: h(73),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(1, 165, 113, 0.15),
                      ),
                      child: ClipOval(
                        child: avatarUser == ""
                            ? Container(
                                width: w(73),
                                height: w(73),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorUI,
                                ),
                                child: Center(
                                  child: Text(
                                    inicialesUserExterno,
                                    style: TextStyle(
                                      fontSize: sp(25),
                                      fontFamily: "PoppinsBold",
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : Image.asset(avatarUser, fit: BoxFit.cover),
                      ),
                    ),
            ),
            SizedBox(height: h(23)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w(400)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: MoneyCounterEscanearQr(
                  amount: montoQR,
                  showBalance: true,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w(400)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  nameUserExterno + " " + apellidoUserExterno,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "Poppins",
                    fontSize: sp(15),
                  ),
                ),
              ),
            ),
            SizedBox(height: h(23)),
            Container(
              width: w(350),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: Colors.transparent, width: w(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h(13)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(200)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Pagar con:",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "PoppinsBold",
                              fontSize: sp(20),
                            ),
                          ),
                        ),
                      ),
                      if (metodos.length > 1 &&
                          _pageController != null &&
                          _pageController!.hasClients)
                        SmoothPageIndicator(
                          controller: _pageController!,
                          count: metodos.length,
                          effect: SwapEffect(
                            activeDotColor: (_paginaActual == 0
                                ? Color.fromRGBO(1, 165, 113, 1)
                                : _paginaActual == 1
                                ? Color.fromRGBO(33, 13, 243, 1)
                                : Color.fromRGBO(165, 53, 253, 1)),
                            dotColor: Colors.white,
                            dotHeight: sp(10),
                            dotWidth: sp(10),
                            spacing: sp(10),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: h(23)),
                  SizedBox(
                    height: h(250),
                    child: metodos.isEmpty
                        ? Center(child: CircularProgressIndicator())
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Extensiones')
                                .where('Para', isEqualTo: widget.userUid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: Color.fromRGBO(1, 165, 113, 0.878),
                                  ),
                                );
                              }

                              return FutureBuilder(
                                future: cargarExtensiones(snapshot.data!),
                                builder: (context, snapExt) {
                                  if (!snapExt.hasData) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: Color.fromRGBO(
                                          1,
                                          165,
                                          113,
                                          0.878,
                                        ),
                                      ),
                                    );
                                  }

                                  final extensiones = snapExt.data!;

                                  // RESET listas
                                  datosMetodos.clear();
                                  List<Widget> metodosFinal = [];

                                  // 1) FONDOS DE CUENTA
                                  metodosFinal.add(fondosDeCuentaWidget());
                                  datosMetodos.add({
                                    "tipo": "cuenta",
                                    "verificacion": false,
                                    "saldo": saldoUser,
                                  });

                                  // 2) MI TARJETA
                                  if (numeroTarjetaUser.isNotEmpty &&
                                      numeroTarjetaUser != "No" &&
                                      numeroTarjetaUser != "Solicitada") {
                                    metodosFinal.add(miTarjetaWidget());
                                    datosMetodos.add({
                                      "tipo": "tarjeta",
                                      "verificacion": false,
                                      "limite": limite,
                                      "limiteGastado": limiteGastado,
                                      "estado": estadoTarjetaUser,
                                    });
                                  }

                                  // 3) EXTENSIONES
                                  for (var ext in extensiones) {
                                    datosMetodos.add(ext);
                                    metodosFinal.add(
                                      extensionTarjetaWidget(data: ext),
                                    );
                                  }

                                  // GENERAR PALABRAS
                                  metodos = List.generate(
                                    metodosFinal.length,
                                    (i) => "metodo_$i",
                                  );

                                  // 🔥 DETECCIÓN DE CAMBIO EN CANTIDAD DE MÉTODOS
                                  final cantidadActual = metodosFinal.length;
                                  final cambioEnCantidad =
                                      cantidadActual != _ultimaCantidadMetodos;

                                  if (cambioEnCantidad) {
                                    _ultimaCantidadMetodos = cantidadActual;

                                    // Resetear página actual si está fuera de rango
                                    if (_paginaActual >= cantidadActual) {
                                      _paginaActual = 0;
                                    }

                                    // 🔥 RECREAR PAGECONTROLLER cuando cambia la cantidad
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted) {
                                            _pageController?.dispose();
                                            _pageController = PageController(
                                              viewportFraction: 0.90,
                                              initialPage: _paginaActual,
                                            );
                                            setState(() {});
                                          }
                                        });
                                  }

                                  // Validación de seguridad adicional
                                  if (_paginaActual < 0) {
                                    _paginaActual = 0;
                                  }
                                  if (_paginaActual >= cantidadActual) {
                                    _paginaActual = cantidadActual - 1;
                                    if (_paginaActual < 0) _paginaActual = 0;
                                  }

                                  // PAGEVIEW FINAL
                                  return SizedBox(
                                    height: h(250),
                                    child: _pageController == null
                                        ? Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : PageView.builder(
                                            controller: _pageController!,
                                            itemCount: metodosFinal.length,
                                            onPageChanged: (index) {
                                              // 🔥 VALIDACIÓN CRÍTICA
                                              if (index < 0 ||
                                                  index >=
                                                      datosMetodos.length) {
                                                print(
                                                  "⚠️ Índice inválido: $index (total: ${datosMetodos.length})",
                                                );
                                                return;
                                              }

                                              Vibration.vibrate(duration: 5);

                                              setState(() {
                                                _paginaActual = index;
                                                tarjetaActual =
                                                    datosMetodos[index];
                                                necesitaVerificacion =
                                                    tarjetaActual["verificacion"] ??
                                                    false;

                                                // CONTROL EXTENSION ACTIVA
                                                if (index < 2) {
                                                  extensionActiva = {
                                                    "uidOriginario":
                                                        "NO_EXTENSION",
                                                    "tipo": "ninguno",
                                                  };
                                                } else {
                                                  extensionActiva =
                                                      tarjetaActual;
                                                }

                                                // SALDO EXTENSIONES
                                                if (tarjetaActual["tipo"] ==
                                                    "extension") {
                                                  final saldo =
                                                      tarjetaActual["saldoOriginario"] ??
                                                      0;
                                                  sinSaldoExtension =
                                                      saldo < montoQR;
                                                } else {
                                                  sinSaldoExtension = false;
                                                }
                                              });
                                            },
                                            itemBuilder: (context, index) {
                                              if (index >=
                                                      metodosFinal.length ||
                                                  index < 0) {
                                                return const SizedBox.shrink();
                                              }

                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: w(10),
                                                ),
                                                child: metodosFinal[index],
                                              );
                                            },
                                          ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: esperandoAprobacion,
              child: Column(
                children: [
                  SizedBox(height: h(33)),
                  Text(
                    "Esperando Aprobacion",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "PoppinsBold",
                      fontSize: sp(15),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: h(13)),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                reverse: true,
                child: Column(
                  children: [
                    SizedBox(height: h(23)),
                    SizedBox(
                      width: w(350),
                      child: Center(
                        child: SwipeableButtonView(
                          isActive: _paginaActual == 0
                              ? (saldoUser >= montoQR ? true : false)
                              : _paginaActual == 1
                              ? // --- Validación de LÍMITE ---
                                (limiteActivo == true
                                        ? (estadoTarjetaUser == "Habilitada"
                                              ? (limite > 0 &&
                                                        (montoQR +
                                                                limiteGastado >
                                                            limite)
                                                    ? false
                                                    : (saldoUser >= montoQR
                                                          ? true
                                                          : false))
                                              : false)
                                        : true) &&
                                    // --- Validación de UMBRAL ---
                                    (umbralActivo == true
                                        ? (estadoTarjetaUser == "Habilitada"
                                              ? (saldoUser - montoQR < umbral &&
                                                        accionUmbral ==
                                                            "Rechazar")
                                                    ? false
                                                    : (saldoUser >= montoQR
                                                          ? true
                                                          : false)
                                              : false)
                                        : true)
                              : _paginaActual > 1
                              ? (estadoExtension == "Habilitada"
                                    ? (sinSaldoExtension
                                          ? false
                                          : (limiteExtension > 0 &&
                                                    (montoQR +
                                                            limiteGastadoExtension >
                                                        limiteExtension)
                                                ? false
                                                : mismoUsuario
                                                ? false
                                                : true))
                                    : false)
                              : false,

                          buttonText: _paginaActual == 0
                              ? (saldoUser >= montoQR
                                    ? "Deslizá para pagar"
                                    : "Saldo insuficiente")
                              : _paginaActual == 1
                              ? // --- Validación por LÍMITE ---
                                (limiteActivo == true
                                    ? (estadoTarjetaUser == "Habilitada"
                                          ? (saldoUser >= montoQR
                                                ? (
                                                  // Si supera el límite → mensaje de error
                                                  (limite < montoQR
                                                      ? "Límite superado"
                                                      : (limiteGastado +
                                                                montoQR >
                                                            limite)
                                                      ? "Límite superado"
                                                      :
                                                        // Si el límite está OK → pasamos a validar UMBRAL
                                                        (umbralActivo == true
                                                            ? (
                                                              // ¿saldo OK? ya lo verificaste arriba
                                                              (saldoUser - montoQR <
                                                                          umbral &&
                                                                      accionUmbral ==
                                                                          "Rechazar"
                                                                  ? "Umbral superado"
                                                                  : "Deslizá para pagar"))
                                                            : "Deslizá para pagar")))
                                                : "Saldo insuficiente")
                                          : "Tarjeta Congelada")
                                    :
                                      // --- Si límite NO está activo, validamos UMBRAL ---
                                      (umbralActivo == true
                                          ? (estadoTarjetaUser == "Habilitada"
                                                ? (saldoUser >= montoQR
                                                      ? (saldoUser - montoQR <
                                                                    umbral &&
                                                                accionUmbral ==
                                                                    "Rechazar"
                                                            ? "Umbral superado"
                                                            : "Deslizá para pagar")
                                                      : "Saldo insuficiente")
                                                : "Tarjeta congelada")
                                          : "Deslizá para pagar"))
                              : _paginaActual > 1
                              ? (estadoExtension == "Habilitada"
                                    ? (sinSaldoExtension
                                          ? "Saldo insuficiente"
                                          : (limiteExtension > 0 &&
                                                    montoQR +
                                                            limiteGastadoExtension >
                                                        limiteExtension
                                                ? "Límite superado"
                                                : mismoUsuario
                                                ? "No disponible"
                                                : (extensionActiva?["verificacion"] ==
                                                          true
                                                      ? "Solicitar aprobación"
                                                      : "Deslizá para pagar")))
                                    : "Tarjeta congelada")
                              : "",
                          buttonWidget: Container(
                            width: w(300),
                            height: h(53),
                            child: Icon(
                              LucideIcons.arrowRight,
                              color: Colors.black,
                            ),
                          ),
                          activeColor: (_paginaActual == 0
                              ? Color.fromRGBO(1, 165, 113, 1)
                              : _paginaActual == 1
                              ? Colors.blue
                              : Color.fromRGBO(165, 53, 253, 1)),
                          isFinished: isFinished,
                          onWaitingProcess: () {
                            if (_paginaActual == 0) {
                              Future.delayed(
                                const Duration(milliseconds: 1800),
                                () {
                                  Vibration.vibrate(duration: 20);
                                  setState(() {
                                    isFinished = true;
                                  });
                                },
                              );
                            } else if (_paginaActual == 1) {
                              Vibration.vibrate(duration: 5);
                              if (umbralActivo == true) {
                                if (accionUmbral == "Avisar") {
                                  setState(() {
                                    avisoUmbral = true;
                                  });
                                }

                                if (accionUmbral == "Verificar") {
                                  setState(() {
                                    verificarUmbral = true;
                                  });
                                  solicitarBiometria();
                                }
                              } else {
                                Future.delayed(
                                  const Duration(milliseconds: 1800),
                                  () {
                                    Vibration.vibrate(duration: 20);
                                    setState(() {
                                      isFinished = true;
                                    });
                                  },
                                );
                              }
                            } else {
                              bool requiereVerificacion = false;

                              if (extensionActiva != null &&
                                  extensionActiva!.containsKey(
                                    "verificacion",
                                  )) {
                                var valor = extensionActiva!["verificacion"];

                                if (valor is bool) {
                                  requiereVerificacion = valor;
                                }

                                if (valor is String) {
                                  requiereVerificacion =
                                      valor.toLowerCase() == "true";
                                }
                              }

                              if (!requiereVerificacion) {
                                obtenerDatosExtension(
                                  extensionActiva?["originario"] ?? "",
                                );

                                Future.delayed(
                                  const Duration(milliseconds: 1800),
                                  () {
                                    Vibration.vibrate(duration: 20);
                                    setState(() {
                                      isFinished = true;
                                    });
                                  },
                                );
                              } else {
                                if (!esperandoAprobacion) {
                                  solicitarGasto();
                                  setState(() {
                                    esperandoAprobacion = true;
                                  });
                                }
                              }
                            }
                          },
                          onFinish: () {
                            setState(() {
                              isFinished = true;
                              _controllerAnimPago.forward();
                            });

                            Future.delayed(Duration(milliseconds: 3500), () {
                              Navigator.of(context).pushAndRemoveUntil(
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => pagoRealizadoPage(
                                        qrData: widget.qrData,
                                        paginaActual: _paginaActual,
                                        metodo: metodo,
                                        montoQR: montoQR,

                                        // 🔥 DATOS CUENTA/TARJETA (no cambian)
                                        uidUserExterno: uidUserExterno,
                                        nameUserExterno:
                                            nameUserExterno +
                                            " " +
                                            apellidoUserExterno,
                                        saldoUser: saldoUser,
                                        saldoUserExterno: saldoUserExterno,
                                        codeQR: codeQR,
                                        avatarUserExterno: avatarUserExterno,

                                        // 🔥 DATOS EXTENSIÓN (directo de extensionActiva)
                                        nombreExtension:
                                            extensionActiva?["nombreExtension"] ??
                                            "",
                                        uidOriginarioExtension:
                                            extensionActiva?["originario"] ??
                                            "",
                                        saldoOriginarioExtension:
                                            extensionActiva?["saldoOriginario"] ??
                                            0.0,
                                        limiteExterno: limiteExtensionActivo,
                                        limiteGastadoExterno:
                                            extensionActiva?["limiteGastado"] ??
                                            0.0,
                                        valorLimiteExtension:
                                            extensionActiva?["limite"] ?? 0.0,
                                        codeTarjetaExterno:
                                            extensionActiva?["codigo"] ?? "",
                                        medioPago: _paginaActual == 0
                                            ? "Cuenta"
                                            : _paginaActual == 1
                                            ? "Tarjeta"
                                            : "Extension",
                                      ),
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero,
                                ),
                                (Route<dynamic> route) => false,
                              );
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: h(23)),
                    Column(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(350)),
                          child: Text(
                            (_paginaActual == 0
                                ? (saldoUser >= montoQR
                                      ? "Al confirmar, se debitará el monto de tu cuenta principal."
                                      : "Método de pago no disponible.")
                                : _paginaActual == 1
                                ? (limiteActivo == true
                                      ? (estadoTarjetaUser == "Habilitada"
                                            ? (saldoUser >= montoQR
                                                  ? (
                                                    // Si supera el límite → no disponible
                                                    (limite < montoQR
                                                        ? "Método de pago no disponible."
                                                        : (limiteGastado +
                                                                  montoQR >
                                                              limite)
                                                        ? "Método de pago no disponible."
                                                        :
                                                          // Si límite OK → validar umbral
                                                          (umbralActivo == true
                                                              ? (
                                                                // Si supera el umbral → no disponible
                                                                (saldoUser - montoQR <
                                                                            umbral &&
                                                                        accionUmbral ==
                                                                            "Rechazar"
                                                                    ? "Método de pago no disponible."
                                                                    : "Al confirmar, se debitará el monto de tu cuenta principal."))
                                                              : "Al confirmar, se debitará el monto de tu cuenta principal.")))
                                                  : "Método de pago no disponible.")
                                            : "Método de pago no disponible.")
                                      :
                                        // Si limiteActivo == false → validamos solo umbral
                                        (umbralActivo == true
                                            ? (estadoTarjetaUser == "Habilitada"
                                                  ? (saldoUser >= montoQR
                                                        ? (saldoUser - montoQR <
                                                                      umbral &&
                                                                  accionUmbral ==
                                                                      "Rechazar"
                                                              ? "Método de pago no disponible."
                                                              : "Al confirmar, se debitará el monto de tu cuenta principal.")
                                                        : "Método de pago no disponible.")
                                                  : "Método de pago no disponible.")
                                            : "Al confirmar, se debitará el monto de tu cuenta principal."))
                                : _paginaActual > 1
                                ? (estadoExtension == "Habilitada"
                                      ? (sinSaldoExtension
                                            ? "Método de pago no disponible."
                                            : (limiteExtension > 0 &&
                                                      montoQR +
                                                              limiteGastadoExtension >
                                                          limiteExtension
                                                  ? "Método de pago no disponible."
                                                  : mismoUsuario
                                                  ? "Método de pago no disponible."
                                                  : "Al confirmar, se debitará el monto de la cuenta de $originarioNombreExtension."))
                                      : "Método de pago no disponible.")
                                : "Al confirmar, se debitará el monto de tu cuenta principal."),
                            style: TextStyle(
                              color: Colors.white60,
                              fontFamily: "Poppins",
                              fontSize: sp(10),
                            ),
                          ),
                        ),
                        SizedBox(height: h(5)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(350)),
                          child: Text(
                            "Esta acción no se puede deshacer.",
                            style: TextStyle(
                              color: Colors.white60,
                              fontFamily: "Poppins",
                              fontSize: sp(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h(33)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ============================================================
        //  CAPA CANCELAR
        // ============================================================
        if (deseasCancelar == true) ...[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                child: Container(color: Colors.white.withOpacity(0.03)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: h(83)),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.xCircle,
                      color: Colors.white,
                      size: sp(25),
                    ),
                  ),
                  SizedBox(height: h(13)),
                  Text(
                    "¿Deseas cancelar la transaccion?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sp(18),
                      fontFamily: "PoppinsBold",
                    ),
                  ),
                  SizedBox(height: h(13)),
                  Text(
                    "Se cancelara la solicitud de aprobacion al salir.",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: sp(15),
                      fontFamily: "PoppinsBold",
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w(33)),
                    child: GestureDetector(
                      child: Container(
                        height: h(53),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(208, 0, 0, 1),
                              Colors.red.shade600,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Salir",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        cancelarSolicitudAprobacion();
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
                  SizedBox(height: h(23)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w(33)),
                    child: GestureDetector(
                      child: Container(
                        height: h(53),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            "Atras",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          deseasCancelar = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // ============================================================
        //  CAPA AVISO UMBRAL
        // ============================================================
        if (avisoUmbral == true) ...[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                child: Container(color: Colors.white.withOpacity(0.03)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: h(83)),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.gauge,
                      color: Colors.white,
                      size: sp(25),
                    ),
                  ),
                  SizedBox(height: h(13)),
                  Text(
                    "¿Deseas continuar con la transaccion?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sp(18),
                      fontFamily: "PoppinsBold",
                    ),
                  ),
                  SizedBox(height: h(13)),
                  Text(
                    "El valor supera tu umbral establecido.",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: sp(15),
                      fontFamily: "PoppinsBold",
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w(33)),
                    child: GestureDetector(
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
                        ),
                        child: Center(
                          child: Text(
                            "Pagar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        setState(() {
                          avisoUmbral = false;
                        });

                        Future.delayed(Duration(seconds: 1), () {
                          setState(() {
                            isFinished = true;
                          });
                        });
                      },
                    ),
                  ),
                  SizedBox(height: h(23)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w(33)),
                    child: GestureDetector(
                      child: Container(
                        height: h(53),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            "Cancelar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          avisoUmbral = false;
                          Navigator.of(context).pushAndRemoveUntil(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      confirmacionPage(
                                        qrData: widget.qrData,
                                        userUid: widget.userUid,
                                      ),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                            (Route<dynamic> route) => false,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // ============================================================
        //  CAPA VERIFICACION UMBRAL
        // ============================================================
        if (verificarUmbral == true) ...[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                child: Container(color: Colors.white.withOpacity(0.03)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: h(83)),
            child: Container(
              decoration: BoxDecoration(color: Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.all(33),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: h(53)),
                    Center(
                      child: Icon(
                        LucideIcons.scanFace,
                        color: Color.fromRGBO(1, 165, 113, 1),
                        size: sp(83),
                      ),
                    ),
                    SizedBox(height: h(53)),
                    Center(
                      child: Text(
                        "Umbral Superado",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sp(20),
                          fontFamily: "PoppinsBold",
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    SizedBox(height: h(10)),
                    Center(
                      child: Text(
                        "Escanea tu rostro para continuar",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: sp(18),
                          fontFamily: "PoppinsBold",
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget fondosDeCuentaWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return GestureDetector(
      onTap: () {
        Vibration.vibrate(duration: 5);
        _pageController?.animateToPage(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: sp(18),
              vertical: sp(14.7),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Color(0xFF1E2A38), Color(0xFF15212B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Color(0xFF00C896), width: w(1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF0B3B2F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF00C896),
                        size: sp(28),
                      ),
                    ),
                    Visibility(
                      visible: (_paginaActual == 0),
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: h(20)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(300)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Fondos de Cuenta",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sp(18),
                        fontFamily: "PoppinsBold",
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h(5)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(400)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Saldo disponible",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: sp(13),
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h(10)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: MoneyCounterSaldoUserQr(amount: saldoUser),
                  ),
                ),
                SizedBox(height: h(8)),
                Divider(color: Colors.white60, height: h(0.5)),
                SizedBox(height: h(8)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Disponible para usar",
                      style: TextStyle(
                        color: Color(0xFF00C896),
                        fontSize: 13,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ============================================================
          //  CAPA SIN SALDO
          // ============================================================
          if (saldoUser < montoQR) ...[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.white.withOpacity(0.03)),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.money_off,
                      color: Colors.white,
                      size: sp(20),
                    ),
                  ),
                  SizedBox(height: h(13)),
                  Text(
                    "Saldo Insuficiente",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sp(15),
                      fontFamily: "PoppinsBold",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget miTarjetaWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return GestureDetector(
      onTap: () {
        Vibration.vibrate(duration: 5);

        // Congelada → no navega
        if (estadoTarjetaUser == "Congelada") {
          Vibration.vibrate(duration: 15);
          return;
        }

        // Límite superado → no navega
        if (estadoTarjetaUser == "Habilitada" &&
            montoQR + limiteGastado > limite) {
          Vibration.vibrate(duration: 15);
          return;
        }

        // OK → navega
        _pageController?.animateToPage(
          1,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Stack(
        children: [
          // ============================================================
          // 🟦 TARJETA BASE (tu mismo diseño original)
          // ============================================================
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: sp(18),
              vertical: sp(14.7),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Color(0xFF1E2A38), Color(0xFF15212B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Color.fromRGBO(33, 13, 243, 1),
                width: w(1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF0B3B8F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.credit_card,
                        color: Color(0xFF007BFF),
                        size: sp(28),
                      ),
                    ),
                    Visibility(
                      visible: (_paginaActual == 1),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h(20)),

                // TITULO TARJETA
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Mi Tarjeta",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sp(18),
                        fontFamily: "PoppinsBold",
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h(5)),

                // SUBTITULO
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Prepaga",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: sp(13),
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h(10)),

                // NÚMERO DE TARJETA
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "**** **** **** ${safeLastDigits(numeroTarjetaUser, 4).trim()}",
                      style: TextStyle(
                        fontSize: sp(23),
                        color: Color(0xFF007BFF),
                        fontFamily: "PoppinsBold",
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h(8)),
                Divider(color: Colors.white60, height: h(0.5)),
                SizedBox(height: h(8)),

                // TARJETA PRINCIPAL
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Tarjeta Principal",
                      style: TextStyle(
                        color: Color(0xFF007BFF),
                        fontSize: sp(13),
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h(10)),

                // ============================================================
                // 🔵 LÍMITE (solo si está habilitada y límite activado)
                // ============================================================
                if (estadoTarjetaUser == "Habilitada" && limiteActivo)
                  Row(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(350)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Límite:",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(13),
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: w(5)),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(350)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "\$" + formatMoney(limite),
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: sp(13),
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

          // ============================================================
          //  CAPA UMBRAL
          // ============================================================
          if (saldoUser - montoQR < umbral && accionUmbral == "Rechazar") ...[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.white.withOpacity(0.03)),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.gauge,
                      color: Colors.white,
                      size: sp(20),
                    ),
                  ),
                  SizedBox(height: h(13)),
                  Text(
                    "Umbral Superado",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sp(15),
                      fontFamily: "PoppinsBold",
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ============================================================
          //  CAPA SIN SALDO
          // ============================================================
          if (saldoUser < montoQR) ...[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.white.withOpacity(0.03)),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.money_off,
                      color: Colors.white,
                      size: sp(20),
                    ),
                  ),
                  SizedBox(height: h(13)),
                  Text(
                    "Saldo Insuficiente",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sp(15),
                      fontFamily: "PoppinsBold",
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ============================================================
          // ❄️ CAPA TARJETA CONGELADA
          // ============================================================
          if (estadoTarjetaUser == "Congelada") ...[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.white.withOpacity(0.03)),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.ac_unit,
                      color: Colors.white,
                      size: sp(20),
                    ),
                  ),
                  SizedBox(height: h(13)),
                  Text(
                    "Tarjeta Congelada",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sp(15),
                      fontFamily: "PoppinsBold",
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ============================================================
          // ⚠️ CAPA LIMITE SUPERADO
          // ============================================================
          if (estadoTarjetaUser == "Habilitada" &&
              limiteActivo &&
              montoQR + limiteGastado > limite) ...[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.white.withOpacity(0.03)),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: sp(20),
                    ),
                  ),
                  SizedBox(height: h(13)),
                  Text(
                    "Límite Superado",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sp(15),
                      fontFamily: "PoppinsBold",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget extensionTarjetaWidget({required Map<String, dynamic> data}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    nombreExtension = data['nombreExtension'] ?? "";
    numeroExtension = data["numeroTarjeta"] ?? "";
    originarioExtension = data["Originario"] ?? "";
    originarioNombreExtension = data["nombreOriginarioExtension"] ?? "";

    mismoUsuario = originarioNombreExtension == nameUserExterno;

    // ----- LÍMITE -----
    final tieneLimite = data.containsKey("limite") && data["limite"] != null;
    limiteExtension = tieneLimite ? safeDouble(data["limite"]) : 0.0;

    // ----- LÍMITE USADO -----
    limiteGastadoExtension = safeDouble(data["limiteGastado"] ?? 0.0);

    // ----- ESTADO -----
    estadoExtension = data['estado'] ?? "Habilitada";

    // ----- ACTIVADO: SOLO SI EL CAMPO EXISTE Y ES > 0 -----
    limiteExtensionActivo = tieneLimite && limiteExtension > 0;

    // ----- CÓDIGO -----
    codeTarjetaExtension = data['codigo'] ?? "";

    // ----- VERIFICACION -----
    verificacionExtension = data["verificacion"] ?? false;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Color(0xFF1E2A38), Color(0xFF15212B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Color.fromRGBO(165, 53, 253, 1),
              width: w(1),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(left: w(18), right: w(18), top: h(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(165, 53, 253, 1).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.credit_card,
                        color: Colors.purpleAccent,
                        size: sp(28),
                      ),
                    ),
                    Visibility(
                      visible: (_paginaActual > 1),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h(20)),

                // TITULO TARJETA
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      nombreExtension,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sp(18),
                        fontFamily: "PoppinsBold",
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h(5)),

                // SUBTITULO
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      originarioNombreExtension,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: sp(13),
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h(10)),

                // NÚMERO DE TARJETA
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "**** **** **** ${numeroExtension.substring(numeroExtension.length - 5).trimRight().trimLeft()}",
                      style: TextStyle(
                        fontSize: sp(23),
                        color: Color.fromRGBO(165, 53, 253, 1),
                        fontFamily: "PoppinsBold",
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h(8)),
                Divider(color: Colors.white60, height: h(0.5)),
                SizedBox(height: h(8)),

                // TARJETA PRINCIPAL
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Extension",
                      style: TextStyle(
                        color: Color.fromRGBO(165, 53, 253, 1),
                        fontSize: sp(13),
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h(10)),

                // ============================================================
                // LÍMITE + VERIFICACIÓN
                // ============================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (limiteExtensionActivo) ...[
                      Text(
                        "Límite:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sp(13),
                          fontFamily: "Poppins",
                        ),
                      ),
                      SizedBox(width: w(5)),
                      Text(
                        "\$" + formatMoney(limiteExtension),
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: sp(13),
                          fontFamily: "Poppins",
                        ),
                      ),
                    ],

                    SizedBox(width: w(10)),

                    if (verificacionExtension == true)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w(5),
                          vertical: h(3),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: sp(15),
                            ),
                            SizedBox(width: w(5)),
                            Text(
                              "Verificación",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ============================================================
        //  CAPA SIN SALDO
        // ============================================================
        if (sinSaldoExtension == true) ...[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.white.withOpacity(0.03)),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.money_off,
                    color: Colors.white,
                    size: sp(20),
                  ),
                ),
                SizedBox(height: h(13)),
                Text(
                  "Saldo Insuficiente",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: sp(15),
                    fontFamily: "PoppinsBold",
                  ),
                ),
              ],
            ),
          ),
        ],

        // ============================================================
        // ❄️ CAPA TARJETA CONGELADA
        // ============================================================
        if (estadoExtension == "Congelada") ...[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.white.withOpacity(0.03)),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.ac_unit, color: Colors.white, size: sp(20)),
                ),
                SizedBox(height: h(13)),
                Text(
                  "Tarjeta Congelada",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: sp(15),
                    fontFamily: "PoppinsBold",
                  ),
                ),
              ],
            ),
          ),
        ],

        // ============================================================
        // ⚠️ CAPA LIMITE SUPERADO
        // ============================================================
        if (estadoExtension == "Habilitada" &&
            limiteExtensionActivo &&
            montoQR + limiteGastadoExtension > limiteExtension) ...[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.white.withOpacity(0.03)),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning, color: Colors.white, size: sp(20)),
                ),
                SizedBox(height: h(13)),
                Text(
                  "Límite Superado",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: sp(15),
                    fontFamily: "PoppinsBold",
                  ),
                ),
              ],
            ),
          ),
        ],

        // ============================================================
        //  CAPA MISMO USUARIO
        // ============================================================
        if (mismoUsuario == true) ...[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.white.withOpacity(0.03)),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_off,
                    color: Colors.white,
                    size: sp(20),
                  ),
                ),
                SizedBox(height: h(13)),
                Text(
                  "Dueño Extension",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: sp(15),
                    fontFamily: "PoppinsBold",
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class MoneyCounterEscanearQr extends StatelessWidget {
  final double amount;
  final bool showBalance;
  final ValueChanged<double>?
  onUpdate; // 🔹 callback opcional para devolver el double

  const MoneyCounterEscanearQr({
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
                    fontSize: 37,
                    color: Colors.white,
                    fontFamily: "PoppinsBold",
                  ),
                ),
                if (decimalPart.isNotEmpty)
                  WidgetSpan(
                    child: Transform.translate(
                      offset: const Offset(0, 1),
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

class MoneyCounterSaldoUserQr extends StatelessWidget {
  final double amount;
  final bool showBalance;
  final ValueChanged<double>?
  onUpdate; // 🔹 callback opcional para devolver el double

  const MoneyCounterSaldoUserQr({
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
                    fontSize: 30,
                    color: Color(0xFF00C896),
                    fontFamily: "PoppinsBold",
                  ),
                ),
                if (decimalPart.isNotEmpty)
                  WidgetSpan(
                    child: Transform.translate(
                      offset: const Offset(0, 3),
                      child: Text(
                        decimalPart,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
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

class MoneyCounterProximoSaldoQr extends StatelessWidget {
  final double amount;
  final bool showBalance;
  final ValueChanged<double>?
  onUpdate; // 🔹 callback opcional para devolver el double

  const MoneyCounterProximoSaldoQr({
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
                    fontSize: 20,
                    color: Colors.white,
                    fontFamily: "PoppinsBold",
                  ),
                ),
                if (decimalPart.isNotEmpty)
                  WidgetSpan(
                    child: Transform.translate(
                      offset: const Offset(0, 1),
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
