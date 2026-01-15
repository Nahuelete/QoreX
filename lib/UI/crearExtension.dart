// ignore_for_file: file_names, use_key_in_widget_constructors, camel_case_types, avoid_unnecessary_containers, unnecessary_null_comparison, deprecated_member_use, unused_local_variable, unrelated_type_equality_checks, prefer_interpolation_to_compose_strings, avoid_print, unused_element, use_build_context_synchronously, prefer_adjacent_string_concatenation, unnecessary_string_interpolations, override_on_non_overriding_member

import 'dart:async';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/UI/miTarjeta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class crearExtensionPage extends StatefulWidget {
  @override
  State<crearExtensionPage> createState() => _crearExtensionPageState();
}

class _crearExtensionPageState extends State<crearExtensionPage>
    with TickerProviderStateMixin {
  //Text Controller
  final TextEditingController _controllerNombreExtension =
      TextEditingController();
  final TextEditingController _controllerUsuarioExtension =
      TextEditingController();
  final TextEditingController _controllerMontoMaximo = TextEditingController();
  final TextEditingController _controllerNombreUsuario =
      TextEditingController();
  final TextEditingController _controllerDniUsuario = TextEditingController();
  TextEditingController _controllerDireccionUsuario = TextEditingController();
  final TextEditingController _controllerCodigoPostalUsuario =
      TextEditingController();

  //Scroll Controller
  final ScrollController _scrollController = ScrollController();

  //Direccion
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

  //Animaciones
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  //Suscripcion
  StreamSubscription? _extSub;

  //Tipo Entrega
  String tipoExtension = "Virtual";

  //Datos Usuario
  bool usuarioEncontrado = false;

  //Limite Gasto
  String limiteGasto = "Monto fijo";

  //Fecha Expiracion
  String fechaExpiracion = "Original";

  //Opciones adicionales
  bool sVerificacionAdicional = false;

  //Estados
  String estadoBuscando = "Inicial";

  //Solicitar Biometrica
  final localAuth = LocalAuthentication();

  bool creandoExtensionVis = false;
  String estadoCreacion = "Inicial";

  //Distorcion
  bool distorcion = false;

  //Datos Usuario Local
  String uidUser = "";
  String nameUser = "";
  String avatarUser = "";
  String dniUser = "";
  String apellidoUser = "";

  //Datos TarjetaUsuario Local
  String codeTarjetaUser = "";
  String numeroTarjetaOcultaUser = "";
  String numeroTarjetaUser = "";
  String vencimientoTarjetaUser = "";
  String cvvTarjetaUser = "";

  //Datos Usuario Externo
  String uidUserExterno = "";
  String nameUserExterno = "";
  String avatarUserExterno = "";
  String dniUserExterno = "";
  String apellidoUserExterno = "";

  //Elegir Fecha
  DateTime? selectedDate;
  void showCupertinoPicker(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    DateTime tempDate =
        selectedDate ??
        DateTime.now(); // 👉 variable temporal para mostrar en el header

    int year = DateTime.now().year;

    DateTime parseExpiration(String exp) {
      final parts = exp.split("/");
      final month = int.parse(parts[0]);
      final year = 2000 + int.parse(parts[1]); // “29” -> 2029

      // Último día del mes
      return DateTime(year, month + 1, 0);
    }

    final minDate = DateTime.now();
    final maxDate = parseExpiration(vencimientoTarjetaUser);

    // asegurar que initial está dentro del rango
    final initial = minDate.isAfter(maxDate) ? maxDate : minDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: h(360),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 20, 25, 50),
                    Color.fromARGB(255, 20, 25, 50),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border.all(
                  color: Color.fromRGBO(200, 90, 0, 1),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  // ==============================
                  //  FECHA SELECCIONADA EN VIVO
                  // ==============================
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: h(60),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(200, 90, 0, 1),
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Text(
                        selectedDate == null
                            ? "Elegir Fecha"
                            : "Elegir ${selectedDate!.month < 10 ? "0" + selectedDate!.month.toString() : selectedDate!.month}/${tempDate.year.toString().substring(2)}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sp(18),
                          fontFamily: "PoppinsBold",
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: const Color.fromRGBO(200, 90, 0, 1),
                            fontSize: sp(20),
                            fontFamily: 'PoppinsBold',
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        initialDateTime: initial,
                        minimumDate: minDate,
                        maximumDate: maxDate,
                        mode: CupertinoDatePickerMode.monthYear,
                        onDateTimeChanged: (date) {
                          // 👉 se actualiza en tiempo real dentro del modal
                          setModalState(() => tempDate = date);

                          // 👉 se actualiza afuera del modal (tu variable real)
                          setState(() => selectedDate = date);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> leerShared() async {
    //Datos User
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString('codeUser') == null) {
      uidUser = "";
    } else {
      uidUser = prefs.getString('codeUser')!;
    }

    //Tarjeta User
    final prefsTarjeta = await SharedPreferences.getInstance();

    if (prefsTarjeta.getString('tarjetaUser') == null) {
      numeroTarjetaUser = "";
    } else {
      numeroTarjetaUser = prefsTarjeta.getString('tarjetaUser')!;
    }
  }

  Future<void> obtenerDatos() async {
    await leerShared();

    FirebaseFirestore.instance
        .collection("Usuarios")
        .doc(uidUser)
        .snapshots()
        .listen((docSnapshot) {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              nameUser = data["Nombre"] ?? "";
              apellidoUser = data["Apellido"] ?? "";
              dniUser = data["Dni"] ?? "";
              avatarUser = data["Avatar"] ?? "";
              codeTarjetaUser = data["Tarjeta"] ?? "";
            });

            obtenerDatosTarjeta();
          } else {
            print("Error al obtener los datos del usuario.");
          }
        });
  }

  Future<void> obtenerDatosTarjeta() async {
    FirebaseFirestore.instance
        .collection("Tarjetas")
        .doc(codeTarjetaUser)
        .snapshots()
        .listen((docSnapshot) {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              numeroTarjetaOcultaUser = data["NumeroTarjeta"] ?? "";
              vencimientoTarjetaUser = data["Vencimiento"] ?? "";
              cvvTarjetaUser = data["CVV"] ?? "";
            });
          } else {
            print("Error al obtener los datos de la tarjeta.");
          }
        });
  }

  //Digital
  Future<void> buscarUsuario() async {
    setState(() {
      estadoBuscando = "Buscando";
    });
    FirebaseFirestore.instance
        .collection("BusquedaUsers")
        .doc(_controllerUsuarioExtension.text)
        .snapshots()
        .listen((docSnapshot) {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              uidUserExterno = data["Uid"] ?? "";
            });

            if (uidUserExterno == uidUser) {
              Future.delayed(Duration(milliseconds: 1800), () {
                showFlushbarError(
                  context,
                  "No podes otorgarte una extension a vos mismo.",
                );
                setState(() {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    estadoBuscando = "Inicial";
                  });
                });
              });
            } else {
              Vibration.vibrate(duration: 5);
              obtenerDatosExterno();
            }
          } else {
            print("Error al obtener los datos del usuario.");
            Future.delayed(Duration(milliseconds: 1800), () {
              showFlushbarError(context, "Usuario no encontrado.");
              Vibration.vibrate(duration: 15);
              setState(() {
                estadoBuscando = "Inicial";
              });
            });
          }
        });
  }

  Future<void> obtenerDatosExterno() async {
    await leerShared();

    FirebaseFirestore.instance
        .collection("Usuarios")
        .doc(uidUserExterno)
        .snapshots()
        .listen((docSnapshot) {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              nameUserExterno = data["Nombre"] ?? "";
              apellidoUserExterno = data["Apellido"] ?? "";
              avatarUserExterno = data["Avatar"] ?? "";
              dniUserExterno = data["Dni"] ?? "";
            });

            Future.delayed(Duration(milliseconds: 1800), () {
              Vibration.vibrate(duration: 5);
              setState(() {
                estadoBuscando = "Inicial";
                usuarioEncontrado = true;
              });
            });
          } else {
            print("Error al obtener los datos del usuario.");
            Future.delayed(Duration(milliseconds: 1800), () {
              showFlushbarError(
                context,
                "Error al obtener los datos. Intenta mas tarde.",
              );
              Vibration.vibrate(duration: 15);
              setState(() {
                estadoBuscando = "Inicial";
              });
            });
          }
        });
  }

  Future<void> verificarExistenciaExtension() async {
    _extSub = FirebaseFirestore.instance
        .collection("Extensiones")
        .doc("Extension ${_controllerNombreExtension.text}")
        .snapshots()
        .listen((docSnapshot) {
          if (docSnapshot.exists) {
            showFlushbarError(
              context,
              "Ya existe una extencion con este nombre. Porfavor cambialo.",
            );
          } else {
            verificarCantidadExtensiones();
            _extSub?.cancel();
          }
        });
  }

  Future<void> verificarCantidadExtensiones() async {
    FirebaseFirestore.instance
        .collection('Extensiones')
        .where("Para", isEqualTo: uidUserExterno)
        //.where('Involucra', arrayContains: uidUser)
        .get()
        .then((snapshot) {
          int cantidadExtensionesRecibidas = snapshot.docs.length;

          if (cantidadExtensionesRecibidas < 3) {
            solicitarBiometria();
          } else {
            showFlushbarError(
              context,
              "El usuario seleccionado tiene el máximo de extensiones asociadas.",
            );
          }
        })
        .catchError((error) {
          print("Error al obtener extensiones: $error");
          showFlushbarError(
            context,
            "Error al verificar las extensiones. Intenta nuevamente.",
          );
        });
  }

  Future<void> crearExtension() async {
    FirebaseFirestore.instance
        .collection("Extensiones")
        .doc("Extension ${_controllerNombreExtension.text}")
        .set({
          "NombreExtension": _controllerNombreExtension.text,
          "NumeroTarjeta": numeroTarjetaUser,
          "CVV": cvvTarjetaUser,
          "Originario": uidUser,
          "Involucra": {uidUser, uidUserExterno},
          "De": uidUser,
          "Para": uidUserExterno,
          "Avatar": avatarUserExterno,
          "De Nombre": nameUser + " " + apellidoUser,
          "Para Nombre": nameUserExterno + " " + apellidoUserExterno,
          "Codigo": codeTarjetaUser,
          "Nombre": nameUserExterno + " " + apellidoUserExterno,
          "Estado": "Habilitada",
          "Alta": DateTime.now(),
          "Verificacion": sVerificacionAdicional,
          "Tipo": tipoExtension,
        });

    if (limiteGasto == "Monto fijo") {
      double limite =
          double.tryParse(
            _controllerMontoMaximo.text
                .replaceAll(".", "")
                .replaceAll(",", "."),
          ) ??
          0.0;
      FirebaseFirestore.instance
          .collection("Extensiones")
          .doc("Extension ${_controllerNombreExtension.text}")
          .update({
            "Limite": limite,
            "Limite Usado": 0,
            "Limite Estado": true,
            "Tipo Limite": "Fijo",
          });
    }

    if (fechaExpiracion == "Original") {
      FirebaseFirestore.instance
          .collection("Extensiones")
          .doc("Extension ${_controllerNombreExtension.text}")
          .update({"Vencimiento": vencimientoTarjetaUser});
    } else {
      FirebaseFirestore.instance
          .collection("Extensiones")
          .doc("Extension ${_controllerNombreExtension.text}")
          .update({
            "Vencimiento":
                "${selectedDate!.month < 10 ? "0" + selectedDate!.month.toString() : selectedDate!.month}/${selectedDate!.year.toString().substring(2)}",
          });
    }

    //Enviar Notificacion Originario Digital
    crearNotificacionOriginarioDigital();

    //Enviar Notificacion Receptor Digital
    crearNotificacionReceptorDigital();

    //Fisica
    if (tipoExtension == "Fisica") {
      crearSolicitudTarjetaFisica();
    }
  }

  Future<void> crearNotificacionOriginarioDigital() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc(
          "Notificacion Extension ${_controllerNombreExtension.text} Creada #$uidUser",
        )
        .set({
          "Avatar": avatarUserExterno,
          "De": nameUser + " " + apellidoUser,
          "De uid": uidUser,
          "De Dni": dniUser,
          "Para": nameUserExterno + " " + apellidoUserExterno,
          "Para uid": uidUserExterno,
          "Para Dni": dniUserExterno,
          "NombreExtension": _controllerNombreExtension.text,
          "Limite": limiteGasto == "Monto fijo"
              ? _controllerMontoMaximo.text
                    .replaceAll(".", "")
                    .replaceAll(",", ".")
              : "Sin Limite",
          "Vencimiento": fechaExpiracion == "Original"
              ? vencimientoTarjetaUser
              : "${selectedDate!.month < 10 ? "0" + selectedDate!.month.toString() : selectedDate!.month}/${selectedDate!.year.toString().substring(2)}",
          "Verificacion": sVerificacionAdicional,
          "Tipo Extension": tipoExtension,
          "FechaTime": DateTime.now(),
          "Fecha": fecha,
          "Hora": horaActual,
          "Involucra": [uidUser],
          "Leida": {uidUser: false},
          "Tipo": "Extension Creada",
        });
  }

  Future<void> crearNotificacionReceptorDigital() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc(
          "Notificacion Extension ${_controllerNombreExtension.text} Recibida #$uidUserExterno",
        )
        .set({
          "Avatar": avatarUser,
          "De": nameUser + " " + apellidoUser,
          "De uid": uidUser,
          "De Dni": dniUser,
          "Para": nameUserExterno + " " + apellidoUserExterno,
          "Para uid": uidUserExterno,
          "Para Dni": dniUserExterno,
          "NombreExtension": _controllerNombreExtension.text,
          "Limite": limiteGasto == "Monto fijo"
              ? _controllerMontoMaximo.text
                    .replaceAll(".", "")
                    .replaceAll(",", ".")
              : "Sin Limite",
          "Vencimiento": fechaExpiracion == "Original"
              ? vencimientoTarjetaUser
              : "${selectedDate!.month < 10 ? "0" + selectedDate!.month.toString() : selectedDate!.month}/${selectedDate!.year.toString().substring(2)}",
          "Verificacion": sVerificacionAdicional,
          "Tipo Extension": tipoExtension,
          "FechaTime": DateTime.now(),
          "Fecha": fecha,
          "Hora": horaActual,
          "Involucra": [uidUserExterno],
          "Leida": {uidUserExterno: false},
          "Tipo": "Extension Recibida",
        });
  }

  //Fisica
  Future<void> crearSolicitudTarjetaFisica() async {
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

    FirebaseFirestore.instance
        .collection("SolicitudesTarjetas")
        .doc("Solicitud $uidUser")
        .set({
          "User ID": uidUser,
          "Tipo": "Extension",
          "Estado": "Solicitada",
          "Fecha Solicitud": fecha,
          "Entrega Estimada":
              "$fechaEstimada7 - $fechaEstimada10 de $mesFechaEstimada",
          "Direccion":
              "${_controllerDireccionUsuario.text}, ${ciudadSeleccionada!}, ${provinciaSeleccionada!}",
          "Nombre": _controllerNombreUsuario.text,
          "Dni": _controllerDniUsuario.text,
        });
  }

  Future<void> solicitarBiometria() async {
    bool canCheck = await localAuth.canCheckBiometrics;
    bool authenticated = false;

    setState(() {
      creandoExtensionVis = true;
      estadoCreacion = "Esperando";
      distorcion = true;
    });

    if (!canCheck) {
      print('El dispositivo no soporta biometría');

      //Cancelar Tarjeta
      Future.delayed(Duration(milliseconds: 800), () {
        //Cancelar Tarjeta
        if (creandoExtensionVis == true) {
          setState(() {
            Vibration.vibrate(duration: 5);
            estadoCreacion = "Creando";
          });

          Future.delayed(Duration(seconds: 3), () {
            crearExtension();
            setState(() {
              Vibration.vibrate(duration: 15);
              estadoCreacion = "Creada";
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
          estadoCreacion = "Inicial";
          creandoExtensionVis = false;
          distorcion = false;
        });
        return;
      }

      if (e.code == "Canceled") {
        print("El usuario canceló la autenticación");
        setState(() {
          estadoCreacion = "Inicial";
          creandoExtensionVis = false;
          distorcion = false;
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
        if (creandoExtensionVis == true) {
          setState(() {
            Vibration.vibrate(duration: 5);
            estadoCreacion = "Creando";
          });

          Future.delayed(Duration(seconds: 3), () {
            crearExtension();
            setState(() {
              Vibration.vibrate(duration: 15);
              estadoCreacion = "Creada";
            });
          });
        }
      });
    } else {
      print('Autenticación biométrica fallida');
      setState(() {
        estadoCreacion = "Inicial";
        creandoExtensionVis = false;
        distorcion = false;
      });
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
    leerShared();

    obtenerDatos();

    _scrollController.addListener(() {
      if (_scrollController.position.isScrollingNotifier.value) {
        FocusScope.of(context).unfocus();
      }
    });

    _controllerDireccionUsuario = TextEditingController();

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
    _extSub?.cancel();
    super.dispose();
  }

  String normalizarMonto(String input) {
    // Si tiene coma, eliminar ceros finales
    if (input.contains(',')) {
      return input.replaceAll(RegExp(r'0+$'), '');
    }
    return input;
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
        GestureDetector(
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
                        Navigator.pop(context);
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
                              "Crear Extensión",
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
                              "Tarjeta virtual con límites personalizados",
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
              body: Stack(children: [SizedBox(child: crearExtensionWidget())]),
            ),
          ),
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              currentFocus.focusedChild!.unfocus();
            }
          },
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
        creandoExtensionWidget(),
      ],
    );
  }

  Widget crearExtensionWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w(23), vertical: h(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: h(20)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w(350)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Nombre de la extensión",
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
                          Color.fromRGBO(200, 90, 0, 1),
                          Colors.orange.shade600,
                        ],
                      ),
                    ),
                    child: Icon(
                      LucideIcons.tag,
                      color: Colors.white,
                      size: sp(18),
                    ),
                  ),
                  // TextField
                  Expanded(
                    child: TextField(
                      controller: _controllerNombreExtension,
                      textCapitalization: TextCapitalization.words,
                      textAlignVertical:
                          TextAlignVertical.center, // centra verticalmente
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sp(15),
                        fontFamily: "PoppinsBold",
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: "Ej: Extension para Pedro...",
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
                              _controllerNombreExtension.clear();
                              setState(
                                () {},
                              ); // refresca la visibilidad del icono
                            },
                            child: Icon(
                              Icons.close,
                              color: (_controllerNombreExtension.text.isNotEmpty
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
                            _controllerNombreExtension.text = value;
                          } else {
                            _controllerNombreExtension.text = "";
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: h(43)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w(350)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Tipo de extensión",
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
                        gradient: tipoExtension == "Fisica"
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
                                  const Color(0xFF4A1F0F),
                                  const Color(0xFF3A150C),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(w(18)),
                        border: Border.all(
                          color: tipoExtension == "Fisica"
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFFFF7A00),
                          width: w(1),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mobile_friendly,
                            size: sp(25),
                            color: tipoExtension == "Fisica"
                                ? Colors.white.withOpacity(0.65)
                                : const Color(0xFFFF7A00),
                          ),
                          SizedBox(height: h(10)),
                          Text(
                            "Virtual",
                            style: TextStyle(
                              color: tipoExtension == "Fisica"
                                  ? Colors.white.withOpacity(0.65)
                                  : const Color(0xFFFF7A00),
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
                        tipoExtension = "Virtual";
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
                        gradient: tipoExtension == "Virtual"
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
                                  const Color(0xFF4A1F0F),
                                  const Color(0xFF3A150C),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(w(18)),
                        border: Border.all(
                          color: tipoExtension == "Virtual"
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFFFF7A00),
                          width: w(1),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card,
                            size: sp(25),
                            color: tipoExtension == "Virtual"
                                ? Colors.white.withOpacity(0.65)
                                : const Color(0xFFFF7A00),
                          ),
                          SizedBox(height: h(10)),
                          Text(
                            "Fisica",
                            style: TextStyle(
                              color: tipoExtension == "Virtual"
                                  ? Colors.white.withOpacity(0.75)
                                  : const Color(0xFFFF7A00),
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
                        tipoExtension = "Fisica";
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
                  tipoExtension == "Virtual"
                      ? "Asignar usuario"
                      : "Ingresar Datos",
                  style: TextStyle(
                    color: Colors.white60,
                    fontFamily: "PoppinsBold",
                    fontSize: sp(17),
                  ),
                ),
              ),
            ),
            SizedBox(height: h(13)),
            Visibility(
              visible: tipoExtension == "Virtual" ? true : false,
              child: Row(
                children: [
                  // 👉 TEXTFIELD COMPLETO (con icono y todo)
                  Container(
                    width: w(318),
                    height: h(63),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(20, 25, 50, 1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        // ICONO IZQUIERDO
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: w(13)),
                          height: h(35),
                          width: w(35),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromRGBO(200, 90, 0, 1),
                                Colors.orange.shade600,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: sp(18),
                          ),
                        ),

                        // TEXTFIELD
                        Expanded(
                          child: TextField(
                            controller: _controllerUsuarioExtension,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              hintText: "Busca por Alias, CBU o Email...",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: sp(15),
                                fontFamily: "PoppinsBold",
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: h(13),
                              ),
                              suffixIcon: Padding(
                                padding: EdgeInsets.only(right: w(8)),
                                child: GestureDetector(
                                  onTap: () {
                                    _controllerUsuarioExtension.clear();
                                    setState(() {
                                      usuarioEncontrado = false;
                                    });
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color:
                                        _controllerUsuarioExtension
                                            .text
                                            .isNotEmpty
                                        ? Colors.white
                                        : Colors.transparent,
                                    size: sp(18),
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: w(12)),

                  // 🔍 BOTÓN DE BUSQUEDA (afuera del TextField, mismo diseño)
                  GestureDetector(
                    child: Container(
                      height: h(53),
                      width: h(53),
                      decoration: BoxDecoration(
                        color: _controllerUsuarioExtension.text.isEmpty
                            ? const Color.fromRGBO(20, 25, 50, 1)
                            : const Color(0xFF4A1F0F),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: _controllerUsuarioExtension.text.isEmpty
                              ? Colors.white
                              : const Color(0xFFFF7A00),
                          width: _controllerUsuarioExtension.text.isEmpty
                              ? 0.3
                              : 0.5,
                        ),
                      ),
                      child: estadoBuscando == "Inicial"
                          ? Center(
                              child: Icon(
                                Icons.search,
                                size: sp(20),
                                color: const Color(0xFFFF7A00),
                              ),
                            )
                          : Center(
                              child: SizedBox(
                                height: h(23),
                                width: w(23),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFFFF7A00),
                                  ),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ),
                    ),
                    onTap: () {
                      Vibration.vibrate(duration: 5);
                      FocusScopeNode currentFocus = FocusScope.of(context);
                      if (!currentFocus.hasPrimaryFocus &&
                          currentFocus.focusedChild != null) {
                        currentFocus.focusedChild!.unfocus();
                      }
                      buscarUsuario();
                    },
                  ),
                ],
              ),
            ),
            Visibility(
              visible: tipoExtension == "Fisica" ? true : false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                Color.fromRGBO(200, 90, 0, 1),
                                Colors.orange.shade600,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: sp(18),
                          ),
                        ),
                        // TextField
                        Expanded(
                          child: TextField(
                            controller: _controllerNombreUsuario,
                            textCapitalization: TextCapitalization.words,
                            textAlignVertical: TextAlignVertical
                                .center, // centra verticalmente
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              hintText: "Nombre Completo",
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
                                    _controllerNombreUsuario.clear();
                                    setState(
                                      () {},
                                    ); // refresca la visibilidad del icono
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color:
                                        (_controllerNombreUsuario
                                            .text
                                            .isNotEmpty
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
                                  _controllerNombreUsuario.text = value;
                                } else {
                                  _controllerNombreUsuario.text = "";
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: h(23)),
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
                                Color.fromRGBO(200, 90, 0, 1),
                                Colors.orange.shade600,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.badge,
                            color: Colors.white,
                            size: sp(18),
                          ),
                        ),
                        // TextField
                        Expanded(
                          child: TextField(
                            controller: _controllerDniUsuario,
                            textAlignVertical: TextAlignVertical
                                .center, // centra verticalmente
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              hintText: "DNI",
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
                                    _controllerDniUsuario.clear();
                                    setState(
                                      () {},
                                    ); // refresca la visibilidad del icono
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color:
                                        (_controllerDniUsuario.text.isNotEmpty
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
                                  _controllerDniUsuario.text = value;
                                } else {
                                  _controllerDniUsuario.text = "";
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: h(23)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(350)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Datos entrega",
                        style: TextStyle(
                          color: Colors.white60,
                          fontFamily: "PoppinsBold",
                          fontSize: sp(17),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h(23)),
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
                                Color.fromRGBO(200, 90, 0, 1),
                                Colors.orange.shade600,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.home,
                            color: Colors.white,
                            size: sp(18),
                          ),
                        ),
                        // TextField
                        Expanded(
                          child: TextField(
                            controller: _controllerDireccionUsuario,
                            textCapitalization: TextCapitalization.words,
                            textAlignVertical: TextAlignVertical
                                .center, // centra verticalmente
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              hintText: "Direccion",
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
                                    _controllerDireccionUsuario.clear();
                                    setState(
                                      () {},
                                    ); // refresca la visibilidad del icono
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color:
                                        (_controllerDireccionUsuario
                                            .text
                                            .isNotEmpty
                                        ? Colors.white
                                        : Colors.transparent),
                                    size: sp(18),
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (value) async {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: h(23)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Provincia
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w(15),
                            vertical: h(3),
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(20, 25, 50, 1),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: [
                              // Ícono naranja
                              Container(
                                height: h(35),
                                width: w(35),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color.fromRGBO(200, 90, 0, 1),
                                      Colors.orange.shade600,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  LucideIcons.mapPin,
                                  color: Colors.white,
                                  size: sp(20),
                                ),
                              ),

                              SizedBox(width: w(15)),

                              // 👉 Dropdown que se expande
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: provinciaSeleccionada,
                                    hint: Text(
                                      "Elegir Provincia",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: sp(14),
                                        fontFamily: "Poppins",
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
                                      fontSize: sp(14),
                                    ),
                                    isExpanded: true, // 👈 IMPORTANTE
                                    items: provinciasYCiudades.keys.map((
                                      provincia,
                                    ) {
                                      return DropdownMenuItem(
                                        value: provincia,
                                        child: Text(
                                          provincia,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Poppins",
                                            fontSize: sp(14),
                                          ),
                                        ),
                                      );
                                    }).toList(),
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
                        ),
                      ),

                      SizedBox(width: w(13)),

                      // Ciudad
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w(15),
                            vertical: h(3),
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(20, 25, 50, 1),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: [
                              // 🔸 Ícono naranja igual al de Provincia
                              Container(
                                height: h(35),
                                width: w(35),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color.fromRGBO(200, 90, 0, 1),
                                      Colors.orange.shade600,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.location_city,
                                  color: Colors.white,
                                  size: sp(20),
                                ),
                              ),

                              SizedBox(width: w(12)),

                              // 🔸 Dropdown de Ciudad
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: ciudadSeleccionada,
                                    hint: Text(
                                      "Elegir Ciudad",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: sp(14),
                                        fontFamily: "Poppins",
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
                                      fontSize: sp(14),
                                    ),
                                    isExpanded: true,
                                    borderRadius: BorderRadius.circular(15),

                                    items: provinciaSeleccionada == null
                                        ? []
                                        : provinciasYCiudades[provinciaSeleccionada!]!
                                              .map(
                                                (ciudad) => DropdownMenuItem(
                                                  value: ciudad,
                                                  child: Text(
                                                    ciudad,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "Poppins",
                                                      fontSize: sp(14),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),

                                    onChanged: (value) {
                                      setState(
                                        () => ciudadSeleccionada = value,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h(23)),
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
                                Color.fromRGBO(200, 90, 0, 1),
                                Colors.orange.shade600,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.abc,
                            color: Colors.white,
                            size: sp(18),
                          ),
                        ),
                        // TextField
                        Expanded(
                          child: TextField(
                            controller: _controllerCodigoPostalUsuario,
                            textAlignVertical: TextAlignVertical
                                .center, // centra verticalmente
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              hintText: "Codigo Postal",
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
                                    _controllerCodigoPostalUsuario.clear();
                                    setState(
                                      () {},
                                    ); // refresca la visibilidad del icono
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color:
                                        (_controllerCodigoPostalUsuario
                                            .text
                                            .isNotEmpty
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
                                  _controllerCodigoPostalUsuario.text = value;
                                } else {
                                  _controllerCodigoPostalUsuario.text = "";
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: usuarioEncontrado && tipoExtension == "Virtual",
              child: Column(
                children: [
                  SizedBox(height: h(23)),
                  Container(
                    width: w(400),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromRGBO(1, 165, 113, 1).withOpacity(0.3),
                          Colors.green.shade600.withOpacity(0.3),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 0.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: sp(20),
                          backgroundColor: Colors.green,
                          child: Image.asset(avatarUserExterno),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(13)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nameUserExterno,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "PoppinsBold",
                                  fontSize: sp(16),
                                ),
                              ),
                              SizedBox(height: h(5)),
                              Text(
                                dniUserExterno,
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "PoppinsBold",
                                  fontSize: sp(15),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        GestureDetector(
                          child: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: sp(18),
                            ),
                          ),
                          onTap: () {
                            Vibration.vibrate(duration: 5);
                            setState(() {
                              _controllerUsuarioExtension.clear();
                              usuarioEncontrado = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: h(43)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w(350)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Límite de gasto",
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
                        gradient: limiteGasto == "Sin limite"
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
                                  const Color(0xFF4A1F0F),
                                  const Color(0xFF3A150C),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(w(18)),
                        border: Border.all(
                          color: limiteGasto == "Sin limite"
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFFFF7A00),
                          width: w(1),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: sp(25),
                            color: limiteGasto == "Sin limite"
                                ? Colors.white.withOpacity(0.65)
                                : const Color(0xFFFF7A00),
                          ),
                          SizedBox(height: h(10)),
                          Text(
                            "Monto fijo",
                            style: TextStyle(
                              color: limiteGasto == "Sin limite"
                                  ? Colors.white.withOpacity(0.65)
                                  : const Color(0xFFFF7A00),
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
                        limiteGasto = "Monto fijo";
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
                        gradient: limiteGasto == "Monto fijo"
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
                                  const Color(0xFF4A1F0F),
                                  const Color(0xFF3A150C),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(w(18)),
                        border: Border.all(
                          color: limiteGasto == "Monto fijo"
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFFFF7A00),
                          width: w(1),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.public,
                            size: sp(25),
                            color: limiteGasto == "Monto fijo"
                                ? Colors.white.withOpacity(0.65)
                                : const Color(0xFFFF7A00),
                          ),
                          SizedBox(height: h(10)),
                          Text(
                            "Sin límite",
                            style: TextStyle(
                              color: limiteGasto == "Monto fijo"
                                  ? Colors.white.withOpacity(0.75)
                                  : const Color(0xFFFF7A00),
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
                        limiteGasto = "Sin limite";
                      });
                    },
                  ),
                ),
              ],
            ),
            Visibility(
              visible: limiteGasto == "Monto fijo" ? true : false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h(43)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(350)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Monto máximo",
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
                                const Color.fromRGBO(200, 90, 0, 1),
                                Colors.orange.shade600,
                              ],
                            ),
                          ),
                          child: Icon(
                            LucideIcons.dollarSign,
                            color: Colors.white,
                            size: sp(18),
                          ),
                        ),
                        // TextField
                        Expanded(
                          child: Visibility(
                            visible: true,
                            child: TextField(
                              controller: _controllerMontoMaximo,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: false,
                                  ),
                              inputFormatters: [DynamicMoneyFormatter()],
                              textInputAction: TextInputAction.done,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "PoppinsBold",
                              ),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                hintText: "Ingresa el monto",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                border: InputBorder.none,
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
            SizedBox(height: h(43)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w(350)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Fecha de expiración",
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
                        gradient: fechaExpiracion == "Personalizar"
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
                                  const Color(0xFF4A1F0F),
                                  const Color(0xFF3A150C),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(w(18)),
                        border: Border.all(
                          color: fechaExpiracion == "Personalizar"
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFFFF7A00),
                          width: w(1),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: sp(25),
                            color: fechaExpiracion == "Personalizar"
                                ? Colors.white.withOpacity(0.65)
                                : const Color(0xFFFF7A00),
                          ),
                          SizedBox(height: h(10)),
                          Text(
                            "Igual a la principal",
                            style: TextStyle(
                              color: fechaExpiracion == "Personalizar"
                                  ? Colors.white.withOpacity(0.65)
                                  : const Color(0xFFFF7A00),
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
                        fechaExpiracion = "Original";
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
                        gradient: fechaExpiracion == "Original"
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
                                  const Color(0xFF4A1F0F),
                                  const Color(0xFF3A150C),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(w(18)),
                        border: Border.all(
                          color: fechaExpiracion == "Original"
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFFFF7A00),
                          width: w(1),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: sp(25),
                            color: fechaExpiracion == "Original"
                                ? Colors.white.withOpacity(0.65)
                                : const Color(0xFFFF7A00),
                          ),
                          SizedBox(height: h(10)),
                          Text(
                            "Personalizada",
                            style: TextStyle(
                              color: fechaExpiracion == "Original"
                                  ? Colors.white.withOpacity(0.75)
                                  : const Color(0xFFFF7A00),
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
                        fechaExpiracion = "Personalizar";
                      });
                    },
                  ),
                ),
              ],
            ),
            Visibility(
              visible: fechaExpiracion == "Original" ? true : false,
              child: Column(
                children: [
                  SizedBox(height: h(23)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: h(20),
                      horizontal: w(20),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color.fromRGBO(20, 25, 50, 1),
                          const Color.fromRGBO(20, 25, 50, 1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(23),
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
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromRGBO(200, 90, 0, 1),
                                Colors.orange.shade600,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: sp(25), // tamaño auto relativo está permitido
                          ),
                        ),

                        SizedBox(width: w(15)),

                        // TEXTOS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "La extensión vencerá el mismo día que tu tarjeta principal.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: sp(13),
                                  fontFamily: "PoppinsBold",
                                ),
                              ),
                              SizedBox(height: h(5)),
                              Text(
                                vencimientoTarjetaUser,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
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
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: fechaExpiracion == "Personalizar" ? true : false,
              child: Column(
                children: [
                  SizedBox(height: h(23)),
                  GestureDetector(
                    onTap: () => showCupertinoPicker(context),
                    child: Container(
                      width: w(400),
                      height: h(63),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(20, 25, 50, 1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          // ICONO IZQUIERDO
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: w(13)),
                            height: h(35),
                            width: w(35),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromRGBO(200, 90, 0, 1),
                                  Colors.orange.shade600,
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                              size: sp(18),
                            ),
                          ),

                          // TEXTFIELD
                          Expanded(
                            child: Text(
                              selectedDate != null
                                  ? "Expira el ${selectedDate!.month < 10 ? "0" + selectedDate!.month.toString() : selectedDate!.month}/${selectedDate!.year.toString().substring(2)}"
                                  : "Seleccionar fecha",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "PoppinsBold",
                                fontSize: sp(15),
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
            SizedBox(height: h(43)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w(350)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Opciones adicionales",
                  style: TextStyle(
                    color: Colors.white60,
                    fontFamily: "PoppinsBold",
                    fontSize: sp(17),
                  ),
                ),
              ),
            ),
            SizedBox(height: h(13)),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                // Card externo
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.010,
                ),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(20, 25, 50, 1),
                  borderRadius: BorderRadius.circular(13),
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
                    // Icon con glow / gradiente
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Circle icon
                        Center(
                          child: Icon(
                            LucideIcons.lock,
                            color: Colors.white,
                            size: sp(20),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(width: screenWidth * 0.04),

                    // Textos (title + subtitle) y botón
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Text(
                            'Solicitar aprobación',
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
                            'Validar cada gasto antes de aprobarlo.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: sp(13),
                              fontFamily: "Poppins",
                            ),
                          ),
                        ],
                      ),
                    ),

                    //Switch
                    Switch(
                      value: sVerificacionAdicional,
                      onChanged: (value) {
                        Vibration.vibrate(duration: 5);
                        setState(() {
                          sVerificacionAdicional = value;
                        });
                      },
                      activeColor: Colors.white, // color del círculo
                      activeTrackColor: const Color.fromRGBO(
                        200,
                        90,
                        0,
                        1,
                      ), // color de la barra cuando está activo
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: h(53)),
            GestureDetector(
              child: Container(
                height: h(53),
                width: w(400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient:
                      (_controllerNombreExtension.text.isNotEmpty &&
                          (tipoExtension == "Virtual"
                              ? usuarioEncontrado == true
                              : _controllerNombreUsuario.text.isNotEmpty &&
                                    _controllerDniUsuario.text.isNotEmpty &&
                                    _controllerDireccionUsuario
                                        .text
                                        .isNotEmpty &&
                                    provinciaSeleccionada!.isNotEmpty &&
                                    ciudadSeleccionada!.isNotEmpty &&
                                    _controllerCodigoPostalUsuario
                                        .text
                                        .isNotEmpty) &&
                          (limiteGasto == "Monto fijo"
                              ? _controllerMontoMaximo.text.isNotEmpty
                              : true) &&
                          (fechaExpiracion == "Personalizar"
                              ? selectedDate != null
                                    ? true
                                    : false
                              : true)
                      ? LinearGradient(
                          colors: [
                            const Color.fromRGBO(200, 90, 0, 1),
                            Colors.orange.shade600,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : LinearGradient(
                          colors: [Colors.white60, Colors.grey],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Crear Extensión",
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
                if (_controllerNombreExtension.text.isNotEmpty &&
                    (tipoExtension == "Virtual"
                        ? usuarioEncontrado == true
                        : _controllerNombreUsuario.text.isNotEmpty &&
                              _controllerDniUsuario.text.isNotEmpty &&
                              _controllerDireccionUsuario.text.isNotEmpty &&
                              provinciaSeleccionada!.isNotEmpty &&
                              ciudadSeleccionada!.isNotEmpty &&
                              _controllerCodigoPostalUsuario.text.isNotEmpty) &&
                    (limiteGasto == "Monto fijo"
                        ? _controllerMontoMaximo.text.isNotEmpty
                        : true) &&
                    (fechaExpiracion == "Personalizar"
                        ? selectedDate != null
                              ? true
                              : false
                        : true)) {
                  verificarExistenciaExtension();
                  Vibration.vibrate(duration: 5);
                } else {
                  showFlushbarError(context, "Completa todos los campos.");
                  Vibration.vibrate(duration: 15);
                }
              },
            ),
            SizedBox(height: h(13)),
          ],
        ),
      ),
    );
  }

  Widget creandoExtensionWidget() {
    final size = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Visibility(
      visible: creandoExtensionVis,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w(23),
            vertical: estadoCreacion == "Esperando"
                ? h(300)
                : estadoCreacion == "Creando"
                ? h(300)
                : estadoCreacion == "Creada"
                ? h(263)
                : h(113),
          ),
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
                color: estadoCreacion != "Creada"
                    ? Color.fromRGBO(200, 90, 0, 1)
                    : Color.fromRGBO(1, 165, 113, 0.878),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: estadoCreacion != "Creada"
                      ? Color.fromRGBO(200, 90, 0, 1)
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
                  if (estadoCreacion == "Esperando") ...[
                    SizedBox(height: h(53)),
                    Center(
                      child: Icon(
                        LucideIcons.scanFace,
                        color: Color.fromRGBO(200, 90, 0, 1),
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
                  ] else if (estadoCreacion == "Creando") ...[
                    SizedBox(height: h(53)),
                    Center(
                      child: SizedBox(
                        height: h(83),
                        width: w(83),
                        child: CircularProgressIndicator(
                          color: Color.fromRGBO(200, 90, 0, 1),
                          strokeWidth: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: h(53)),
                    Center(
                      child: Text(
                        "Creando Extensión",
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
                  ] else if (estadoCreacion == "Creada") ...[
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
                        "Extensión Creada",
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
                        tipoExtension == "Virtual"
                            ? "Tu extensión ha sido creada exitosamente. $nameUserExterno ya puede comenzar a utilizarla."
                            : "Tu extensión ha sido solicitada exitosamente. Podes seguir el envio desde Notificaciones.",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: sp(15),
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
                                creandoExtensionVis = false;
                                distorcion = false;
                                estadoCreacion = "Inicial";
                              });
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
