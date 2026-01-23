// ignore_for_file: use_key_in_widget_constructors, camel_case_types, avoid_unnecessary_containers, avoid_print, unused_local_variable, body_might_complete_normally_nullable, deprecated_member_use, prefer_interpolation_to_compose_strings, unnecessary_string_interpolations, use_build_context_synchronously, constant_pattern_never_matches_value_type, prefer_adjacent_string_concatenation, unnecessary_brace_in_string_interps, await_only_futures, unnecessary_string_escapes

import 'package:bluetooth/UI/aprobarTutoria.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:vibration/vibration.dart';

class notificacionesPage extends StatefulWidget {
  @override
  State<notificacionesPage> createState() => _notificacionesPageState();
}

class _notificacionesPageState extends State<notificacionesPage>
    with TickerProviderStateMixin {
  StreamSubscription<QuerySnapshot>? _notiSubscription;

  final PageController _controllerPage = PageController(viewportFraction: 0.7);
  int _paginaActual = 0;

  final List<String> filtros = [
    "Todas",
    "Sin leer",
    "Solicitudes",
    "Ingresos",
    "Egresos",
  ];

  // Declarar global o en un provider
  final ValueNotifier<int> cantidadNotificacionesSinLeer = ValueNotifier<int>(
    0,
  );

  late AnimationController _controller;

  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  Offset _offset = const Offset(-1, 0); // comienza "izquierda"

  Color colorFondo = Colors.transparent;
  IconData icono = LucideIcons.bell;

  //Animacion Aparicion
  late AnimationController _controllerAparicion;
  late Animation<Offset> _offsetAnimationAparicion;

  String indexNoti = "";

  double saldoUser = 0.0;

  //Solicitudes y Movimientos
  double montoNoti = 0.0;
  String mensajeNoti = "";
  String fechaNoti = "";
  late DateTime fechaNotiTime;
  String horaNoti = "";
  String deNoti = "";
  String deUidNoti = "";
  String deDniNoti = "";
  String deEmailNoti = "";
  String AvatarEnviaNoti = "";
  String AvatarRecibeNoti = "";
  String paraNoti = "";
  String paraUidNoti = "";
  String paraDniNoti = "";
  String medioPagoNoti = "";
  String estadoNoti = "";
  String tipoNoti = "";
  String metodoNoti = "";
  bool leido = false;
  bool soyElEmisor = false;
  bool ingreso = false;
  //Fin Solicitudes y Movimientos

  //Tarjeta
  String idSolicitudTarjeta = "";
  String fechaSolicitudTarjeta = "";
  String estadoSolicitudTarjeta = "";
  String direccionSolicitudTarjeta = "";
  String entregaEstimadaSolicitudaTarjeta = "";
  String fechaEntregada = "";
  String motivoNoti = "";
  //Fin Tarjeta

  //Extension
  String nombreExtensionNoti = "";
  String limiteExtensionNoti = "";
  String vencimientoExtensionNoti = "";
  String tipoExtensionNoti = "";
  String avatarDeExtensionNoti = "";
  String avatarParaExtensionNoti = "";
  bool verificacionExtensionNoti = false;
  double limiteRestanteExtension = 0.0;
  bool utilitario = false;
  //Fin Extension

  //Limite
  double limiteNoti = 0.0;
  String tipoLimiteNoti = "";
  //Fin Limite

  //Umbral
  double umbralNoti = 0.0;
  String tipoUmbralNoti = "";
  String accionUmbralNoti = "";
  //Fin Umbral

  String horaActual = "";

  int reciboIDNoti = 0;

  String textoTiempo = "";

  //Datos
  String uidUser = "";
  String temaUser = "";
  //Datos

  Future<String> leerShared() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString('codeUser') == null) {
      uidUser = "";
    } else {
      uidUser = prefs.getString('codeUser')!;
    }
    return uidUser;
  }

  String tiempoRelativo(DateTime fechaFirebase) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fechaFirebase);

    if (diferencia.inSeconds < 60) {
      return 'Justo ahora';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} minuto${diferencia.inMinutes == 1 ? '' : 's'}';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} hora${diferencia.inHours == 1 ? '' : 's'}';
    } else if (diferencia.inHours < 48) {
      return 'Ayer';
    } else if (diferencia.inHours < 72) {
      return 'Antes de ayer';
    } else if (diferencia.inDays < 365) {
      return DateFormat('dd/MM').format(fechaNotiTime);
    } else {
      return DateFormat('dd/MM/yyyy').format(fechaNotiTime);
    }
  }

  Future<void> obtenerDatosUser() async {
    await leerShared();

    try {
      FirebaseFirestore.instance
          .collection('Usuarios') // colección principal
          .doc(uidUser) // documento del usuario
          .snapshots() // escuchar en tiempo real
          .listen((docSnapshot) async {
            if (docSnapshot.exists) {
              Map<String, dynamic> data =
                  docSnapshot.data() as Map<String, dynamic>;

              setState(() {
                saldoUser = (data["Saldo"] != null)
                    ? (data["Saldo"] as num).toDouble()
                    : 0.0;

                temaUser = data["Tema"] ?? "";
              });

              //Verificar Tarjeta
              FirebaseFirestore.instance
                  .collection('Usuarios') // colección principal
                  .doc(uidUser)
                  .snapshots()
                  .listen((docSnapshot) async {
                    if (docSnapshot.exists) {
                      Map<String, dynamic> data =
                          docSnapshot.data() as Map<String, dynamic>;

                      if (data["Tarjeta"] != "No") {
                        if (!filtros.contains("Tarjeta")) {
                          filtros.add("Tarjeta");
                        }
                      } else {
                        if (filtros.contains("Tarjeta")) {
                          filtros.remove("Tarjeta");
                        }
                      }
                    } else {
                      print('No existe una tarjeta para este usuario.');
                    }
                  });

              //Verificar Pupilos
              FirebaseFirestore.instance
                  .collection('Pupilos') // o la colección correcta
                  .where('Tutor', isEqualTo: uidUser)
                  .snapshots()
                  .listen((querySnapshot) {
                    if (querySnapshot.docs.isNotEmpty) {
                      if (!filtros.contains("Pupilo")) {
                        filtros.add("Pupilo");
                      }
                    } else {
                      filtros.remove("Pupilo");
                    }
                  });

              //Verificar Tutor
              FirebaseFirestore.instance
                  .collection('Pupilos') // o la colección correcta
                  .where('Pupilo', isEqualTo: uidUser)
                  .snapshots()
                  .listen((querySnapshot) {
                    if (querySnapshot.docs.isNotEmpty) {
                      if (!filtros.contains("Tutor")) {
                        filtros.add("Tutor");
                      }
                    } else {
                      filtros.remove("Tutor");
                    }
                  });

              //Verificar Extensiones
              FirebaseFirestore.instance
                  .collection('Extensiones')
                  .where('Involucra', arrayContains: uidUser)
                  .snapshots()
                  .listen((querySnapshot) {
                    if (querySnapshot.docs.isEmpty) {
                      filtros.remove("Extensiones");
                      return;
                    }

                    bool algunaExtension = false;

                    for (var doc in querySnapshot.docs) {
                      final data = doc.data();

                      if (data["Extensiones"] != "No") {
                        algunaExtension = true;
                        break;
                      }
                    }

                    if (algunaExtension) {
                      if (!filtros.contains("Extensiones")) {
                        filtros.add("Extensiones");
                      }
                    } else {
                      filtros.remove("Extensiones");
                    }
                  });
            } else {
              print('El documento no existe');
            }
          });
    } catch (e) {
      print("Error al obetner los datos del usuario: $e");
    }
  }

  Future<void> eliminarNotificacion() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc(indexNoti);
      final docSnap = await docRef.get();

      if (!docSnap.exists) return;

      List<dynamic> involucra = docSnap.data()?['Involucra'] ?? [];

      if (involucra.length <= 1) {
        // Si queda solo un usuario, eliminamos el documento completo
        await docRef.delete();
      } else {
        // Si quedan varios, eliminamos solo al usuario actual
        await docRef.update({
          "Involucra": FieldValue.arrayRemove([uidUser]),
          "Leida.$uidUser": FieldValue.delete(), // opcional
        });
      }
    } catch (e) {
      print("Error al eliminar la notificación: $e");
    }
  }

  Future<void> marcarTodasNotificacionesComoLeidas(String uidUser) async {
    try {
      // Obtener todas las notificaciones donde el usuario está involucrado
      final snapshot = await FirebaseFirestore.instance
          .collection('Notificaciones')
          .where('Involucra', arrayContains: uidUser)
          .get();

      // Actualizar todas en batch para mayor eficiencia
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'Leida.$uidUser': true});
      }

      await batch.commit();

      setState(() {
        cantidadNotificacionesSinLeer.value = 0;
      });
    } catch (e) {
      print("Error al marcar todas las notificaciones como leídas: $e");
    }
  }

  Future<void> marcarNotificacionLeidaUnitaria(doc) async {
    try {
      FirebaseFirestore.instance
          .collection('Notificaciones')
          .doc(doc.id)
          .update({
            'Leida.$uidUser': true, // Solo se actualiza el usuario actual
          });

      FirebaseFirestore.instance
          .collection('Notificaciones')
          .where('Involucra', arrayContains: uidUser)
          .snapshots()
          .listen((snapshot) {
            cantidadNotificacionesSinLeer.value = snapshot.docs
                .where(
                  (doc) => ((doc['Leida'] ?? {})[uidUser] ?? false) == false,
                )
                .length;
          });
    } catch (e) {
      print("Error al marcar la notificacion unitaria como leida: $e");
    }
  }

  Future<void> rechazarSolicitud() async {
    try {
      final notiRecibeRef = FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc(indexNoti);

      final notiUpdates = Future.wait([
        notiRecibeRef.set({"Estado": "Rechazada"}, SetOptions(merge: true)),
      ]);

      await Future.wait([notiUpdates]);

      borrarRecibo();
      actualizarMovimientos();

      Future.delayed(Duration(seconds: 1), () {
        FirebaseFirestore.instance
            .collection("Transacciones")
            .doc("Transaccion #$reciboIDNoti")
            .update({"Estado": "Rechazada"});

        FirebaseFirestore.instance
            .collection("Notificaciones")
            .doc("Notificacion Transaccion #$reciboIDNoti")
            .update({"Estado": "Rechazada"});
      });

      print("Solicitud marcada como rechazada ✅");
    } catch (e) {
      print("Error al rechazar la solicitud: $e");
    }
  }

  Future<void> aceptarSolicitud() async {
    try {
      final notiRecibeRef = FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc(indexNoti);

      // 🔹 Actualizar notificaciones (crear si no existen)
      final notiUpdates = Future.wait([
        notiRecibeRef.set({"Estado": "Aceptada"}, SetOptions(merge: true)),
      ]);

      // 🔹 Actualizar saldos de forma rápida con increment
      final saldoUpdates = Future.wait([
        FirebaseFirestore.instance.collection("Usuarios").doc(paraUidNoti).set({
          "Saldo": FieldValue.increment(-montoNoti),
        }, SetOptions(merge: true)),
        FirebaseFirestore.instance.collection("Usuarios").doc(deUidNoti).set({
          "Saldo": FieldValue.increment(montoNoti),
        }, SetOptions(merge: true)),
      ]);

      // 🔹 Esperar que todas las operaciones terminen
      await Future.wait([notiUpdates, saldoUpdates]);

      borrarRecibo();
      actualizarMovimientos();
      crearNotificacionMovimiento();

      Future.delayed(Duration(seconds: 1), () {
        FirebaseFirestore.instance
            .collection("Transacciones")
            .doc("Transaccion #$reciboIDNoti")
            .update({"Estado": "Aceptada"});

        FirebaseFirestore.instance
            .collection("Notificaciones")
            .doc("Notificacion Transaccion #$reciboIDNoti")
            .update({"Estado": "Aceptada"});
      });

      print("Solicitud aceptada y saldos actualizados ✅");
    } catch (e) {
      print("Error al aceptar la solicitud: $e");
    }
  }

  Future<void> aceptarSolicitudGastoExtension(id) async {
    FirebaseFirestore.instance
        .collection('Notificaciones')
        .doc("Notificacion Solicitud Gasto Extension #$id")
        .update({"Estado": "Pago"});
  }

  Future<void> rechazarSolicitudGastoExtension(id) async {
    FirebaseFirestore.instance
        .collection('Notificaciones')
        .doc("Notificacion Solicitud Gasto Extension #$id")
        .update({"Estado": "Rechazado"});
  }

  Future<void> borrarRecibo() async {
    try {
      FirebaseFirestore.instance
          .collection("Recibos")
          .doc("Recibo #$reciboIDNoti")
          .delete();
    } catch (e) {
      print("Error al eliminar el recibo: $e");
    }
  }

  Future<void> actualizarMovimientos() async {
    try {
      FirebaseFirestore.instance
          .collection("Transacciones")
          .doc("Transaccion #$reciboIDNoti")
          .set({
            "De": deNoti,
            "Para": paraNoti,
            "Monto": montoNoti,
            "Fecha": fechaNoti,
            "Hora": horaNoti,
            "Metodo": "Solicitud $metodoNoti",
            "ID": reciboIDNoti,
            "Involucra": [deUidNoti, paraUidNoti],
          });
    } catch (e) {
      print("Error al crear la transferencia: $e");
    }
  }

  Future<void> crearNotificacionMovimiento() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    try {
      //Obtener Monto Correcto
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc("Notificacion #$reciboIDNoti")
          .get();

      double monto = 0.0;

      if (doc.exists) {
        monto = (doc['Monto'] ?? 0).toDouble();
      }
      //Fin Obtener Monto Correcto

      await FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc("Notificacion Transaccion #$reciboIDNoti")
          .set({
            "Tipo": "Movimiento",
            "De": deNoti,
            "De uid": deUidNoti,
            "Avatar Envia": AvatarEnviaNoti,
            "Avatar Recibe": AvatarRecibeNoti,
            "Para": paraNoti,
            "Para uid": uidUser,
            "Monto": monto,
            "Fecha": fecha, // 🔹 string solo para mostrar (dd-MM-yyyy)
            "Hora": horaActual, // 🔹 string solo para mostrar
            "FechaTime": Timestamp.fromDate(
              ahora,
            ), // 🔹 este es el que se usa en queries
            "ID Recibo": reciboIDNoti,
            "Metodo": "Solicitud Por $metodoNoti",
            "Leida": {uidUser: false, deUidNoti: false},
            "Involucra": [uidUser, deUidNoti],
          });

      print("Notificacion Movimiento creadas ✅");
    } catch (e, st) {
      print("Error al crear la notificacion: $e");
      print(st);
    }
  }

  Future<void> obtenerEstadoSolicitudTarjeta() async {
    await leerShared();
    await obtenerDatosUser();
    FirebaseFirestore.instance
        .collection("SolicitudesTarjetas")
        .doc("Solicitud $uidUser")
        .snapshots()
        .listen((docSnapshot) {
          //if (!mounted) return;

          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              estadoSolicitudTarjeta = data["Estado"] ?? "";
              direccionSolicitudTarjeta = data["Direccion"] ?? "";
              fechaSolicitudTarjeta = data["Fecha Solicitud"] ?? "";
              entregaEstimadaSolicitudaTarjeta = data["Entrega Estimada"] ?? "";
              fechaEntregada = data["Entregada"] ?? "";
            });

            //print(mesFechaEstimada);

            //print(fechaEstimada7.toString() + "-" + fechaEstimada10.toString());
          }
        });
  }

  Future<void> rechazarSolicitudTutoria(id) async {
    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Solicitud Tutor #$id")
        .update({"Estado": "Rechazado"});
  }

  Future<void> aceptarSolicitudTutoria(id) async {
    Future.delayed(Duration(milliseconds: 150), () {
      Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.leftToRight,
          child: aprobarTutoriaPage(codePupilo: id),
        ),
      );
    });
  }

  void cancelarNotiListener() {
    _notiSubscription?.cancel();
    _notiSubscription = null;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await leerShared();
      await obtenerDatosUser();
      await obtenerEstadoSolicitudTarjeta();

      Future.delayed(const Duration(milliseconds: 100), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _offset = Offset.zero;
          });
        });
      });
    });

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

    //Animacion Aparicion
    _controllerAparicion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimationAparicion =
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _controllerAparicion, curve: Curves.easeOut),
        );

    Future.delayed(Duration(milliseconds: 150), () {
      _controllerAparicion.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _controllerPage.dispose();
    _controllerAparicion.dispose();
    _iconController.dispose();
    cancelarNotiListener();
    super.dispose();
  }

  String formatMoney(double value) {
    // Separamos parte entera y decimal
    final partes = value.toStringAsFixed(2).split('.');

    final parteEntera = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    final parteDecimal = partes[1];

    // Si los decimales son "00", no los mostramos
    if (parteDecimal == '00') {
      return parteEntera;
    }

    // Caso con decimales
    return '$parteEntera,$parteDecimal';
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              SizedBox(width: 13),
              GestureDetector(
                child: Container(
                  width: 40,
                  height: 40,
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
                    size: 23,
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
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 300),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            textAlign: TextAlign.start,
                            "Notificaciones",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: "PoppinsBold",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 3),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) =>
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: ValueListenableBuilder<int>(
                          valueListenable: cantidadNotificacionesSinLeer,
                          builder: (context, value, child) {
                            return Text(
                              value != 0 ? "$value Sin Leer" : "Todo Al Día",
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white60,
                                fontFamily: "Poppins",
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ValueListenableBuilder<int>(
              valueListenable: cantidadNotificacionesSinLeer,
              builder: (context, value, child) {
                return AnimatedSlide(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  offset: value > 0 ? Offset.zero : const Offset(0, 5),
                  child: IconButton(
                    onPressed: () {
                      Vibration.vibrate(duration: 10);
                      marcarTodasNotificacionesComoLeidas(uidUser);
                    },
                    icon: Icon(
                      cantidadNotificacionesSinLeer.value > 1
                          ? LucideIcons.checkCheck
                          : null,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            SizedBox(width: 13),
          ],
        ),
        body: Stack(
          children: [
            SizedBox(
              child: Column(
                children: [
                  SizedBox(height: 23),
                  SizedBox(child: filtro()),
                  SizedBox(height: 8),
                  Expanded(child: notificaciones()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget filtro() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SizedBox(
      height: h(60),
      child: PageView.builder(
        controller: _controllerPage,
        itemCount: filtros.length,
        onPageChanged: (index) {
          Vibration.vibrate(duration: 5);
          setState(() {
            _paginaActual = index;
          });
        },
        physics: BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          bool esActivo = index == _paginaActual;

          return GestureDetector(
            onTap: () {
              Vibration.vibrate(duration: 5);
              _controllerPage.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(
                horizontal: w(8),
                vertical: esActivo ? 0 : h(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: w(15), vertical: h(8)),
              decoration: BoxDecoration(
                color: esActivo
                    ? const Color.fromRGBO(1, 165, 113, 1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white24, width: w(1)),
              ),
              child: Center(
                child: Text(
                  filtros[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: esActivo ? sp(18) : sp(16),
                    fontWeight: esActivo ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget notificaciones() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return FutureBuilder<void>(
      future: leerShared(),
      builder: (context, snapshotUid) {
        if (snapshotUid.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator());
        }

        if (uidUser.isEmpty) {
          return Center(
            child: Text(
              "Inicia sesión para ver tus notificaciones.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Notificaciones')
              .where('Involucra', arrayContains: uidUser)
              .orderBy('FechaTime', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    SizedBox(height: h(100)),
                    LottieBuilder.asset("assets/sinNotificaciones.json"),
                    SizedBox(height: h(33)),
                    Text(
                      "No hay notificaciones.",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "PoppinsBold",
                        fontSize: sp(18),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 🔹 Contar las no leídas en tiempo real
            WidgetsBinding.instance.addPostFrameCallback((_) {
              cantidadNotificacionesSinLeer.value = snapshot.data!.docs
                  .where(
                    (doc) => ((doc['Leida'] ?? {})[uidUser] ?? false) == false,
                  )
                  .length;
            });

            // 🔹 (Eliminado el sort aquí)
            List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

            //Cambiar numero por nombre de filtro
            final filtroActivo = filtros[_paginaActual];

            // 🔹 Filtrar según pestaña
            List<QueryDocumentSnapshot> filtradas;
            switch (filtroActivo) {
              case "Sin leer":
                filtradas = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ((data['Leida'] ?? {})[uidUser] ?? false) == false;
                }).toList();
                break;

              case "Solicitudes":
                filtradas = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['Tipo'].contains("Solicitud");
                }).toList();
                break;

              case "Ingresos":
                filtradas = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final paraUid = data['Para uid'] ?? "";
                  return data['Tipo'].contains("Movimiento") &&
                      paraUid == uidUser;
                }).toList();
                break;

              case "Egresos":
                filtradas = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final deUid = data['De uid'] ?? "";
                  return data['Tipo'].contains("Movimiento") &&
                      deUid == uidUser;
                }).toList();
                break;

              case "Tarjeta":
                filtradas = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['Tipo'].contains("Tarjeta");
                }).toList();
                break;

              case "Extensiones":
                filtradas = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['Tipo'].contains("Extension");
                }).toList();
                break;

              case "Tutor":
                filtradas = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['Tipo'].contains("Pupilo");
                }).toList();
                break;

              case "Pupilo":
                filtradas = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['Tipo'].contains("Tutor");
                }).toList();
                break;

              default: // Todas
                filtradas = docs;
            }

            if (filtradas.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    SizedBox(height: h(100)),
                    LottieBuilder.asset("assets/sinNotificaciones.json"),
                    SizedBox(height: h(33)),
                    Text(
                      "No hay notificaciones aqui.",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "PoppinsBold",
                        fontSize: sp(18),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: w(13), vertical: h(23)),
              itemCount: filtradas.length,
              itemBuilder: (context, index) {
                var doc = filtradas[index];
                var data = doc.data() as Map<String, dynamic>;

                tipoNoti = data['Tipo'] ?? "";

                if (tipoNoti == "Solicitud") {
                  montoNoti = (data['Monto'] ?? 0).toDouble();
                  mensajeNoti = data['Mensaje'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  AvatarEnviaNoti = data["Avatar Envia"] ?? "";
                  AvatarRecibeNoti = data["Avatar Recibe"] ?? "";
                  metodoNoti = data['Metodo'] ?? "";
                  paraNoti = data['Para'] ?? "";
                  paraUidNoti = data['Para uid'] ?? "";
                  estadoNoti = data["Estado"] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  soyElEmisor = deUidNoti == uidUser;
                }

                if (tipoNoti == "Movimiento") {
                  montoNoti = (data['Monto'] ?? 0).toDouble();
                  mensajeNoti = data['Mensaje'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  AvatarEnviaNoti = data["Avatar Envia"] ?? "";
                  AvatarRecibeNoti = data["Avatar Recibe"] ?? "";
                  metodoNoti = data['Metodo'] ?? "";
                  paraNoti = data['Para'] ?? "";
                  paraUidNoti = data['Para uid'] ?? "";
                  medioPagoNoti = data["Medio De Pago"] ?? "";
                  estadoNoti = data["Estado"] ?? "";
                  nombreExtensionNoti = data["Nombre Extension"] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  ingreso = paraUidNoti == uidUser;
                }

                if (tipoNoti == "Solicitud Tarjeta") {
                  idSolicitudTarjeta = data["ID Solicitud Tarjeta"] ?? "";
                  fechaSolicitudTarjeta = data["Fecha"] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Tarjeta Activada") {
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Tarjeta Cancelada") {
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  motivoNoti = data['Motivo'] ?? "";
                }

                if (tipoNoti == "Tarjeta Congelada") {
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  motivoNoti = data['Motivo'] ?? "";
                }

                if (tipoNoti == "Tarjeta Descongelada") {
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  motivoNoti = data['Motivo'] ?? "";
                }

                if (tipoNoti == "Extension Creada") {
                  nombreExtensionNoti = data['NombreExtension'] ?? "";
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  paraNoti = data['Para'] ?? "";
                  paraUidNoti = data['Para uid'] ?? "";
                  paraDniNoti = data['Para Dni'] ?? "";
                  limiteExtensionNoti = data['Limite'] ?? "";
                  vencimientoExtensionNoti = data['Vencimiento'] ?? "";
                  tipoExtensionNoti = data['Tipo Extension'] ?? "";
                  verificacionExtensionNoti = data['Verificacion'] ?? "";
                  avatarParaExtensionNoti = data['Avatar'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  motivoNoti = data['Motivo'] ?? "";
                }

                if (tipoNoti == "Extension Recibida") {
                  nombreExtensionNoti = data['NombreExtension'] ?? "";
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  deDniNoti = data['De Dni'] ?? "";
                  paraNoti = data['Para'] ?? "";
                  paraUidNoti = data['Para uid'] ?? "";
                  paraDniNoti = data['Para Dni'] ?? "";
                  limiteExtensionNoti = data['Limite'] ?? "";
                  vencimientoExtensionNoti = data['Vencimiento'] ?? "";
                  tipoExtensionNoti = data['Tipo Extension'] ?? "";
                  verificacionExtensionNoti = data['Verificacion'] ?? "";
                  avatarDeExtensionNoti = data['Avatar'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  motivoNoti = data['Motivo'] ?? "";
                }

                if (tipoNoti == "Limite Tarjeta Creado") {
                  limiteNoti = (data["Limite"] is num)
                      ? (data["Limite"] as num).toDouble()
                      : 0.0;
                  tipoLimiteNoti = data["Tipo Limite"] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Limite Tarjeta Actualizado") {
                  limiteNoti = (data["Limite"] is num)
                      ? (data["Limite"] as num).toDouble()
                      : 0.0;
                  tipoLimiteNoti = data["Tipo Limite"] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Limite Tarjeta Eliminado") {
                  limiteNoti = (data["Limite"] is num)
                      ? (data["Limite"] as num).toDouble()
                      : 0.0;
                  tipoLimiteNoti = data["Tipo Limite"] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Umbral Tarjeta Creado") {
                  umbralNoti = (data["Umbral"] is num)
                      ? (data["Umbral"] as num).toDouble()
                      : 0.0;
                  tipoUmbralNoti = data["Tipo Umbral"] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  accionUmbralNoti = data['Accion Umbral'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Umbral Tarjeta Actualizado") {
                  umbralNoti = (data["Umbral"] is num)
                      ? (data["Umbral"] as num).toDouble()
                      : 0.0;
                  tipoUmbralNoti = data["Tipo Umbral"] ?? "";
                  accionUmbralNoti = data['Accion Umbral'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Umbral Tarjeta Eliminado") {
                  umbralNoti = (data["Umbral"] is num)
                      ? (data["Umbral"] as num).toDouble()
                      : 0.0;
                  tipoUmbralNoti = data["Tipo Umbral"] ?? "";
                  accionUmbralNoti = data['Accion Umbral'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Solicitud Gasto Extension") {
                  nombreExtensionNoti = data["Nombre Extension"] ?? "";
                  montoNoti = (data['Monto'] ?? 0).toDouble();
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  AvatarEnviaNoti = data["Avatar"] ?? "";
                  estadoNoti = data["Estado"] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Gasto Virtual Extension") {
                  montoNoti = (data['Monto'] ?? 0).toDouble();
                  mensajeNoti = data['Mensaje'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  deDniNoti = data["De Dni"] ?? "";
                  AvatarEnviaNoti = data["Avatar Envia"] ?? "";
                  metodoNoti = data['Metodo'] ?? "";
                  paraNoti = data['Para'] ?? "";
                  paraUidNoti = data['Para uid'] ?? "";
                  medioPagoNoti = data["Medio De Pago"] ?? "";
                  estadoNoti = data["Estado"] ?? "";
                  nombreExtensionNoti = data["Nombre Extension"] ?? "";
                  limiteRestanteExtension = (data['Limite Restante'] ?? 0)
                      .toDouble();
                  reciboIDNoti = data["ID"] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Extension Cancelada") {
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  nombreExtensionNoti = data['Nombre Extension'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  motivoNoti = data['Motivo'] ?? "";
                  utilitario = data['Utilitario'] == uidUser;
                }

                if (tipoNoti == "Extension Congelada") {
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  nombreExtensionNoti = data['Nombre Extension'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  motivoNoti = data['Motivo'] ?? "";
                  utilitario = data['Utilitario'] == uidUser;
                }

                if (tipoNoti == "Extension Descongelada") {
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  nombreExtensionNoti = data['Nombre Extension'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  motivoNoti = data['Motivo'] ?? "";
                  utilitario = data['Utilitario'] == uidUser;
                }

                if (tipoNoti == "Limite Extension Creado") {
                  limiteNoti = (data["Limite"] is num)
                      ? (data["Limite"] as num).toDouble()
                      : 0.0;
                  tipoLimiteNoti = data["Tipo Limite"] ?? "";
                  nombreExtensionNoti = data['Nombre Extension'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  utilitario = data['Utilitario'] == uidUser;
                }

                if (tipoNoti == "Limite Extension Actualizado") {
                  limiteNoti = (data["Limite"] is num)
                      ? (data["Limite"] as num).toDouble()
                      : 0.0;
                  tipoLimiteNoti = data["Tipo Limite"] ?? "";
                  nombreExtensionNoti = data['Nombre Extension'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  utilitario = data['Utilitario'] == uidUser;
                }

                if (tipoNoti == "Limite Extension Eliminado") {
                  limiteNoti = (data["Limite"] is num)
                      ? (data["Limite"] as num).toDouble()
                      : 0.0;
                  tipoLimiteNoti = data["Tipo Limite"] ?? "";
                  nombreExtensionNoti = data['Nombre Extension'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                  utilitario = data['Utilitario'] == uidUser;
                }

                if (tipoNoti == "Tutor Solicitado") {
                  deNoti = data['De'] ?? "";
                  deUidNoti = data['De uid'] ?? "";
                  deDniNoti = data['Dni'] ?? "";
                  estadoNoti = data['Estado'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Pupilo Aceptado") {
                  deNoti = "${data['Nombre'] ?? ""} ${data['Apellido'] ?? ""}";
                  deUidNoti = data['Uid'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                if (tipoNoti == "Registrado") {
                  deNoti = data['Nombre'] ?? "";
                  deUidNoti = data['Uid'] ?? "";
                  deDniNoti = data['Dni'] ?? "";
                  deEmailNoti = data['Email'] ?? "";
                  estadoNoti = data['Estado'] ?? "";
                  fechaNoti = data['Fecha'] ?? "";
                  horaNoti = data['Hora'] ?? "";
                  leido = (data['Leida'] ?? {})[uidUser] ?? false;
                }

                fechaNotiTime = DateFormat("dd-MM-yyyy").parse(fechaNoti);

                // 🔹 Parsear fecha
                final partesFecha = fechaNoti.split('-');
                final dia = int.tryParse(partesFecha[0]) ?? 1;
                final mes = int.tryParse(partesFecha[1]) ?? 1;
                final anio = int.tryParse(partesFecha[2]) ?? 2000;

                // 🔹 Parsear hora
                int hora = 0;
                int minuto = 0;
                if (horaNoti.contains(':')) {
                  final partesHora = horaNoti.split(':');
                  hora = int.tryParse(partesHora[0]) ?? 0;
                  minuto = int.tryParse(partesHora[1]) ?? 0;
                }

                final fechaFirebase = DateTime(anio, mes, dia, hora, minuto);
                textoTiempo = tiempoRelativo(fechaFirebase);

                switch (tipoNoti) {
                  case "Solicitud":
                    return soyElEmisor
                        ? widgetSolicitudEmisor(doc, data)
                        : widgetSolicitudReceptor(doc, data);
                  case "Movimiento":
                    return ingreso
                        ? widgetDineroRecibido(doc, data)
                        : widgetDineroEnviado(doc, data);
                  case "Solicitud Tarjeta":
                    return widgetSolicitudTarjeta(doc, data);
                  case "Tarjeta Activada":
                    return widgetTarjetaActivada(doc, data);
                  case "Tarjeta Cancelada":
                    return widgetTarjetaCancelada(doc, data);
                  case "Tarjeta Congelada":
                    return widgetTarjetaCongelada(doc, data);
                  case "Tarjeta Descongelada":
                    return widgetTarjetaDescongelada(doc, data);
                  case "Extension Creada":
                    return tipoExtensionNoti == "Virtual"
                        ? widgetExtensionCreada(doc, data)
                        : widgetTarjetaDescongelada(doc, data);
                  case "Extension Recibida":
                    return widgetExtensionRecibida(doc, data);
                  case "Limite Tarjeta Creado":
                    return widgetLimiteCreado(doc, data);
                  case "Limite Tarjeta Actualizado":
                    return widgetLimiteActualizado(doc, data);
                  case "Limite Tarjeta Eliminado":
                    return widgetLimiteEliminado(doc, data);
                  case "Solicitud Gasto Extension":
                    return widgetSolicitudGastoExtension(doc, data);
                  case "Gasto Virtual Extension":
                    return widgetGastoVirtualExtension(doc, data);
                  case "Umbral Tarjeta Creado":
                    return widgetUmbralCreado(doc, data);
                  case "Umbral Tarjeta Actualizado":
                    return widgetUmbralActualizado(doc, data);
                  case "Umbral Tarjeta Eliminado":
                    return widgetUmbralEliminado(doc, data);
                  case "Extension Cancelada":
                    return utilitario
                        ? widgetExtensionCanceladaUtilitario(doc, data)
                        : widgetExtensionCanceladaTitular(doc, data);
                  case "Extension Congelada":
                    return utilitario
                        ? widgetExtensionCongeladaUtilitario(doc, data)
                        : widgetExtensionCongeladaTitular(doc, data);
                  case "Extension Descongelada":
                    return utilitario
                        ? widgetExtensionDescongeladaUtilitario(doc, data)
                        : widgetExtensionDescongeladaTitular(doc, data);
                  case "Limite Extension Creado":
                    return utilitario
                        ? widgetExtensionLimiteCreadoUtilitario(doc, data)
                        : widgetExtensionLimiteCreadoTitular(doc, data);
                  case "Limite Extension Actualizado":
                    return utilitario
                        ? widgetExtensionLimiteActualizadoUtilitario(doc, data)
                        : widgetExtensionLimiteActualizadoTitular(doc, data);
                  case "Limite Extension Eliminado":
                    return utilitario
                        ? widgetExtensionLimiteEliminadoUtilitario(doc, data)
                        : widgetExtensionLimiteEliminadoTitular(doc, data);
                  case "Tutor Solicitado":
                    return widgetSolicitudTutor(doc, data);
                  case "Pupilo Aceptado":
                    return widgetPupiloAprobado(doc, data);
                  case "Registrado":
                    return widgetBienvenidaRegistro(doc, data);
                  default:
                    return ListTile(
                      leading: Icon(Icons.notifications, color: Colors.white60),
                      title: Text(
                        "Notificación Desconocida",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Poppins",
                          fontSize: sp(15),
                        ),
                      ),
                      subtitle: Text(
                        "Error al cargar notificación.",
                        style: TextStyle(
                          color: Colors.white60,
                          fontFamily: "Poppins",
                          fontSize: sp(13),
                        ),
                      ),
                    );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget widgetSolicitudEmisor(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Color.fromRGBO(33, 13, 243, 1),
                  width: leido ? 1 : 8, // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(33, 13, 243, 1).withOpacity(0.5),
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.messageSquare,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: Text(
                                    "Solicitud de pago\nenviada",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(150)),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      textoTiempo,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontFamily: "Poppins",
                                        fontSize: sp(13),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Le solicitaste",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontFamily: "Poppins",
                                        fontSize: sp(15),
                                      ),
                                    ),
                                    SizedBox(width: w(3)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(73),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: MoneyCounter(
                                          amount: montoNoti,
                                          showBalance: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: w(300),
                                  ), // límite para salto de línea
                                  child: Text(
                                    "a $paraNoti",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              //height: 100,
                              width: w(300),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: w(350),
                                    padding: EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent, // fondo oscuro
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.transparent,
                                        width: w(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: sp(23),
                                          backgroundColor: Colors.blue,
                                          child: Image.asset(AvatarEnviaNoti),
                                        ),
                                        SizedBox(width: w(13)),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: w(150),
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  paraNoti,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: sp(20),
                                                    fontFamily: "PoppinsBold",
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: h(3)),
                                            Row(
                                              children: [
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: w(150),
                                                  ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      "Solicitaste",
                                                      style: TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: sp(15),
                                                        fontFamily: "Poppins",
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: w(3)),
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: w(73),
                                                  ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: MoneyCounter(
                                                      amount: montoNoti,
                                                      showBalance: true,
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
                                  if (mensajeNoti != "") ...[
                                    SizedBox(height: h(13)),
                                    Container(
                                      width: w(223),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: w(0.1),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: w(13),
                                              top: h(13),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  LucideIcons.messageSquare,
                                                  color: Colors.white60,
                                                  size: sp(13),
                                                ),
                                                SizedBox(width: w(8)),
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: w(300),
                                                  ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      "Mensaje De Solicitud",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: sp(13),
                                                        fontFamily:
                                                            "PoppinsBold",
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: h(13)),
                                          Container(
                                            width: w(223),
                                            color: Colors.transparent,
                                            child: Center(
                                              child: Container(
                                                width: w(223),
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color.fromRGBO(
                                                    20,
                                                    25,
                                                    50,
                                                    1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(13),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth: w(300),
                                                    ),
                                                    child: Text(
                                                      mensajeNoti,
                                                      style: TextStyle(
                                                        color: Colors.white60,
                                                        fontFamily: "Poppins",
                                                        fontSize: sp(13),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: h(23)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: w(23),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: w(200),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              "Método: $metodoNoti",
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontFamily: "Poppins",
                                                fontSize: sp(13),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: (estadoNoti == "Pendiente"
                                                ? Color(
                                                    0xFFFFD700,
                                                  ).withOpacity(0.8)
                                                : (estadoNoti == "Aceptada"
                                                      ? Colors.green.shade600
                                                            .withOpacity(0.8)
                                                      : (estadoNoti ==
                                                                "Rechazada"
                                                            ? Colors.red
                                                                  .withOpacity(
                                                                    0.8,
                                                                  )
                                                            : Colors
                                                                  .transparent))),
                                            borderRadius: BorderRadius.circular(
                                              13,
                                            ),
                                          ),
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: w(150),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    estadoNoti,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "Poppins",
                                                      fontSize: sp(13),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: h(23)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetSolicitudReceptor(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: (estadoNoti == "Pendiente"
                      ? Color(0xFFFFD700)
                      : (estadoNoti == "Aceptada"
                            ? Colors.greenAccent.shade400
                            : (estadoNoti == "Rechazada"
                                  ? Colors.red
                                  : Colors.transparent))),
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: estadoNoti == "Pendiente"
                              ? LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700).withOpacity(0.5),
                                    Colors.yellow.shade600,
                                  ],
                                )
                              : estadoNoti == "Aceptada"
                              ? LinearGradient(
                                  colors: [
                                    Color.fromRGBO(1, 165, 113, 1),
                                    Colors.green.shade600,
                                  ],
                                )
                              : estadoNoti == "Rechazada"
                              ? LinearGradient(
                                  colors: [Colors.red, Colors.red.shade600],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.banknote,
                          color: Colors.white,
                          size: sp(20),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (estadoNoti == "Pendiente"
                                      ? "Solicitud de pago\nrecibida"
                                      : (estadoNoti == "Aceptada"
                                            ? "Solicitud de pago\naceptada"
                                            : (estadoNoti == "Rechazada"
                                                  ? "Solicitud de pago\nrechazada"
                                                  : "Solicitud de pago"))),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Primera línea: NOMBRE (se ajusta y hace wrap si es necesario)
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(200)),
                                  child: Text(
                                    deNoti,
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "PoppinsBold",
                                      fontSize: sp(15),
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),

                                SizedBox(height: h(4)),

                                // Segunda línea: "Te solicita" + MONTO (monto al lado derecho del texto)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      (estadoNoti == "Pendiente"
                                          ? "te solicita"
                                          : "te solicitó"),
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontFamily: "Poppins",
                                        fontSize: sp(15),
                                      ),
                                    ),
                                    SizedBox(width: w(6)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(73),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: MoneyCounter(
                                          amount: montoNoti,
                                          showBalance: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              //height: 100,
                              width: w(350),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: w(350),
                                    padding: EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent, // fondo oscuro
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.transparent,
                                        width: w(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: sp(23),
                                          backgroundColor: Colors.blue,
                                          child: Image.asset(AvatarRecibeNoti),
                                        ),
                                        SizedBox(width: w(13)),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: w(143),
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  deNoti,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: sp(20),
                                                    fontFamily: "PoppinsBold",
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: h(3)),
                                            Row(
                                              children: [
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: w(183),
                                                  ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      (estadoNoti == "Pendiente"
                                                          ? "Solicita"
                                                          : "Solicito"),
                                                      style: TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: sp(15),
                                                        fontFamily: "Poppins",
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: w(3)),
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: w(73),
                                                  ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: MoneyCounter(
                                                      amount: montoNoti,
                                                      showBalance: true,
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
                                  if (mensajeNoti != "") ...[
                                    SizedBox(height: h(13)),
                                    Container(
                                      width: w(200),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: w(0.1),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: w(13),
                                              top: h(13),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  LucideIcons.messageSquare,
                                                  color: Colors.white60,
                                                  size: sp(13),
                                                ),
                                                SizedBox(width: w(8)),
                                                Text(
                                                  "Mensaje De Solicitud",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: sp(13),
                                                    fontFamily: "PoppinsBold",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: h(13)),
                                          Container(
                                            width: w(200),
                                            color: Colors.transparent,
                                            child: Center(
                                              child: Container(
                                                width: w(200),
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color.fromRGBO(
                                                    20,
                                                    25,
                                                    50,
                                                    1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(13),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  child: Text(
                                                    mensajeNoti,
                                                    style: TextStyle(
                                                      color: Colors.white60,
                                                      fontFamily: "Poppins",
                                                      fontSize: sp(13),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: h(23)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: w(23),
                                    ),
                                    child: Row(
                                      children: [
                                        // Texto del método
                                        Expanded(
                                          child: Text(
                                            "Método: $metodoNoti",
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontFamily: "Poppins",
                                              fontSize: sp(13),
                                            ),
                                            overflow: TextOverflow
                                                .clip, // evita overflow
                                          ),
                                        ),
                                        SizedBox(
                                          width: w(8),
                                        ), // espacio entre texto y container
                                        // Container del estado
                                        Container(
                                          //width: 63,
                                          //height: 28,
                                          decoration: BoxDecoration(
                                            color: (estadoNoti == "Pendiente"
                                                ? Color(
                                                    0xFFFFD700,
                                                  ).withOpacity(0.8)
                                                : (estadoNoti == "Aceptada"
                                                      ? Colors.green.shade600
                                                            .withOpacity(0.8)
                                                      : (estadoNoti ==
                                                                "Rechazada"
                                                            ? Colors.red
                                                                  .withOpacity(
                                                                    0.8,
                                                                  )
                                                            : Colors
                                                                  .transparent))),
                                            borderRadius: BorderRadius.circular(
                                              13,
                                            ),
                                          ),
                                          child: Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(10),
                                              child: Text(
                                                estadoNoti,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: "Poppins",
                                                  fontSize: sp(13),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: h(23)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (estadoNoti == "Pendiente") ...[
                    SizedBox(height: h(23)),
                    Padding(
                      padding: EdgeInsets.only(left: w(23)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            child: Container(
                              height: h(33),
                              width: w(100),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(1, 165, 113, 1),
                                    Colors.green.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    (saldoUser < montoNoti
                                        ? "Sin Fondos"
                                        : "Aceptar"),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Poppins",
                                      fontSize: (saldoUser < montoNoti
                                          ? 12.3
                                          : 13),
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _iconAnimation,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(_iconAnimation.value, 0),
                                        child: child,
                                      );
                                    },
                                    child: Icon(
                                      (saldoUser < montoNoti
                                          ? LucideIcons.circleDollarSign
                                          : LucideIcons.check),
                                      color: Colors.white,
                                      size: (saldoUser < montoNoti ? 15 : 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              if (saldoUser >= montoNoti) {
                                indexNoti = doc.id;
                                montoNoti = (data['Monto'] ?? 0).toDouble();
                                reciboIDNoti = data["ID Recibo"] ?? 0;
                                reciboIDNoti = data["ID Recibo"] ?? 0;
                                deUidNoti = data["De uid"] ?? "";
                                paraUidNoti = data["Para uid"] ?? "";
                                aceptarSolicitud();
                                crearNotificacionMovimiento();
                              }
                            },
                          ),
                          GestureDetector(
                            child: Container(
                              height: h(33),
                              width: w(100),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "Rechazar",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontFamily: "Poppins",
                                      fontSize: sp(13),
                                    ),
                                  ),
                                  Icon(
                                    LucideIcons.x,
                                    color: Colors.redAccent,
                                    size: sp(18),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              indexNoti = doc.id;
                              montoNoti = (data['Monto'] ?? 0).toDouble();
                              reciboIDNoti = data["ID Recibo"] ?? 0;
                              deUidNoti = data["De uid"] ?? "";
                              paraUidNoti = data["Para uid"] ?? "";
                              rechazarSolicitud();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetDineroRecibido(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Color.fromRGBO(1, 165, 113, 1),
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(1, 165, 113, 1).withOpacity(0.5),
                              Colors.green.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.arrowUpRight,
                          color: Colors.white,
                          size: sp(20),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Dinero Recibido",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Recibiste",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontFamily: "Poppins",
                                        fontSize: sp(15),
                                      ),
                                    ),

                                    SizedBox(width: w(3)),

                                    // Monto: ocupa menos espacio relativo
                                    Flexible(
                                      flex: 2, // 👈 antes 1
                                      fit: FlexFit.loose,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: MoneyCounter(
                                          amount: montoNoti,
                                          showBalance: true,
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: w(3)),

                                    // Texto final: ocupa MÁS espacio
                                    Expanded(
                                      flex:
                                          5, // 👈 más ancho para evitar ellipsis rápido
                                      child: Text(
                                        "de $deNoti.",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontFamily: "Poppins",
                                          fontSize: sp(15),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              //height: 100,
                              width: w(233),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: h(23)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: w(23),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: w(183),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              "Método: $metodoNoti",
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontFamily: "Poppins",
                                                fontSize: sp(13),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: h(23)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetDineroEnviado(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.red,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withOpacity(0.5),
                              Colors.red.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.arrowDownLeft,
                          color: Colors.white,
                          size: sp(20),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Dinero Enviado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Enviaste",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontFamily: "Poppins",
                                        fontSize: sp(15),
                                      ),
                                    ),
                                    SizedBox(width: w(3)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(73),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: MoneyCounter(
                                          amount: montoNoti,
                                          showBalance: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: w(300),
                                  ), // o el ancho que quieras
                                  child: Text(
                                    medioPagoNoti == "Cuenta"
                                        ? "a $paraNoti."
                                        : medioPagoNoti == "Tarjeta"
                                        ? "a $paraNoti con tu tarjeta."
                                        : "a $paraNoti con tu extensión.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              //height: 100,
                              width: w(233),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: h(23)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: w(23),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: w(183),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              "Método: $metodoNoti",
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontFamily: "Poppins",
                                                fontSize: sp(13),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (medioPagoNoti == "Extension") ...[
                                    SizedBox(height: h(13)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: w(23),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(183),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "Extensión: $nombreExtensionNoti",
                                                style: TextStyle(
                                                  color: Colors.white60,
                                                  fontFamily: "Poppins",
                                                  fontSize: sp(13),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  SizedBox(height: h(23)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetSolicitudTarjeta(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(color: Colors.cyan, width: leido ? 1 : 8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyan.withOpacity(0.5),
                              Colors.cyanAccent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.banknote,
                          color: Colors.white,
                          size: sp(20),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: Text(
                                    (estadoSolicitudTarjeta != "Entregada"
                                        ? "Tarjeta fisica\nsolicitada"
                                        : "Tarjeta fisica\nentregada"),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(150)),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      textoTiempo,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontFamily: "Poppins",
                                        fontSize: sp(13),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (estadoSolicitudTarjeta == "Entregada"
                                      ? "Tu tarjeta física prepaga fue entregada."
                                      : (estadoSolicitudTarjeta == "Solicitada"
                                            ? "Tu tarjeta física prepaga fue solicitada."
                                            : "Tu tarjeta física prepaga está\n${estadoSolicitudTarjeta}.")),
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              //height: 100,
                              width: w(300),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            LucideIcons.package,
                                            color: Colors.cyan,
                                            size: 15,
                                          ),
                                          SizedBox(width: w(5)),
                                          Text(
                                            "Estado del envio",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: "Poppins",
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          height: h(23),
                                          width: 100,
                                          decoration: BoxDecoration(
                                            color:
                                                (estadoSolicitudTarjeta ==
                                                    "Solicitada"
                                                ? Color(
                                                    0xFFFFD700,
                                                  ).withOpacity(0.5)
                                                : (estadoSolicitudTarjeta ==
                                                          "Entregada"
                                                      ? Colors.green.shade600
                                                            .withOpacity(0.5)
                                                      : (estadoSolicitudTarjeta ==
                                                                "Cancelada"
                                                            ? Colors.red
                                                                  .withOpacity(
                                                                    0.5,
                                                                  )
                                                            : (estadoSolicitudTarjeta ==
                                                                      "En Camino"
                                                                  ? Colors.cyan
                                                                        .withOpacity(
                                                                          0.5,
                                                                        )
                                                                  : (estadoSolicitudTarjeta ==
                                                                            "En Preparacion"
                                                                        ? Colors
                                                                              .purple
                                                                        : Colors
                                                                              .transparent))))),
                                            borderRadius: BorderRadius.circular(
                                              13,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              estadoSolicitudTarjeta,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: "Poppins",
                                                fontSize: 11.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h(13)),
                                    Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            LucideIcons.calendar,
                                            color: Colors.cyan,
                                            size: 13,
                                          ),
                                          SizedBox(width: w(5)),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Fecha de solicitud",
                                                style: TextStyle(
                                                  color: Colors.white60,
                                                  fontFamily: "Poppins",
                                                  fontSize: 13,
                                                ),
                                              ),
                                              SizedBox(height: w(3)),
                                              Text(
                                                fechaSolicitudTarjeta,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: "Poppins",
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: h(18)),
                                    Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            LucideIcons.mapPin,
                                            color: Colors.cyan,
                                            size: 13,
                                          ),
                                          SizedBox(width: w(5)),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Dirección de envío",
                                                  style: TextStyle(
                                                    color: Colors.white60,
                                                    fontFamily: "Poppins",
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                SizedBox(height: w(3)),
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: w(218),
                                                  ),
                                                  child: Text(
                                                    direccionSolicitudTarjeta,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "Poppins",
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: h(18)),
                                    Padding(
                                      padding: EdgeInsets.only(left: w(8)),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.local_shipping_outlined,
                                            color: Colors.cyan,
                                            size: 13,
                                          ),
                                          SizedBox(width: w(5)),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (estadoSolicitudTarjeta !=
                                                        "Entregada"
                                                    ? "Entrega estimada"
                                                    : "Entregada"),
                                                style: TextStyle(
                                                  color: Colors.white60,
                                                  fontFamily: "Poppins",
                                                  fontSize: 13,
                                                ),
                                              ),
                                              SizedBox(height: w(3)),
                                              ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: w(300),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    (estadoSolicitudTarjeta !=
                                                            "Entregada"
                                                        ? entregaEstimadaSolicitudaTarjeta
                                                        : fechaEntregada),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "Poppins",
                                                      fontSize: 13,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: h(13)),
                                    Divider(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    Container(
                                      height: 33,
                                      width: double.infinity,
                                      color: Colors.transparent,
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            // ETAPA 1 - Activa
                                            Container(
                                              height: 25,
                                              width: 25,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF00D5E2),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Color(0xFF00D5E2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                (estadoSolicitudTarjeta ==
                                                        "Solicitada"
                                                    ? LucideIcons.inbox
                                                    : LucideIcons.check),
                                                color: Colors.white,
                                                size: 13,
                                              ),
                                            ),

                                            // LÍNEA 1
                                            Expanded(
                                              child: Container(
                                                height: 1,
                                                color:
                                                    (estadoSolicitudTarjeta ==
                                                            "En Preparacion" ||
                                                        estadoSolicitudTarjeta ==
                                                            "En Camino" ||
                                                        estadoSolicitudTarjeta ==
                                                            "Entregada"
                                                    ? Colors.cyan
                                                    : Colors.white.withOpacity(
                                                        0.15,
                                                      )),
                                              ),
                                            ),

                                            // ETAPA 2 - Inactiva
                                            Container(
                                              height: 25,
                                              width: 25,
                                              decoration: BoxDecoration(
                                                color:
                                                    (estadoSolicitudTarjeta ==
                                                            "En Preparacion" ||
                                                        estadoSolicitudTarjeta ==
                                                            "En Camino" ||
                                                        estadoSolicitudTarjeta ==
                                                            "Entregada"
                                                    ? Color(0xFF00D5E2)
                                                    : Colors.transparent),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      (estadoSolicitudTarjeta ==
                                                              "En Preparacion" ||
                                                          estadoSolicitudTarjeta ==
                                                              "En Camino" ||
                                                          estadoSolicitudTarjeta ==
                                                              "Entregada"
                                                      ? Color(0xFF00D5E2)
                                                      : Colors.white24),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                (estadoSolicitudTarjeta ==
                                                            "Solicitada" ||
                                                        estadoSolicitudTarjeta ==
                                                            "En Preparacion"
                                                    ? Icons.inventory_2_rounded
                                                    : LucideIcons.check),
                                                color:
                                                    (estadoSolicitudTarjeta ==
                                                            "En Preparacion" ||
                                                        estadoSolicitudTarjeta ==
                                                            "En Camino" ||
                                                        estadoSolicitudTarjeta ==
                                                            "Entregada"
                                                    ? Colors.white
                                                    : Colors.white.withOpacity(
                                                        0.3,
                                                      )),
                                                size: 13,
                                              ),
                                            ),

                                            // LÍNEA 2
                                            Expanded(
                                              child: Container(
                                                height: 1,
                                                color:
                                                    (estadoSolicitudTarjeta ==
                                                            "En Camino" ||
                                                        estadoSolicitudTarjeta ==
                                                            "Entregada"
                                                    ? Colors.cyan
                                                    : Colors.white.withOpacity(
                                                        0.15,
                                                      )),
                                              ),
                                            ),

                                            // ETAPA 3 - Inactiva
                                            Container(
                                              height: 25,
                                              width: 25,
                                              decoration: BoxDecoration(
                                                color:
                                                    (estadoSolicitudTarjeta ==
                                                            "En Camino" ||
                                                        estadoSolicitudTarjeta ==
                                                            "Entregada"
                                                    ? Color(0xFF00D5E2)
                                                    : Colors.transparent),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      (estadoSolicitudTarjeta ==
                                                              "En Camino" ||
                                                          estadoSolicitudTarjeta ==
                                                              "Entregada"
                                                      ? Color(0xFF00D5E2)
                                                      : Colors.white24),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                (estadoSolicitudTarjeta ==
                                                        "Entregada"
                                                    ? LucideIcons.check
                                                    : Icons
                                                          .local_shipping_outlined),
                                                color:
                                                    (estadoSolicitudTarjeta ==
                                                            "En Camino" ||
                                                        estadoSolicitudTarjeta ==
                                                            "Entregada"
                                                    ? Colors.white
                                                    : Colors.white.withOpacity(
                                                        0.3,
                                                      )),
                                                size: 13,
                                              ),
                                            ),

                                            // LÍNEA 3
                                            Expanded(
                                              child: Container(
                                                height: 1,
                                                color:
                                                    (estadoSolicitudTarjeta ==
                                                        "Entregada"
                                                    ? Colors.cyan
                                                    : Colors.white.withOpacity(
                                                        0.15,
                                                      )),
                                              ),
                                            ),

                                            // ETAPA 4 - Inactiva
                                            Container(
                                              height: 25,
                                              width: 25,
                                              decoration: BoxDecoration(
                                                color:
                                                    (estadoSolicitudTarjeta ==
                                                        "Entregada"
                                                    ? Color(0xFF00D5E2)
                                                    : Colors.transparent),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      (estadoSolicitudTarjeta ==
                                                          "Entregada"
                                                      ? Color(0xFF00D5E2)
                                                      : Colors.white24),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.check_circle_outline,
                                                color:
                                                    (estadoSolicitudTarjeta ==
                                                        "Entregada"
                                                    ? Colors.white
                                                    : Colors.white.withOpacity(
                                                        0.3,
                                                      )),
                                                size: 13,
                                              ),
                                            ),
                                          ],
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
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetTarjetaActivada(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.orange,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withOpacity(0.5),
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.credit_score,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "¡Tarjeta Activada!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$deNoti, ",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                SizedBox(width: w(3)),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: Text(
                                    "tu tarjeta está lista para usar.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF21C16B),
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Activada",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Ya puedes usar tu tarjeta en todos los comercios adheridos.",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetTarjetaCancelada(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Color.fromRGBO(208, 0, 0, 1),
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(208, 0, 0, 1),
                              Colors.red.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.xCircle,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Tarjeta Cancelada",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$deNoti, ",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                SizedBox(width: w(3)),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: Text(
                                    "Tu tarjeta ha sido cancelada.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.xCircle,
                                        color: Color.fromRGBO(208, 0, 0, 1),
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Cancelada",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu tarjeta ha sido cancelada el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  if (motivoNoti != "") ...[
                                    SizedBox(height: h(13)),
                                    Divider(
                                      color: Colors.white60,
                                      height: h(1),
                                    ),
                                    SizedBox(height: h(13)),
                                    Text(
                                      "Motivo:",
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white60,
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    Text(
                                      motivoNoti,
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetTarjetaCongelada(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Color.fromRGBO(33, 13, 243, 1),
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(33, 13, 243, 1),
                              Colors.blue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.snowflake,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Tarjeta Congelada",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Tu tarjeta ha sido congelada.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.snowflake,
                                        color: Color.fromRGBO(33, 13, 243, 1),
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Congelada",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu tarjeta ha sido congelada el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  if (motivoNoti != "") ...[
                                    SizedBox(height: h(13)),
                                    Divider(
                                      color: Colors.white60,
                                      height: h(1),
                                    ),
                                    SizedBox(height: h(13)),
                                    Text(
                                      "Motivo:",
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white60,
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    Text(
                                      motivoNoti,
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetTarjetaDescongelada(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.teal,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal, Colors.tealAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.flame,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Tarjeta Descongelada",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Tu tarjeta ha sido descongelada.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.flame,
                                        color: Colors.teal,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Descongelada",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu tarjeta ha sido descongelada el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  if (motivoNoti != "") ...[
                                    SizedBox(height: h(13)),
                                    Divider(
                                      color: Colors.white60,
                                      height: h(1),
                                    ),
                                    SizedBox(height: h(13)),
                                    Text(
                                      "Motivo:",
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white60,
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    Text(
                                      motivoNoti,
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionCreada(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.pinkAccent,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink, Colors.pinkAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.link,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Extensión Creada",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Has creado una nueva extensión para $paraNoti",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.link,
                                        color: Colors.pinkAccent,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Extensión $nombreExtensionNoti",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Tipo:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    tipoExtensionNoti,
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Limite:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    limiteExtensionNoti == "Sin Limite"
                                        ? "Sin Limite"
                                        : "\$" +
                                              formatMoney(
                                                double.parse(
                                                  limiteExtensionNoti,
                                                ),
                                              ),
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Vencimiento:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    vencimientoExtensionNoti,
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Verificacion:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    verificacionExtensionNoti == true
                                        ? "Activada"
                                        : "Desactivada",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Destinatario:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(8)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: sp(15),
                                        backgroundColor: Colors.green,
                                        child: Image.asset(
                                          avatarParaExtensionNoti,
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
                                            paraNoti,
                                            style: TextStyle(
                                              fontSize: sp(13),
                                              fontFamily: "Poppins",
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: h(3)),
                                          Text(
                                            paraDniNoti,
                                            style: TextStyle(
                                              fontSize: sp(11.8),
                                              fontFamily: "Poppins",
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
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionRecibida(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.brown,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.brown.shade800, Colors.brown],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_link,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Extensión Recibida",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "$deNoti te asigno una extension de su tarjeta.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.add_link,
                                        color: Colors.brown,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Extensión $nombreExtensionNoti",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Tipo:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    tipoExtensionNoti,
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Limite:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    limiteExtensionNoti == "Sin Limite"
                                        ? limiteExtensionNoti
                                        : "\$" +
                                              formatMoney(
                                                double.parse(
                                                  limiteExtensionNoti,
                                                ),
                                              ),
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Vencimiento:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    vencimientoExtensionNoti,
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Verificacion:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    verificacionExtensionNoti == true
                                        ? "Activada"
                                        : "Desactivada",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Propietario:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(8)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: sp(15),
                                        backgroundColor: Colors.green,
                                        child: Image.asset(
                                          avatarDeExtensionNoti,
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
                                            deNoti,
                                            style: TextStyle(
                                              fontSize: sp(13),
                                              fontFamily: "Poppins",
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: h(3)),
                                          Text(
                                            deDniNoti,
                                            style: TextStyle(
                                              fontSize: sp(11.8),
                                              fontFamily: "Poppins",
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
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetGastoVirtualExtension(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.blueGrey,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blueGrey, Colors.grey],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.payments,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Pago Extensión",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "$deNoti realizó un gasto con tu extensión.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.payments,
                                        color: Colors.blueGrey,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Transferencia #$reciboIDNoti",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Fecha:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    "${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Monto:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    "\$" + formatMoney(montoNoti),
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  if (limiteExtensionNoti != "Sin Limite") ...[
                                    Divider(
                                      color: Colors.white60,
                                      height: h(1),
                                    ),
                                    SizedBox(height: h(13)),
                                    Text(
                                      limiteExtensionNoti == "Sin Limite"
                                          ? "Sin Limite"
                                          : "Limite Restante",
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white60,
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    Text(
                                      limiteExtensionNoti == "Sin Limite"
                                          ? "Sin Limite"
                                          : limiteRestanteExtension == 0
                                          ? "Limite Alcanzado"
                                          : "\$" +
                                                formatMoney(
                                                  limiteRestanteExtension,
                                                ),
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: h(13)),
                                  ],
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Destinatario:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    paraNoti,
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Utilizada Por:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(8)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: sp(15),
                                        backgroundColor: Colors.green,
                                        child: Image.asset(AvatarEnviaNoti),
                                      ),
                                      SizedBox(width: w(8)),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            deNoti,
                                            style: TextStyle(
                                              fontSize: sp(13),
                                              fontFamily: "Poppins",
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: h(3)),
                                          Text(
                                            deDniNoti,
                                            style: TextStyle(
                                              fontSize: sp(11.8),
                                              fontFamily: "Poppins",
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
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetLimiteCreado(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.indigo,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.indigoAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Limite Creado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Estableciste un limite de gasto a tu tarjeta.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.lock,
                                        color: Colors.indigo,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Limite Creado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu tarjeta ha sido limitada a \$${formatMoney(limiteNoti)} el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetLimiteActualizado(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.indigo,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.indigoAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Limite Actualizado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Actualizaste el limite de gasto de tu tarjeta.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.lock,
                                        color: Colors.indigo,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Limite Actualizado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "El limite de tu tarjeta ha sido actualizado a \$${formatMoney(limiteNoti)} el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  if (motivoNoti != "") ...[
                                    SizedBox(height: h(13)),
                                    Divider(
                                      color: Colors.white60,
                                      height: h(1),
                                    ),
                                    SizedBox(height: h(13)),
                                    Text(
                                      "Motivo:",
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white60,
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    Text(
                                      "a",
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetLimiteEliminado(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.indigo,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.indigoAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Limite Eliminado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Eliminaste el limite de gasto de tu tarjeta.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        color: Colors.indigo,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Limite Eliminado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "El limite de tu tarjeta ha sido eliminado el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetUmbralCreado(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.purple,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.purpleAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.gauge,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Umbral Activado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Estableciste un umbral seguro a tu tarjeta.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.gauge,
                                        color: Colors.purpleAccent,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Umbral Activado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu umbral de \$${formatMoney(umbralNoti)} ha sido activado el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Accion:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    accionUmbralNoti,
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetUmbralActualizado(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.purple,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.purpleAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.gauge,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Umbral Actualizado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Actualizaste el umbral seguro de tu tarjeta.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.gauge,
                                        color: Colors.purpleAccent,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Umbral Actualizado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu umbral de \$${formatMoney(umbralNoti)} ha sido actualizado el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Accion:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    accionUmbralNoti,
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetUmbralEliminado(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.purple,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.purpleAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.gauge,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Umbral Eliminado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Eliminaste el umbral seguro de tu tarjeta.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.gauge,
                                        color: Colors.purpleAccent,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Umbral Eliminado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu umbral de \$${formatMoney(umbralNoti)} fue eliminado el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Accion:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    accionUmbralNoti,
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetSolicitudGastoExtension(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: (estadoNoti == "Pendiente"
                      ? Color(0xFFFFD700)
                      : (estadoNoti == "Pago"
                            ? Colors.greenAccent.shade400
                            : (estadoNoti == "Rechazada"
                                  ? Colors.red
                                  : Colors.transparent))),
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: estadoNoti == "Pendiente"
                              ? LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700).withOpacity(0.5),
                                    Colors.yellow.shade600,
                                  ],
                                )
                              : estadoNoti == "Pago"
                              ? LinearGradient(
                                  colors: [
                                    Color.fromRGBO(1, 165, 113, 1),
                                    Colors.green.shade600,
                                  ],
                                )
                              : estadoNoti == "Rechazada"
                              ? LinearGradient(
                                  colors: [Colors.red, Colors.red.shade600],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.banknote,
                          color: Colors.white,
                          size: sp(20),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (estadoNoti == "Pendiente"
                                      ? "Solicitud de gasto\nrecibida"
                                      : (estadoNoti == "Pago"
                                            ? "Solicitud de gasto\naceptada"
                                            : (estadoNoti == "Rechazada"
                                                  ? "Solicitud de gasto\nrechazada"
                                                  : "Solicitud de gasto"))),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(350)),
                              child: Text(
                                estadoNoti == "Pendiente"
                                    ? "$deNoti te solicita una aprobacion para su extension."
                                    : "$deNoti te solicitó una aprobacion para su extension.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "PoppinsBold",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.payments,
                                        color: Colors.blueGrey,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Solicitud #$reciboIDNoti",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Fecha:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    "${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Monto:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    "\$" + formatMoney(montoNoti),
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),

                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Extension:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(5)),
                                  Text(
                                    nombreExtensionNoti,
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: h(13)),
                                  Divider(color: Colors.white60, height: h(1)),
                                  SizedBox(height: h(13)),
                                  Text(
                                    "Solcitado Por:",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      fontFamily: "Poppins",
                                      color: Colors.white60,
                                    ),
                                  ),
                                  SizedBox(height: h(8)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: sp(15),
                                        backgroundColor: Colors.green,
                                        child: Image.asset(AvatarEnviaNoti),
                                      ),
                                      SizedBox(width: w(8)),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            deNoti,
                                            style: TextStyle(
                                              fontSize: sp(13),
                                              fontFamily: "Poppins",
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: h(3)),
                                          Text(
                                            deDniNoti,
                                            style: TextStyle(
                                              fontSize: sp(11.8),
                                              fontFamily: "Poppins",
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
                    ],
                  ),
                  if (estadoNoti == "Pendiente") ...[
                    SizedBox(height: h(23)),
                    Padding(
                      padding: EdgeInsets.only(left: w(23)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            child: Container(
                              height: h(33),
                              width: w(100),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(1, 165, 113, 1),
                                    Colors.green.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    (saldoUser < montoNoti
                                        ? "Sin Fondos"
                                        : "Aceptar"),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Poppins",
                                      fontSize: (saldoUser < montoNoti
                                          ? 12.3
                                          : 13),
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _iconAnimation,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(_iconAnimation.value, 0),
                                        child: child,
                                      );
                                    },
                                    child: Icon(
                                      (saldoUser < montoNoti
                                          ? LucideIcons.circleDollarSign
                                          : LucideIcons.check),
                                      color: Colors.white,
                                      size: (saldoUser < montoNoti ? 15 : 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              if (saldoUser >= montoNoti) {
                                indexNoti = doc.id;
                                montoNoti = (data['Monto'] ?? 0).toDouble();
                                reciboIDNoti = data["ID Recibo"] ?? 0;
                                deUidNoti = data["De uid"] ?? "";
                                aceptarSolicitudGastoExtension(reciboIDNoti);
                              }
                            },
                          ),
                          GestureDetector(
                            child: Container(
                              height: h(33),
                              width: w(100),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "Rechazar",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontFamily: "Poppins",
                                      fontSize: sp(13),
                                    ),
                                  ),
                                  Icon(
                                    LucideIcons.x,
                                    color: Colors.redAccent,
                                    size: sp(18),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              indexNoti = doc.id;
                              montoNoti = (data['Monto'] ?? 0).toDouble();
                              reciboIDNoti = data["ID Recibo"] ?? 0;
                              deUidNoti = data["De uid"] ?? "";
                              rechazarSolicitudGastoExtension(reciboIDNoti);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionCanceladaTitular(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Color.fromRGBO(208, 0, 0, 1),
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(208, 0, 0, 1),
                              Colors.red.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.xCircle,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Extensión Cancelada",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: Text(
                                    "$deNoti, tu extensión $nombreExtensionNoti ha sido cancelada.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.xCircle,
                                        color: Color.fromRGBO(208, 0, 0, 1),
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Cancelada",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu extensión ha sido cancelada el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  if (motivoNoti != "") ...[
                                    SizedBox(height: h(13)),
                                    Divider(
                                      color: Colors.white60,
                                      height: h(1),
                                    ),
                                    SizedBox(height: h(13)),
                                    Text(
                                      "Motivo:",
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white60,
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    Text(
                                      motivoNoti,
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionCanceladaUtilitario(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Color.fromRGBO(208, 0, 0, 1),
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(208, 0, 0, 1),
                              Colors.red.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.xCircle,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Extensión Cancelada",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: Text(
                                    "$deNoti cancelo su extension $nombreExtensionNoti.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.xCircle,
                                        color: Color.fromRGBO(208, 0, 0, 1),
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Cancelada",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu extensión recibida ha sido cancelada el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionCongeladaTitular(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Color.fromRGBO(33, 13, 243, 1),
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(33, 13, 243, 1),
                              Colors.blue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.snowflake,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Extensión Congelada",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: Text(
                                    "$deNoti, tu extensión $nombreExtensionNoti ha sido congelada.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.snowflake,
                                        color: Color.fromRGBO(33, 13, 243, 1),
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Congelada",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu extensión ha sido congelada el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  if (motivoNoti != "") ...[
                                    SizedBox(height: h(13)),
                                    Divider(
                                      color: Colors.white60,
                                      height: h(1),
                                    ),
                                    SizedBox(height: h(13)),
                                    Text(
                                      "Motivo:",
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white60,
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    Text(
                                      motivoNoti,
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionCongeladaUtilitario(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Color.fromRGBO(33, 13, 243, 1),
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(33, 13, 243, 1),
                              Colors.blue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.snowflake,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Extensión Congelada",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: Text(
                                    "$deNoti congeló su extension $nombreExtensionNoti.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.snowflake,
                                        color: Color.fromRGBO(33, 13, 243, 1),
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Congelada",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu extensión recibida ha sido congelada el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionDescongeladaTitular(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.teal,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal, Colors.tealAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.flame,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Extensión Descongelada",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: Text(
                                    "$deNoti, tu extensión $nombreExtensionNoti ha sido descongelada.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.flame,
                                        color: Colors.teal,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Descongelada",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu extensión ha sido descongelada el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  if (motivoNoti != "") ...[
                                    SizedBox(height: h(13)),
                                    Divider(
                                      color: Colors.white60,
                                      height: h(1),
                                    ),
                                    SizedBox(height: h(13)),
                                    Text(
                                      "Motivo:",
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white60,
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    Text(
                                      motivoNoti,
                                      style: TextStyle(
                                        fontSize: sp(13),
                                        fontFamily: "Poppins",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionDescongeladaUtilitario(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.teal,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal, Colors.tealAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.flame,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Extensión Descongelada",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: Text(
                                    "$deNoti descongeló su extension $nombreExtensionNoti.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.flame,
                                        color: Colors.teal,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Descongelada",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu extensión recibida ha sido descongelada el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionLimiteCreadoTitular(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.indigo,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.indigoAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Limite Creado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Estableciste un limite de gasto a tu extensión $nombreExtensionNoti.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.lock,
                                        color: Colors.indigo,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Limite Creado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "Tu extensión ha sido limitada a \$${formatMoney(limiteNoti)} el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionLimiteCreadoUtilitario(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.indigo,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.indigoAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Limite Creado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "$deNoti establecio un limite de gasto a la extensión $nombreExtensionNoti.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.lock,
                                        color: Colors.indigo,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Limite Creado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "La extensión ha sido limitada a \$${formatMoney(limiteNoti)} el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionLimiteActualizadoTitular(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.indigo,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.indigoAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Limite Actualizado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Actualizaste el limite de gasto de tu extensión $nombreExtensionNoti.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.lock,
                                        color: Colors.indigo,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Limite Actualizado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "El limite de tu extensión ha sido actualizado a \$${formatMoney(limiteNoti)} el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionLimiteActualizadoUtilitario(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.indigo,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.indigoAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Limite Actualizado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "$deNoti actualizo el limite de la extension $nombreExtensionNoti",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.lock,
                                        color: Colors.indigo,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Limite Actualizado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "El limite de la extensión ha sido actualizado a \$${formatMoney(limiteNoti)} el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionLimiteEliminadoTitular(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.indigo,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.indigoAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Limite Eliminado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "Eliminaste el limite de gasto de tu extensión $nombreExtensionNoti.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        color: Colors.indigo,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Limite Eliminado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "El limite de tu extensión ha sido eliminado el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetExtensionLimiteEliminadoUtilitario(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(1),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() {
                  indexNoti = doc.id;
                });
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    indexNoti = doc.id;
                  });
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,

                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: Colors.indigo,
                  width: leido ? w(1) : w(8), // 🔹 se achica hasta desaparecer
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.indigoAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        // <--- esto asegura que el texto largo no desborde
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Limite Eliminado",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                "$deNoti elimino el limite de gasto de la extensión $nombreExtensionNoti.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(15),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: h(23)),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(sp(13)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        color: Colors.indigo,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: h(8)),
                                      Text(
                                        "Limite Eliminado",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h(8)),
                                  Text(
                                    "El limite de la extensión ha sido eliminado el ${fechaNoti.replaceAll("-", "/")} a las $horaNoti\hs",
                                    style: TextStyle(
                                      fontSize: sp(13),
                                      height: h(2),
                                      fontFamily: "Poppins",
                                      color: Colors.white.withOpacity(0.8),
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
                  if (leido == false) ...[
                    GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leido",
                              style: TextStyle(
                                color: Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
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

  Widget widgetSolicitudTutor(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: (estadoNoti != "Espera"),
          key: ValueKey(doc.id),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) {
                  Vibration.vibrate(duration: 15);
                  setState(() => indexNoti = doc.id);
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,
                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: doc["Estado"] == "Espera"
                      ? Colors.teal
                      : doc["Estado"] == "Rechazado"
                      ? Colors.red
                      : Color.fromRGBO(1, 165, 113, 1),
                  width: leido ? w(1) : w(8),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: doc["Estado"] == "Espera"
                              ? LinearGradient(
                                  colors: [Colors.teal, Colors.tealAccent],
                                )
                              : doc["Estado"] == "Rechazado"
                              ? LinearGradient(
                                  colors: [
                                    Colors.red.withOpacity(0.5),
                                    Colors.red.shade600,
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Color.fromRGBO(
                                      1,
                                      165,
                                      113,
                                      1,
                                    ).withOpacity(0.5),
                                    Colors.green.shade600,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.userPlus,
                          color: Colors.white,
                          size: sp(18),
                        ),
                      ),
                      SizedBox(width: w(13)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  doc["Estado"] == "Rechazado"
                                      ? "Tutoria rechazada"
                                      : doc["Estado"] == "Aceptado"
                                      ? "Tutoria aceptada"
                                      : "Solicitud de tutoria",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h(5)),
                            Text(
                              doc["Estado"] != "Espera"
                                  ? "$deNoti solicitó crear una cuenta contigo como tutor."
                                  : "$deNoti solicita crear una cuenta contigo como tutor.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontFamily: "Poppins",
                                fontSize: sp(15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(23)),

                  /// CARD INTERNA
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(33, 47, 67, 1),
                          Color.fromRGBO(15, 28, 45, 1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(sp(13)),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.shieldCheck,
                              color: Colors.teal,
                              size: sp(18),
                            ),
                            SizedBox(width: h(8)),
                            Text(
                              doc["Estado"] == "Rechazado"
                                  ? "Aprobación rechazada"
                                  : doc["Estado"] == "Aceptado"
                                  ? "Aprobación aceptada"
                                  : "Aprobación requerida",
                              style: TextStyle(
                                fontSize: sp(15),
                                fontFamily: "PoppinsBold",
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (doc["Estado"] == "Espera") ...[
                          SizedBox(height: h(8)),
                          Text(
                            "El pupilo será vinculado a tu cuenta y quedará bajo tu supervisión.",
                            style: TextStyle(
                              fontSize: sp(13),
                              height: h(2),
                              fontFamily: "Poppins",
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: h(18)),

                  /// ACCIONES
                  if (doc["Estado"] == "Espera") ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton(
                          child: Text(
                            "Rechazar",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontFamily: "PoppinsBold",
                              fontSize: sp(13),
                            ),
                          ),
                          onPressed: () {
                            Vibration.vibrate(duration: 10);
                            rechazarSolicitudTutoria(doc["De uid"]);
                          },
                        ),
                        SizedBox(width: w(13)),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Ir a aprobar",
                            style: TextStyle(
                              fontFamily: "PoppinsBold",
                              fontSize: sp(13),
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            Vibration.vibrate(duration: 10);
                            aceptarSolicitudTutoria(doc["De uid"]);
                          },
                        ),
                      ],
                    ),
                  ],

                  if (!leido) ...[
                    SizedBox(height: h(23)),
                    GestureDetector(
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            LucideIcons.checkCheck,
                            color: Color.fromRGBO(1, 165, 113, 1),
                            size: sp(15),
                          ),
                          SizedBox(width: w(8)),
                          Text(
                            "Marcar como leído",
                            style: TextStyle(
                              color: Color.fromRGBO(1, 165, 113, 1),
                              fontSize: sp(13),
                              fontFamily: "PoppinsBold",
                            ),
                          ),
                        ],
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

  Widget widgetPupiloAprobado(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    final String nombreTutor = data["NombreTutor"] ?? "Tu tutor";
    final String avatarTutor = data["AvatarTutor"] ?? "";

    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: true,
          key: ValueKey(doc.id),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() => indexNoti = doc.id);
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() => indexNoti = doc.id);
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,
                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: const Color.fromRGBO(1, 165, 113, 1),
                  width: leido ? w(1) : w(8),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// AVATAR / ICONO TUTOR
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromRGBO(
                                1,
                                165,
                                113,
                                1,
                              ).withOpacity(0.6),
                              Colors.green.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: avatarTutor.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  avatarTutor,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                LucideIcons.heartHandshake,
                                color: Colors.white,
                                size: sp(20),
                              ),
                      ),
                      SizedBox(width: w(13)),

                      /// CONTENIDO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// TITULO + TIEMPO
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Cuenta aprobada",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: h(8)),

                            /// MENSAJE
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: sp(13),
                                  height: 1.45,
                                  color: Colors.white.withOpacity(0.65),
                                ),
                                children: [
                                  const TextSpan(
                                    text: "Tu cuenta fue aprobada por ",
                                  ),
                                  TextSpan(
                                    text: deNoti,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ", quien ahora es tu tutor.",
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: h(23)),

                            /// BLOQUE INFO
                            Container(
                              width: w(233),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: h(18),
                                  horizontal: w(18),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.shieldCheck,
                                      color: const Color.fromRGBO(
                                        1,
                                        165,
                                        113,
                                        1,
                                      ),
                                      size: sp(18),
                                    ),
                                    SizedBox(width: w(10)),
                                    Expanded(
                                      child: Text(
                                        "Ya podés usar todas las funciones",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontFamily: "Poppins",
                                          fontSize: sp(13),
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
                    ],
                  ),

                  /// MARCAR COMO LEÍDO
                  if (!leido)
                    GestureDetector(
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: const Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leído",
                              style: TextStyle(
                                color: const Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
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

  Widget widgetBienvenidaRegistro(doc, data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return SlideTransition(
      position: _offsetAnimationAparicion,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: _offset,
        child: Slidable(
          enabled: true,
          key: ValueKey(doc.id),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                Vibration.vibrate(duration: 15);
                setState(() => indexNoti = doc.id);
                eliminarNotificacion();
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  Vibration.vibrate(duration: 15);
                  setState(() => indexNoti = doc.id);
                  eliminarNotificacion();
                },
                backgroundColor: Colors.transparent,
                icon: Icons.delete,
                label: 'Borrar',
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10131A), Color(0xFF161823)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border(
                left: BorderSide(
                  color: const Color.fromRGBO(1, 165, 113, 1),
                  width: leido ? w(1) : w(8),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ICONO
                      Container(
                        width: w(33),
                        height: h(33),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Image.asset(
                          "assets/logoApp.png",
                          height: h(33),
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: w(13)),

                      /// CONTENIDO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// TITULO + TIEMPO
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "¡Bienvenido a QoreX!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(15),
                                  ),
                                ),
                                Text(
                                  textoTiempo,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontFamily: "Poppins",
                                    fontSize: sp(13),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: h(8)),

                            /// MENSAJE
                            Text(
                              "$deNoti, tu cuenta fue creada correctamente y ya podés comenzar a usar la app.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontFamily: "Poppins",
                                fontSize: sp(13),
                                height: 1.45,
                              ),
                            ),

                            SizedBox(height: h(23)),

                            /// BLOQUE INFO
                            Container(
                              width: w(233),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromRGBO(33, 47, 67, 1),
                                    Color.fromRGBO(15, 28, 45, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: h(18),
                                  horizontal: w(18),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.checkCircle,
                                      color: const Color.fromRGBO(
                                        1,
                                        165,
                                        113,
                                        1,
                                      ),
                                      size: sp(18),
                                    ),
                                    SizedBox(width: w(10)),
                                    Expanded(
                                      child: Text(
                                        "Registro completado con éxito",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontFamily: "Poppins",
                                          fontSize: sp(13),
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
                    ],
                  ),

                  /// MARCAR COMO LEÍDO
                  if (!leido)
                    GestureDetector(
                      onTap: () {
                        Vibration.vibrate(duration: 5);
                        marcarNotificacionLeidaUnitaria(doc);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: h(23), right: w(13)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              color: const Color.fromRGBO(1, 165, 113, 1),
                              size: sp(15),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Marcar como leído",
                              style: TextStyle(
                                color: const Color.fromRGBO(1, 165, 113, 1),
                                fontSize: sp(13),
                                fontFamily: "PoppinsBold",
                              ),
                            ),
                          ],
                        ),
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

class MoneyCounter extends StatefulWidget {
  final double amount;
  final bool showBalance;
  final ValueChanged<double>? onUpdate; // callback opcional

  const MoneyCounter({
    super.key,
    required this.amount,
    this.onUpdate,
    this.showBalance = true,
  });

  @override
  State<MoneyCounter> createState() => _MoneyCounterState();
}

class _MoneyCounterState extends State<MoneyCounter>
    with AutomaticKeepAliveClientMixin {
  bool _hasAnimated = false;

  Duration get duration {
    double seconds = 3 - (widget.amount / 1000) * 2; // fórmula simple
    if (seconds < 1) seconds = 1;
    return Duration(seconds: seconds.toInt());
  }

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
    super.build(context); // necesario por AutomaticKeepAliveClientMixin

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.amount),
      duration: _hasAnimated ? Duration.zero : duration,
      curve: Curves.easeOut,
      onEnd: () {
        if (!_hasAnimated) {
          setState(() {
            _hasAnimated = true; // marcamos que ya se animó
          });
        }
      },
      builder: (context, value, child) {
        if (widget.onUpdate != null) widget.onUpdate!(value);

        final showDecimals = widget.amount % 1 != 0;
        String formatted = formatCurrency(value, showDecimals: showDecimals);

        List<String> parts = formatted.split(',');
        String integerPart = parts[0];
        String decimalPart = parts.length > 1 ? "," + parts[1] : '';

        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "\$" + integerPart,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white60,
                  fontFamily: "Poppins",
                ),
              ),
              if (decimalPart.isNotEmpty)
                WidgetSpan(
                  child: Transform.translate(
                    offset: const Offset(0, 0),
                    child: Text(
                      decimalPart,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true; // 🔹 evita que se destruya al hacer scroll
}
