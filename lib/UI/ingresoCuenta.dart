// ignore_for_file: camel_case_types, file_names, unused_field, prefer_final_fields, unused_import, prefer_interpolation_to_compose_strings, deprecated_member_use, avoid_print, unused_local_variable, use_build_context_synchronously, use_key_in_widget_constructors, unused_element, override_on_non_overriding_member, no_leading_underscores_for_local_identifiers, sized_box_for_whitespace

import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:bluetooth/UI/bloqueado.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:bluetooth/UI/recuperarPassword.dart';
import 'package:bluetooth/UI/registrarse.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class ingresoPage extends StatefulWidget {
  @override
  State<ingresoPage> createState() => _ingresoPageState();
}

class _ingresoPageState extends State<ingresoPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  //Controller
  final TextEditingController _controllerClave = TextEditingController();

  //Datos Usuario
  String uidUser = "";
  String nombreUser = "";
  String apellidoUser = "";
  String emailUser = "";
  String avatarUser = "";
  String claveUser = "";
  String iniciales = "";
  String temaUser = "";
  String colorUser = "";
  Color colorUI = Color.fromRGBO(1, 165, 113, 1);
  bool faceIdUser = false;

  //Face ID
  bool biometriaSolicitada = false;

  //Focus
  FocusNode? _focusClave;

  //Steps
  int currentStep = 1;

  //Cargando
  bool cargando = false;

  //Validar Campos
  bool emailValido = false;

  //Clave
  bool claveValida = false;
  bool claveErronea = false;
  bool _mostrarNumeroPlano = false;
  int _indicePlano = -1;
  int cantidadIntentos = 3;
  bool cuentaBloqueada = false;

  //efecto Shake
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();
    uidUser = prefs.getString('codeUser') ?? "";
    claveUser = prefs.getString('claveUser') ?? "";
  }

  Future<void> obtenerDatos() async {
    await leerShared();

    FirebaseFirestore.instance
        .collection("Usuarios")
        .doc(uidUser)
        .snapshots()
        .listen((docSnapshot) async {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              nombreUser = data["Nombre"] ?? "";
              apellidoUser = data["Apellido"] ?? "";
              emailUser = data["Email"] ?? "";
              claveUser = data["Clave"] ?? "";
              colorUser = data["Color"] ?? "";
              uidUser = data["Uid"] ?? "";
              faceIdUser = data["Face ID"] ?? false;
              temaUser = data["Tema"] ?? "Oscuro";
              iniciales = nombreUser.isNotEmpty && apellidoUser.isNotEmpty
                  ? "${nombreUser[0]}${apellidoUser[0]}".toUpperCase()
                  : "";
              colorUI = obtenerColor(colorUser);
            });

            if (faceIdUser) {
              Future.delayed(Duration(milliseconds: 500), () {
                solicitarBiometria();
              });
            }
          }
        });
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

  //Teclado Virtual
  void _agregarDigito(String digito) {
    if (_controllerClave.text.length >= 5) return;

    final nuevaClave = _controllerClave.text + digito;

    // Actualizamos el controller con un nuevo TextEditingValue
    _controllerClave.value = TextEditingValue(
      text: nuevaClave,
      selection: TextSelection.collapsed(offset: nuevaClave.length),
    );

    // Llamamos manualmente el onChanged
    _onClaveChanged(nuevaClave);
  }

  void _borrarDigito() {
    if (_controllerClave.text.isEmpty) return;

    final nuevaClave = _controllerClave.text.substring(
      0,
      _controllerClave.text.length - 1,
    );

    _controllerClave.value = TextEditingValue(
      text: nuevaClave,
      selection: TextSelection.collapsed(offset: nuevaClave.length),
    );

    _onClaveChanged(nuevaClave);
  }

  void _onClaveChanged(String value) async {
    setState(() {
      claveErronea = false;
      _mostrarNumeroPlano = true;
      _indicePlano = value.length - 1;
    });

    if (value.isNotEmpty) Vibration.vibrate(duration: 3);

    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    setState(() {
      _mostrarNumeroPlano = false;
    });

    if (value.length == 5) validarClave();
  }

  //Guardar Intentos
  Future<void> guardarTiempoIntentos() async {
    final prefs = await SharedPreferences.getInstance();

    // Hora actual
    DateTime ahora = DateTime.now();

    // Sumar 10 minutos
    DateTime horaMas10 = ahora.add(const Duration(minutes: 10));

    // Guardar como String ISO (recomendado)
    await prefs.setString('horaResetIntentos', horaMas10.toIso8601String());
    await prefs.setInt('cantidadIntentos', cantidadIntentos);
  }

  Future<void> verificarTiempoIntentos() async {
    await leerShared();
    await obtenerDatos();
    final prefs = await SharedPreferences.getInstance();

    final horaString = prefs.getString('horaResetIntentos');
    final cantidadIntentosGuardadosInt = prefs.getInt('cantidadIntentos');

    if (horaString == null) {
      setState(() {
        cantidadIntentos = 3;
      });
      return;
    }

    final DateTime horaGuardada = DateTime.parse(horaString);
    final DateTime ahora = DateTime.now();

    if (ahora.isAfter(horaGuardada) || ahora.isAtSameMomentAs(horaGuardada)) {
      setState(() {
        cantidadIntentos = 3;
      });
    } else {
      setState(() {
        cantidadIntentos = cantidadIntentosGuardadosInt!;
      });
    }
  }
  //Fin Guardar Intentos

  Future<void> bloquearCuenta() async {
    FirebaseFirestore.instance.collection("Usuarios").doc(uidUser).update({
      "Estado": "Bloqueado",
    });
  }

  Future<void> validarClave() async {
    bool esValida = BCrypt.checkpw(_controllerClave.text + "000", claveUser);

    if (esValida) {
      iniciarSesion();
    } else {
      setState(() {
        cantidadIntentos -= 1;
      });

      guardarTiempoIntentos();

      if (cantidadIntentos == 0) {
        setState(() {
          cuentaBloqueada = true;
          claveErronea = true;
        });

        bloquearCuenta();

        Future.delayed(const Duration(milliseconds: 800), () {
          Vibration.vibrate(duration: 5);

          Navigator.of(context).pushAndRemoveUntil(
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 430),
              reverseDuration: const Duration(milliseconds: 300),
              child: bloqueadoPage(),
            ),
            (Route<dynamic> route) => false,
          );
        });
      } else {
        setState(() {
          claveErronea = true;
        });

        _shakeController.forward(from: 0);
        Vibration.vibrate(duration: 15);

        Future.delayed(Duration(milliseconds: 850), () {
          setState(() {
            claveValida = false;
            _controllerClave.clear();
          });
        });

        Future.delayed(const Duration(milliseconds: 3800), () {
          setState(() {
            claveErronea = false;
          });
        });
      }
    }
  }

  //Iniciar Sesion
  final storage = FlutterSecureStorage();
  final auth = FirebaseAuth.instance;
  final localAuth = LocalAuthentication();

  Future<void> guardarDatos(String code, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('codeUser', code);
    await prefs.setString('passUser', password);
  }

  Future<void> iniciarSesion() async {
    if (!mounted) return;

    try {
      // 🔐 LOGIN AUTH
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailUser.trim(),
            password: _controllerClave.text.trim() + "000",
          );

      final User user = userCredential.user!;
      uidUser = user.uid;

      // ✅ CLAVE OK
      if (!mounted) return;

      setState(() {
        claveValida = true;
        claveErronea = false;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      setState(() {
        currentStep = 2;
      });

      // 💾 Guardar datos locales
      await guardarDatos(uidUser, (_controllerClave.text.trim() + "000"));

      await storage.write(key: 'codeUser', value: uidUser);
      await storage.write(
        key: 'claveUser',
        value: _controllerClave.text.trim() + "000",
      );

      // ⏳ Espera visual
      //Agregar vibracion "Candado"
      await Future.delayed(const Duration(milliseconds: 1300));

      Vibration.vibrate(duration: 15);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          type: PageTransitionType.leftToRight,
          child: MenuPrincipalPage(),
        ),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      // ❌ CONTRASEÑA INCORRECTA
      print("Auth error: ${e.code}");

      if (!mounted) return;
      //showFlushbar(context, "La contraseña es incorrecta.");

      /*
      setState(() {
        cantidadIntentos -= 1;
      });

      if (cantidadIntentos == 0) {
        setState(() {
          cuentaBloqueada = true;
          claveErronea = true;
          faceIdUser = false;
        });

        bloquearCuenta();

        Future.delayed(const Duration(milliseconds: 800), () {
          Vibration.vibrate(duration: 5);

          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              child: bloqueadoPage(),
            ),
          );
        });
      }

      setState(() {
        claveErronea = true;
        cargando = false;
      });

      _shakeController.forward(from: 0);

      Future.delayed(const Duration(milliseconds: 1300), () {
        if (!mounted) return;
        setState(() {
          _controllerClave.clear();
        });
      });

      Future.delayed(const Duration(milliseconds: 3800), () {
        setState(() {
          claveErronea = false;
        });
      });
      */
    } catch (e) {
      // ❌ ERROR DESCONOCIDO
      print("Error iniciarSesion: $e");

      if (!mounted) return;
      //showFlushbar(context, "Error al iniciar sesión");

      setState(() {
        cargando = false;
      });
    }
  }

  //Face ID
  Future<void> iniciarSesionFaceID() async {
    if (!mounted) return;

    try {
      // 🔐 Leer datos desde storage
      final uidGuardado = await storage.read(
        key: 'codeUser',
      ); // UID del usuario
      final claveGuardada = await storage.read(
        key: 'claveUser',
      ); // Clave plana guardada

      if (uidGuardado == null ||
          uidGuardado.isEmpty ||
          claveGuardada == null ||
          claveGuardada.isEmpty) {
        setState(() {
          claveErronea = true;
        });

        _shakeController.forward(from: 0);
        Vibration.vibrate(duration: 15);

        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() {
            claveErronea = false;
            _controllerClave.clear();
          });
        });
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _controllerClave.text = claveGuardada;
      });

      await Future.delayed(const Duration(milliseconds: 800));

      // SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('codeUser', uidUser);
      await prefs.setString('claveUser', _controllerClave.text.trim() + "000");

      await storage.write(key: 'codeUser', value: uidUser);
      await storage.write(
        key: 'claveUser',
        value: _controllerClave.text.trim(),
      );

      // ✅ Clave correcta, iniciar sesión local
      setState(() {
        claveValida = true;
        claveErronea = false;
        uidUser = uidGuardado;
      });

      setState(() {
        currentStep = 2;
      });

      await Future.delayed(const Duration(seconds: 1));

      Vibration.vibrate(duration: 15);

      // ⏳ Ir al menú principal
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          type: PageTransitionType.leftToRight,
          child: MenuPrincipalPage(),
        ),
        (_) => false,
      );
    } catch (e) {
      print("Error iniciarSesionFaceID: $e");
      if (!mounted) return;
      setState(() {
        claveErronea = true;
        cargando = false;
      });

      _shakeController.forward(from: 0);

      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        setState(() {
          _controllerClave.clear();
          claveErronea = false;
        });
      });
    }
  }

  Future<void> solicitarBiometria() async {
    if (!cuentaBloqueada) {
      setState(() {
        currentStep = 0;
        biometriaSolicitada = true;
      });

      bool canCheck = await localAuth.canCheckBiometrics;
      bool authenticated = false;

      //Setear Estado

      if (!canCheck) {
        print('El dispositivo no soporta biometría');
        setState(() {
          faceIdUser = false;
          biometriaSolicitada = false;
          currentStep = 1;
        });
        return;
      }

      try {
        authenticated = await localAuth.authenticate(
          localizedReason: 'Escanea tu huella o Face ID para iniciar sesión',
          options: const AuthenticationOptions(
            stickyAuth: false,
            biometricOnly: true,
          ),
        );
      } on PlatformException catch (e) {
        print("Error de biometría: ${e.code}");

        setState(() {
          currentStep = 1;
          biometriaSolicitada = false;
        });

        if (e.code == "NotEnrolled" ||
            e.code == "LockedOut" ||
            e.code == "PermanentlyLockedOut") {
          return;
        }

        if (e.code == "Canceled") {
          print("El usuario canceló la autenticación");
          setState(() {
            currentStep = 1;
            biometriaSolicitada = false;
          });
          return;
        }
      }

      if (authenticated) {
        iniciarSesionFaceID();
      } else {
        print('Autenticación biométrica fallida');
        setState(() {
          currentStep = 1;
          biometriaSolicitada = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    leerShared();

    obtenerDatos();

    verificarTiempoIntentos();

    _focusClave = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusClave);
    });

    // Efecto Shake mejorado con TweenSequence para un shake más natural
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 430),
    );

    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -18.0), weight: 12),
          TweenSequenceItem(tween: Tween(begin: -18.0, end: 14.0), weight: 14),
          TweenSequenceItem(tween: Tween(begin: 14.0, end: -10.0), weight: 14),
          TweenSequenceItem(tween: Tween(begin: -10.0, end: 7.0), weight: 13),
          TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 12),
          TweenSequenceItem(tween: Tween(begin: -5.0, end: 2.0), weight: 10),
          TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0), weight: 25),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 🔑 CLAVE
    _shakeController.dispose();
    _focusClave?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    // El gradiente cubre toda la pantalla, incluso detrás del AppBar, usando Stack
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: temaUser == "Oscuro"
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F1117), Color(0xFF0F1117)],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(255, 237, 235, 235),
                      Color.fromARGB(255, 237, 235, 235),
                    ],
                    stops: const [
                      0.01, // solo 1% verde arriba
                      1.0, // 95% blanco
                    ],
                  ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AppBar(
              backgroundColor: Colors.transparent,
              systemOverlayStyle: temaUser == "Oscuro"
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: Center(
                child: currentStep == 1 || currentStep == 2
                    ? Image.asset(
                        temaUser == "Oscuro"
                            ? "assets/logoAppCompleto.png"
                            : "assets/logoAppCompletoNegro.png",
                        height: h(100),
                        width: w(100),
                      )
                    : null,
              ),
            ),
          ),
          body: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                reverseDuration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final fade = Tween<double>(
                    begin: 0,
                    end: 1,
                  ).animate(animation);

                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(animation);

                  final scale = Tween<double>(
                    begin: 0.98,
                    end: 1,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: ScaleTransition(scale: scale, child: child),
                    ),
                  );
                },
                child: currentStep == 0
                    ? focusPerdido(key: const ValueKey('focus perdido'))
                    : currentStep == 1
                    ? ingresar(key: const ValueKey('ingresar'))
                    : currentStep == 2
                    ? ingresandoCuenta(key: const ValueKey('loading'))
                    : Container(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget ingresar({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double v) => v / 430 * screenWidth;
    double h(double v) => v / 932 * screenHeight;
    double sp(double v) =>
        v / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    // shake sólo cuando claveErronea es true
    if (claveErronea) {
      _shakeController.forward(from: 0);
    }

    return SafeArea(
      key: key,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: Column(
          children: [
            SizedBox(height: h(53)),

            /// AVATAR
            Container(
              height: h(88),
              width: h(88),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(1, 165, 113, 0.15),
              ),
              child: ClipOval(
                child: avatarUser == ""
                    ? Container(
                        width: w(88),
                        height: w(88),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorUI,
                        ),
                        child: Center(
                          child: Text(
                            iniciales,
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

            SizedBox(height: h(16)),

            /// NOMBRE
            Text(
              "$nombreUser $apellidoUser",
              style: TextStyle(
                fontFamily: "PoppinsBold",
                fontSize: sp(20),
                color: temaUser == "Oscuro" ? Colors.white : Colors.black,
              ),
            ),

            SizedBox(height: h(8)),

            /// SUBTEXTO
            Text(
              "Ingresá tu clave",
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(13),
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black.withOpacity(0.6),
              ),
            ),

            SizedBox(height: h(30)),

            /// INPUT CLAVE (LOGIN)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(40)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final filled = _controllerClave.text.length > index;
                  final mostrarNumero =
                      _mostrarNumeroPlano && _indicePlano == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: w(48),
                    height: w(48),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? (claveErronea
                                ? Colors.red.withOpacity(0.85)
                                : const Color.fromRGBO(1, 165, 113, 1))
                          : (temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.10)
                                : Colors.black.withOpacity(0.18)),
                      border: Border.all(
                        color: filled
                            ? (claveErronea
                                  ? Colors.red.withOpacity(0.85)
                                  : const Color.fromRGBO(1, 165, 113, 1))
                            : (temaUser == "Oscuro"
                                  ? Colors.white.withOpacity(0.25)
                                  : Colors.black.withOpacity(0.25)),
                      ),
                    ),
                    child: filled
                        ? (mostrarNumero
                              ? Center(
                                  child: Text(
                                    _controllerClave.text[index],
                                    style: TextStyle(
                                      fontSize: sp(18),
                                      fontFamily: "PoppinsBold",
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    claveErronea
                                        ? LucideIcons.x
                                        : (claveValida
                                              ? LucideIcons.check
                                              : LucideIcons.lock),
                                    size: sp(18),
                                    color: Colors.white,
                                  ),
                                ))
                        : null,
                  );
                }),
              ),
            ),

            /// INPUT OCULTO (LOGIN)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(40)),
              child: TextField(
                controller: _controllerClave,
                keyboardType: TextInputType.number,
                focusNode: _focusClave,
                autofocus: true,
                readOnly: true,
                maxLength: 5,
                obscureText: true,
                obscuringCharacter: "●",
                cursorColor: Colors.transparent,
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration(
                  counterText: "",
                  border: InputBorder.none,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                onChanged: (value) async {
                  setState(() {
                    claveErronea = false;
                    _mostrarNumeroPlano = true;
                    _indicePlano = value.length - 1;
                  });

                  if (value.isNotEmpty) {
                    Vibration.vibrate(duration: 3);
                  }

                  await Future.delayed(const Duration(milliseconds: 280));
                  if (!mounted) return;

                  setState(() {
                    _mostrarNumeroPlano = false;
                  });

                  if (value.length == 5) {
                    //iniciarSesion();
                    validarClave();
                  }
                },
              ),
            ),

            /// ALERTA CLAVE ERRONEA
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: claveErronea
                  ? Padding(
                      key: const ValueKey("error"),
                      padding: EdgeInsets.symmetric(horizontal: w(40)),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w(14),
                          vertical: h(12),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.alertCircle,
                              size: sp(15),
                              color: Colors.red.withOpacity(0.85),
                            ),
                            SizedBox(width: w(10)),
                            Expanded(
                              child: Text(
                                cantidadIntentos > 1
                                    ? "La clave ingresada es incorrecta. Te quedan $cantidadIntentos intentos."
                                    : cantidadIntentos == 0
                                    ? "La clave ingresada es incorrecta. No te quedan mas intentos."
                                    : "La clave ingresada es incorrecta. Te queda $cantidadIntentos intento.",
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: sp(13.5),
                                  color: Colors.red.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey("no_error")),
            ),

            SizedBox(height: h(13)),

            Spacer(),

            /// BOTÓN OLVIDE CLAVE
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(40)),
              child: GestureDetector(
                child: Container(
                  height: h(53),
                  decoration: BoxDecoration(
                    color: temaUser == "Oscuro"
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: temaUser == "Oscuro"
                          ? Colors.white.withOpacity(0.13)
                          : Colors.black.withOpacity(0.73),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.helpCircle,
                          size: sp(13.8),
                          color: temaUser == "Oscuro"
                              ? Colors.white.withOpacity(0.45)
                              : Colors.black.withOpacity(0.73),
                        ),
                        SizedBox(width: w(8)),
                        Text(
                          "Olvidé mi clave",
                          style: TextStyle(
                            fontSize: sp(15),
                            fontFamily: "PoppinsBold",
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.8)
                                : Colors.black.withOpacity(0.8),
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
                      type: PageTransitionType.rightToLeft,
                      child: recuperarPasswordPage(),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: h(23)),

            /// TECLADO
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(28)),
              child: Column(
                children: [
                  for (var fila in [
                    ["1", "2", "3"],
                    ["4", "5", "6"],
                    ["7", "8", "9"],
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: h(14)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: fila.map((n) {
                          return _tecla(
                            texto: n,
                            w: w,
                            sp: sp,
                            onTap: () => _agregarDigito(n),
                          );
                        }).toList(),
                      ),
                    ),

                  /// FILA FINAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// FACE ID
                      _teclaIcono(
                        icon: LucideIcons.scanFace,
                        esFaceId: true,
                        w: w,
                        onTap: () {
                          Vibration.vibrate(duration: 5);
                          solicitarBiometria();
                        },
                      ),

                      /// 0
                      _tecla(
                        texto: "0",
                        w: w,
                        sp: sp,
                        onTap: () => _agregarDigito("0"),
                      ),

                      /// BORRAR
                      _teclaIcono(
                        icon: LucideIcons.delete,
                        w: w,
                        onTap: () {
                          _borrarDigito();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget ingresandoCuenta({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return SafeArea(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// AVATAR
          Container(
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
                          iniciales,
                          style: TextStyle(
                            fontSize: sp(23),
                            fontFamily: "PoppinsBold",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Image.asset(avatarUser, fit: BoxFit.cover),
            ),
          ),

          SizedBox(height: h(20)),

          /// TEXTO PRINCIPAL
          Text(
            "Ingresando a tu cuenta",
            style: TextStyle(
              fontSize: sp(18),
              fontFamily: "PoppinsBold",
              color: temaUser == "Oscuro" ? Colors.white : Colors.black,
            ),
          ),

          SizedBox(height: h(8)),

          /// SUBTEXTO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(60)),
            child: Text(
              "Estamos verificando tu información de forma segura",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sp(13),
                fontFamily: "Poppins",
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ),

          SizedBox(height: h(33)),

          /// LOADER
          SizedBox(
            height: h(38),
            width: h(38),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color.fromRGBO(1, 165, 113, 1),
            ),
          ),
        ],
      ),
    );
  }

  //Focus Perdido
  Widget focusPerdido({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double v) => v / 430 * screenWidth;
    double h(double v) => v / 932 * screenHeight;
    double sp(double v) =>
        v / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Stack(
      children: [
        // 🔹 Contenido principal
        SafeArea(
          child: Container(
            width: screenWidth,
            height: screenHeight,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // centra horizontalmente
              children: [
                SizedBox(
                  height: h(200),
                ), // 🔹 distancia desde arriba (ajustá a gusto)
                Center(
                  child: Image.asset(
                    "assets/logoApp.png",
                    height: h(83),
                    width: w(83),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w(400)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Qore",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "PoppinsBold",
                              fontSize: sp(38),
                            ),
                          ),
                          TextSpan(
                            text: "X",
                            style: TextStyle(
                              color: Color(0xFF01A571),
                              fontFamily: "PoppinsBold",
                              fontSize: sp(38),
                            ),
                          ),
                        ],
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
                      "Tu dinero, siempre con vos.",
                      style: TextStyle(
                        color: Colors.white60,
                        fontFamily: "PoppinsBold",
                        fontSize: sp(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //Extras
  Widget _tecla({
    required String texto,
    required double Function(double) w,
    required double Function(double) sp,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w(90),
        height: w(60),
        decoration: BoxDecoration(
          color: temaUser == "Oscuro"
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            texto,
            style: TextStyle(
              fontFamily: "PoppinsBold",
              fontSize: sp(23),
              color: temaUser == "Oscuro" ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _teclaIcono({
    required IconData icon,
    required double Function(double) w,
    required VoidCallback onTap,
    bool esFaceId = false,
  }) {
    final bool habilitado = !esFaceId || faceIdUser;

    return GestureDetector(
      onTap: habilitado ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: w(90),
        height: w(60),
        decoration: BoxDecoration(
          color: habilitado
              ? (temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.18))
              : (temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.025)
                    : Colors.black.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: habilitado
                ? Colors.transparent
                : (temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.12)),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: w(24),
            color: habilitado
                ? (temaUser == "Oscuro" ? Colors.white : Colors.black)
                : (temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.35)
                      : Colors.black.withOpacity(0.35)),
          ),
        ),
      ),
    );
  }
}
