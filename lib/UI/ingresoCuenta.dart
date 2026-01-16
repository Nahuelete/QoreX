// ignore_for_file: camel_case_types, file_names, unused_field, prefer_final_fields, unused_import, prefer_interpolation_to_compose_strings, deprecated_member_use, avoid_print, unused_local_variable, use_build_context_synchronously, use_key_in_widget_constructors, unused_element

import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:bluetooth/UI/recuperarPassword.dart';
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
    with TickerProviderStateMixin {
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
  bool faceIdUser = false;

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
              uidUser = data["Uid"] ?? "";
              faceIdUser = data["Face ID"] ?? false;
              temaUser = data["Tema"] ?? "Oscuro";
              iniciales = nombreUser.isNotEmpty && apellidoUser.isNotEmpty
                  ? "${nombreUser[0]}${apellidoUser[0]}".toUpperCase()
                  : "";
            });

            if (faceIdUser) {
              Future.delayed(Duration(milliseconds: 500), () {
                solicitarBiometria();
              });
            }
          }
        });
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

  Future<void> validarClave() async {
    bool esValida = BCrypt.checkpw(_controllerClave.text + "000", claveUser);

    if (esValida) {
      iniciarSesion();
    } else {
      setState(() {
        claveErronea = true;
      });

      Future.delayed(Duration(milliseconds: 850), () {
        setState(() {
          claveValida = false;
          claveErronea = false;
          _controllerClave.clear();
        });
      });
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

      // ⏳ Espera visual
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

      setState(() {
        claveErronea = true;
        cargando = false;
      });

      _shakeController.forward(from: 0);

      Future.delayed(const Duration(milliseconds: 1300), () {
        if (!mounted) return;
        setState(() {
          _controllerClave.clear();
          claveErronea = false;
        });
      });
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

      // 🔑 Poner la clave en el TextField (opcional, para feedback visual)
      setState(() {
        _controllerClave.text = claveGuardada;
      });

      await Future.delayed(const Duration(milliseconds: 800));

      // ✅ Clave correcta, iniciar sesión local
      setState(() {
        claveValida = true;
        claveErronea = false;
        uidUser = uidGuardado;
      });

      await Future.delayed(const Duration(milliseconds: 800));

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
    bool canCheck = await localAuth.canCheckBiometrics;
    bool authenticated = false;

    //Setear Estado

    if (!canCheck) {
      print('El dispositivo no soporta biometría');

      setState(() {
        _controllerClave.text = "00000";
        claveErronea = true;
      });

      _shakeController.forward(from: 0);

      Future.delayed(Duration(milliseconds: 800), () {
        setState(() {
          claveValida = false;
          claveErronea = false;
          _controllerClave.clear();
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
          _controllerClave.text = "00000";
          claveErronea = true;
        });

        _shakeController.forward(from: 0);

        Future.delayed(Duration(milliseconds: 800), () {
          setState(() {
            claveValida = false;
            claveErronea = false;
            _controllerClave.clear();
          });
        });
        return;
      }

      if (e.code == "Canceled") {
        print("El usuario canceló la autenticación");
        setState(() {
          _controllerClave.text = "00000";
          claveErronea = true;
        });

        _shakeController.forward(from: 0);

        Future.delayed(Duration(milliseconds: 800), () {
          setState(() {
            claveValida = false;
            claveErronea = false;
            _controllerClave.clear();
          });
        });
        return;
      }
    }

    if (authenticated) {
      iniciarSesionFaceID();
    } else {
      print('Autenticación biométrica fallida');
      setState(() {
        _controllerClave.text = "00000";
        claveErronea = true;
      });

      _shakeController.forward(from: 0);

      Future.delayed(Duration(milliseconds: 800), () {
        setState(() {
          claveValida = false;
          claveErronea = false;
          _controllerClave.clear();
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    leerShared();

    obtenerDatos();

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
                    colors: [
                      Color.fromRGBO(3, 5, 25, 1),
                      Color.fromRGBO(13, 20, 40, 1),
                    ],
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
                child: Image.asset(
                  temaUser == "Oscuro"
                      ? "assets/logoAppCompleto.png"
                      : "assets/logoAppCompletoNegro.png",
                  height: h(100),
                  width: w(100),
                ),
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
                child: currentStep == 1
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
                          color: const Color.fromRGBO(1, 165, 113, 1),
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
                          : Colors.black.withOpacity(0.18),
                      border: Border.all(
                        color: filled
                            ? (claveErronea
                                  ? Colors.red.withOpacity(0.85)
                                  : const Color.fromRGBO(1, 165, 113, 1))
                            : Colors.black.withOpacity(0.25),
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

            SizedBox(height: h(33)),

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
                        color: const Color.fromRGBO(1, 165, 113, 1),
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
          child: Icon(
            icon,
            color: temaUser == "Oscuro" ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
