// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, unused_field, deprecated_member_use, avoid_print, duplicate_ignore, use_build_context_synchronously, unused_local_variable, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/UI/configuracionExtension.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:vibration/vibration.dart';

class configurarExtensionPage extends StatefulWidget {
  final String nombreExtension;

  const configurarExtensionPage({super.key, required this.nombreExtension});

  @override
  State<configurarExtensionPage> createState() =>
      _configurarExtensionPageState();
}

class _configurarExtensionPageState extends State<configurarExtensionPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  //Perdida Foco App
  bool _isAppInactive = false;
  bool distorcion = false;
  // Perdida Foco App

  //Suscripciones
  StreamSubscription<DocumentSnapshot>? userSub;
  StreamSubscription<DocumentSnapshot>? extensionSub;
  StreamSubscription<DocumentSnapshot>? utilitarioSub;
  //Fin Suscripciones

  //Animaciones
  late AnimationController _controllerTarjetas;

  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  bool frente = true;

  //Copiar Numero Tarjeta
  bool numeroCopiado = false;

  //Pages Controller
  final PageController _controllerPages = PageController();

  int cantExtensiones = 0;
  int currentPage = 0;

  //Sheet
  final PanelController sheetController = PanelController();

  //Vibracion Sheet
  double _lastPosition = 0.0;
  double _acumulado = 0.0;
  final double _umbral = 0.03;

  bool _didVibrateOpen = false;
  bool _didVibrateClose = false;

  //Ocultar Datos Tarjeta
  bool sheetExpand = true;

  bool showDatos = true;

  //Cancelar Tarjeta
  String? razonSeleccionada;

  final razonesCancelar = [
    "Ya no la necesito",
    "Problemas de seguridad",
    "Encontré una mejor alternativa",
    "Problemas con el utilitario",
    "Decision personal",
  ];

  bool cancelarTarjetaVis = false;
  String estadoCancelacion = "Inicial";

  //Congelar Tarjeta
  String? razonCongelarSeleccionada;

  bool congelarTarjetaVis = false;
  String estadoCongelacion = "Inicial";

  final razonesCongelar = [
    "Tarjeta extraviada",
    "Sospecha de fraude",
    "Problemas con el utilitario",
    "Congelamiento Temporal",
  ];

  //Descongelar Tarjeta
  bool descongelarTarjetaVis = false;
  String estadoDescongelacion = "Inicial";

  //Solicitar FaceID
  final localAuth = LocalAuthentication();

  late AnimationController _controllerCancelarTarjeta;
  late Animation<Offset> _slideAnimationCancelarTarjeta;

  //Datos User
  String nameuser = "";
  String uidUser = "";
  String avatarUser = "";
  double saldoUser = 0.0;

  //Datos Tarjeta User
  bool showTarjeta = true;

  String codeTarjetaUser = "";
  String numeroTarjetaUser = "";
  String numeroTarjetaUserOculto = "";
  String vencimientoTarjetaUser = "";
  String cvvTarjetaUser = "";
  String estadoTarjetaUser = "";

  //Configuraciones Tarjeta
  //Limite
  bool limiteGastos = false;
  bool sLimiteGastos = true;
  bool estadoLimite = false;
  bool limiteAlcanzado = false;
  double limite = 0.0;
  double limiteGastado = 0.0;
  double limiteRestante = 0.0;
  double porcentajeLimiteBar = 0.0;
  //Fin Limite

  //Datos Utilitario
  String uidUserExtension = "";
  String avatarUserExtension = "";
  String nombreUserExtension = "";
  String dniUserExtension = "";

  Future<void> leerShared() async {
    //Datos User
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString('codeUser') == null) {
      uidUser = "";
    } else {
      uidUser = prefs.getString('codeUser')!;
    }

    //Datos Tarjeta
    final prefsTarjeta = await SharedPreferences.getInstance();

    if (prefsTarjeta.getString('tarjetaUser') == null) {
      numeroTarjetaUser = "";
    } else {
      numeroTarjetaUser = prefsTarjeta.getString('tarjetaUser')!;
    }

    if (prefs.getBool('visSaldoUser') == null) {
      showTarjeta = true;
    } else {
      showTarjeta = prefs.getBool('visSaldoUser')!;
    }
  }

  Future<void> obtenerDatos() async {
    User? user = FirebaseAuth.instance.currentUser;

    await leerShared();

    userSub?.cancel();

    userSub = FirebaseFirestore.instance
        .collection('Usuarios') // colección principal
        .doc(uidUser) // documento del usuario
        .snapshots() // escuchar en tiempo real
        .listen((docSnapshot) async {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            try {
              //Obtener Datos Principales
              setState(() {
                nameuser = data["Nombre"] ?? "";
                avatarUser = data["Avatar"] ?? "";
                uidUser = user?.uid ?? "";
                showTarjeta = data["Mostrar Saldo"] ?? false;
              });

              //Obtener Tarjeta
              codeTarjetaUser = data["Tarjeta"] ?? "";
              obtenerTarjeta(widget.nombreExtension);
            } catch (e, s) {
              print("Error al asignar valores: $e");
              print(s);
            }
          } else {
            print('El documento no existe');
          }
        });
  }

  Future<void> obtenerDatosUtilitario() async {
    await obtenerDatos();

    utilitarioSub?.cancel();

    utilitarioSub = FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(uidUserExtension)
        .snapshots()
        .listen((docSnapshot) async {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            try {
              //Obtener Datos Principales
              setState(() {
                nombreUserExtension = data["Nombre"] ?? "";
                avatarUserExtension = data["Avatar"] ?? "";
                dniUserExtension = data["Dni"] ?? "";
              });
            } catch (e, s) {
              print("Error al asignar valores: $e");
              print(s);
            }
          } else {
            print('El documento no existe');
          }
        });
  }

  Future<void> obtenerTarjeta(String nombreExtension) async {
    extensionSub?.cancel();

    extensionSub = FirebaseFirestore.instance
        .collection('Extensiones')
        .doc("Extension $nombreExtension")
        .snapshots()
        .listen((docSnapshot) async {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              numeroTarjetaUser = data["NumeroTarjeta"] ?? "";
              vencimientoTarjetaUser = data["Vencimiento"] ?? "";
              cvvTarjetaUser = data["CVV"] ?? "";
              estadoTarjetaUser = data["Estado"] ?? "";
              uidUserExtension = data["Para"] ?? "";
            });

            //Limite Gastos
            limite = (data["Limite"] != null)
                ? (data["Limite"] as num).toDouble()
                : 0.0;

            estadoLimite = data["Limite Estado"] ?? true;

            if (limite != 0) {
              if (estadoLimite == false) {
                setState(() {
                  limiteGastos = true;
                  limiteGastado = (data["Limite Usado"] != null)
                      ? (data["Limite Usado"] as num).toDouble()
                      : 0.0;
                  limiteRestante = limite - limiteGastado;
                  porcentajeLimiteBar = (limiteGastado / limite).clamp(
                    0.0,
                    1.0,
                  );
                  sLimiteGastos = false;
                });
              } else {
                setState(() {
                  limiteGastos = true;
                  limiteGastado = (data["Limite Usado"] != null)
                      ? (data["Limite Usado"] as num).toDouble()
                      : 0.0;
                  limiteRestante = limite - limiteGastado;
                  porcentajeLimiteBar = (limiteGastado / limite).clamp(
                    0.0,
                    1.0,
                  );
                  sLimiteGastos = true;
                });
              }
            } else if (limite == 0 || estadoLimite == false) {
              setState(() {
                limiteGastos = false;
              });
            }

            if (limite != 0) {
              if (limite == limiteGastado) {
                setState(() {
                  limiteAlcanzado = true;
                });
              } else {
                setState(() {
                  limiteAlcanzado = false;
                });
              }
            }

            obtenerDatosUtilitario();
          }
        });
  }

  Future<void> solicitarBiometria() async {
    bool canCheck = await localAuth.canCheckBiometrics;
    bool authenticated = false;

    setState(() {
      estadoCancelacion = "Esperando";
      estadoCongelacion = "Esperando";
      estadoDescongelacion = "Esperando";
    });

    if (!canCheck) {
      print('El dispositivo no soporta biometría');

      //Cancelar Tarjeta
      Future.delayed(Duration(milliseconds: 800), () {
        if (cancelarTarjetaVis == true) {
          setState(() {
            Vibration.vibrate(duration: 5);
            estadoCancelacion = "Cancelando";
          });

          Future.delayed(Duration(seconds: 3), () {
            cancelarTarjeta();
            setState(() {
              Vibration.vibrate(duration: 15);
              estadoCancelacion = "Cancelada";
            });
          });
        }

        //Congelar Tarjeta
        if (congelarTarjetaVis == true) {
          setState(() {
            Vibration.vibrate(duration: 5);
            estadoCongelacion = "Cancelando";
          });

          Future.delayed(Duration(seconds: 3), () {
            congelarTarjeta();
            setState(() {
              Vibration.vibrate(duration: 15);
              estadoCongelacion = "Cancelada";
            });
          });
        }

        //Descongelar Tarjeta
        if (descongelarTarjetaVis == true) {
          setState(() {
            Vibration.vibrate(duration: 5);
            estadoDescongelacion = "Cancelando";
          });

          Future.delayed(Duration(seconds: 3), () {
            descongelarTarjeta();
            setState(() {
              Vibration.vibrate(duration: 15);
              estadoDescongelacion = "Cancelada";
            });
          });
        }
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
          estadoCancelacion = "Inicial";
          estadoCongelacion = "Inicial";
          estadoDescongelacion = "Inicial";
        });
        return;
      }

      if (e.code == "Canceled") {
        print("El usuario canceló la autenticación");
        setState(() {
          estadoCancelacion = "Inicial";
          estadoCongelacion = "Inicial";
          estadoDescongelacion = "Inicial";
        });
        showFlushbarError(
          context,
          "Error en la Autenticación. Intenta nuevamente.",
        );
        return;
      }
    }

    if (authenticated) {
      Future.delayed(Duration(milliseconds: 800), () {
        //Cancelar Tarjeta
        if (cancelarTarjetaVis == true) {
          setState(() {
            Vibration.vibrate(duration: 5);
            estadoCancelacion = "Cancelando";
          });

          Future.delayed(Duration(seconds: 3), () {
            cancelarTarjeta();
            setState(() {
              Vibration.vibrate(duration: 15);
              estadoCancelacion = "Cancelada";
            });
          });
        }

        //Congelar Tarjeta
        if (congelarTarjetaVis == true) {
          setState(() {
            Vibration.vibrate(duration: 5);
            estadoCongelacion = "Cancelando";
          });

          Future.delayed(Duration(seconds: 3), () {
            congelarTarjeta();
            setState(() {
              Vibration.vibrate(duration: 15);
              estadoCongelacion = "Cancelada";
            });
          });
        }

        //Descongelar Tarjeta
        if (descongelarTarjetaVis == true) {
          setState(() {
            Vibration.vibrate(duration: 5);
            estadoDescongelacion = "Cancelando";
          });

          Future.delayed(Duration(seconds: 3), () {
            descongelarTarjeta();
            setState(() {
              Vibration.vibrate(duration: 15);
              estadoDescongelacion = "Cancelada";
            });
          });
        }
      });
    } else {
      print('Autenticación biométrica fallida');
      setState(() {
        estadoCancelacion = "Inicial";
        estadoCongelacion = "Inicial";
        estadoDescongelacion = "Inicial";
      });
      showFlushbarError(
        context,
        "Error en la Autenticación. Intenta nuevamente.",
      );
    }
  }

  //Limite Gastos
  Future<void> cambiarEstadoLimite(String nombreExtension) async {
    FirebaseFirestore.instance
        .collection("Extensiones")
        .doc("Extension $nombreExtension")
        .update({"Limite Estado": sLimiteGastos});
  }
  //Fin Limite gastos

  //Cancelar Extension
  Future<void> cancelarTarjeta() async {
    //Borrar Tarjeta
    FirebaseFirestore.instance
        .collection('Extensiones')
        .doc("Extension ${widget.nombreExtension}")
        .delete();

    //Enviar Notificacion
    crearNotificacionCancelar();
  }

  Future<void> crearNotificacionCancelar() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Extension Cancelada #$uidUser")
        .set({
          "Avatar": avatarUser,
          "De": nameuser,
          "De uid": uidUser,
          "Motivo": razonSeleccionada ?? "",
          "Nombre Extension": widget.nombreExtension,
          "FechaTime": DateTime.now(),
          "Fecha": fecha,
          "Hora": horaActual,
          "Utilitario": uidUserExtension,
          "Involucra": [uidUser, uidUserExtension],
          "Leida": {uidUser: false, uidUserExtension: false},
          "Tipo": "Extension Cancelada",
        });
  }

  //Congelar Extension
  Future<void> congelarTarjeta() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final hora =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    //Actualizar Tarjeta
    FirebaseFirestore.instance
        .collection('Extensiones')
        .doc("Extension ${widget.nombreExtension}")
        .update({"Estado": "Congelada"});

    //Enviar Notificacion
    crearNotificacionCongelar();
  }

  Future<void> crearNotificacionCongelar() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Extension Congelada #$uidUser")
        .set({
          "Avatar": avatarUser,
          "De": nameuser,
          "De uid": uidUser,
          "Motivo": razonCongelarSeleccionada ?? "",
          "Nombre Extension": widget.nombreExtension,
          "FechaTime": DateTime.now(),
          "Fecha": fecha,
          "Hora": horaActual,
          "Utilitario": uidUserExtension,
          "Involucra": [uidUser, uidUserExtension],
          "Leida": {uidUser: false, uidUserExtension: false},
          "Tipo": "Extension Congelada",
        });
  }

  //Descongelar Extension
  Future<void> descongelarTarjeta() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final hora =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    //Actualizar Tarjeta
    FirebaseFirestore.instance
        .collection('Extensiones')
        .doc("Extension ${widget.nombreExtension}")
        .update({"Estado": "Habilitada"});

    //Enviar Notificacion
    crearNotificacionDescongelar();
  }

  Future<void> crearNotificacionDescongelar() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Extension Descongelada #$uidUser")
        .set({
          "Avatar": avatarUser,
          "De": nameuser,
          "De uid": uidUser,
          "FechaTime": DateTime.now(),
          "Nombre Extension": widget.nombreExtension,
          "Fecha": fecha,
          "Hora": horaActual,
          "Utilitario": uidUserExtension,
          "Involucra": [uidUser, uidUserExtension],
          "Leida": {uidUser: false, uidUserExtension: false},
          "Tipo": "Extension Descongelada",
        });
  }

  void showFlushbarCopiado(BuildContext context, String message) {
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

  void abrirSheet() {
    if (!mounted) return;

    if (sheetController.isAttached) {
      sheetController.open();
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        abrirSheet();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    leerShared();

    obtenerDatos();

    setState(() {}); //Actualizar UI

    Future.delayed(Duration(seconds: 3), () {
      print(widget.nombreExtension);
    });

    //Perdida Foco App
    WidgetsBinding.instance.addObserver(this);
    // Perdida Foco App

    abrirSheet();

    //Fondo Tarjetas
    _controllerTarjetas = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    //Cancelar Tarjeta
    _controllerCancelarTarjeta = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimationCancelarTarjeta =
        Tween<Offset>(
          begin: const Offset(0, 1), // ← empieza abajo
          end: Offset.zero, // ← termina arriba
        ).animate(
          CurvedAnimation(
            parent: _controllerCancelarTarjeta,
            curve: Curves.easeInOut,
          ),
        );

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _iconAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  dispose() {
    _controllerTarjetas.dispose();
    _controllerCancelarTarjeta.dispose();
    _iconController.dispose();
    setState(() {
      sheetExpand = false;
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isAppInactive =
          state != AppLifecycleState.resumed; // si no está en primer plano
    });

    if (_isAppInactive =
        state != AppLifecycleState.resumed && sheetExpand == false ||
        cancelarTarjetaVis == true ||
        congelarTarjetaVis == true ||
        descongelarTarjetaVis == true) {
      setState(() {
        distorcion = true;
      });
    } else {
      setState(() {
        distorcion = false;
      });
    }
  }

  String formatMoney(double value) {
    // Si es entero, devolvemos sin decimales
    if (value % 1 == 0) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );
    }

    // Si tiene decimales → mostramos decimales con coma y miles con punto
    String integerPart = value.floor().toString();
    String decimalPart = value.toStringAsFixed(2).split('.')[1];

    // Formatear miles
    String formattedInt = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return "$formattedInt,$decimalPart";
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

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(3, 5, 25, 1),
                Color.fromRGBO(13, 20, 40, 1),
              ],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
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
                      child: Icon(LucideIcons.arrowLeft, color: Colors.white),
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
                      setState(() {
                        sheetExpand = false;
                      });
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
                            "Mi Extension",
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
                            widget.nombreExtension,
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
            body: Stack(children: [SizedBox(child: tarjetaWidget())]),
          ),
        ),
        Visibility(
          visible: distorcion,
          child: Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Container(
                  color: Colors.black.withOpacity(0.3), // oscurece un poco
                ),
              ),
            ),
          ),
        ),
        cancelarTarjetaWidget(),
        congelarTarjetaWidget(),
        descongelarTarjetaWidget(),
      ],
    );
  }

  Widget tarjetaWidget() {
    final size = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Stack(
      children: [
        // Patrones de tarjetas animadas
        Positioned.fill(
          child: Opacity(
            opacity: 0.3,
            child: AnimatedBuilder(
              animation: _controllerTarjetas,
              builder: (context, child) {
                return CustomPaint(
                  painter: _TarjetasPatternPainter(
                    animationValue: _controllerTarjetas.value,
                  ),
                );
              },
            ),
          ),
        ),
        // TARJETA
        Positioned(
          top: h(13),
          left: w(20),
          right: w(20),
          child: GestureDetector(
            child: GestureDetector(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                curve: Curves.easeOut,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: estadoTarjetaUser == "Habilitada"
                      ? LinearGradient(
                          colors: [
                            Color.fromRGBO(200, 90, 0, 1),
                            Colors.orange.shade600,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : LinearGradient(
                          colors: [
                            Color.fromRGBO(33, 13, 243, 1),
                            Colors.blue.shade600,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                ),
                child: Stack(
                  children: [
                    SvgPicture.asset(
                      'assets/fondoTarjeta.svg',
                      color: Colors.white.withOpacity(0.1), // color del patrón
                      fit: BoxFit.cover,
                      width: screenWidth,
                      height: screenHeight,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Mi Extension",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: sp(15),
                                  fontFamily: "Poppins",
                                ),
                              ),
                              Icon(
                                LucideIcons.creditCard,
                                color: Colors.white,
                                size: sp(25),
                              ),
                            ],
                          ),

                          Text(
                            widget.nombreExtension,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(28),
                              fontFamily: "PoppinsBold",
                            ),
                          ),

                          Spacer(),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                numeroTarjetaUser,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: sp(20),
                                  letterSpacing: 3,
                                  fontFamily: "PoppinsBold",
                                ),
                              ),
                              Icon(
                                showDatos
                                    ? numeroCopiado
                                          ? LucideIcons.checkCircle
                                          : LucideIcons.copy
                                    : null,
                                color: Colors.white,
                                size: sp(20),
                              ),
                            ],
                          ),
                          SizedBox(height: h(18)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Vencimiento",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: sp(15),
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    showDatos
                                        ? vencimientoTarjetaUser
                                        : "**/**",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: sp(18),
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Código De Seguridad",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: sp(15),
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    showDatos ? cvvTarjetaUser : "***",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: sp(18),
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                if (sheetExpand == false && showDatos == true) {
                  Vibration.vibrate(duration: 10);

                  Clipboard.setData(ClipboardData(text: numeroTarjetaUser));

                  setState(() {
                    numeroCopiado = true;
                  });

                  showFlushbarCopiado(
                    context,
                    "Numero de tarjeta copiado al portapapeles.",
                  );

                  Future.delayed(Duration(milliseconds: 4000), () {
                    setState(() {
                      numeroCopiado = false;
                    });
                  });
                }
              },
            ),
          ),
        ),
        //Sheet
        SlidingUpPanel(
          color: Colors.transparent, //Color.fromRGBO(13, 20, 40, 1),
          controller: sheetController,
          minHeight: h(563), // Altura minima 580
          maxHeight: h(690), // Altura inicial 700
          defaultPanelState: PanelState.CLOSED,
          backdropEnabled: false,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(33),
            topRight: Radius.circular(33),
          ),

          onPanelClosed: () {
            setState(() {
              sheetExpand = false;
            });
          },

          onPanelOpened: () {
            setState(() {
              sheetExpand = true;
            });

            //Verificar Lado Tarjeta
            if (frente == false) {
              setState(() {
                frente = true;
              });
            }
          },

          onPanelSlide: (position) {
            // ===== HAPTICA SCROLL =====
            double delta = (position - _lastPosition).abs();
            _lastPosition = position;

            _acumulado += delta;

            if (_acumulado > _umbral) {
              HapticFeedback.selectionClick(); // haptica suave repetida
              _acumulado = 0;
            }

            // ===== HAPTICA AL FINAL DE ANIMACIÓN =====
            // Cuando llega a 1.0 (panel totalmente abierto)
            if (position >= 0.999) {
              if (!_didVibrateOpen) {
                HapticFeedback.mediumImpact(); // golpe más sólido
                _didVibrateOpen = true;
                _didVibrateClose = false; // reseteo del contrario
              }
            }
            // Cuando llega a 0.0 (panel totalmente cerrado)
            else if (position <= 0.001) {
              if (!_didVibrateClose) {
                HapticFeedback.mediumImpact(); // golpe más sólido
                _didVibrateClose = true;
                _didVibrateOpen = false; // reseteo del contrario
              }
            }
          },

          panelBuilder: (scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(33),
                topRight: Radius.circular(33),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                child: Container(
                  color: Color.fromRGBO(1, 165, 113, 0.878).withOpacity(0.1),

                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors
                              .transparent, //Color.fromRGBO(1, 165, 113, 0.878),
                          Color.fromRGBO(13, 20, 40, 1),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(33),
                        topRight: Radius.circular(33),
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.06,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: h(18)),
                            Center(
                              child: Container(
                                height: h(5),
                                width: w(80),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(33),
                                  color: Colors.white60,
                                ),
                              ),
                            ),
                            SizedBox(height: h(23)),
                            // -------------------------
                            // BOTONES SUPERIORES
                            // -------------------------
                            if (estadoTarjetaUser == "Habilitada") ...[
                              Row(
                                children: [
                                  // -------------------------
                                  // BOTÓN 2
                                  // -------------------------
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: size.width * 0.01,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 6,
                                            sigmaY: 6,
                                          ),
                                          child: GestureDetector(
                                            child: Container(
                                              height: 113,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.03,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.03),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: w(45),
                                                    height: h(45),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: [
                                                          Color.fromRGBO(
                                                            33,
                                                            13,
                                                            243,
                                                            1,
                                                          ),
                                                          Colors.blue.shade600,
                                                        ],
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      LucideIcons.snowflake,
                                                      color: Colors.white,
                                                      size: sp(23),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Congelar\nTarjeta',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white60,
                                                      fontSize: sp(13),
                                                      fontFamily: "PoppinsBold",
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            onTap: () {
                                              Vibration.vibrate(duration: 5);
                                              _controllerCancelarTarjeta
                                                  .forward();
                                              setState(() {
                                                distorcion = true;
                                                congelarTarjetaVis = true;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // -------------------------
                                  // BOTÓN 3
                                  // -------------------------
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: size.width * 0.01,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 6,
                                            sigmaY: 6,
                                          ),
                                          child: GestureDetector(
                                            child: Container(
                                              height: 113,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.03,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.03),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: w(45),
                                                    height: h(45),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: [
                                                          Color.fromRGBO(
                                                            208,
                                                            0,
                                                            0,
                                                            1,
                                                          ),
                                                          Colors.red.shade600,
                                                        ],
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      LucideIcons.xCircle,
                                                      color: Colors.white,
                                                      size: sp(23),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Cancelar\nTarjeta',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white60,
                                                      fontSize: sp(13),
                                                      fontFamily: "PoppinsBold",
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            onTap: () {
                                              Vibration.vibrate(duration: 5);
                                              _controllerCancelarTarjeta
                                                  .forward();
                                              setState(() {
                                                distorcion = true;
                                                cancelarTarjetaVis = true;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (estadoTarjetaUser == "Congelada") ...[
                              GestureDetector(
                                onTap: () {
                                  Vibration.vibrate(duration: 5);
                                  _controllerCancelarTarjeta.forward();
                                  setState(() {
                                    distorcion = true;
                                    descongelarTarjetaVis = true;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: h(20),
                                    horizontal: w(20),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0F6BFF,
                                    ), // azul exacto del ejemplo
                                    borderRadius: BorderRadius.circular(23),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0F6BFF,
                                        ).withOpacity(0.35),
                                        blurRadius: 23,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // ICONO
                                      Container(
                                        padding: const EdgeInsets.all(
                                          13,
                                        ), // sin valores fijos tipo width/height
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.25),
                                        ),
                                        child: Icon(
                                          Icons.ac_unit_rounded,
                                          color: Colors.white,
                                          size: sp(
                                            25,
                                          ), // tamaño auto relativo está permitido
                                        ),
                                      ),

                                      SizedBox(width: w(15)),

                                      // TEXTOS
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Descongelar Extensión",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: sp(18),
                                                fontFamily: "PoppinsBold",
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "Volvé habilitar tu extensión.",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: sp(15),
                                                fontFamily: "PoppinsBold",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            SizedBox(
                              height: estadoTarjetaUser == "Habilitada"
                                  ? size.height * 0.02
                                  : size.height * 0.05,
                            ),

                            if (estadoTarjetaUser == "Habilitada") ...[
                              // -------------------------
                              // Limite De Gastos
                              // -------------------------
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  // Card externo
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenHeight * 0.025,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0F1A27,
                                    ), // fondo oscuro similar
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.03),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.45),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          // Icon con glow / gradiente
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Circle icon
                                              Container(
                                                width: screenWidth * 0.09,
                                                height: screenWidth * 0.09,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient:
                                                      limiteAlcanzado == true
                                                      ? LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Colors.red,
                                                            Colors.redAccent,
                                                          ],
                                                        )
                                                      : estadoLimite
                                                      ? LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Color.fromRGBO(
                                                              1,
                                                              165,
                                                              113,
                                                              1,
                                                            ),
                                                            Color(0xFF00A86B),
                                                          ],
                                                        )
                                                      : LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Colors.white60,
                                                            Colors.grey,
                                                          ],
                                                        ),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    limiteAlcanzado == true
                                                        ? Icons.warning
                                                        : Icons.lock_outline,
                                                    color: Colors.white,
                                                    size: sp(20),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(width: screenWidth * 0.03),

                                          // Textos (title + subtitle) y botón
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Título
                                                Text(
                                                  limiteAlcanzado == true
                                                      ? 'Límite Alcanzado'
                                                      : 'Límite de gastos',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: sp(16),
                                                    fontFamily: "PoppinsBold",
                                                    height: h(1),
                                                  ),
                                                ),

                                                SizedBox(height: h(5)),

                                                // Subtítulo
                                                Text(
                                                  limiteGastos == true
                                                      ? "\$" +
                                                            formatMoney(limite)
                                                      : 'Ponele limite a tus gastos.',
                                                  style: TextStyle(
                                                    color: Colors.white60,
                                                    fontSize: sp(13),
                                                    fontFamily: "Poppins",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Botón "Activar" tipo pill o switch
                                          if (limite == 0) ...[
                                            Container(
                                              height: screenHeight * 0.045,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: screenWidth * 0.04,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color.fromRGBO(
                                                      1,
                                                      165,
                                                      113,
                                                      1,
                                                    ),
                                                    Color(0xFF00A86B),
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
                                                    ).withOpacity(0.23),
                                                    blurRadius: 13,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: TextButton(
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: Size(
                                                    60,
                                                    screenHeight * 0.045,
                                                  ),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                onPressed: () {
                                                  Vibration.vibrate(
                                                    duration: 5,
                                                  );
                                                  Navigator.push(
                                                    context,
                                                    PageTransition(
                                                      type: PageTransitionType
                                                          .leftToRight,
                                                      child: configuraciontExtensionPage(
                                                        configuracion:
                                                            "Limite Extensión",
                                                        descripcionconfiguracion:
                                                            "Establece un limite a tu extensión",
                                                        nombreExtension: widget
                                                            .nombreExtension,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Activar',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: "PoppinsBold",
                                                    fontSize: sp(13),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ] else if (limite != 0) ...[
                                            Switch(
                                              value: sLimiteGastos,
                                              onChanged: (value) {
                                                Vibration.vibrate(duration: 5);
                                                setState(() {
                                                  sLimiteGastos = value;
                                                });
                                                cambiarEstadoLimite(
                                                  widget.nombreExtension,
                                                );
                                              },
                                              activeColor: Colors
                                                  .white, // color del círculo
                                              activeTrackColor: Color.fromRGBO(
                                                1,
                                                165,
                                                113,
                                                1,
                                              ), // color de la barra cuando está activo
                                              inactiveThumbColor: Colors.white,
                                              inactiveTrackColor:
                                                  Colors.grey.shade700,
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (limite != 0) ...[
                                        SizedBox(height: h(8)),
                                        LinearProgressIndicator(
                                          value: porcentajeLimiteBar,
                                          backgroundColor: Colors.white12,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            sLimiteGastos == true
                                                ? porcentajeLimiteBar <= 0.5
                                                      ? Color.fromRGBO(
                                                          1,
                                                          165,
                                                          113,
                                                          1,
                                                        )
                                                      : porcentajeLimiteBar >
                                                                0.5 &&
                                                            porcentajeLimiteBar <=
                                                                0.75
                                                      ? Colors.yellow
                                                      : porcentajeLimiteBar >
                                                                0.75 &&
                                                            porcentajeLimiteBar <=
                                                                1
                                                      ? Colors.red
                                                      : Color.fromRGBO(
                                                          1,
                                                          165,
                                                          113,
                                                          1,
                                                        )
                                                : Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                        SizedBox(height: h(8)),
                                        if (limiteAlcanzado == true) ...[
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Cambia o desactiva el limite para utilizar la tarjeta.",
                                              style: TextStyle(
                                                color: sLimiteGastos == true
                                                    ? Colors.white
                                                    : Colors.white60,
                                                fontFamily: "PoppinsBold",
                                                fontSize: sp(13),
                                              ),
                                            ),
                                          ),
                                        ] else ...[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "\$" +
                                                    formatMoney(limiteGastado),
                                                style: TextStyle(
                                                  color: sLimiteGastos == true
                                                      ? Colors.white
                                                      : Colors.white60,
                                                  fontFamily: "PoppinsBold",
                                                  fontSize: sp(13),
                                                ),
                                              ),
                                              Text(
                                                "\$" +
                                                    formatMoney(limiteRestante),
                                                style: TextStyle(
                                                  color: sLimiteGastos == true
                                                      ? Colors.green
                                                      : Colors.white60,
                                                  fontFamily: "PoppinsBold",
                                                  fontSize: sp(13),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        SizedBox(height: h(13)),
                                        GestureDetector(
                                          child: Container(
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
                                                  BorderRadius.circular(13),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: h(13),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Configurar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "PoppinsBold",
                                                      fontSize: sp(15),
                                                    ),
                                                  ),
                                                  SizedBox(width: w(5)),
                                                  AnimatedBuilder(
                                                    animation: _iconAnimation,
                                                    builder: (context, child) {
                                                      return Transform.translate(
                                                        offset: Offset(
                                                          _iconAnimation.value,
                                                          0,
                                                        ),
                                                        child: child,
                                                      );
                                                    },
                                                    child: Icon(
                                                      LucideIcons.settings,
                                                      color: Colors.white,
                                                      size: sp(15),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            Vibration.vibrate(duration: 5);
                                            Navigator.push(
                                              context,
                                              PageTransition(
                                                type: PageTransitionType
                                                    .rightToLeft,
                                                child: configuraciontExtensionPage(
                                                  configuracion:
                                                      "Limite Extensión",
                                                  descripcionconfiguracion:
                                                      "Establece un limite a tu extensión",
                                                  nombreExtension:
                                                      widget.nombreExtension,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                      SizedBox(height: h(33)),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: w(15),
                                          vertical: h(15),
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color.fromRGBO(
                                                200,
                                                90,
                                                0,
                                                1,
                                              ).withOpacity(0.3),
                                              Color.fromRGBO(
                                                200,
                                                90,
                                                0,
                                                1,
                                              ).withOpacity(0.3),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: Color.fromRGBO(
                                              200,
                                              90,
                                              0,
                                              1,
                                            ),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.35,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: sp(18),
                                                  backgroundColor: Colors.green,
                                                  child: Image.asset(
                                                    avatarUserExtension,
                                                  ),
                                                ),
                                                SizedBox(width: w(8)),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      nombreUserExtension,
                                                      style: TextStyle(
                                                        fontSize: sp(15),
                                                        fontFamily:
                                                            "PoppinsBold",
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    SizedBox(height: h(3)),
                                                    Text(
                                                      dniUserExtension,
                                                      style: TextStyle(
                                                        fontSize: sp(13),
                                                        fontFamily:
                                                            "PoppinsBold",
                                                        color: Colors.white60,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (estadoTarjetaUser == "Congelada") ...[
                              Column(
                                children: [
                                  Center(
                                    child: Text(
                                      "Tu extensión está congelada",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: sp(18),
                                        fontFamily: "PoppinsBold",
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: h(10)),
                                  Center(
                                    child: Text(
                                      "Descongelala para ver mas.",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: sp(15),
                                        fontFamily: "PoppinsBold",
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: h(33)),
                                  Lottie.asset(
                                    "assets/congeladaSheetAnim.json",
                                    repeat: true,
                                    height: h(300),
                                    width: w(300),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },

          body: null, // puede quedar vacío o poner background
        ),
        //Fin Sheet
      ],
    );
  }

  Widget cancelarTarjetaWidget() {
    final size = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Visibility(
      visible: cancelarTarjetaVis,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w(23),
            vertical: estadoCancelacion == "Inicial"
                ? h(113)
                : estadoCancelacion == "Cancelando"
                ? h(300)
                : estadoCancelacion == "Cancelada"
                ? h(200)
                : estadoCancelacion == "Esperando"
                ? h(300)
                : h(113),
          ),
          child: SlideTransition(
            position: _slideAnimationCancelarTarjeta,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
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
                border: Border.all(
                  color: estadoCancelacion != "Cancelada"
                      ? Colors.red
                      : Color.fromRGBO(1, 165, 113, 0.878),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: estadoCancelacion != "Cancelada"
                        ? Colors.red
                        : Color.fromRGBO(1, 165, 113, 0.878),
                    blurRadius: 5,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(33),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (estadoCancelacion == "Inicial") ...[
                      Row(
                        children: [
                          Icon(
                            LucideIcons.xCircle,
                            color: Colors.red,
                            size: sp(25),
                          ),
                          SizedBox(width: w(10)),
                          Text(
                            "Cancelar Extensión",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(20),
                              fontFamily: "PoppinsBold",
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: h(18)),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "¿Estás seguro que deseas cancelar tu extensión? Esta acción es ",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: sp(13.8),
                                fontFamily: "Poppins",
                              ),
                            ),
                            TextSpan(
                              text: "irreversible. ",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: sp(13.8),
                                fontFamily: "Poppins",
                              ),
                            ),
                            TextSpan(
                              text:
                                  "Podés solicitar una nueva en cualquier momento.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: sp(13.8),
                                fontFamily: "Poppins",
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: h(23)),
                      Divider(color: Colors.white60, height: h(1)),
                      SizedBox(height: h(23)),
                      Text(
                        "¿Por qué cancelás tu extensión? (Opcional)",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: sp(13.8),
                          fontFamily: "PoppinsBold",
                          decoration: TextDecoration.none,
                        ),
                      ),
                      SizedBox(height: h(23)),
                      Column(
                        children: razonesCancelar.map((r) {
                          final isSelected = razonSeleccionada == r;

                          return GestureDetector(
                            onTap: () {
                              Vibration.vibrate(duration: 5);
                              if (razonSeleccionada == r) {
                                setState(() {
                                  razonSeleccionada = "";
                                });
                              } else {
                                setState(() {
                                  razonSeleccionada = r;
                                });
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: h(13)),
                              padding: EdgeInsets.symmetric(
                                vertical: h(13),
                                horizontal: w(15),
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF1E293B),
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          Color.fromRGBO(
                                            1,
                                            165,
                                            113,
                                            1,
                                          ).withOpacity(0.3),
                                          Colors.green.shade600.withOpacity(
                                            0.3,
                                          ),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Color(0xFF1E293B),
                                          Color(0xFF1E293B),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: isSelected
                                      ? Color.fromRGBO(1, 165, 113, 1)
                                      : Colors.transparent,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: sp(13.8),
                                        fontFamily: "Poppins",
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: h(20),
                                    width: h(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Color.fromRGBO(1, 165, 113, 1)
                                            : Colors.grey,
                                        width: 1.8,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              height: h(8),
                                              width: w(8),
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
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: h(30)),
                      SizedBox(
                        width: double.infinity,
                        height: h(50),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          onPressed: () {
                            Vibration.vibrate(duration: 5);
                            solicitarBiometria();
                          },
                          child: Text(
                            "Sí, cancelar extensión",
                            style: TextStyle(
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h(8)),
                      SizedBox(
                        width: double.infinity,
                        height: h(50),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(13, 20, 40, 1),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          onPressed: () {
                            Vibration.vibrate(duration: 5);
                            _controllerCancelarTarjeta.reverse();
                            Future.delayed(Duration(milliseconds: 500), () {
                              setState(() {
                                cancelarTarjetaVis = false;
                                distorcion = false;
                                razonSeleccionada = "";
                              });
                            });
                          },
                          child: Text(
                            "No, volver atrás",
                            style: TextStyle(
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ] else if (estadoCancelacion == "Esperando") ...[
                      SizedBox(height: h(53)),
                      Center(
                        child: Icon(
                          LucideIcons.scanFace,
                          color: Colors.red,
                          size: sp(83),
                        ),
                      ),
                      SizedBox(height: h(53)),
                      Center(
                        child: Text(
                          "Verificacion Biometrica",
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
                    ] else if (estadoCancelacion == "Cancelando") ...[
                      SizedBox(height: h(53)),
                      Center(
                        child: SizedBox(
                          height: h(83),
                          width: w(83),
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 1,
                          ),
                        ),
                      ),
                      SizedBox(height: h(53)),
                      Center(
                        child: Text(
                          "Cancelando tu extensión",
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
                          "Porfavor espera unos segundos",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: sp(18),
                            fontFamily: "PoppinsBold",
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ] else if (estadoCancelacion == "Cancelada") ...[
                      Center(
                        child: Lottie.asset(
                          "assets/pagoRealizadoVerde.json",
                          repeat: false,
                          height: h(250),
                          width: w(250),
                        ),
                      ),
                      Center(
                        child: Text(
                          "Extensión Cancelada",
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
                          textAlign: TextAlign.center,
                          "Tu extensión ha sido cancelada exitosamente. Ya nadie podra realizar transacciones con ella.",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: sp(18),
                            fontFamily: "PoppinsBold",
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      SizedBox(height: h(43)),
                      Center(
                        child: GestureDetector(
                          child: Container(
                            height: h(50),
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
                                "Entendido",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: sp(17),
                                  fontFamily: "PoppinsBold",
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            Vibration.vibrate(duration: 5);
                            _controllerCancelarTarjeta.reverse();
                            Future.delayed(Duration(milliseconds: 500), () {
                              Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: MenuPrincipalPage(),
                                ),
                              );
                              setState(() {
                                cancelarTarjetaVis = false;
                                distorcion = false;
                                razonSeleccionada = "";
                                estadoCancelacion = "Inicial";
                                estadoCongelacion = "Inicial";
                                estadoDescongelacion = "Inicial";
                              });
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget congelarTarjetaWidget() {
    final size = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Visibility(
      visible: congelarTarjetaVis,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w(23),
            vertical: estadoCongelacion == "Inicial"
                ? h(100)
                : estadoCongelacion == "Cancelando"
                ? h(300)
                : estadoCongelacion == "Cancelada"
                ? h(200)
                : estadoCongelacion == "Esperando"
                ? h(300)
                : h(100),
          ),
          child: SlideTransition(
            position: _slideAnimationCancelarTarjeta,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
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
                border: Border.all(
                  color: estadoCongelacion != "Cancelada"
                      ? Color.fromRGBO(33, 13, 243, 1)
                      : Color.fromRGBO(33, 13, 243, 1),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: estadoCongelacion != "Cancelada"
                        ? Color.fromRGBO(33, 13, 243, 1)
                        : Color.fromRGBO(33, 13, 243, 1),
                    blurRadius: 5,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(33),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (estadoCongelacion == "Inicial") ...[
                      Row(
                        children: [
                          Icon(
                            LucideIcons.snowflake,
                            color: Color.fromRGBO(33, 13, 243, 1),
                            size: sp(25),
                          ),
                          SizedBox(width: w(10)),
                          Text(
                            "Congelar Extensión",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(20),
                              fontFamily: "PoppinsBold",
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: h(18)),
                      Text(
                        "Suspende temporalmente tu extensión",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: sp(13.8),
                          fontFamily: "PoppinsBold",
                          decoration: TextDecoration.none,
                        ),
                      ),
                      SizedBox(height: h(23)),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(
                                  255,
                                  15,
                                  22,
                                  36,
                                ), // fondo oscuro
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.blueAccent,
                                  width: w(1),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🔹 Icono de check
                                  Container(
                                    padding: const EdgeInsets.all(4.1),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.warning,
                                      color: Colors.blueAccent,
                                      size: sp(18),
                                    ),
                                  ),
                                  SizedBox(width: w(13)),
                                  // 🔹 Texto
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: w(300),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              "¿Qué sucede al congelar?",
                                              style: TextStyle(
                                                color: Colors.blueAccent,
                                                fontFamily: "PoppinsBold",
                                                fontSize: sp(15),
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: h(8)),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: w(300),
                                          ),
                                          child: Text(
                                            "• El utilitario no podra utilizarla.",
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: sp(13),
                                              fontFamily: "PoppinsBold",
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: h(5)),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: w(300),
                                          ),
                                          child: Text(
                                            "• Los pagos recurrentes serán rechazados.",
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: sp(13),
                                              fontFamily: "PoppinsBold",
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: h(5)),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: w(300),
                                          ),
                                          child: Text(
                                            "• Podrás descongelarla cuando quieras.",
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: sp(13),
                                              fontFamily: "PoppinsBold",
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: h(23)),
                      Divider(color: Colors.white60, height: h(1)),
                      SizedBox(height: h(23)),
                      Text(
                        "¿Por qué congelas tu extensión? (Opcional)",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: sp(13.8),
                          fontFamily: "PoppinsBold",
                          decoration: TextDecoration.none,
                        ),
                      ),
                      SizedBox(height: h(23)),
                      Column(
                        children: razonesCongelar.map((r) {
                          final isSelected = razonCongelarSeleccionada == r;

                          return GestureDetector(
                            onTap: () {
                              Vibration.vibrate(duration: 5);
                              if (razonCongelarSeleccionada == r) {
                                setState(() {
                                  razonCongelarSeleccionada = "";
                                });
                              } else {
                                setState(() {
                                  razonCongelarSeleccionada = r;
                                });
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: h(13)),
                              padding: EdgeInsets.symmetric(
                                vertical: h(13),
                                horizontal: w(15),
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF1E293B),
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          Color.fromRGBO(
                                            1,
                                            165,
                                            113,
                                            1,
                                          ).withOpacity(0.3),
                                          Colors.green.shade600.withOpacity(
                                            0.3,
                                          ),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Color(0xFF1E293B),
                                          Color(0xFF1E293B),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: isSelected
                                      ? Color.fromRGBO(1, 165, 113, 1)
                                      : Colors.transparent,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: sp(13.8),
                                        fontFamily: "Poppins",
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: h(20),
                                    width: h(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Color.fromRGBO(1, 165, 113, 1)
                                            : Colors.grey,
                                        width: 1.8,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              height: h(8),
                                              width: w(8),
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
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: h(13)),
                      SizedBox(
                        width: double.infinity,
                        height: h(50),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(33, 13, 243, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          onPressed: () {
                            Vibration.vibrate(duration: 5);
                            solicitarBiometria();
                          },
                          child: Text(
                            "Sí, congelar extensión",
                            style: TextStyle(
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h(8)),
                      SizedBox(
                        width: double.infinity,
                        height: h(50),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(13, 20, 40, 1),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          onPressed: () {
                            Vibration.vibrate(duration: 5);
                            _controllerCancelarTarjeta.reverse();
                            Future.delayed(Duration(milliseconds: 500), () {
                              setState(() {
                                congelarTarjetaVis = false;
                                distorcion = false;
                                razonCongelarSeleccionada = "";
                              });
                            });
                          },
                          child: Text(
                            "No, volver atrás",
                            style: TextStyle(
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ] else if (estadoCongelacion == "Esperando") ...[
                      SizedBox(height: h(53)),
                      Center(
                        child: Icon(
                          LucideIcons.scanFace,
                          color: Color.fromRGBO(33, 13, 243, 1),
                          size: sp(83),
                        ),
                      ),
                      SizedBox(height: h(53)),
                      Center(
                        child: Text(
                          "Verificacion Biometrica",
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
                    ] else if (estadoCongelacion == "Cancelando") ...[
                      SizedBox(height: h(53)),
                      Center(
                        child: SizedBox(
                          height: h(83),
                          width: w(83),
                          child: CircularProgressIndicator(
                            color: Color.fromRGBO(33, 13, 243, 1),
                            strokeWidth: 1,
                          ),
                        ),
                      ),
                      SizedBox(height: h(53)),
                      Center(
                        child: Text(
                          "Congelando tu extensión",
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
                          "Porfavor espera unos segundos",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: sp(18),
                            fontFamily: "PoppinsBold",
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ] else if (estadoCongelacion == "Cancelada") ...[
                      Center(
                        child: Lottie.asset(
                          "assets/pagoRealizadoAzul.json",
                          repeat: false,
                          height: h(250),
                          width: w(250),
                        ),
                      ),
                      Center(
                        child: Text(
                          "Extensión Congelada",
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
                          textAlign: TextAlign.center,
                          "Tu extensión ha sido congelada exitosamente. Puedes descongelarla cuando quieras.",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: sp(18),
                            fontFamily: "PoppinsBold",
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      SizedBox(height: h(43)),
                      Center(
                        child: GestureDetector(
                          child: Container(
                            height: h(50),
                            width: w(300),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromRGBO(33, 13, 243, 1),
                                  Colors.blue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Center(
                              child: Text(
                                "Entendido",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: sp(17),
                                  fontFamily: "PoppinsBold",
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            Vibration.vibrate(duration: 5);
                            _controllerCancelarTarjeta.reverse();
                            Future.delayed(Duration(milliseconds: 500), () {
                              setState(() {
                                congelarTarjetaVis = false;
                                distorcion = false;
                                razonCongelarSeleccionada = "";
                                estadoCancelacion = "Inicial";
                                estadoCongelacion = "Inicial";
                                estadoDescongelacion = "Inicial";
                              });
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget descongelarTarjetaWidget() {
    final size = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Visibility(
      visible: descongelarTarjetaVis,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w(23),
            vertical: estadoDescongelacion == "Inicial"
                ? h(280)
                : estadoDescongelacion == "Cancelando"
                ? h(300)
                : estadoDescongelacion == "Cancelada"
                ? h(200)
                : h(280),
          ),
          child: SlideTransition(
            position: _slideAnimationCancelarTarjeta,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
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
                border: Border.all(
                  color: estadoDescongelacion != "Cancelada"
                      ? Color.fromRGBO(33, 13, 243, 1)
                      : Color.fromRGBO(33, 13, 243, 1),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: estadoDescongelacion != "Cancelada"
                        ? Color.fromRGBO(33, 13, 243, 1)
                        : Color.fromRGBO(33, 13, 243, 1),
                    blurRadius: 5,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(33),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (estadoDescongelacion == "Inicial") ...[
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(
                                13,
                              ), // sin valores fijos tipo width/height
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.25),
                              ),
                              child: Icon(
                                Icons.ac_unit_rounded,
                                color: Colors.white,
                                size: sp(
                                  25,
                                ), // tamaño auto relativo está permitido
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Text(
                              "Descongelar Tarjeta",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sp(20),
                                fontFamily: "PoppinsBold",
                                decoration: TextDecoration.none,
                              ),
                            ),
                            SizedBox(height: h(10)),
                            Text(
                              "Volve habilitar tu extensión.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: sp(17),
                                fontFamily: "PoppinsBold",
                                decoration: TextDecoration.none,
                              ),
                            ),
                            SizedBox(height: h(53)),
                            SizedBox(
                              width: double.infinity,
                              height: h(50),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromRGBO(
                                    33,
                                    13,
                                    243,
                                    1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                onPressed: () {
                                  Vibration.vibrate(duration: 5);
                                  solicitarBiometria();
                                },
                                child: Text(
                                  "Sí, descongelar extensión",
                                  style: TextStyle(
                                    fontSize: sp(15),
                                    fontFamily: "PoppinsBold",
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: h(13)),
                            SizedBox(
                              width: double.infinity,
                              height: h(50),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromRGBO(
                                    13,
                                    20,
                                    40,
                                    1,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                onPressed: () {
                                  Vibration.vibrate(duration: 5);
                                  _controllerCancelarTarjeta.reverse();
                                  Future.delayed(
                                    Duration(milliseconds: 500),
                                    () {
                                      setState(() {
                                        descongelarTarjetaVis = false;
                                        distorcion = false;
                                      });
                                    },
                                  );
                                },
                                child: Text(
                                  "No, volver atrás",
                                  style: TextStyle(
                                    fontSize: sp(15),
                                    fontFamily: "PoppinsBold",
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (estadoDescongelacion == "Esperando") ...[
                      SizedBox(height: h(53)),
                      Center(
                        child: Icon(
                          LucideIcons.scanFace,
                          color: Color.fromRGBO(33, 13, 243, 1),
                          size: sp(83),
                        ),
                      ),
                      SizedBox(height: h(53)),
                      Center(
                        child: Text(
                          "Verificacion Biometrica",
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
                    ] else if (estadoDescongelacion == "Cancelando") ...[
                      SizedBox(height: h(53)),
                      Center(
                        child: SizedBox(
                          height: h(83),
                          width: w(83),
                          child: CircularProgressIndicator(
                            color: Color.fromRGBO(33, 13, 243, 1),
                            strokeWidth: 1,
                          ),
                        ),
                      ),
                      SizedBox(height: h(53)),
                      Center(
                        child: Text(
                          "Descongelando tu extensión",
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
                          "Porfavor espera unos segundos",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: sp(18),
                            fontFamily: "PoppinsBold",
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ] else if (estadoDescongelacion == "Cancelada") ...[
                      Center(
                        child: Lottie.asset(
                          "assets/pagoRealizadoAzul.json",
                          repeat: false,
                          height: h(250),
                          width: w(250),
                        ),
                      ),
                      Center(
                        child: Text(
                          "Extensión Descongelada",
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
                          textAlign: TextAlign.center,
                          "Tu extensión ha sido descongelada exitosamente. Pueden utilizarla nuevamente.",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: sp(18),
                            fontFamily: "PoppinsBold",
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      SizedBox(height: h(43)),
                      Center(
                        child: GestureDetector(
                          child: Container(
                            height: h(50),
                            width: w(300),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromRGBO(33, 13, 243, 1),
                                  Colors.blue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Center(
                              child: Text(
                                "Entendido",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: sp(17),
                                  fontFamily: "PoppinsBold",
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            Vibration.vibrate(duration: 5);
                            _controllerCancelarTarjeta.reverse();
                            Future.delayed(Duration(milliseconds: 500), () {
                              setState(() {
                                descongelarTarjetaVis = false;
                                distorcion = false;
                                estadoCancelacion = "Inicial";
                                estadoCongelacion = "Inicial";
                                estadoDescongelacion = "Inicial";
                              });
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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

    // 🟩 POSICIONES (5 tarjetas)
    final cards = [
      Offset(0.1, 0.2), // original
      Offset(0.6, 0.1), // original
      Offset(0.1, 0.7), // original
      Offset(0.55, 0.55), // NUEVA 1
      Offset(0.75, 0.35), // NUEVA 2
    ];

    // 🟪 TAMAÑOS (5 tarjetas)
    final cardSizes = [
      Size(83, 50), // original
      Size(110, 60), // original
      Size(110, 65), // original
      Size(95, 58), // NUEVA 1
      Size(70, 45), // NUEVA 2
    ];

    for (int i = 0; i < cards.length; i++) {
      double dyOffset = sin(animationValue * 2 * pi + i) * 10;

      final pos = Offset(
        cards[i].dx * size.width,
        cards[i].dy * size.height + dyOffset,
      );

      // Rotaciones personalizadas
      double angle = 0;
      if (i == 0) angle = 0.1;
      if (i == 2) angle = -0.1;
      if (i == 3) angle = 0.05; // pequeña inclinación
      if (i == 4) angle = -0.07; // inclinación suave

      canvas.save();
      canvas.translate(
        pos.dx + cardSizes[i].width / 2,
        pos.dy + cardSizes[i].height / 2,
      );
      canvas.rotate(angle);

      // ---------------------------------------------------------
      // TARJETA (misma lógica que la tuya, NO toqué nada)
      // ---------------------------------------------------------

      // tarjeta
      paint
        ..color = Color.fromRGBO(35, 65, 75, 1).withOpacity(1)
        ..style = PaintingStyle.fill;
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

      // borde tarjeta
      paint
        ..color = Colors.green.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(cardRRect, paint);

      paint.style = PaintingStyle.fill;

      // chip
      paint.color = Color.fromRGBO(85, 97, 67, 1).withOpacity(0.5);
      double chipWidth = cardSizes[i].width * 0.18;
      double chipHeight = cardSizes[i].height * 0.25;
      Rect chipRect = Rect.fromLTWH(
        -cardSizes[i].width / 2 + cardSizes[i].width * 0.08,
        -cardSizes[i].height / 2 + cardSizes[i].height * 0.12,
        chipWidth,
        chipHeight,
      );
      final chipRRect = RRect.fromRectAndRadius(
        chipRect,
        Radius.circular(cardSizes[i].width * 0.07),
      );
      canvas.drawRRect(chipRRect, paint);

      // borde chip
      paint
        ..color = Colors.yellow.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(chipRRect, paint);

      // restaurar fill
      paint.style = PaintingStyle.fill;

      // lineas
      paint.color = Colors.white.withOpacity(0.3);
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

      // nombre
      paint.color = Colors.grey.withOpacity(0.3);
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
