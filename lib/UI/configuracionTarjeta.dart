// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, unused_element, deprecated_member_use, unnecessary_null_comparison, avoid_print, prefer_interpolation_to_compose_strings, unrelated_type_equality_checks, use_build_context_synchronously

import 'dart:async';

import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/UI/miTarjeta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class configuraciontTarjetaPage extends StatefulWidget {
  final String configuracion;
  final String descripcionconfiguracion;

  const configuraciontTarjetaPage({
    super.key,
    required this.configuracion,
    required this.descripcionconfiguracion,
  });

  @override
  State<configuraciontTarjetaPage> createState() =>
      _configuraciontTarjetaPageState();
}

class _configuraciontTarjetaPageState extends State<configuraciontTarjetaPage>
    with TickerProviderStateMixin {
  //Limite
  //Text Controllers
  final TextEditingController _controllerLimite = TextEditingController();

  String tipoLimite = "Fijo";

  double valorLimite = 0.0;

  bool porcentajeMayor = false;

  //Suscripcion
  StreamSubscription<DocumentSnapshot>? _independienteSub;

  String estadoLimite = "Inicial";
  String estadoEliminarLimite = "Inicial";
  //Fin Limite

  //Umbral
  final TextEditingController _controllerUmbral = TextEditingController();

  String tipoUmbral = "Fijo";

  double valorUmbral = 0.0;

  String estadoUmbral = "Inicial";
  String estadoEliminarUmbral = "Inicial";

  String palabraSeleccionada = "";
  //Fin Ubral

  //Animaciones
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  //Solicitar Biometrica
  final localAuth = LocalAuthentication();

  //Datos Usuario
  String uidUser = "";
  String nameUser = "";
  double saldoUser = 0.0;

  //Datos Tarjeta
  String codeTarjetaUser = "";

  //Configuracion Tarjeta
  //limite
  bool limiteCreado = false;
  double limite = 0.0;
  double limiteUsado = 0.0;
  bool sResetearLimite = false;
  String porcentajeLimite = "";

  //Umbral
  bool umbralCreado = false;
  double umbral = 0.0;
  String porcentajeUmbral = "";
  String accionUmbral = "";

  Future<void> leerShared() async {
    //Datos User
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString('codeUser') == null) {
      uidUser = "";
    } else {
      uidUser = prefs.getString('codeUser')!;
    }
  }

  Future<void> obtenerDatos() async {
    User? user = FirebaseAuth.instance.currentUser;

    await leerShared();

    _independienteSub = FirebaseFirestore.instance
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
                nameUser = data["Nombre"] ?? "";
                uidUser = user?.uid ?? "";
                saldoUser = (data["Saldo"] != null)
                    ? (data["Saldo"] as num).toDouble()
                    : 0.0;
                codeTarjetaUser = data["Tarjeta"] ?? "";
              });

              //Obtener Datos Tarjeta
              obtenerDatosTarjeta(codeTarjetaUser);
            } catch (e, s) {
              print("Error al asignar valores: $e");
              print(s);
            }
          } else {
            print('El documento no existe');
          }
        });
  }

  Future<void> obtenerDatosTarjeta(String codeTarjeta) async {
    _independienteSub = FirebaseFirestore.instance
        .collection('Tarjetas')
        .doc(codeTarjeta)
        .snapshots()
        .listen((docSnapshot) async {
          if (!mounted) return;

          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            //Limite
            setState(() {
              limite = (data["Limite"] != null)
                  ? (data["Limite"] as num).toDouble()
                  : 0.0;
              tipoLimite = data["Tipo Limite"] ?? "Fijo";
              limiteUsado = (data["Limite Usado"] != null)
                  ? (data["Limite Usado"] as num).toDouble()
                  : 0.0;
            });

            if (limite == 0) {
              setState(() {
                limiteCreado = false;
              });
            } else {
              setState(() {
                limiteCreado = true;
              });
            }

            if (tipoLimite == "Fijo") {
              setState(() {
                tipoLimite = "Fijo";
                porcentajeLimite = ((limite / saldoUser) * 100).toStringAsFixed(
                  2,
                );
              });
            } else {
              setState(() {
                tipoLimite = "Porcentual";
                porcentajeLimite = data["Porcentaje Limite"] ?? "";
              });
            }
            //Fin Limite

            //Umbral
            setState(() {
              umbral = (data["Umbral"] != null)
                  ? (data["Umbral"] as num).toDouble()
                  : 0.0;
              tipoUmbral = data["Tipo Umbral"] ?? "Fijo";
              palabraSeleccionada = data["Accion Umbral"] ?? "";
              accionUmbral = data["Accion Umbral"] ?? "";
            });

            if (umbral == 0) {
              setState(() {
                umbralCreado = false;
              });
            } else {
              setState(() {
                umbralCreado = true;
              });
            }

            if (tipoUmbral == "Fijo") {
              setState(() {
                tipoUmbral = "Fijo";
                porcentajeUmbral = ((umbral / saldoUser) * 100).toStringAsFixed(
                  2,
                );
              });
            } else {
              setState(() {
                tipoUmbral = "Porcentual";
                porcentajeUmbral = data["Porcentaje Umbral"] ?? "";
              });
            }
            //Fin Umbral
          }
        });
  }

  //Limite
  Future<void> activarLimite() async {
    FirebaseFirestore.instance
        .collection("Tarjetas")
        .doc(codeTarjetaUser)
        .update({
          "Limite": double.parse(valorLimite.toStringAsFixed(2)),
          "Limite Usado": (sResetearLimite || limiteUsado == 0)
              ? 0
              : limiteUsado,
          "Limite Estado": true,
          "Tipo Limite": tipoLimite,
        });

    if (tipoLimite == "Porcentual") {
      FirebaseFirestore.instance
          .collection("Tarjetas")
          .doc(codeTarjetaUser)
          .update({"Porcentaje Limite": _controllerLimite.text});
    }

    //Crear Notificaicon
    notificacionLimiteActivado();
  }

  Future<void> eliminarLimite() async {
    //Eliminar Limite
    FirebaseFirestore.instance
        .collection("Tarjetas")
        .doc(codeTarjetaUser)
        .update({
          "Limite": FieldValue.delete(),
          "Limite Usado": FieldValue.delete(),
          "Limite Estado": FieldValue.delete(),
          "Tipo Limite": FieldValue.delete(),
          "Porcentaje Limite": FieldValue.delete(),
        });

    //Crear Notificaicon
    notificacionLimiteEliminado();
  }

  Future<void> notificacionLimiteActivado() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    String horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Limite #$uidUser")
        .set({
          "Tipo": limiteCreado == false
              ? "Limite Tarjeta Creado"
              : "Limite Tarjeta Actualizado",
          "Limite": double.parse(valorLimite.toStringAsFixed(2)),
          "Tipo Limite": tipoLimite,
          "Fecha": fecha,
          "Hora": horaActual,
          "FechaTime": Timestamp.fromDate(ahora),
          "Leida": {uidUser: false},
          "Involucra": [uidUser],
        });
  }

  Future<void> notificacionLimiteEliminado() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    String horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Limite #$uidUser")
        .set({
          "Tipo": "Limite Tarjeta Eliminado",
          "Limite": double.parse(valorLimite.toStringAsFixed(2)),
          "Tipo Limite": tipoLimite,
          "Fecha": fecha,
          "Hora": horaActual,
          "FechaTime": Timestamp.fromDate(ahora),
          "Leida": {uidUser: false},
          "Involucra": [uidUser],
        });
  }
  //Fin Limite

  //Umbral
  Future<void> activarUmbral() async {
    FirebaseFirestore.instance
        .collection("Tarjetas")
        .doc(codeTarjetaUser)
        .update({
          "Umbral": valorUmbral == 0
              ? umbral
              : double.parse(valorUmbral.toStringAsFixed(2)),
          "Accion Umbral": palabraSeleccionada,
          "Umbral Estado": true,
          "Tipo Umbral": tipoUmbral,
        });

    if (tipoUmbral == "Porcentual") {
      FirebaseFirestore.instance
          .collection("Tarjetas")
          .doc(codeTarjetaUser)
          .update({"Porcentaje Umbral": _controllerUmbral.text});
    }

    //Crear Notificacion
    notificacionUmbralActivado();
  }

  Future<void> eliminarUmbral() async {
    FirebaseFirestore.instance
        .collection("Tarjetas")
        .doc(codeTarjetaUser)
        .update({
          "Umbral": FieldValue.delete(),
          "Accion Umbral": FieldValue.delete(),
          "Umbral Estado": FieldValue.delete(),
          "Tipo Umbral": FieldValue.delete(),
          "Porcentaje Umbral": FieldValue.delete(),
        });

    //Crear Notificacion
    notificacionUmbralEliminado();
  }

  Future<void> notificacionUmbralActivado() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    String horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Umbral #$uidUser")
        .set({
          "Tipo": umbralCreado == false
              ? "Umbral Tarjeta Creado"
              : "Umbral Tarjeta Actualizado",
          "Umbral": valorUmbral == 0
              ? umbral
              : double.parse(valorUmbral.toStringAsFixed(2)),
          "Tipo Umbral": tipoUmbral,
          "Accion Umbral": palabraSeleccionada,
          "Fecha": fecha,
          "Hora": horaActual,
          "FechaTime": Timestamp.fromDate(ahora),
          "Leida": {uidUser: false},
          "Involucra": [uidUser],
        });
  }

  Future<void> notificacionUmbralEliminado() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    String horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Umbral #$uidUser")
        .set({
          "Tipo": "Umbral Tarjeta Eliminado",
          "Umbral": valorUmbral == 0
              ? umbral
              : double.parse(valorUmbral.toStringAsFixed(2)),
          "Tipo Umbral": tipoUmbral,
          "Accion Umbral": palabraSeleccionada,
          "Fecha": fecha,
          "Hora": horaActual,
          "FechaTime": Timestamp.fromDate(ahora),
          "Leida": {uidUser: false},
          "Involucra": [uidUser],
        });
  }
  //Fin Umbral

  Future<void> solicitarBiometria() async {
    bool canCheck = await localAuth.canCheckBiometrics;
    bool authenticated = false;

    if (!canCheck) {
      print('El dispositivo no soporta biometría');

      Future.delayed(Duration(milliseconds: 800), () {
        //Limite
        if (widget.configuracion == "Limite") {
          if (estadoLimite == "Esperando") {
            setState(() {
              Vibration.vibrate(duration: 5);
              estadoLimite = "Activando";
            });

            Future.delayed(Duration(seconds: 3), () {
              activarLimite();
              setState(() {
                Vibration.vibrate(duration: 15);
                estadoLimite = "Activado";
              });
            });
          }

          //Eliminar Limite Tarjeta
          if (estadoEliminarLimite == "Esperando") {
            setState(() {
              Vibration.vibrate(duration: 5);
              estadoEliminarLimite = "Eliminando";
            });

            Future.delayed(Duration(seconds: 3), () {
              eliminarLimite();
              setState(() {
                Vibration.vibrate(duration: 15);
                estadoEliminarLimite = "Eliminado";
              });
            });
          }
        }

        //Umbral
        if (widget.configuracion == "Umbral") {
          if (estadoUmbral == "Esperando") {
            setState(() {
              Vibration.vibrate(duration: 5);
              estadoUmbral = "Activando";
            });

            Future.delayed(Duration(seconds: 3), () {
              activarUmbral();
              setState(() {
                Vibration.vibrate(duration: 15);
                estadoUmbral = "Activado";
              });
            });
          }

          //Eliminar Umbral Tarjeta
          if (estadoEliminarUmbral == "Esperando") {
            setState(() {
              Vibration.vibrate(duration: 5);
              estadoEliminarUmbral = "Eliminando";
            });

            Future.delayed(Duration(seconds: 3), () {
              eliminarUmbral();
              setState(() {
                Vibration.vibrate(duration: 15);
                estadoEliminarUmbral = "Eliminado";
              });
            });
          }
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
        if (widget.configuracion == "Limite") {
          setState(() {
            estadoLimite = "Inicial";
            estadoEliminarLimite = "Inicial";
          });
        }

        if (widget.configuracion == "Umbral") {
          setState(() {
            estadoUmbral = "Inicial";
            estadoEliminarUmbral = "Inicial";
          });
        }

        return;
      }

      if (e.code == "Canceled") {
        print("El usuario canceló la autenticación");

        if (widget.configuracion == "Limite") {
          setState(() {
            estadoLimite = "Inicial";
            estadoEliminarLimite = "Inicial";
          });
        }

        if (widget.configuracion == "Umbral") {
          setState(() {
            estadoUmbral = "Inicial";
            estadoEliminarUmbral = "Inicial";
          });
        }

        showFlushbarError(
          context,
          "Error en la Autenticación. Intenta nuevamente.",
        );
        return;
      }
    }

    if (authenticated) {
      Future.delayed(Duration(milliseconds: 800), () {
        //Limite
        if (widget.configuracion == "Limite") {
          if (estadoLimite == "Esperando") {
            setState(() {
              Vibration.vibrate(duration: 5);
              estadoLimite = "Activando";
            });

            Future.delayed(Duration(seconds: 3), () {
              activarLimite();
              setState(() {
                Vibration.vibrate(duration: 15);
                estadoLimite = "Activado";
              });
            });
          }

          //Eliminar Limite Tarjeta
          if (estadoEliminarLimite == "Esperando") {
            setState(() {
              Vibration.vibrate(duration: 5);
              estadoEliminarLimite = "Eliminando";
            });

            Future.delayed(Duration(seconds: 3), () {
              eliminarLimite();
              setState(() {
                Vibration.vibrate(duration: 15);
                estadoEliminarLimite = "Eliminado";
              });
            });
          }
        }

        //Umbral
        if (widget.configuracion == "Umbral") {
          if (estadoUmbral == "Esperando") {
            setState(() {
              Vibration.vibrate(duration: 5);
              estadoUmbral = "Activando";
            });

            Future.delayed(Duration(seconds: 3), () {
              activarUmbral();
              setState(() {
                Vibration.vibrate(duration: 15);
                estadoUmbral = "Activado";
              });
            });
          }

          //Eliminar Umbral Tarjeta
          if (estadoEliminarUmbral == "Esperando") {
            setState(() {
              Vibration.vibrate(duration: 5);
              estadoEliminarUmbral = "Eliminando";
            });

            Future.delayed(Duration(seconds: 3), () {
              eliminarUmbral();
              setState(() {
                Vibration.vibrate(duration: 15);
                estadoEliminarUmbral = "Eliminado";
              });
            });
          }
        }
      });
    } else {
      print('Autenticación biométrica fallida');

      if (widget.configuracion == "Limite") {
        setState(() {
          estadoLimite = "Inicial";
          estadoEliminarLimite = "Inicial";
        });
      }

      if (widget.configuracion == "Umbral") {
        setState(() {
          estadoUmbral = "Inicial";
          estadoEliminarUmbral = "Inicial";
        });
      }

      showFlushbarError(
        context,
        "Error en la Autenticación. Intenta nuevamente.",
      );
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
    _iconController.dispose();
    _controllerLimite.dispose();
    _independienteSub?.cancel();
    super.dispose();
  }

  double parseMoneyField(String text) {
    if (text.isEmpty) return 0;

    // Eliminar puntos de miles
    String clean = text.replaceAll('.', '');

    // Reemplazar coma decimal por punto
    clean = clean.replaceAll(',', '.');

    // Convertir a double con tryParse
    return double.tryParse(clean) ?? 0;
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
    double w(double width) => width / 430 * MediaQuery.of(context).size.width;
    double h(double height) =>
        height / 932 * MediaQuery.of(context).size.height;
    double sp(double size) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      return size /
          430 *
          (screenWidth < screenHeight ? screenWidth : screenHeight);
    }

    return GestureDetector(
      child: Container(
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
          resizeToAvoidBottomInset: widget.configuracion == "Limite"
              ? true
              : widget.configuracion == "Umbral"
              ? MediaQuery.of(context).viewInsets.bottom > 0 &&
                        palabraSeleccionada == ""
                    ? false
                    : true
              : true,
          appBar: estadoLimite == "Inicial" || estadoEliminarLimite == "Inicial"
              ? AppBar(
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
                              child: miTarjetaPage(),
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
                                "Configurar ${widget.configuracion}",
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
                                widget.descripcionconfiguracion,
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
                  actions: [
                    //limite
                    if (widget.configuracion == "Limite" &&
                        limiteCreado == true &&
                        estadoLimite == "Inicial") ...[
                      IconButton(
                        color: Colors.white60,
                        icon: Icon(
                          Icons.delete_forever,
                          color: Colors.red.withOpacity(0.8),
                        ),
                        onPressed: () async {
                          Vibration.vibrate(duration: 5);
                          setState(() {
                            estadoEliminarLimite = "Esperando";
                            estadoLimite = "Oculto";
                            solicitarBiometria();
                          });
                        },
                      ),
                    ],

                    //Umbral
                    if (widget.configuracion == "Umbral" &&
                        umbralCreado == true &&
                        estadoUmbral == "Inicial") ...[
                      IconButton(
                        color: Colors.white60,
                        icon: Icon(
                          Icons.delete_forever,
                          color: Colors.red.withOpacity(0.8),
                        ),
                        onPressed: () async {
                          Vibration.vibrate(duration: 5);
                          setState(() {
                            estadoEliminarUmbral = "Esperando";
                            estadoUmbral = "Oculto";
                            solicitarBiometria();
                          });
                        },
                      ),
                    ],
                  ],
                )
              : null,
          body: Stack(
            children: [
              SizedBox(child: configurarLimiteWidget()),
              SizedBox(child: configurarUmbralWidget()),
            ],
          ),
        ),
      ),
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          currentFocus.focusedChild!.unfocus();
        }
      },
    );
  }

  Widget configurarLimiteWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Visibility(
      visible: widget.configuracion == "Limite",
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w(33), vertical: h(23)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              estadoLimite == "Activando" ||
                  estadoEliminarLimite == "Eliminando"
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (estadoLimite == "Inicial" ||
                estadoEliminarLimite == "Inicial") ...[
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: w(350)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Tipo de limite",
                    style: TextStyle(
                      color: Colors.white60,
                      fontFamily: "PoppinsBold",
                      fontSize: sp(17),
                    ),
                  ),
                ),
              ),
              SizedBox(height: h(13)),
              Row(
                children: [
                  // ====================================================
                  //     BOTÓN SELECCIONADO (MARRÓN + NARANJA)
                  // ====================================================
                  Expanded(
                    child: GestureDetector(
                      child: Container(
                        margin: EdgeInsets.only(right: w(13)),
                        padding: EdgeInsets.symmetric(
                          vertical: h(13),
                          horizontal: w(8),
                        ),
                        decoration: BoxDecoration(
                          gradient: tipoLimite == "Porcentual"
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color.fromRGBO(20, 25, 50, 1),
                                    const Color.fromRGBO(20, 25, 50, 1),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ).withOpacity(0.3),
                                    const Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ).withOpacity(0.3),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(w(18)),
                          border: Border.all(
                            color: tipoLimite == "Porcentual"
                                ? Colors.white.withOpacity(0.5)
                                : const Color.fromRGBO(1, 165, 113, 1),
                            width: w(1),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              size: sp(25),
                              color: tipoLimite == "Porcentual"
                                  ? Colors.white.withOpacity(0.65)
                                  : const Color.fromRGBO(1, 165, 113, 1),
                            ),
                            SizedBox(height: h(10)),
                            Text(
                              "Valor Fijo",
                              style: TextStyle(
                                color: tipoLimite == "Porcentual"
                                    ? Colors.white.withOpacity(0.65)
                                    : const Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(15),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        setState(() {
                          tipoLimite = "Fijo";
                          _controllerLimite.clear();
                          valorLimite = 0.0;
                        });
                      },
                    ),
                  ),

                  // ====================================================
                  //     BOTÓN NO SELECCIONADO (AZUL OSCURO)
                  // ====================================================
                  Expanded(
                    child: GestureDetector(
                      child: Container(
                        margin: EdgeInsets.only(left: w(12)),
                        padding: EdgeInsets.symmetric(
                          vertical: h(13),
                          horizontal: w(10),
                        ),
                        decoration: BoxDecoration(
                          gradient: tipoLimite == "Fijo"
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color.fromRGBO(20, 25, 50, 1),
                                    const Color.fromRGBO(20, 25, 50, 1),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ).withOpacity(0.3),
                                    const Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ).withOpacity(0.3),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(w(18)),
                          border: Border.all(
                            color: tipoLimite == "Fijo"
                                ? Colors.white.withOpacity(0.5)
                                : const Color.fromRGBO(1, 165, 113, 1),
                            width: w(1),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.percent,
                              size: sp(25),
                              color: tipoLimite == "Fijo"
                                  ? Colors.white.withOpacity(0.65)
                                  : const Color.fromRGBO(1, 165, 113, 1),
                            ),
                            SizedBox(height: h(10)),
                            Text(
                              "Porcentual",
                              style: TextStyle(
                                color: tipoLimite == "Fijo"
                                    ? Colors.white.withOpacity(0.75)
                                    : const Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(15),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        setState(() {
                          tipoLimite = "Porcentual";
                          _controllerLimite.clear();
                          valorLimite = 0.0;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: h(43)),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: w(350)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tipoLimite == "Fijo"
                        ? "Limite fijo"
                        : "Porcentaje del saldo",
                    style: TextStyle(
                      color: Colors.white60,
                      fontFamily: "PoppinsBold",
                      fontSize: sp(17),
                    ),
                  ),
                ),
              ),
              SizedBox(height: h(13)),
              Container(
                width: w(400),
                height: h(63),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(
                    20,
                    25,
                    50,
                    1,
                  ), // fondo oscuro del TextField
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    // Icono con fondo y borde redondeado
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: w(13)),
                      height: h(35),
                      width: w(35),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(1, 165, 113, 1),
                            Colors.green.shade600,
                          ],
                        ),
                      ),
                      child: Icon(
                        tipoLimite == "Fijo"
                            ? LucideIcons.dollarSign
                            : LucideIcons.percent,
                        color: Colors.white,
                        size: sp(18),
                      ),
                    ),
                    // TextField
                    Expanded(
                      child: TextField(
                        controller: _controllerLimite,
                        textCapitalization: TextCapitalization.words,
                        textAlignVertical:
                            TextAlignVertical.center, // centra verticalmente
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sp(15),
                          fontFamily: "PoppinsBold",
                        ),
                        maxLength: tipoLimite == "Porcentual" ? 3 : 10,
                        cursorColor: Colors.white,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                        inputFormatters: [
                          tipoLimite == "Fijo"
                              ? DynamicMoneyFormatter()
                              : FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: limite == 0
                              ? tipoLimite == "Fijo"
                                    ? "\$0"
                                    : "0%"
                              : tipoLimite == "Fijo"
                              ? "\$" + formatMoney(limite)
                              : "$porcentajeLimite%",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: sp(15),
                            fontFamily: "PoppinsBold",
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical:
                                13, // ⚡ ajustar vertical para centrar con el icono
                          ),
                          suffixIcon: Padding(
                            padding: EdgeInsets.only(
                              right: w(8),
                            ), // pequeño margen
                            child: GestureDetector(
                              onTap: () {
                                _controllerLimite.clear();
                                valorLimite = 0.0;
                                setState(() {});
                              },
                              child: Icon(
                                Icons.close,
                                color: (_controllerLimite.text.isNotEmpty
                                    ? Colors.white
                                    : Colors.transparent),
                                size: sp(18),
                              ),
                            ),
                          ),
                        ),
                        onChanged: (value) async {
                          setState(() {
                            if (value != null) {
                              _controllerLimite.text = value;
                            } else {
                              _controllerLimite.text = "";
                            }

                            if (tipoLimite == "Porcentual") {
                              double porcentaje = parseMoneyField(
                                _controllerLimite.text,
                              );

                              if (porcentaje > 100) {
                                porcentaje = 100;
                                _controllerLimite.text = "100";
                              }

                              valorLimite = (porcentaje / 100) * saldoUser;
                            } else {
                              valorLimite = parseMoneyField(
                                _controllerLimite.text,
                              );
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: h(13)),
              Visibility(
                visible: _controllerLimite.text.isNotEmpty,
                child: valorLimite > 999
                    ? Row(
                        children: [
                          Text(
                            "Podrás gastar hasta ",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "PoppinsBold",
                              fontSize: sp(13),
                            ),
                          ),
                          formattedMoney(valorLimite),
                          Text(
                            "con tu tarjeta.",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "PoppinsBold",
                              fontSize: sp(13),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        "El minimo de los límites  es de \$1.000",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "PoppinsBold",
                          fontSize: sp(13),
                        ),
                      ),
              ),
              if (limiteUsado != 0) ...[
                SizedBox(height: h(13)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.020,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1A27), // fondo oscuro similar
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
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: screenWidth * 0.09,
                            height: screenWidth * 0.09,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.fromRGBO(1, 165, 113, 1),
                                  Color(0xFF00A86B),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.restore,
                                color: Colors.white,
                                size: sp(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título
                            Text(
                              'Empezar de cero',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sp(15),
                                fontFamily: "PoppinsBold",
                                height: h(1),
                              ),
                            ),

                            SizedBox(height: h(5)),

                            // Subtítulo
                            Text(
                              "Hace que los valores no sean acumulativos.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: sp(13),
                                fontFamily: "Poppins",
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: sResetearLimite,
                        onChanged: (value) {
                          Vibration.vibrate(duration: 5);
                          setState(() {
                            sResetearLimite = value;
                          });
                        },
                        activeColor: Colors.white, // color del círculo
                        activeTrackColor: Color.fromRGBO(
                          1,
                          165,
                          113,
                          1,
                        ), // color de la barra cuando está activo
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ],
              Spacer(),
              GestureDetector(
                child: Container(
                  height: h(53),
                  width: w(400),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: valorLimite != 0 && valorLimite > 999
                        ? LinearGradient(
                            colors: [
                              Color.fromRGBO(1, 165, 113, 1),
                              Colors.green.shade600,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : LinearGradient(
                            colors: [Colors.white60, Colors.grey],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        limiteCreado ? "Actualizar Límite" : "Activar Límite",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "PoppinsBold",
                          fontSize: sp(18),
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
                          LucideIcons.check,
                          color: Colors.white,
                          size: sp(20),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  if (valorLimite > 999) {
                    Vibration.vibrate(duration: 5);
                    FocusScopeNode currentFocus = FocusScope.of(context);
                    if (!currentFocus.hasPrimaryFocus &&
                        currentFocus.focusedChild != null) {
                      currentFocus.focusedChild!.unfocus();
                    }
                    setState(() {
                      estadoLimite = "Esperando";
                      estadoEliminarLimite = "Oculto";
                    });

                    solicitarBiometria();
                  } else {
                    Vibration.vibrate(duration: 10);
                    showFlushbarError(context, "Ingresa un limite valido.");
                  }
                },
              ),
              SizedBox(height: h(2)),
            ] else if (estadoLimite == "Esperando" ||
                estadoEliminarLimite == "Esperando") ...[
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
                            color: estadoLimite == "Esperando"
                                ? Color.fromRGBO(1, 165, 113, 1)
                                : estadoEliminarLimite == "Esperando"
                                ? Colors.red
                                : null,
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
                      ],
                    ),
                  ),
                ),
              ),
            ] else if (estadoLimite == "Activando" ||
                estadoEliminarLimite == "Eliminando") ...[
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
                          child: SizedBox(
                            height: h(83),
                            width: w(83),
                            child: CircularProgressIndicator(
                              color: estadoLimite == "Activando"
                                  ? Color.fromRGBO(1, 165, 113, 1)
                                  : estadoEliminarLimite == "Eliminando"
                                  ? Colors.red
                                  : null,
                              strokeWidth: 1,
                            ),
                          ),
                        ),
                        SizedBox(height: h(53)),
                        Center(
                          child: Text(
                            estadoLimite == "Activando"
                                ? "Activando Limite"
                                : estadoEliminarLimite == "Eliminando"
                                ? "Eliminando Limite"
                                : "",
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
                      ],
                    ),
                  ),
                ),
              ),
            ] else if (estadoLimite == "Activado" ||
                estadoEliminarLimite == "Eliminado") ...[
              SizedBox(height: h(83)),
              Center(
                child: Lottie.asset(
                  "assets/pagoRealizadoVerde.json",
                  repeat: false,
                  height: h(150),
                  width: w(150),
                ),
              ),
              Center(
                child: Text(
                  estadoLimite == "Activado"
                      ? "Limite Activado"
                      : estadoEliminarLimite == "Eliminado"
                      ? "Limite Eliminado"
                      : "",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: sp(23),
                    fontFamily: "PoppinsBold",
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              SizedBox(height: h(10)),
              Center(
                child: Text(
                  textAlign: TextAlign.center,
                  estadoLimite == "Activado"
                      ? "Tu nuevo limite de tarjeta fue activado."
                      : estadoEliminarLimite == "Eliminado"
                      ? "El limite de tu tarjeta fue eliminado."
                      : "",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: sp(17),
                    fontFamily: "PoppinsBold",
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              Spacer(),
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
                    Future.delayed(Duration(milliseconds: 500), () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: miTarjetaPage(),
                        ),
                      );
                      Future.delayed(Duration(milliseconds: 500), () {
                        setState(() {
                          estadoLimite = "Inicial";
                          estadoEliminarLimite = "Inicial";
                        });
                      });
                    });
                  },
                ),
              ),
              SizedBox(height: h(43)),
            ],
          ],
        ),
      ),
    );
  }

  Widget configurarUmbralWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Visibility(
      visible: widget.configuracion == "Umbral",
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w(33), vertical: h(23)),
        child: GestureDetector(
          onVerticalDragDown: (_) {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                estadoUmbral == "Activando" ||
                    estadoEliminarUmbral == "Eliminando"
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              if (estadoUmbral == "Inicial" ||
                  estadoEliminarUmbral == "Inicial") ...[
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Tipo de umbral",
                      style: TextStyle(
                        color: Colors.white60,
                        fontFamily: "PoppinsBold",
                        fontSize: sp(17),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h(13)),
                Row(
                  children: [
                    // ====================================================
                    //     BOTÓN SELECCIONADO (MARRÓN + NARANJA)
                    // ====================================================
                    Expanded(
                      child: GestureDetector(
                        child: Container(
                          margin: EdgeInsets.only(right: w(13)),
                          padding: EdgeInsets.symmetric(
                            vertical: h(13),
                            horizontal: w(8),
                          ),
                          decoration: BoxDecoration(
                            gradient: tipoUmbral == "Porcentual"
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color.fromRGBO(20, 25, 50, 1),
                                      const Color.fromRGBO(20, 25, 50, 1),
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.purple.withOpacity(0.3),
                                      Colors.purpleAccent.withOpacity(0.3),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(w(18)),
                            border: Border.all(
                              color: tipoUmbral == "Porcentual"
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.purple,
                              width: w(1),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock,
                                size: sp(25),
                                color: tipoUmbral == "Porcentual"
                                    ? Colors.white.withOpacity(0.65)
                                    : Colors.purple,
                              ),
                              SizedBox(height: h(10)),
                              Text(
                                "Valor Fijo",
                                style: TextStyle(
                                  color: tipoUmbral == "Porcentual"
                                      ? Colors.white.withOpacity(0.65)
                                      : Colors.purple,
                                  fontSize: sp(15),
                                  fontFamily: "PoppinsBold",
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Vibration.vibrate(duration: 5);
                          setState(() {
                            tipoUmbral = "Fijo";
                            _controllerUmbral.clear();
                            valorUmbral = 0.0;
                          });
                        },
                      ),
                    ),

                    // ====================================================
                    //     BOTÓN NO SELECCIONADO (AZUL OSCURO)
                    // ====================================================
                    Expanded(
                      child: GestureDetector(
                        child: Container(
                          margin: EdgeInsets.only(left: w(12)),
                          padding: EdgeInsets.symmetric(
                            vertical: h(13),
                            horizontal: w(10),
                          ),
                          decoration: BoxDecoration(
                            gradient: tipoUmbral == "Fijo"
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color.fromRGBO(20, 25, 50, 1),
                                      const Color.fromRGBO(20, 25, 50, 1),
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.purple.withOpacity(0.3),
                                      Colors.purpleAccent.withOpacity(0.3),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(w(18)),
                            border: Border.all(
                              color: tipoUmbral == "Fijo"
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.purple,
                              width: w(1),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.percent,
                                size: sp(25),
                                color: tipoUmbral == "Fijo"
                                    ? Colors.white.withOpacity(0.65)
                                    : Colors.purple,
                              ),
                              SizedBox(height: h(10)),
                              Text(
                                "Porcentual",
                                style: TextStyle(
                                  color: tipoUmbral == "Fijo"
                                      ? Colors.white.withOpacity(0.75)
                                      : Colors.purple,
                                  fontSize: sp(15),
                                  fontFamily: "PoppinsBold",
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Vibration.vibrate(duration: 5);
                          setState(() {
                            tipoUmbral = "Porcentual";
                            _controllerUmbral.clear();
                            valorUmbral = 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: h(43)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(350)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tipoUmbral == "Fijo"
                          ? "Umbral fijo"
                          : "Porcentaje del saldo",
                      style: TextStyle(
                        color: Colors.white60,
                        fontFamily: "PoppinsBold",
                        fontSize: sp(17),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h(13)),
                Container(
                  width: w(400),
                  height: h(63),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(
                      20,
                      25,
                      50,
                      1,
                    ), // fondo oscuro del TextField
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      // Icono con fondo y borde redondeado
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: w(13)),
                        height: h(35),
                        width: w(35),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.purpleAccent],
                          ),
                        ),
                        child: Icon(
                          tipoUmbral == "Fijo"
                              ? LucideIcons.dollarSign
                              : LucideIcons.percent,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      // TextField
                      Expanded(
                        child: TextField(
                          controller: _controllerUmbral,
                          textCapitalization: TextCapitalization.words,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sp(15),
                            fontFamily: "PoppinsBold",
                          ),
                          maxLength: tipoUmbral == "Porcentual" ? 3 : 10,
                          cursorColor: Colors.white,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: false,
                          ),
                          inputFormatters: [
                            tipoUmbral == "Fijo"
                                ? DynamicMoneyFormatter()
                                : FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: umbral == 0
                                ? tipoUmbral == "Fijo"
                                      ? "\$0"
                                      : "0%"
                                : tipoUmbral == "Fijo"
                                ? "\$" + formatMoney(umbral)
                                : "$porcentajeUmbral%",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical:
                                  13, // ⚡ ajustar vertical para centrar con el icono
                            ),
                            suffixIcon: Padding(
                              padding: EdgeInsets.only(
                                right: w(8),
                              ), // pequeño margen
                              child: GestureDetector(
                                onTap: () {
                                  _controllerUmbral.clear();
                                  valorUmbral = 0.0;
                                  setState(() {});
                                },
                                child: Icon(
                                  Icons.close,
                                  color: (_controllerUmbral.text.isNotEmpty
                                      ? Colors.white
                                      : Colors.transparent),
                                  size: sp(18),
                                ),
                              ),
                            ),
                          ),
                          onChanged: (value) async {
                            setState(() {
                              if (value != null) {
                                _controllerUmbral.text = value;
                              } else {
                                _controllerUmbral.text = "";
                              }

                              if (tipoUmbral == "Porcentual") {
                                double porcentaje = parseMoneyField(
                                  _controllerUmbral.text,
                                );

                                if (porcentaje > 100) {
                                  porcentaje = 100;
                                  _controllerUmbral.text = "100";
                                }

                                valorUmbral = (porcentaje / 100) * saldoUser;
                              } else {
                                valorUmbral = parseMoneyField(
                                  _controllerUmbral.text,
                                );
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h(13)),
                Visibility(
                  visible: _controllerUmbral.text.isNotEmpty,
                  child: valorUmbral >= 500
                      ? Row(
                          children: [
                            Text(
                              "El umbral seguro de tu tarjeta es ",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "PoppinsBold",
                                fontSize: sp(13),
                              ),
                            ),
                            formattedMoney(valorUmbral),
                            Text(
                              ".",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "PoppinsBold",
                                fontSize: sp(13),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "El minimo del Umbral es de \$500",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "PoppinsBold",
                            fontSize: sp(13),
                          ),
                        ),
                ),
                Visibility(
                  visible:
                      palabraSeleccionada != "" &&
                          MediaQuery.of(context).viewInsets.bottom > 0
                      ? false
                      : true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: h(33)),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(350)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Acción al bajar del umbral",
                            style: TextStyle(
                              color: Colors.white60,
                              fontFamily: "PoppinsBold",
                              fontSize: sp(17),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h(13)),
                      GestureDetector(
                        child: Container(
                          height: h(93),
                          width: w(400),
                          decoration: BoxDecoration(
                            gradient: (palabraSeleccionada == "Rechazar"
                                ? LinearGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.3),
                                      Colors.red.shade600.withOpacity(0.3),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null),
                            color: (palabraSeleccionada != "Rechazar"
                                ? const Color.fromRGBO(20, 25, 50, 1)
                                : null), // Fondo oscuro solo cuando NO está seleccionado
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (palabraSeleccionada == "Rechazar"
                                  ? Colors.red
                                  : Colors.white60),
                              width: (palabraSeleccionada == "Rechazar"
                                  ? 0.3
                                  : 0.1),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: w(33),
                                height: h(33),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red, Colors.red.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Icon(
                                    LucideIcons.x,
                                    color: Colors.white,
                                    size: sp(20),
                                  ),
                                ),
                              ),
                              SizedBox(width: w(18)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(300),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Rechazar Pago",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "PoppinsBold",
                                            fontSize: sp(17),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(300),
                                      ),
                                      child: Text(
                                        "Cancelar Automaticamente.",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontFamily: "Poppins",
                                          fontSize: sp(15),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: "Rechazar",
                                groupValue: palabraSeleccionada,
                                onChanged: (value) {
                                  setState(() {
                                    palabraSeleccionada = value!;
                                  });
                                },
                                activeColor: Colors.red,
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Vibration.vibrate(duration: 15);
                          setState(() {
                            palabraSeleccionada = "Rechazar";
                          });
                        },
                      ),
                      SizedBox(height: h(23)),
                      GestureDetector(
                        child: Container(
                          height: h(93),
                          width: w(400),
                          decoration: BoxDecoration(
                            gradient: (palabraSeleccionada == "Avisar"
                                ? LinearGradient(
                                    colors: [
                                      Colors.blue.withOpacity(0.3),
                                      Colors.blue.shade600.withOpacity(0.3),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null),
                            color: (palabraSeleccionada != "Avisar"
                                ? const Color.fromRGBO(20, 25, 50, 1)
                                : null), // Fondo oscuro solo cuando NO está seleccionado
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (palabraSeleccionada == "Avisar"
                                  ? Colors.blue
                                  : Colors.white60),
                              width: (palabraSeleccionada == "Avisar"
                                  ? 0.3
                                  : 0.1),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: w(33),
                                height: h(33),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue, Colors.blue.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Icon(
                                    LucideIcons.bell,
                                    color: Colors.white,
                                    size: sp(20),
                                  ),
                                ),
                              ),
                              SizedBox(width: w(18)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(300),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Solo avisar",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "PoppinsBold",
                                            fontSize: sp(17),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(300),
                                      ),
                                      child: Text(
                                        "Avisar sin bloquear el pago.",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontFamily: "Poppins",
                                          fontSize: sp(15),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: "Avisar",
                                groupValue: palabraSeleccionada,
                                onChanged: (value) {
                                  setState(() {
                                    palabraSeleccionada = value!;
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Vibration.vibrate(duration: 15);
                          setState(() {
                            palabraSeleccionada = "Avisar";
                          });
                        },
                      ),
                      SizedBox(height: h(23)),
                      GestureDetector(
                        child: Container(
                          height: h(93),
                          width: w(400),
                          decoration: BoxDecoration(
                            gradient: (palabraSeleccionada == "Verificar"
                                ? LinearGradient(
                                    colors: [
                                      Colors.green.withOpacity(0.3),
                                      Colors.green.shade600.withOpacity(0.3),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null),
                            color: (palabraSeleccionada != "Verificar"
                                ? const Color.fromRGBO(20, 25, 50, 1)
                                : null), // Fondo oscuro solo cuando NO está seleccionado
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (palabraSeleccionada == "Verificar"
                                  ? Colors.green
                                  : Colors.white60),
                              width: (palabraSeleccionada == "Verificar"
                                  ? 0.3
                                  : 0.1),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: w(33),
                                height: h(33),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green,
                                      Colors.green.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.security,
                                    color: Colors.white,
                                    size: sp(20),
                                  ),
                                ),
                              ),
                              SizedBox(width: w(18)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(300),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Solicitar verificacion",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "PoppinsBold",
                                            fontSize: sp(17),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(300),
                                      ),
                                      child: Text(
                                        "Verificacion extra.",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontFamily: "Poppins",
                                          fontSize: sp(15),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: "Verificar",
                                groupValue: palabraSeleccionada,
                                onChanged: (value) {
                                  setState(() {
                                    palabraSeleccionada = value!;
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Vibration.vibrate(duration: 15);
                          setState(() {
                            palabraSeleccionada = "Verificar";
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Spacer(),
                GestureDetector(
                  child: Container(
                    height: h(53),
                    width: w(400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: !umbralCreado
                          ? valorUmbral != 0 &&
                                    valorUmbral >= 500 &&
                                    palabraSeleccionada != ""
                                ? LinearGradient(
                                    colors: [
                                      Colors.purple,
                                      Colors.purpleAccent,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : LinearGradient(
                                    colors: [Colors.white60, Colors.grey],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                          : palabraSeleccionada != accionUmbral ||
                                valorUmbral >= 500 && valorUmbral != umbral
                          ? LinearGradient(
                              colors: [Colors.purple, Colors.purpleAccent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : LinearGradient(
                              colors: [Colors.white60, Colors.grey],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          umbralCreado ? "Actualizar Umbral" : "Activar Umbral",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "PoppinsBold",
                            fontSize: sp(18),
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
                            LucideIcons.check,
                            color: Colors.white,
                            size: sp(20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    if (umbralCreado == false) {
                      if (valorUmbral >= 500 && palabraSeleccionada != "") {
                        Vibration.vibrate(duration: 5);

                        FocusScopeNode currentFocus = FocusScope.of(context);
                        if (!currentFocus.hasPrimaryFocus &&
                            currentFocus.focusedChild != null) {
                          currentFocus.focusedChild!.unfocus();
                        }
                        setState(() {
                          estadoUmbral = "Esperando";
                          estadoEliminarUmbral = "Oculto";
                        });

                        solicitarBiometria();
                      } else {
                        Vibration.vibrate(duration: 10);
                        if (palabraSeleccionada == "") {
                          showFlushbarError(context, "Selecciona una accion.");
                        }
                        if (valorUmbral < 500) {
                          showFlushbarError(
                            context,
                            "Ingresa un umbral valido.",
                          );
                        }
                      }
                    } else {
                      if (palabraSeleccionada != "" || valorUmbral >= 500) {
                        Vibration.vibrate(duration: 5);

                        FocusScopeNode currentFocus = FocusScope.of(context);
                        if (!currentFocus.hasPrimaryFocus &&
                            currentFocus.focusedChild != null) {
                          currentFocus.focusedChild!.unfocus();
                        }

                        setState(() {
                          estadoUmbral = "Esperando";
                          estadoEliminarUmbral = "Oculto";
                        });

                        solicitarBiometria();
                      }
                    }
                  },
                ),
                SizedBox(height: h(2)),
              ] else if (estadoUmbral == "Esperando" ||
                  estadoEliminarUmbral == "Esperando") ...[
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
                              color: estadoUmbral == "Esperando"
                                  ? Color.fromRGBO(1, 165, 113, 1)
                                  : estadoEliminarUmbral == "Esperando"
                                  ? Colors.red
                                  : null,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ] else if (estadoUmbral == "Activando" ||
                  estadoEliminarUmbral == "Eliminando") ...[
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
                            child: SizedBox(
                              height: h(83),
                              width: w(83),
                              child: CircularProgressIndicator(
                                color: estadoUmbral == "Activando"
                                    ? Color.fromRGBO(1, 165, 113, 1)
                                    : estadoEliminarUmbral == "Eliminando"
                                    ? Colors.red
                                    : null,
                                strokeWidth: 1,
                              ),
                            ),
                          ),
                          SizedBox(height: h(53)),
                          Center(
                            child: Text(
                              estadoUmbral == "Activando"
                                  ? umbralCreado
                                        ? "Actualizando Umbral"
                                        : "Activando Umbral"
                                  : estadoEliminarUmbral == "Eliminando"
                                  ? "Eliminando Umbral"
                                  : "",
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
                        ],
                      ),
                    ),
                  ),
                ),
              ] else if (estadoUmbral == "Activado" ||
                  estadoEliminarUmbral == "Eliminado") ...[
                SizedBox(height: h(83)),
                Center(
                  child: Lottie.asset(
                    "assets/pagoRealizadoVerde.json",
                    repeat: false,
                    height: h(150),
                    width: w(150),
                  ),
                ),
                Center(
                  child: Text(
                    estadoUmbral == "Activado"
                        ? "Umbral Activado"
                        : estadoEliminarUmbral == "Eliminado"
                        ? "Umbral Eliminado"
                        : "",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sp(23),
                      fontFamily: "PoppinsBold",
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                SizedBox(height: h(10)),
                Center(
                  child: Text(
                    textAlign: TextAlign.center,
                    estadoUmbral == "Activado"
                        ? "Tu nuevo umbral de gasto fue activado."
                        : estadoEliminarUmbral == "Eliminado"
                        ? "El umbral de tu tarjeta fue eliminado."
                        : "",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: sp(17),
                      fontFamily: "PoppinsBold",
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Spacer(),
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
                      Future.delayed(Duration(milliseconds: 500), () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: miTarjetaPage(),
                          ),
                        );
                        Future.delayed(Duration(milliseconds: 500), () {
                          setState(() {
                            estadoUmbral = "Inicial";
                            estadoEliminarUmbral = "Inicial";
                          });
                        });
                      });
                    },
                  ),
                ),
                SizedBox(height: h(43)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget formattedMoney(double amount) {
    final showDecimals = amount % 1 != 0;
    String formatted = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '',
      decimalDigits: showDecimals ? 2 : 0,
    ).format(amount);

    List<String> parts = formatted.split(',');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? "," + parts[1] : '';

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "\$" + integerPart,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: "PoppinsBold",
              fontSize: 10,
            ),
          ),
          if (decimalPart.isNotEmpty)
            WidgetSpan(
              child: Text(
                decimalPart,
                style: const TextStyle(
                  color: Colors.white60,
                  fontFamily: "PoppinsBold",
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DynamicMoneyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Permitir coma sin eliminarla
    bool hasComma = text.contains(',');

    // Si no hay coma → solo miles
    if (!hasComma) {
      String digits = text.replaceAll('.', '').replaceAll(',', '');
      if (digits.isEmpty) return newValue;

      final number = int.parse(digits);
      final formatted = NumberFormat('#,###', 'es_AR').format(number);

      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // Si hay coma → separar entero y decimal según tecleado
    List<String> parts = text.split(',');
    String integers = parts[0].replaceAll('.', '');
    String decimals = parts.length > 1 ? parts[1] : '';

    // limitar a 2 decimales
    if (decimals.length > 2) decimals = decimals.substring(0, 2);

    // formateo miles
    final formattedInt = NumberFormat(
      '#,###',
      'es_AR',
    ).format(int.tryParse(integers) ?? 0);

    String newText = formattedInt + ',' + decimals;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
