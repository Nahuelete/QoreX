// ignore_for_file: use_key_in_widget_constructors, camel_case_types, avoid_print, deprecated_member_use, sized_box_for_whitespace, no_leading_underscores_for_local_identifiers, curly_braces_in_flow_control_structures, prefer_interpolation_to_compose_strings, unrelated_type_equality_checks, avoid_unnecessary_containers, use_build_context_synchronously, prefer_final_fields, unused_field, non_constant_identifier_names, unnecessary_null_comparison, unnecessary_string_interpolations, unused_local_variable, unused_element, unnecessary_string_escapes

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class recibirPage extends StatefulWidget {
  @override
  State<recibirPage> createState() => _recibirPageState();
}

class _recibirPageState extends State<recibirPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isAppInactive = false;

  late AnimationController _controller;

  late AnimationController _controllerNeon;

  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  late AnimationController _controllerGiro;

  final ScrollController _scrollController = ScrollController();

  final TextEditingController _controllerCantidad = TextEditingController();
  final TextEditingController _controllerBusquedaUser = TextEditingController();
  final TextEditingController _controllerMensaje = TextEditingController();

  final GlobalKey _qrKey = GlobalKey();

  bool _showIcon = false;
  double _offset = 0;

  double cantidadElegida = 0.0;

  String? palabraSeleccionada = "";
  IconData iconMetodo = Icons.qr_code;

  String codeTransaccion = "";
  int codeTransaccionNum = 0;
  String estadoTransaccion = "";

  bool distorcionVis = false;

  bool recibirVis = true;
  bool qrGeneradoVis = false;
  bool reciboFinalizadoVis = false;
  bool generarCodeVinVis = false;
  bool solicitudUsuarioVis = false;
  bool solicitudEnviadaVis = false;

  // Variables de selección
  bool elegido100 = false;
  bool elegido250 = false;
  bool elegido500 = false;
  bool elegido1000 = false;
  bool elegido2000 = false;
  bool elegido5000 = false;

  late List<AnimationController> _controllersVibracion;
  late List<Animation<double>> _animationsVibracion;

  final List<int> tempos = [0, 500, 1000, 1500, 2000, 2500];

  String _contenidoPortapapeles = "Todavía no se verificó";

  bool mismoUsuario = false;

  String nameUserExterno = "";
  String uidUserExterno = "";
  String avatarUserExterno = "";
  String dniUserExterno = "";
  String referenciaUserExterno = "";

  String tipoBusqueda = "";
  IconData iconBusquedaUser = LucideIcons.atSign;

  String fechaActual = "";
  String horaActual = "";

  String nameUser = "";
  String emailUser = "";
  String dniUser = "";
  String uidUser = "";
  String cbuUser = "";
  String aliasUser = "";
  String avatarUser = "";
  String fechaRegistroUser = "";
  double saldoUser = 0.0;

  void reset() {
    setState(() {
      _controllerCantidad.text = "";

      cantidadElegida = 0.0;

      elegido100 = false;
      elegido250 = false;
      elegido500 = false;
      elegido1000 = false;
      elegido2000 = false;
      elegido5000 = false;
    });
  }

  Future<void> leerShared() async {
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

    FirebaseFirestore.instance
        .collection('Usuarios') // colección principal
        .doc(uidUser) // documento del usuario
        .snapshots() // escuchar en tiempo real
        .listen((docSnapshot) async {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            try {
              setState(() {
                nameUser = data["Nombre"] ?? "";
                emailUser = data["Email"] ?? "";
                aliasUser = data["Alias"] ?? "";
                cbuUser = data["CBU"] ?? "";
                dniUser = data["Dni"] ?? "";
                avatarUser = data["Avatar"] ?? "";
                fechaRegistroUser = data["Registrado"] ?? "";
                saldoUser = (data["Saldo"] != null)
                    ? (data["Saldo"] as num).toDouble()
                    : 0.0;
                uidUser = user?.uid ?? "";
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

  void scheduleVibration(int index) async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 3000 + tempos[index]));
      if (mounted) _controllersVibracion[index].forward(from: 0);
    }
  }

  Future<void> _verificarClipboard() async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    setState(() {
      _contenidoPortapapeles = datos?.text ?? "Portapapeles vacío";
    });

    Future.delayed(Duration(milliseconds: 3800), () {
      setState(() {
        _contenidoPortapapeles = "";
      });
    });
  }

  Future<void> _compartirQr() async {
    try {
      // Convertir QR en imagen
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Guardar temporalmente
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr.png').create();
      await file.writeAsBytes(pngBytes);

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: "QR cobro \$${cantidadElegida.toString()}",
        text:
            "Escanea el QR para enviarle \$${cantidadElegida.toString()} a $nameUser",
      );
    } catch (e) {
      print("Error al compartir QR: $e");
    }
  }

  Future<void> guardarQR() async {
    try {
      // Esperar a que el widget se haya renderizado
      await Future.delayed(Duration(milliseconds: 50));

      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      if (boundary.debugNeedsPaint) {
        await Future.delayed(Duration(milliseconds: 20));
        return guardarQR(); // reintentar
      }

      // Tamaño del widget
      final double width = boundary.size.width;
      final double height = boundary.size.height;
      final double pixelRatio = 3.0; // para mejor resolución

      // Capturar el widget QR como imagen
      final ui.Image qrImage = await boundary.toImage(pixelRatio: pixelRatio);

      // Crear un recorder con tamaño exacto del QR
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Pintar fondo negro completo
      final Paint paint = Paint()..color = Colors.black;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width * pixelRatio, height * pixelRatio),
        paint,
      );

      // Dibujar el QR encima
      canvas.drawImage(qrImage, Offset.zero, Paint());

      // Convertir a imagen final
      final ui.Image finalImage = await recorder.endRecording().toImage(
        (width * pixelRatio).toInt(),
        (height * pixelRatio).toInt(),
      );
      final ByteData? byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Guardar en galería
      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: "qr_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess']) {
        print('QR guardado en galería!');
      } else {
        print('Error al guardar QR');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> generarTransaccion() async {
    Random random = Random();
    codeTransaccionNum = 10000 + random.nextInt(90000);

    setState(() {
      codeTransaccion = "Recibo #${codeTransaccionNum.toString()}";
    });

    try {
      final transaccionRef = FirebaseFirestore.instance
          .collection("Recibos")
          .doc(codeTransaccion);
      final notificacionnRef = FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc("Notificacion #${codeTransaccionNum.toString()}");

      // 🔹 Crear transacción
      await transaccionRef.set({
        "Recibe": uidUser,
        "Cantidad": cantidadElegida,
        "Estado": "Pendiente",
        "Metodo": palabraSeleccionada,
        "ID": codeTransaccionNum,
      });

      // 🔹 Agregar mensaje si existe (sin bloquear)
      if (_controllerMensaje.text.isNotEmpty) {
        transaccionRef.update({"Mensaje": _controllerMensaje.text});

        notificacionnRef.update({"Mensaje": _controllerMensaje.text});
      }

      // 🔹 Llamar a escucha de transacción (fuera del await para no bloquear UI)
      escucharTransaccion();

      print("Transacción Creada ✅");
    } catch (e) {
      print("Error al crear la transacción: $e");
    }
  }

  Future<void> escucharTransaccion() async {
    FirebaseFirestore.instance
        .collection('Recibos')
        .doc(codeTransaccion)
        .snapshots()
        .listen((docSnapshot) async {
          if (!mounted) return; // <- Evita setState si el widget ya no existe

          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            try {
              if (palabraSeleccionada != "Solicitud a Usuario") {
                setState(() {
                  Vibration.vibrate(duration: 50);
                  estadoTransaccion = data["Estado"] ?? "";
                  nameUserExterno = data["Paga"] ?? "";
                  avatarUserExterno = data["AvatarPaga"] ?? "";
                  uidUserExterno = data["Paga uid"] ?? "";
                  tipoBusqueda = data["Metodo"] ?? "";
                });
              }

              // Pago
              if (estadoTransaccion == "Pago") {
                DateTime ahora = DateTime.now();

                setState(() {
                  fechaActual = DateFormat('dd-MM-yyyy').format(ahora);
                  horaActual = DateFormat('HH:mm').format(ahora);
                  qrGeneradoVis = false;
                  generarCodeVinVis = false;
                  reciboFinalizadoVis = true;
                });

                sendEmailDineroRecibido();
              }
            } catch (e, s) {
              print("Error al asignar valores: $e");
              print(s);
            }
          } else {
            print('El documento no existe');
            Vibration.vibrate(duration: 10);
            setState(() {
              distorcionVis = false;
              qrGeneradoVis = false;
              generarCodeVinVis = false;
              solicitudUsuarioVis = false;
              recibirVis = true;
            });
          }
        });
  }

  Future<void> confirmarPagoVin() async {
    FirebaseFirestore.instance
        .collection("Recibos")
        .doc(codeTransaccion)
        .update({"Estado": "Pago"});
  }

  Future<void> buscarUsuario() async {
    try {
      FirebaseFirestore.instance
          .collection('BusquedaUsers')
          .doc(_controllerBusquedaUser.text)
          .snapshots()
          .listen((docSnapshot) async {
            if (!mounted) return;

            if (docSnapshot.exists) {
              Map<String, dynamic> data =
                  docSnapshot.data() as Map<String, dynamic>;

              try {
                setState(() {
                  uidUserExterno = data["Uid"] ?? "";
                  tipoBusqueda = data["Tipo"] ?? "";
                });

                if (tipoBusqueda == "Alias") {
                  setState(() {
                    iconBusquedaUser = LucideIcons.atSign;
                  });
                } else if (tipoBusqueda == "CBU") {
                  setState(() {
                    iconBusquedaUser = LucideIcons.creditCard;
                  });
                } else if (tipoBusqueda == "Email") {
                  setState(() {
                    iconBusquedaUser = LucideIcons.mail;
                  });
                }

                obtenerDatosPersonalesExterno();
              } catch (e, s) {
                print("Error al asignar valores: $e");
                print(s);
              }
            } else {
              showFlushbarError(context, "El Usuario Ingresado No Existe.");
            }
          });
    } catch (e) {
      print("Error al buscar ususario: $e");
    }
  }

  Future<void> obtenerDatosPersonalesExterno() async {
    try {
      FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(uidUserExterno)
          .snapshots()
          .listen((docSnapshot) async {
            if (!mounted) return;

            if (docSnapshot.exists) {
              Map<String, dynamic> data =
                  docSnapshot.data() as Map<String, dynamic>;

              try {
                FocusScope.of(context).unfocus();

                // Determinar referencia según tipoBusqueda
                String referencia = "";
                if (tipoBusqueda == "Alias") {
                  referencia = data["Alias"] ?? "";
                } else if (tipoBusqueda == "CBU") {
                  referencia = data["CBU"] ?? "";
                } else if (tipoBusqueda == "Email") {
                  referencia = data["Email"] ?? "";
                }

                // Actualizar todo en un solo setState
                setState(() {
                  nameUserExterno = data["Nombre"] ?? "";
                  avatarUserExterno = data["Avatar"] ?? "";
                  dniUserExterno = data["Dni"] ?? "";
                  referenciaUserExterno = referencia;
                  distorcionVis = true;
                  solicitudUsuarioVis = true;
                });
              } catch (e, s) {
                print("Error al asignar valores: $e");
                print(s);
              }
            } else {
              showFlushbarError(context, "El Usuario Ingresado No Existe.");
            }
          });
    } catch (e) {
      print("Error al obtener datos personales: $e");
    }
  }

  Future<void> crearNotificacion() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final hora =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    try {
      await FirebaseFirestore.instance
          .collection("Notificaciones")
          .doc("Notificacion #$codeTransaccionNum")
          .set({
            "Tipo": "Solicitud",
            "De": nameUser,
            "De uid": uidUser,
            "Avatar Envia": avatarUserExterno,
            "Avatar Recibe": avatarUser,
            "Para": nameUserExterno,
            "Para uid": uidUserExterno,
            "Monto": cantidadElegida,
            "Fecha": fecha, // 🔹 string solo para mostrar (dd-MM-yyyy)
            "Hora": hora, // 🔹 string solo para mostrar
            "FechaTime": Timestamp.fromDate(
              ahora,
            ), // 🔹 este es el que se usa en queries
            "Estado": "Pendiente",
            "ID Recibo": codeTransaccionNum,
            "Metodo": tipoBusqueda,
            "Leida": {"$uidUser": false, "$uidUserExterno": false},
            "Involucra": [uidUser, uidUserExterno], // array con ambos UIDs
          });

      print("Notificación creada ✅");
    } catch (e, st) {
      print("Error al crear la notificación: $e");
      print(st);
    }
  }

  Future<void> borrarTransaccion() async {
    try {
      await FirebaseFirestore.instance
          .collection("Recibos")
          .doc("Recibo #$codeTransaccionNum")
          .delete();
      setState(() {
        codeTransaccion = "";
        codeTransaccionNum = 0;
      });
      print("Transaccion Elminada");
    } catch (e) {
      print("Error al eliminar la transaccion: $e");
    }
  }

  Future sendEmailDineroRecibido() async {
    final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");
    const serviceId = "service_hp0bj4v";
    const templateId = "template_s71n8qt";
    const userId = "hxl-npJZl6ZirwdKR";
    final response = await http.post(
      url,
      headers: {"origin": "http:localhost", "Content-Type": "application/json"},
      body: json.encode({
        "service_id": serviceId,
        "template_id": templateId,
        "user_id": userId,
        "template_params": {
          "name": nameUser,
          "sender_email": emailUser,
          "amount": cantidadElegida,
          "de": nameUserExterno,
          "date": "$fechaActual a las $horaActual",
          "metodo": palabraSeleccionada,
          "codeNum": "#$codeTransaccionNum",
        },
      }),
    );
    print("ENVIADO");
    print(codeTransaccion);
    return response.statusCode;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    setState(() {
      _isAppInactive = state != AppLifecycleState.resumed;
    });

    if (qrGeneradoVis == true || generarCodeVinVis == true) {
      if (state == AppLifecycleState.detached) {
        // La app está cerrándose
        borrarTransaccion();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    leerShared();

    obtenerDatos();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        ); // siempre arriba
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.isScrollingNotifier.value) {
        FocusScope.of(context).unfocus();
      }
      setState(() {
        _offset = _scrollController.offset;

        // Mostrar el icono cuando se pase cierto scroll
        if (_offset > 750 && _showIcon) {
          _showIcon = false;
        } else if (_offset <= 750 && !_showIcon) {
          _showIcon = true;
        }
      });
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _controllerNeon = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5), // más lento
    )..repeat();

    _controllersVibracion = List.generate(6, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300), // duración de la vibración
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controllersVibracion[index].reverse();
        }
      });
    });

    _animationsVibracion = _controllersVibracion.map((controller) {
      return TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -3.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -3.0, end: 3.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 1),
      ]).animate(controller);
    }).toList();

    // Lanzar vibración automática con tempos distintos
    for (int i = 0; i < _controllersVibracion.length; i++) {
      scheduleVibration(i);
    }

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _iconAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _controllerGiro = AnimationController(
      duration: const Duration(seconds: 1), // velocidad de giro
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _controllerNeon.dispose();
    _iconController.dispose();
    _controllerGiro.dispose();
    for (var c in _controllersVibracion) c.dispose();
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            //Modificar system tema
            backgroundColor: (distorcionVis
                ? Colors.black
                : Colors.transparent),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Visibility(
              visible: !distorcionVis,
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
                            "Recibir Dinero",
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
                            "Elige cómo quieres recibir pagos",
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
            actions: [
              // 🔹 Icono animado
              Visibility(
                visible: !distorcionVis,
                child: AnimatedSlide(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  offset: _showIcon ? Offset.zero : Offset(0, 5),
                  child: IconButton(
                    color: Colors.white60,
                    icon: Icon(LucideIcons.arrowUp),
                    onPressed: () async {
                      Vibration.vibrate(duration: 5);
                      FocusScope.of(context).unfocus();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          if (palabraSeleccionada == "Solicitud a Usuario") {
                            _scrollController.animateTo(
                              1486,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          } else if (palabraSeleccionada == "Vinculación") {
                            _scrollController.animateTo(
                              1028,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          } else if (palabraSeleccionada == "Código QR") {
                            _scrollController.animateTo(
                              1028,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          } else {
                            _scrollController.animateTo(
                              975,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
              SizedBox(width: w(13)),
            ],
          ),
        ),
        body: Stack(
          children: [
            SizedBox(child: recibir()),
            Visibility(
              visible: distorcionVis,
              child: Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: Colors.black.withOpacity(0.7), // oscurece un poco
                  ),
                ),
              ),
            ),
            SizedBox(child: qrGenerado()),
            SizedBox(child: reciboFinalizado()),
            SizedBox(child: generarCodeVin()),
            SizedBox(child: solicitudUsuario()),
            SizedBox(child: solicitudEnviada()),
          ],
        ),
      ),
    );
  }

  Widget recibir() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: recibirVis,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          restorationId: null,
          reverse: true,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: h(13)),

                // --- Container de Datos de Cobro ---
                Container(
                  height: h(500),
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
                  ),
                  child: Stack(
                    children: [
                      // Línea neón pegada al borde del Container
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _controllerNeon,
                          builder: (context, child) {
                            return CustomPaint(
                              size: Size.infinite,
                              painter: NeonBorderPainter(
                                animationValue: _controllerNeon.value,
                              ),
                            );
                          },
                        ),
                      ),

                      // Contenido interno con padding
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: w(33),
                          vertical: h(23),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Container(
                                    height: h(53),
                                    width: w(53),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Visibility(
                                        visible: avatarUser != "",
                                        child: Image.asset(avatarUser),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: w(13),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: w(200),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              nameUser,
                                              style: TextStyle(
                                                fontSize: sp(20),
                                                color: Colors.white,
                                                fontFamily: "PoppinsBold",
                                              ),
                                            ),
                                          ),
                                        ),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: w(200),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              "Mis datos de cobro",
                                              style: TextStyle(
                                                fontSize: sp(15.8),
                                                color: Colors.white60,
                                                fontFamily: "Poppins",
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

                            SizedBox(height: h(23)),

                            // Alias
                            GestureDetector(
                              child: Container(
                                height: h(90),
                                width: w(300),
                                color: Colors.transparent,
                                child: Center(
                                  child: Container(
                                    width: w(300),
                                    height: h(100),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(20, 25, 50, 1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.greenAccent,
                                        width: w(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // 🔹 Contenedor con el @
                                        Container(
                                          width: w(33),
                                          height: h(33),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color.fromRGBO(1, 165, 113, 1),
                                                Colors.green.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              LucideIcons.atSign,
                                              color: Colors.white,
                                              size: sp(15),
                                            ),
                                          ),
                                        ),

                                        SizedBox(width: w(13)),

                                        // 🔹 Columna con "Alias" + aliasUser dinámico
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                                    "Alias",
                                                    style: TextStyle(
                                                      fontSize: sp(16),
                                                      color: Colors.white60,
                                                      fontFamily: "Poppins",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: h(3)),

                                              // 🔹 AliasUser que se achica dinámicamente
                                              ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: w(300),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    aliasUser,
                                                    style: TextStyle(
                                                      fontSize: sp(18),
                                                      color: Colors.white,
                                                      fontFamily: "Poppins",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(width: w(8)),

                                        // 🔹 Icono de copiar / check
                                        Icon(
                                          (_contenidoPortapapeles == aliasUser
                                              ? LucideIcons.checkCircle
                                              : LucideIcons.copy),
                                          color: Color.fromRGBO(1, 165, 113, 1),
                                          size: sp(20),
                                        ),

                                        SizedBox(width: w(8)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () {
                                Vibration.vibrate(duration: 10);
                                Clipboard.setData(
                                  ClipboardData(text: aliasUser),
                                );
                                _verificarClipboard();
                                showFlushbarCopiado(
                                  context,
                                  "Alias copiado al portapapeles.",
                                );
                              },
                            ),
                            SizedBox(height: h(33)),
                            // CBU
                            GestureDetector(
                              child: Container(
                                height: h(90),
                                width: w(300),
                                color: Colors.transparent,
                                child: Center(
                                  child: Container(
                                    width: w(300),
                                    height: h(100),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(20, 25, 50, 1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Color.fromRGBO(200, 90, 0, 1),
                                        width: w(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // 🔹 Contenedor con el @
                                        Container(
                                          width: w(33),
                                          height: h(33),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color.fromRGBO(200, 90, 0, 1),
                                                Colors.orange.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              LucideIcons.creditCard,
                                              color: Colors.white,
                                              size: sp(15),
                                            ),
                                          ),
                                        ),

                                        SizedBox(width: w(13)),

                                        // 🔹 Columna con "Alias" + aliasUser dinámico
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                                    "CBU",
                                                    style: TextStyle(
                                                      fontSize: sp(16),
                                                      color: Colors.white60,
                                                      fontFamily: "Poppins",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: h(3)),

                                              // 🔹 AliasUser que se achica dinámicamente
                                              ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: w(300),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    cbuUser,
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.white,
                                                      fontFamily: "Poppins",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(width: w(8)),

                                        // 🔹 Icono de copiar / check
                                        Icon(
                                          (_contenidoPortapapeles == cbuUser
                                              ? LucideIcons.checkCircle
                                              : LucideIcons.copy),
                                          color: Color.fromRGBO(200, 90, 0, 1),
                                          size: sp(20),
                                        ),

                                        SizedBox(width: w(8)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () {
                                Vibration.vibrate(duration: 10);
                                Clipboard.setData(ClipboardData(text: cbuUser));
                                _verificarClipboard();
                                showFlushbarCopiado(
                                  context,
                                  "CBU copiado al portapapeles.",
                                );
                              },
                            ),
                            SizedBox(height: h(33)),
                            // Email
                            GestureDetector(
                              child: Container(
                                height: h(90),
                                width: w(300),
                                color: Colors.transparent,
                                child: Center(
                                  child: Container(
                                    width: w(300),
                                    height: h(100),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(20, 25, 50, 1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue.shade600,
                                        width: w(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // 🔹 Contenedor con el @
                                        Container(
                                          width: w(33),
                                          height: h(33),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color.fromRGBO(33, 13, 243, 1),
                                                Colors.blue.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              LucideIcons.mail,
                                              color: Colors.white,
                                              size: sp(15),
                                            ),
                                          ),
                                        ),

                                        SizedBox(width: w(13)),

                                        // 🔹 Columna con "Alias" + aliasUser dinámico
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                                    "Email",
                                                    style: TextStyle(
                                                      fontSize: sp(16),
                                                      color: Colors.white60,
                                                      fontFamily: "Poppins",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 3),

                                              // 🔹 AliasUser que se achica dinámicamente
                                              ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: w(200),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    emailUser,
                                                    style: TextStyle(
                                                      fontSize: sp(17),
                                                      color: Colors.white,
                                                      fontFamily: "Poppins",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(width: w(8)),

                                        // 🔹 Icono de copiar / check
                                        Icon(
                                          (_contenidoPortapapeles == emailUser
                                              ? LucideIcons.checkCircle
                                              : LucideIcons.copy),
                                          color: Colors.blue.shade600,
                                          size: sp(20),
                                        ),

                                        SizedBox(width: w(8)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () {
                                Vibration.vibrate(duration: 10);
                                Clipboard.setData(
                                  ClipboardData(text: emailUser),
                                );
                                _verificarClipboard();
                                showFlushbarCopiado(
                                  context,
                                  "Email copiado al portapapeles.",
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: h(53)),

                // --- Segundo Container de Monto a recibir ---
                AnimatedSize(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  child: Container(
                    height: (cantidadElegida == 0 ? 500 : 633),
                    padding: const EdgeInsets.all(20),
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
                        Padding(
                          padding: EdgeInsets.all(sp(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
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
                                      LucideIcons.dollarSign,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: w(13)),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: w(300),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Monto a recibir",
                                        style: TextStyle(
                                          fontSize: sp(23),
                                          color: Colors.white,
                                          fontFamily: "Poppinsbold",
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: h(23)),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.zap,
                                    color: Colors.white,
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
                                        "Montos Rápidos",
                                        style: TextStyle(
                                          fontSize: sp(15),
                                          color: Colors.white60,
                                          fontFamily: "Poppins",
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: h(23)),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // Container $100
                                  GestureDetector(
                                    child: AnimatedBuilder(
                                      animation: _animationsVibracion[0],
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            _animationsVibracion[0].value,
                                            0,
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        height: h(63),
                                        width: w(93),
                                        decoration: BoxDecoration(
                                          gradient: (elegido100
                                              ? LinearGradient(
                                                  colors: [
                                                    Color.fromRGBO(
                                                      1,
                                                      165,
                                                      113,
                                                      1,
                                                    ),
                                                    Colors.green.shade600,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                )
                                              : null),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: w(0.1),
                                          ),
                                        ),
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(83),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "\$100",
                                                style: TextStyle(
                                                  color: (elegido100
                                                      ? Colors.white
                                                      : Colors.white60),
                                                  fontFamily: "Poppins",
                                                  fontSize: sp(18),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      Vibration.vibrate(duration: 5);
                                      if (elegido100) {
                                        reset();
                                      } else {
                                        setState(() {
                                          reset();
                                          cantidadElegida = 100;
                                          elegido100 = true;
                                          _controllerCantidad.text = "100";
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(width: w(8)),

                                  // Container $250
                                  GestureDetector(
                                    child: AnimatedBuilder(
                                      animation: _animationsVibracion[1],
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            _animationsVibracion[1].value,
                                            0,
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        height: h(63),
                                        width: w(93),
                                        decoration: BoxDecoration(
                                          gradient: (elegido250
                                              ? LinearGradient(
                                                  colors: [
                                                    Color.fromRGBO(
                                                      1,
                                                      165,
                                                      113,
                                                      1,
                                                    ),
                                                    Colors.green.shade600,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                )
                                              : null),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: w(0.1),
                                          ),
                                        ),
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(83),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "\$250",
                                                style: TextStyle(
                                                  color: (elegido250
                                                      ? Colors.white
                                                      : Colors.white60),
                                                  fontFamily: "Poppins",
                                                  fontSize: sp(18),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      Vibration.vibrate(duration: 5);
                                      if (elegido250) {
                                        reset();
                                      } else {
                                        setState(() {
                                          reset();
                                          cantidadElegida = 250;
                                          elegido250 = true;
                                          _controllerCantidad.text = "250";
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(width: w(8)),

                                  // Container $500
                                  GestureDetector(
                                    child: AnimatedBuilder(
                                      animation: _animationsVibracion[2],
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            _animationsVibracion[2].value,
                                            0,
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        height: h(63),
                                        width: w(93),
                                        decoration: BoxDecoration(
                                          gradient: (elegido500
                                              ? LinearGradient(
                                                  colors: [
                                                    Color.fromRGBO(
                                                      1,
                                                      165,
                                                      113,
                                                      1,
                                                    ),
                                                    Colors.green.shade600,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                )
                                              : null),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: w(0.1),
                                          ),
                                        ),
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(83),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "\$500",
                                                style: TextStyle(
                                                  color: (elegido500
                                                      ? Colors.white
                                                      : Colors.white60),
                                                  fontFamily: "Poppins",
                                                  fontSize: sp(18),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      Vibration.vibrate(duration: 5);
                                      if (elegido500) {
                                        reset();
                                      } else {
                                        setState(() {
                                          reset();
                                          cantidadElegida = 500;
                                          elegido500 = true;
                                          _controllerCantidad.text = "500";
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: h(18)),

                              // Segunda fila
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // Container $1000
                                  GestureDetector(
                                    child: AnimatedBuilder(
                                      animation: _animationsVibracion[3],
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            _animationsVibracion[3].value,
                                            0,
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        height: h(63),
                                        width: w(93),
                                        decoration: BoxDecoration(
                                          gradient: (elegido1000
                                              ? LinearGradient(
                                                  colors: [
                                                    Color.fromRGBO(
                                                      1,
                                                      165,
                                                      113,
                                                      1,
                                                    ),
                                                    Colors.green.shade600,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                )
                                              : null),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 0.1,
                                          ),
                                        ),
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(83),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "\$1.000",
                                                style: TextStyle(
                                                  color: (elegido1000
                                                      ? Colors.white
                                                      : Colors.white60),
                                                  fontFamily: "Poppins",
                                                  fontSize: sp(18),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      Vibration.vibrate(duration: 5);
                                      if (elegido1000) {
                                        reset();
                                      } else {
                                        setState(() {
                                          reset();
                                          cantidadElegida = 1000;
                                          elegido1000 = true;
                                          _controllerCantidad.text = "1000";
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(width: w(8)),

                                  // Container $2000
                                  GestureDetector(
                                    child: AnimatedBuilder(
                                      animation: _animationsVibracion[4],
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            _animationsVibracion[4].value,
                                            0,
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        height: h(63),
                                        width: w(93),
                                        decoration: BoxDecoration(
                                          gradient: (elegido2000
                                              ? LinearGradient(
                                                  colors: [
                                                    Color.fromRGBO(
                                                      1,
                                                      165,
                                                      113,
                                                      1,
                                                    ),
                                                    Colors.green.shade600,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                )
                                              : null),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: w(0.1),
                                          ),
                                        ),
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(83),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "\$2.000",
                                                style: TextStyle(
                                                  color: (elegido2000
                                                      ? Colors.white
                                                      : Colors.white60),
                                                  fontFamily: "Poppins",
                                                  fontSize: sp(18),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      Vibration.vibrate(duration: 5);
                                      if (elegido2000) {
                                        reset();
                                      } else {
                                        setState(() {
                                          reset();
                                          cantidadElegida = 2000;
                                          elegido2000 = true;
                                          _controllerCantidad.text = "2000";
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(width: w(8)),

                                  // Container $5000
                                  GestureDetector(
                                    child: AnimatedBuilder(
                                      animation: _animationsVibracion[5],
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            _animationsVibracion[5].value,
                                            0,
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        height: h(63),
                                        width: w(93),
                                        decoration: BoxDecoration(
                                          gradient: (elegido5000
                                              ? LinearGradient(
                                                  colors: [
                                                    Color.fromRGBO(
                                                      1,
                                                      165,
                                                      113,
                                                      1,
                                                    ),
                                                    Colors.green.shade600,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                )
                                              : null),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: w(0.1),
                                          ),
                                        ),
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(83),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "\$5.000",
                                                style: TextStyle(
                                                  color: (elegido5000
                                                      ? Colors.white
                                                      : Colors.white60),
                                                  fontFamily: "Poppins",
                                                  fontSize: sp(18),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      Vibration.vibrate(duration: 5);
                                      if (elegido5000) {
                                        reset();
                                      } else {
                                        setState(() {
                                          reset();
                                          cantidadElegida = 5000;
                                          elegido5000 = true;
                                          _controllerCantidad.text = "5000";
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: h(33)),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey, // color de la línea
                                      thickness: h(0.5), // grosor de la línea
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: w(13),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "O", // texto dentro del círculo
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontFamily: "Poppins",
                                          fontSize: sp(15),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey,
                                      thickness: h(0.5),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: h(23)),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.pencil,
                                    color: Colors.white,
                                    size: sp(13),
                                  ),
                                  SizedBox(width: w(8)),
                                  Text(
                                    "Monto Personalizado",
                                    style: TextStyle(
                                      fontSize: sp(15),
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: h(18)),
                              Container(
                                width: w(350),
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
                                      margin: EdgeInsets.symmetric(
                                        horizontal: w(13),
                                      ),
                                      height: h(35),
                                      width: w(35),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: LinearGradient(
                                          colors: [
                                            Color.fromRGBO(33, 13, 243, 1),
                                            Colors.blue.shade600,
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
                                        visible:
                                            (qrGeneradoVis == true ||
                                                generarCodeVinVis == true
                                            ? false
                                            : true),
                                        child: TextField(
                                          controller: _controllerCantidad,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal:
                                                    true, // permite el punto decimal
                                                signed: false,
                                              ), // si quisieras permitir números negativos -> true
                                          inputFormatters: [
                                            DynamicMoneyFormatter(),
                                          ],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Poppins",
                                          ),
                                          cursorColor: Colors.white,
                                          decoration: InputDecoration(
                                            hintText: "Ingresa el monto",
                                            hintStyle: TextStyle(
                                              color: Colors.grey.shade400,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (value) async {
                                            setState(() {
                                              double? monto = double.tryParse(
                                                value
                                                    .replaceAll('.', '')
                                                    .replaceAll(',', '.'),
                                              );
                                              if (monto != null) {
                                                cantidadElegida = monto;
                                              } else {
                                                cantidadElegida = 0;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (cantidadElegida != 0) ...[
                                SizedBox(height: h(33)),
                                Container(
                                  width: w(350),
                                  height: h(93),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF0F1E24),
                                    border: Border.all(
                                      color: Colors.greenAccent,
                                      width: w(1),
                                    ),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Row(
                                    children: [
                                      // Icono con fondo y borde redondeado
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: w(13),
                                        ),
                                        height: h(43),
                                        width: w(43),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromRGBO(1, 165, 113, 1),
                                              Colors.green.shade600,
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.dollarSign,
                                          color: Colors.white,
                                          size: sp(18),
                                        ),
                                      ),
                                      SizedBox(width: w(8)),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                                textAlign: TextAlign.start,
                                                "Monto a Recibir",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: Color.fromRGBO(
                                                    1,
                                                    165,
                                                    113,
                                                    1,
                                                  ),
                                                  fontFamily: "PoppinsBold",
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: h(3)),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: w(300),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: MoneyCounter(
                                                amount: cantidadElegida,
                                                showBalance: true,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: h(53)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w(13)),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w(300)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Métodos de Recepción",
                          style: TextStyle(
                            fontSize: sp(23),
                            color: Colors.white,
                            fontFamily: "Poppinsbold",
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h(23)),
                GestureDetector(
                  child: Container(
                    height: h(133),
                    width: w(400),
                    decoration: BoxDecoration(
                      gradient: (palabraSeleccionada == "Código QR"
                          ? LinearGradient(
                              colors: [
                                const Color.fromRGBO(
                                  1,
                                  165,
                                  113,
                                  1,
                                ).withOpacity(0.3),
                                Colors.green.shade600.withOpacity(0.3),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null),
                      color: (palabraSeleccionada != "Código QR"
                          ? const Color.fromRGBO(20, 25, 50, 1)
                          : null), // Fondo oscuro solo cuando NO está seleccionado
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (palabraSeleccionada == "Código QR"
                            ? Colors.green
                            : Colors.white60),
                        width: (palabraSeleccionada == "Código QR" ? 0.3 : 0.1),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: w(63),
                          height: h(63),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromRGBO(1, 165, 113, 1),
                                Colors.green.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.qrCode,
                              color: Colors.white,
                              size: sp(25),
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
                                constraints: BoxConstraints(maxWidth: w(300)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Código QR",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "PoppinsBold",
                                      fontSize: sp(20),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: h(5)),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(300)),
                                child: Text(
                                  "Genera un código QR para\nrecibir pagos.",
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
                          value: "Código QR",
                          groupValue: palabraSeleccionada,
                          onChanged: (value) {
                            setState(() {
                              palabraSeleccionada = value;
                            });
                          },
                          activeColor: Colors.greenAccent,
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Vibration.vibrate(duration: 15);
                    setState(() {
                      palabraSeleccionada = "Código QR";
                    });
                  },
                ),
                SizedBox(height: h(23)),
                GestureDetector(
                  child: Container(
                    height: h(133),
                    width: w(400),
                    decoration: BoxDecoration(
                      gradient: (palabraSeleccionada == "Vinculación"
                          ? LinearGradient(
                              colors: [
                                const Color.fromRGBO(
                                  33,
                                  13,
                                  243,
                                  1,
                                ).withOpacity(0.3),
                                Colors.blue.shade600.withOpacity(0.3),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null),
                      color: (palabraSeleccionada != "Vinculación"
                          ? const Color.fromRGBO(20, 25, 50, 1)
                          : null), // Fondo oscuro solo cuando NO está seleccionado
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (palabraSeleccionada == "Vinculación"
                            ? Colors.blue
                            : Colors.white60),
                        width: (palabraSeleccionada == "Vinculación"
                            ? 0.3
                            : 0.1),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: w(63),
                          height: h(63),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromRGBO(33, 13, 243, 1),
                                Colors.blue.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.userPlus2,
                              color: Colors.white,
                              size: sp(25),
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
                                constraints: BoxConstraints(maxWidth: w(400)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Vinculación",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "PoppinsBold",
                                      fontSize: sp(20),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: h(5)),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(350)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Genera un código para\nconectarte con otro dispositivo.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: "Vinculación",
                          groupValue: palabraSeleccionada,
                          onChanged: (value) {
                            setState(() {
                              palabraSeleccionada = value;
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
                      palabraSeleccionada = "Vinculación";
                    });
                  },
                ),
                SizedBox(height: h(23)),
                GestureDetector(
                  child: Container(
                    height: h(133),
                    width: w(400),
                    decoration: BoxDecoration(
                      gradient: (palabraSeleccionada == "Solicitud a Usuario"
                          ? LinearGradient(
                              colors: [
                                const Color.fromRGBO(
                                  200,
                                  90,
                                  0,
                                  1,
                                ).withOpacity(0.3),
                                Colors.orange.shade600.withOpacity(0.3),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null),
                      color: (palabraSeleccionada != "Solicitud a Usuario"
                          ? const Color.fromRGBO(20, 25, 50, 1)
                          : null), // Fondo oscuro solo cuando NO está seleccionado
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (palabraSeleccionada == "Solicitud a Usuario"
                            ? Colors.orange
                            : Colors.white60),
                        width: (palabraSeleccionada == "Solicitud a Usuario"
                            ? 0.3
                            : 0.1),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: w(63),
                          height: h(63),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromRGBO(200, 90, 0, 1),
                                Colors.orange.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.users2,
                              color: Colors.white,
                              size: sp(25),
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
                                constraints: BoxConstraints(maxWidth: w(300)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Solicitar a Usuario",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "PoppinsBold",
                                      fontSize: sp(20),
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
                                    "Solicita dinero usando\nAlias, CBU o Email.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: "Solicitud a Usuario",
                          groupValue: palabraSeleccionada,
                          onChanged: (value) {
                            setState(() {
                              palabraSeleccionada = value;
                            });
                          },
                          activeColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Vibration.vibrate(duration: 15);
                    setState(() {
                      palabraSeleccionada = "Solicitud a Usuario";
                    });
                  },
                ),
                SizedBox(height: h(33)),
                //Boton QR
                if (palabraSeleccionada == "Código QR") ...[
                  GestureDetector(
                    child: Container(
                      height: h(53),
                      width: w(400),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: (cantidadElegida != 0
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
                              )),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Generar Código QR",
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
                              LucideIcons.qrCode,
                              color: Colors.white,
                              size: sp(20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Vibration.vibrate(duration: 10);
                      if (cantidadElegida != 0) {
                        setState(() {
                          distorcionVis = true;
                          qrGeneradoVis = true;
                          iconMetodo = Icons.qr_code;
                        });
                        generarTransaccion();
                      } else {
                        showFlushbarError(context, "Ingresa un monto.");
                      }
                    },
                  ),
                ],

                //Boton Vinculacion
                if (palabraSeleccionada == "Vinculación") ...[
                  GestureDetector(
                    child: Container(
                      height: h(53),
                      width: w(400),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: (cantidadElegida != 0
                            ? LinearGradient(
                                colors: [
                                  Color.fromRGBO(33, 13, 243, 1),
                                  Colors.blue.shade600,
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
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(350)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Generar Código De Vinculación",
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
                              LucideIcons.userPlus2,
                              color: Colors.white,
                              size: sp(20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Vibration.vibrate(duration: 10);
                      if (cantidadElegida != 0) {
                        setState(() {
                          distorcionVis = true;
                          generarCodeVinVis = true;
                          iconMetodo = LucideIcons.userPlus2;
                        });
                        Future.delayed(Duration(milliseconds: 1800), () {
                          generarTransaccion();
                        });
                      } else {
                        showFlushbarError(context, "Ingresa un monto.");
                      }
                    },
                  ),
                ],
                if (palabraSeleccionada == "Solicitud a Usuario") ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(350)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Buscar Usuario",
                            style: TextStyle(
                              color: Colors.white60,
                              fontFamily: "PoppinsBold",
                              fontSize: sp(18),
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
                                LucideIcons.search,
                                color: Colors.white,
                                size: sp(18),
                              ),
                            ),
                            // TextField
                            Expanded(
                              child: Visibility(
                                visible:
                                    (qrGeneradoVis == true ||
                                        generarCodeVinVis == true
                                    ? false
                                    : true),
                                child: TextField(
                                  controller: _controllerBusquedaUser,
                                  textAlignVertical: TextAlignVertical
                                      .center, // centra verticalmente
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                  ),
                                  cursorColor: Colors.white,
                                  decoration: InputDecoration(
                                    hintText: "Busca por Alias, CBU o Email.",
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
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
                                          _controllerBusquedaUser.clear();
                                          setState(
                                            () {},
                                          ); // refresca la visibilidad del icono
                                        },
                                        child: Icon(
                                          Icons.close,
                                          color:
                                              (_controllerBusquedaUser
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
                                        _controllerBusquedaUser.text = value;
                                      } else {
                                        _controllerBusquedaUser.text = "";
                                      }
                                    });

                                    if (value == aliasUser ||
                                        value == cbuUser ||
                                        value == emailUser) {
                                      setState(() {
                                        mismoUsuario = true;
                                      });
                                    } else {
                                      setState(() {
                                        mismoUsuario = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: h(13)),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(400)),
                        child: Text(
                          "Escribe cualquier dato del usuario: Alias (Ej: sorpresa.gusto),\nCBU (22 dígitos) o Email.",
                          style: TextStyle(
                            color: Colors.white60,
                            fontFamily: "Poppins",
                            fontSize: sp(13),
                          ),
                        ),
                      ),
                      SizedBox(height: h(33)),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(400)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Mensaje De Solicitud (Opcional)",
                            style: TextStyle(
                              color: Colors.white60,
                              fontFamily: "PoppinsBold",
                              fontSize: sp(18),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h(13)),
                      Container(
                        width: w(400),
                        height: h(100),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(
                            20,
                            25,
                            50,
                            1,
                          ), // fondo oscuro del TextField
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Visibility(
                          visible:
                              (qrGeneradoVis == true ||
                                  generarCodeVinVis == true
                              ? false
                              : true),
                          child: TextField(
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.multiline,
                            minLines: 1,
                            maxLines:
                                5, // 🔧 corregido para no romper con height fijo
                            controller: _controllerMensaje,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "Poppins",
                            ),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              hintText:
                                  "Agrega un mensaje para tu solicitud de pago.",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 13, // margen a izquierda y derecha
                                vertical: 8, // margen arriba y abajo
                              ),
                            ),
                            onChanged: (value) async {
                              setState(() {
                                _controllerMensaje.text = value;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: h(33)),
                      GestureDetector(
                        child: Container(
                          height: h(53),
                          width: w(400),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient:
                                (_controllerBusquedaUser.text != "" &&
                                    cantidadElegida != 0 &&
                                    mismoUsuario == false
                                ? LinearGradient(
                                    colors: [
                                      Color.fromRGBO(200, 90, 0, 1),
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
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(350)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Enviar Solicitud al Usuario",
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
                                  LucideIcons.user2,
                                  color: Colors.white,
                                  size: sp(20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          if (cantidadElegida != 0) {
                            if (_controllerBusquedaUser.text != "") {
                              if (mismoUsuario == false) {
                                buscarUsuario();
                              } else {
                                Vibration.vibrate(duration: 10);
                                showFlushbarError(
                                  context,
                                  "No podes solicitarte dinero a vos mismo.",
                                );
                              }
                            } else {
                              Vibration.vibrate(duration: 10);
                              showFlushbarError(context, "Ingresa Un Usuario.");
                            }
                          } else {
                            Vibration.vibrate(duration: 10);
                            showFlushbarError(context, "Ingresa un monto.");
                          }
                        },
                      ),
                    ],
                  ),
                ],
                SizedBox(height: h(33)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget qrGenerado() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: qrGeneradoVis,
      child: Dialog(
        backgroundColor: const Color(0xFF0D1B2A), // azul oscuro similar
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título + botón cerrar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w(200)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Código QR",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: "PoppinsBold",
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      borrarTransaccion();
                    },
                  ),
                ],
              ),
              SizedBox(height: h(20)),

              // QR con Container grande transparente
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: estadoTransaccion == "Pendiente"
                    ? RepaintBoundary(
                        key: _qrKey,
                        child: QrImageView(
                          data: codeTransaccion,
                          version: QrVersions.auto,
                          size: sp(173), // tamaño visual del QR
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                        ),
                      )
                    : estadoTransaccion == "En Proceso"
                    ? SizedBox(
                        height: h(150),
                        width: w(150),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color.fromRGBO(1, 165, 113, 1),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                      )
                    : null,
              ),
              SizedBox(height: h(20)),

              // Precio en verde
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: w(300)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: MoneyCounterQr(
                    amount: cantidadElegida,
                    showBalance: true,
                  ),
                ),
              ),
              SizedBox(height: h(8)),

              // Texto debajo
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: w(300)),
                child: Text(
                  "Escanea este código para enviarme el pago.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: sp(15),
                    fontFamily: "Poppins",
                  ),
                ),
              ),
              SizedBox(height: h(20)),

              /* Botones compartir y guardar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  child: Container(
                    child: Column(
                      children: [
                        Icon(Icons.share, color: Colors.white70),
                        SizedBox(height: 5),
                        Text("Compartir",
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontFamily: "Poppins")),
                      ],
                    ),
                  ),
                  onTap: () {
                    _compartirQr();
                  },
                ),
                SizedBox(width: 40),
                GestureDetector(
                  child: Container(
                    child: Column(
                      children: [
                        Icon(Icons.save_alt, color: Colors.white70),
                        SizedBox(height: 5),
                        Text("Guardar",
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontFamily: "Poppins")),
                      ],
                    ),
                  ),
                  onTap: () async {
                    await guardarQR();
                    showFlushbarCopiado(context, "QR Guardado En Galeria.");
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            */

              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: _iconAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_iconAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Vibration.vibrate(duration: 10);
                      borrarTransaccion();
                    },
                    icon: (estadoTransaccion == "Pendiente"
                        ? Icon(Icons.close, color: Colors.white)
                        : null),
                    label: Text(
                      (estadoTransaccion == "Pendiente"
                          ? "Cerrar"
                          : "Esperando Pago..."),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "PoppinsBold",
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget generarCodeVin() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: generarCodeVinVis,
      child: Column(
        children: [
          if (codeTransaccionNum == 0 &&
              estadoTransaccion != "Confirmacion") ...[
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white, width: w(0.1)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w(20)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: h(253),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Color(
                            0xFF0D1B2A,
                          ), // fondo oscuro (ajustalo según tu theme)
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icono dentro de círculo azul
                            RotationTransition(
                              turns: _controllerGiro,
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFF1D4ED8), // azul del círculo
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.keySquare,
                                  color: Colors.white,
                                  size: sp(33),
                                ),
                              ),
                            ),
                            SizedBox(height: h(20)),

                            // Título
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Generando Código",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: sp(20),
                                    fontFamily: "PoppinsBold",
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: h(8)),

                            // Subtítulo
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Creando código de vinculación seguro...",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: sp(13),
                                    fontFamily: "Poppins",
                                  ),
                                  textAlign: TextAlign.center,
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
          ],
          if (codeTransaccionNum != 0 &&
              estadoTransaccion != "Confirmacion") ...[
            Stack(
              children: [
                Center(
                  child: Container(
                    height: h(423),
                    width: w(350),
                    decoration: BoxDecoration(
                      color: Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white, width: w(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: h(33)),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF1D4ED8), // azul del círculo
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.userPlus2,
                            color: Colors.white,
                            size: sp(33),
                          ),
                        ),
                        SizedBox(height: h(23)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(300)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Código De Vinculación",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sp(23),
                                fontFamily: "PoppinsBold",
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(height: h(8)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(23)),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: Text(
                              "Comparte este código con la persona que te enviará el dinero.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: sp(17),
                                fontFamily: "Poppins",
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(height: h(33)),
                        if (estadoTransaccion != "En Proceso") ...[
                          GestureDetector(
                            child: Container(
                              width: w(250),
                              padding: const EdgeInsets.all(23),
                              decoration: BoxDecoration(
                                color: Color(0xFF0D1B2A), // fondo oscuro
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white,
                                  width: w(0.1),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Título
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: w(200),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Código de Vinculación",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: sp(15),
                                          fontFamily: "PoppinsBold",
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: h(12)),

                                  // Código grande
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: w(200),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        codeTransaccionNum.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: sp(33),
                                          fontFamily: "PoppinsBold",
                                          letterSpacing: 3,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: h(20)),

                                  // Botón copiar
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (_contenidoPortapapeles ==
                                                codeTransaccionNum.toString()
                                            ? LucideIcons.checkCircle
                                            : LucideIcons.copy),
                                        color: Colors.blue,
                                        size: sp(18),
                                      ),
                                      SizedBox(width: w(5)),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: w(200),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            (_contenidoPortapapeles ==
                                                    codeTransaccionNum
                                                        .toString()
                                                ? "Código Copiado"
                                                : "Copiar Código"),
                                            style: TextStyle(
                                              color: Colors.blue,
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
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: codeTransaccionNum.toString(),
                                ),
                              );
                              _verificarClipboard();
                              showFlushbarCopiado(
                                context,
                                "Copiaste El Código Al Portapapeles.",
                              );
                            },
                          ),
                        ],
                        if (estadoTransaccion == "En Proceso") ...[
                          Container(
                            width: w(250),
                            padding: const EdgeInsets.all(23),
                            decoration: BoxDecoration(
                              color: Color(0xFF0D1B2A), // fondo oscuro
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.1),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Título
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "Esperando Confirmacion...",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: sp(15),
                                        fontFamily: "PoppinsBold",
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: h(23)),
                                SizedBox(
                                  height: h(53),
                                  width: w(53),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromRGBO(1, 165, 113, 1),
                                    ),
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: h(13)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: h(13),
                  right: w(43),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      borrarTransaccion();
                    },
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: h(33)),
          if (estadoTransaccion != "Confirmacion") ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(20)),
              child: Container(
                height: h(243),
                padding: EdgeInsets.all(23),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A), // fondo oscuro
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 0.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Título con ícono
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF1D4ED8),
                        ),
                        SizedBox(width: w(8)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(300)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Instrucciones",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sp(18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: h(20)),

                    // Paso 1
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: w(23),
                          height: h(23),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1D4ED8),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "1",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: w(13)),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: Text(
                              "Comparte el código de vinculación con la persona que te enviará el dinero.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: sp(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: h(13)),

                    // Paso 2
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: w(23),
                          height: h(23),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1D4ED8),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "2",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: w(13)),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: Text(
                              "La otra persona debe ingresar este código en su aplicación.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: sp(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: h(13)),

                    // Paso 3
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: w(23),
                          height: h(23),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1D4ED8),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "3",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: w(13)),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: Text(
                              "Una vez conectados, podrás confirmar la transferencia de forma segura.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
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
          ],
          if (codeTransaccionNum != 0 &&
              estadoTransaccion == "Confirmacion") ...[
            Center(
              child: Container(
                height: h(500),
                width: w(350),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(10, 13, 23, 1),
                      Color.fromRGBO(15, 28, 45, 1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.green, width: w(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: h(33)),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(1, 165, 113, 1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.userPlus2,
                        color: Colors.white,
                        size: sp(33),
                      ),
                    ),
                    SizedBox(height: h(23)),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w(300)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Dispositivo Conectado",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sp(23),
                            fontFamily: "PoppinsBold",
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: h(8)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(23)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(250)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "$nameUserExterno quiere enviarte",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: sp(15),
                                      fontFamily: "Poppins",
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              SizedBox(width: w(5)),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(250)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: MoneyCounterVin(
                                    amount: cantidadElegida,
                                    showBalance: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: h(33)),
                    Container(
                      width: w(300),
                      padding: const EdgeInsets.all(23),
                      decoration: BoxDecoration(
                        color: Color(0xFF0D1B2A), // fondo oscuro
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 0.1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: h(53),
                            width: w(53),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Visibility(
                                visible: avatarUserExterno != "",
                                child: Image.asset(avatarUserExterno),
                              ),
                            ),
                          ),
                          SizedBox(width: w(13)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(183)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: SizedBox(
                                    child: Text(
                                      nameUserExterno,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: sp(18),
                                        fontFamily: "PoppinsBold",
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: h(3)),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(300)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Remitente",
                                    style: TextStyle(
                                      color: Colors.white60,
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
                    ),
                    SizedBox(height: h(33)),
                    Container(
                      width: w(300),
                      padding: const EdgeInsets.all(23),
                      decoration: BoxDecoration(
                        color: Color(0xFF0D1B2A), // fondo oscuro
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: w(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(200)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Monto A Recibir:",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: sp(15),
                                      fontFamily: "PoppinsBold",
                                    ),
                                  ),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(200)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: MoneyCounterVin(
                                    amount: cantidadElegida,
                                    showBalance: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: h(8)),
                          Divider(color: Colors.white60, thickness: h(1)),
                          SizedBox(height: h(8)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(200)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Método:",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: sp(15),
                                      fontFamily: "PoppinsBold",
                                    ),
                                  ),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(200)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    palabraSeleccionada!,
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
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: h(23)),
            GestureDetector(
              child: Container(
                height: h(53),
                width: w(350),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w(300)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Confirmar y Recibir Pago",
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
                        LucideIcons.check,
                        color: Colors.white,
                        size: sp(20),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                confirmarPagoVin();
                print(codeTransaccion);
              },
            ),
            SizedBox(height: h(23)),
            GestureDetector(
              child: Container(
                height: h(53),
                width: w(350),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white, width: w(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w(300)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Rechazar Transferencia",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "PoppinsBold",
                            fontSize: sp(18),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 23),
                    AnimatedBuilder(
                      animation: _iconAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_iconAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: Icon(LucideIcons.x, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              onTap: () {
                reset();
                borrarTransaccion();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget solicitudUsuario() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: solicitudUsuarioVis,
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (codeTransaccionNum == 0) ...[
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(10, 13, 23, 1),
                        Color.fromRGBO(15, 28, 45, 1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.green, width: w(0.3)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: w(20)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: h(273),
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(10, 13, 23, 1),
                                Color.fromRGBO(15, 28, 45, 1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color.fromRGBO(1, 165, 113, 1),
                                      Colors.green.shade600,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.circleDollarSign,
                                  color: Colors.white,
                                  size: sp(33),
                                ),
                              ),
                              SizedBox(height: h(20)),

                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: w(300)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: MoneyCounterQr(
                                    amount: cantidadElegida,
                                    showBalance: true,
                                  ),
                                ),
                              ),

                              SizedBox(height: h(8)),

                              // Subtítulo
                              SizedBox(
                                width: w(263),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Monto a Solicitar",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: sp(15),
                                      fontFamily: "Poppins",
                                    ),
                                    textAlign: TextAlign.center,
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
              SizedBox(height: h(33)),
              Center(
                child: Container(
                  width: w(350),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(10, 13, 23, 1),
                        Color.fromRGBO(15, 28, 45, 1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white, width: w(0.1)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: w(20)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: w(13), top: h(23)),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.user2,
                                    color: Color.fromRGBO(33, 13, 243, 1),
                                    size: sp(23),
                                  ),
                                  SizedBox(width: w(8)),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: w(300),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Datos del Usuario",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: sp(20),
                                          fontFamily: "PoppinsBold",
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: h(23)),
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
                                    radius: sp(28),
                                    backgroundColor: Colors.blue,
                                    child: Image.asset(avatarUserExterno),
                                  ),
                                  SizedBox(width: w(13)),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: w(183),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            nameUserExterno,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: sp(20),
                                              fontFamily: "PoppinsBold",
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: h(3)),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: w(183),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            dniUserExterno,
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
                            SizedBox(height: h(23)),
                            Container(
                              height: h(90),
                              width: w(300),
                              color: Colors.transparent,
                              child: Center(
                                child: Container(
                                  width: w(300),
                                  height: h(100),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(20, 25, 50, 1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: w(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: w(33),
                                        height: h(33),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromRGBO(33, 13, 243, 1),
                                              Colors.blue.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            iconBusquedaUser,
                                            color: Colors.white,
                                            size: sp(15),
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: w(13)),

                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tipoBusqueda,
                                              style: TextStyle(
                                                fontSize: sp(16),
                                                color: Colors.white60,
                                                fontFamily: "Poppins",
                                              ),
                                            ),
                                            SizedBox(height: h(3)),

                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                referenciaUserExterno,
                                                style: TextStyle(
                                                  fontSize: sp(17),
                                                  color: Colors.white,
                                                  fontFamily: "Poppins",
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
                            SizedBox(height: h(33)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //Mensaje (Opcional)
              if (_controllerMensaje.text.isNotEmpty) ...[
                SizedBox(height: h(33)),
                Center(
                  child: Container(
                    width: w(350),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(10, 13, 23, 1),
                          Color.fromRGBO(15, 28, 45, 1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white, width: w(0.1)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: w(20)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  left: w(13),
                                  top: h(23),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.messageSquare,
                                      color: Color.fromRGBO(200, 90, 0, 1),
                                      size: sp(23),
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
                                            fontSize: sp(20),
                                            fontFamily: "PoppinsBold",
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: h(23)),
                              Container(
                                width: w(300),
                                color: Colors.transparent,
                                child: Center(
                                  child: Container(
                                    width: w(300),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(20, 25, 50, 1),
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: w(0.1),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: w(280),
                                        ),
                                        child: Text(
                                          _controllerMensaje.text,
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontFamily: "Poppins",
                                            fontSize: sp(15),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: h(33)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: h(33)),
              Container(
                width: w(350),
                padding: EdgeInsets.all(23),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1422), // Fondo oscuro
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Color(0xFFFFD700), // Amarillo dorado
                    width: w(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono con fondo
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1422),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.shield, // Usa un ícono de seguridad
                        color: Color(0xFFFFD700), // Amarillo dorado
                        size: sp(28),
                      ),
                    ),
                    SizedBox(width: w(13)),

                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Verificación de Seguridad",
                                style: TextStyle(
                                  color: Color(0xFFFFD700), // Amarillo dorado
                                  fontSize: sp(17),
                                  fontFamily: "PoppinsBold",
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: h(5)),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: Text(
                              "Verifica que los datos del usuario sean correctos antes de enviar la solicitud. "
                              "Una vez enviada, el usuario recibirá una notificación inmediata.",
                              style: TextStyle(
                                color: Color(0xFFFFD700).withOpacity(0.8),
                                fontSize: sp(15),
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: h(33)),
              GestureDetector(
                child: Container(
                  height: h(53),
                  width: w(350),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(300)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Confirmar y Enviar Solicitud",
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
                          LucideIcons.check,
                          color: Colors.white,
                          size: sp(20),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  Vibration.vibrate(duration: 15);
                  generarTransaccion();
                  setState(() {
                    solicitudUsuarioVis = false;
                    solicitudEnviadaVis = true;
                  });
                  crearNotificacion();
                },
              ),
              SizedBox(height: h(23)),
              GestureDetector(
                child: Container(
                  height: h(53),
                  width: w(350),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white, width: w(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(300)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Cancelar",
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
                          LucideIcons.x,
                          color: Colors.white,
                          size: sp(20),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  Vibration.vibrate(duration: 15);
                  setState(() {
                    distorcionVis = false;
                    solicitudUsuarioVis = false;
                    palabraSeleccionada = "";
                    tipoBusqueda = "";
                    uidUserExterno = "";
                    _controllerCantidad.clear();
                    _controllerBusquedaUser.clear();
                    _controllerMensaje.clear();
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(1486.0); // siempre arriba
                    }
                  });
                  reset();
                },
              ),
              SizedBox(height: h(33)),
            ],
          ],
        ),
      ),
    );
  }

  Widget solicitudEnviada() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: solicitudEnviadaVis,
      child: Dialog(
        backgroundColor: Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //Animacion
              SizedBox(
                height: h(150),
                child: Lottie.asset(
                  "assets/reciboQrFinalizado.json",
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
              // Título
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(300)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "¡Solicitud Enviada!",
                      style: TextStyle(
                        fontSize: sp(23),
                        color: Colors.white,
                        fontFamily: "PoppinsBold",
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
                    "Tu solicitud de pago ha sido\nenviada exitosamente.",
                    style: TextStyle(
                      fontSize: sp(17),
                      color: Colors.white60,
                      fontFamily: "Poppins",
                    ),
                  ),
                ),
              ),
              SizedBox(height: h(23)),
              Container(
                width: w(300),
                padding: const EdgeInsets.all(23),
                decoration: BoxDecoration(
                  color: Color(0xFF0D1B2A), // fondo oscuro
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: w(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: sp(28),
                          backgroundColor: Colors.blue,
                          child: Image.asset(avatarUserExterno),
                        ),
                        SizedBox(width: w(13)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(183)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  nameUserExterno,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: sp(20),
                                    fontFamily: "PoppinsBold",
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: h(3)),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(153)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  referenciaUserExterno,
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
                    SizedBox(height: h(8)),
                    Divider(color: Colors.white60, thickness: h(1)),
                    SizedBox(height: h(8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Monto Solicitado:",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(83)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: MoneyCounterVin(
                              amount: cantidadElegida,
                              showBalance: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h(8)),
                    Divider(color: Colors.white60, thickness: h(1)),
                    SizedBox(height: h(8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Método:",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            tipoBusqueda,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: h(23)),
              Container(
                width: w(330),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(20, 30, 50, 1), // fondo oscuro
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.blue.shade700.withOpacity(0.6), // borde azul
                    width: w(1),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(300)),
                  child: Text(
                    "El usuario recibirá una notificación y podrá aceptar o rechazar tu solicitud.",
                    style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: sp(15),
                      fontFamily: "Poppins",
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: h(23)),
              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(1, 165, 113, 1), // verde esmeralda
                        Colors.green, // verde más claro
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedBuilder(
                    animation: _iconAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_iconAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          distorcionVis = false;
                          solicitudEnviadaVis = false;
                          palabraSeleccionada = "";
                          tipoBusqueda = "";
                          uidUserExterno = "";
                          _controllerBusquedaUser.text = "";
                          _controllerMensaje.text = "";
                          nameUserExterno = "";
                          uidUserExterno = "";
                          avatarUserExterno = "";
                          dniUserExterno = "";
                          referenciaUserExterno = "";
                          tipoBusqueda = "";
                          codeTransaccionNum = 0;
                          codeTransaccion = "";
                        });
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: MenuPrincipalPage(),
                          ),
                        );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(1486.0); // siempre arriba
                          }
                        });
                        reset();
                      },
                      icon: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: sp(18),
                      ),
                      label: Text(
                        "Finalizar",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Poppins",
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide
                            .none, // quita borde para que no tape el gradiente
                        backgroundColor:
                            Colors.transparent, // fondo transparente
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: sp(13)),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: h(23)),
            ],
          ),
        ),
      ),
    );
  }

  Widget reciboFinalizado() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: reciboFinalizadoVis,
      child: Dialog(
        backgroundColor: Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //Animacion
              SizedBox(
                height: h(150),
                child: Lottie.asset(
                  "assets/reciboQrFinalizado.json",
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
              // Título
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(300)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "¡Pago Recibido!",
                      style: TextStyle(
                        fontSize: sp(23),
                        color: Colors.white,
                        fontFamily: "PoppinsBold",
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
                    "Has recibido el pago exitosamente.",
                    style: TextStyle(
                      fontSize: sp(15),
                      color: Colors.white60,
                      fontFamily: "Poppins",
                    ),
                  ),
                ),
              ),
              SizedBox(height: h(23)),
              Container(
                width: w(320),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF112233), // un tono azul oscuro
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(300)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Monto recibido",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: sp(16),
                              fontFamily: "PoppinsBold",
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: h(8)),
                    // Monto
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(300)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: MoneyCounterQr(
                            amount: cantidadElegida,
                            showBalance: true,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: h(15)),
                    Divider(color: Colors.white24, thickness: h(1)),
                    SizedBox(height: h(15)),
                    // De:
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Image.asset(avatarUserExterno),
                        ),
                        SizedBox(width: w(10)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(183)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              nameUserExterno,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sp(16),
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h(20)),
                    // Método
                    Row(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(150)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Método:",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: sp(14),
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: w(10)),
                        Icon(
                          iconMetodo,
                          color: Colors.greenAccent,
                          size: sp(18),
                        ),
                        SizedBox(width: w(5)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(200)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              palabraSeleccionada!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sp(14),
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h(13)),

                    // ID Transacción
                    Row(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(150)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "ID Transacción:",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: sp(14),
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: w(10)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(250)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "#" + codeTransaccionNum.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sp(14),
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h(13)),

                    // Fecha
                    Row(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(150)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Fecha:",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: sp(14),
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: w(10)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(250)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "$fechaActual a las $horaActual\hs",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sp(14),
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
              SizedBox(height: h(23)),
              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(1, 165, 113, 1), // verde esmeralda
                        Colors.green, // verde más claro
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedBuilder(
                    animation: _iconAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_iconAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Vibration.vibrate(duration: 15);
                        setState(() {
                          distorcionVis = false;
                          reciboFinalizadoVis = false;
                          palabraSeleccionada = "";
                          _controllerCantidad.text = "";
                        });
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: MenuPrincipalPage(),
                          ),
                        );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(975.0); // siempre arriba
                          }
                        });
                        reset();
                        borrarTransaccion();
                      },
                      icon: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: sp(18),
                      ),
                      label: Text(
                        "Finalizar",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Poppins",
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide
                            .none, // quita borde para que no tape el gradiente
                        backgroundColor:
                            Colors.transparent, // fondo transparente
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        padding: EdgeInsets.symmetric(vertical: h(15)),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: h(23)),
            ],
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
    if (seconds < 1) seconds = 1;
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
                    fontSize: 32,
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
            fontSize: 32,
            color: Colors.white,
            fontFamily: "PoppinsBold",
          ),
        );
      },
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

class MoneyCounterQr extends StatelessWidget {
  final double amount;
  final bool showBalance;
  final ValueChanged<double>?
  onUpdate; // 🔹 callback opcional para devolver el double

  const MoneyCounterQr({
    super.key,
    required this.amount,
    this.onUpdate,
    this.showBalance = true,
  });

  Duration get duration {
    double seconds = 3 - (amount / 1000) * 2; // fórmula simple
    if (seconds < 1) seconds = 1;
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
                    fontSize: 25,
                    color: Colors.green,
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

class MoneyCounterVin extends StatelessWidget {
  final double amount;
  final bool showBalance;
  final ValueChanged<double>?
  onUpdate; // 🔹 callback opcional para devolver el double

  const MoneyCounterVin({
    super.key,
    required this.amount,
    this.onUpdate,
    this.showBalance = true,
  });

  Duration get duration {
    double seconds = 3 - (amount / 1000) * 2; // fórmula simple
    if (seconds < 1) seconds = 1;
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
                    fontSize: 18,
                    color: Colors.green,
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
                          fontSize: 13,
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

class NeonBorderPainter extends CustomPainter {
  final double animationValue;
  NeonBorderPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 1.8;
    final borderRadius = 20.0;
    final w = size.width;
    final h = size.height;

    // Rect centrado para stroke
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        w - strokeWidth,
        h - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    // Path completo
    final path = Path()..addRRect(rect);

    // PathMetric
    final metric = path.computeMetrics().first;
    final totalLength = metric.length;

    final dashLength = totalLength * 0.13;
    final start = (animationValue * totalLength) % totalLength;
    final end = (start + dashLength) % totalLength;

    Path extract;
    if (end > start) {
      extract = metric.extractPath(start, end);
    } else {
      final part1 = metric.extractPath(start, totalLength);
      final part2 = metric.extractPath(0, end);
      extract = Path()
        ..addPath(part1, Offset.zero)
        ..addPath(part2, Offset.zero);
    }

    // Usamos SweepGradient para que siga todo el contorno
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 3.1416 * 2,
        colors: [
          Colors.green.withOpacity(0.3),
          Colors.greenAccent.withOpacity(0.8),
          Colors.green.withOpacity(0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(covariant NeonBorderPainter oldDelegate) => true;
}
