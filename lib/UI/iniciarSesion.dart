// ignore_for_file: camel_case_types, use_key_in_widget_constructors, file_names, deprecated_member_use, avoid_print, use_build_context_synchronously, prefer_final_fields, prefer_interpolation_to_compose_strings, unused_local_variable

import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/UI/inicio.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:bluetooth/UI/recuperarPassword.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class iniciarSesionPage extends StatefulWidget {
  @override
  State<iniciarSesionPage> createState() => _iniciarSesionPageState();
}

class _iniciarSesionPageState extends State<iniciarSesionPage>
    with WidgetsBindingObserver {
  //Abrir Teclado
  late FocusNode _focusEmail;
  late FocusNode _focusPassword;

  //Controllers
  final TextEditingController _controllerEmailLogin = TextEditingController();
  final TextEditingController _controllerPasswordLogin =
      TextEditingController();

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

  //Recordarme
  bool recordarme = false;

  //Datos Usuario
  String uidUser = "";
  String nombreUser = "";
  String apellidoUser = "";
  String emailUser = "";
  String avatarUser = "";
  String iniciales = "";
  String colorUser = "";
  Color colorUI = Color.fromRGBO(1, 165, 113, 1);

  //Iniciar Sesion
  final storage = FlutterSecureStorage();
  final auth = FirebaseAuth.instance;
  final localAuth = LocalAuthentication();

  Future<void> verificarFormatoEmail() async {
    String email = _controllerEmailLogin.text.trim();
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.(com|ar|edu|org|es)$');

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        emailValido = false;
      });
    } else {
      setState(() {
        emailValido = true;
      });
    }
  }

  Future<void> verificarExistenciaEmail(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection("Usuarios")
          .where("Email", isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        print("✅ Email existe en Usuarios");

        final doc = query.docs.first;
        final data = doc.data();

        _focusEmail.unfocus();

        setState(() {
          uidUser = doc.id;
          nombreUser = data["Nombre"];
          apellidoUser = data["Apellido"];
          emailUser = data["Email"];
          avatarUser = data["Avatar"] ?? "";
          colorUser = data["Color"] ?? "";
          iniciales = nombreUser.isNotEmpty && apellidoUser.isNotEmpty
              ? "${nombreUser[0]}${apellidoUser[0]}".toUpperCase()
              : "";
          colorUI = obtenerColor(colorUser);
          cargando = false;
          currentStep = 2;
        });

        Future.delayed(const Duration(milliseconds: 218), () {
          _focusPassword.requestFocus();
        });
      } else {
        showFlushbar(context, "El email no está registrado");

        setState(() {
          cargando = false;
        });
      }
    } catch (e) {
      showFlushbar(context, "Error al verificar el email");

      setState(() {
        cargando = false;
      });
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

  Future<void> iniciarSesion() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
    });

    try {
      // 🔐 LOGIN AUTH
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailUser.trim(),
            password: _controllerPasswordLogin.text.trim() + "000",
          );

      final User user = userCredential.user!;
      uidUser = user.uid;

      // ✅ CLAVE OK
      if (!mounted) return;

      setState(() {
        claveValida = true;
        claveErronea = false;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('codeUser', uidUser);
      await prefs.setString(
        'claveUser',
        _controllerPasswordLogin.text.trim() + "000",
      );

      await storage.write(key: 'codeUser', value: uidUser);
      await storage.write(
        key: 'claveUser',
        value: _controllerPasswordLogin.text.trim() + "000",
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      setState(() {
        currentStep = 3;
      });

      // 💾 Guardar datos locales
      await guardarDatos(
        uidUser,
        (_controllerPasswordLogin.text.trim() + "000"),
      );

      await storage.write(key: 'codeUser', value: uidUser);
      await storage.write(key: 'recordarme', value: recordarme.toString());

      // 🔄 Actualizar Firestore
      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(uidUser)
          .update({"Recordarme": recordarme});

      // ⏳ Espera visual
      await Future.delayed(const Duration(seconds: 1));

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
      showFlushbar(context, "La contraseña es incorrecta.");

      setState(() {
        claveErronea = true;
        cargando = false;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _controllerPasswordLogin.clear();
          claveErronea = false;
        });
      });
    } catch (e) {
      // ❌ ERROR DESCONOCIDO
      print("Error iniciarSesion: $e");

      if (!mounted) return;
      showFlushbar(context, "Error al iniciar sesión");

      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> guardarDatos(String code, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('codeUser', code);
    await prefs.setString('passUser', password);
  }

  void showFlushbar(BuildContext context, String message) {
    Vibration.vibrate(duration: 10);
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
      icon: Icon(LucideIcons.xCircle, color: Colors.white),
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

  void _onEmailFocusChange() {
    if (!_focusEmail.hasFocus && mounted && currentStep == 1) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        Future.delayed(Duration(milliseconds: 1), () {
          if (mounted) _focusEmail.requestFocus();
        });
      }
    }
  }

  void _onPasswordFocusChange() {
    if (!_focusPassword.hasFocus && mounted) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        Future.delayed(Duration(milliseconds: 1), () {
          if (mounted) _focusPassword.requestFocus();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _focusEmail = FocusNode();
    _focusPassword = FocusNode();

    _focusEmail.addListener(_onEmailFocusChange);
    _focusPassword.addListener(_onPasswordFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusEmail.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusEmail.removeListener(_onEmailFocusChange);
    _focusPassword.removeListener(_onPasswordFocusChange);

    _focusEmail.dispose();
    _focusPassword.dispose();
    WidgetsBinding.instance.removeObserver(this);
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
        resizeToAvoidBottomInset: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            backgroundColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.light,
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
                    if (currentStep == 1) {
                      Vibration.vibrate(duration: 5);
                      if (FocusManager.instance.primaryFocus != null) {
                        FocusManager.instance.primaryFocus!.unfocus();
                      }
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: inicioPage(),
                        ),
                      );
                    } else {
                      setState(() {
                        currentStep = 1;
                      });
                      _focusEmail.addListener(_onEmailFocusChange);
                      _focusPassword.addListener(_onPasswordFocusChange);

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _focusEmail.requestFocus();
                      });
                    }
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
                          "Iniciar Sesion",
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
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: sp(13),
                              fontFamily: "Poppins",
                              color: Colors.grey,
                            ),
                            children: [
                              TextSpan(text: "Ingresa a tu cuenta de "),
                              TextSpan(
                                text: "Qore",
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: "X",
                                style: TextStyle(
                                  color: Color.fromRGBO(1, 165, 113, 1),
                                ),
                              ),
                            ],
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
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              reverseDuration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final fade = Tween<double>(begin: 0, end: 1).animate(animation);

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
                  ? ingresarEmail(key: const ValueKey('email'))
                  : currentStep == 2
                  ? ingresarPassword(key: const ValueKey('password'))
                  : ingresandoCuenta(key: const ValueKey('loading')),
            ),
          ],
        ),
      ),
    );
  }

  Widget ingresarEmail({Key? key}) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: h(48)),

          /// TEXTO INDICADOR DE PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.layers,
                  size: sp(14),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Paso 1 de 2",
                  style: TextStyle(
                    fontSize: sp(12),
                    fontFamily: "Poppins",
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(10)),

          /// INDICADOR DE PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Container(
                  width: w(32),
                  height: h(4),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(1, 165, 113, 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: w(8)),
                Container(
                  width: w(32),
                  height: h(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(33)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Ingresá tu correo",
              style: TextStyle(
                fontSize: sp(24),
                fontFamily: "PoppinsBold",
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),

          SizedBox(height: h(13)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Usamos tu email para encontrar tu cuenta",
              style: TextStyle(
                fontSize: sp(14),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(33)),

          /// INPUT EMAIL
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              height: h(58),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(23, 27, 51, 1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w(16)),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.mail,
                      size: sp(18),
                      color: Colors.white.withOpacity(0.5),
                    ),
                    SizedBox(width: w(12)),
                    Expanded(
                      child: TextField(
                        controller: _controllerEmailLogin,
                        focusNode: _focusEmail,
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: Color.fromRGBO(1, 165, 113, 1),
                        style: TextStyle(
                          fontSize: sp(15),
                          fontFamily: "Poppins",
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: "Correo electrónico",
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          verificarFormatoEmail();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: h(23)),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w(15), vertical: h(13)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// ICONO
                  Container(
                    width: w(33),
                    height: w(33),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromRGBO(
                        1,
                        165,
                        113,
                        1,
                      ).withOpacity(0.15),
                    ),
                    child: Icon(
                      LucideIcons.shieldCheck,
                      size: sp(15),
                      color: const Color.fromRGBO(1, 165, 113, 1),
                    ),
                  ),

                  SizedBox(width: w(13)),

                  /// TEXTOS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Mantener sesión iniciada",
                          style: TextStyle(
                            fontSize: sp(13),
                            fontFamily: "PoppinsMedium",
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: h(3)),
                        Text(
                          "Solo en este dispositivo",
                          style: TextStyle(
                            fontSize: sp(11),
                            fontFamily: "Poppins",
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// SWITCH
                  Switch(
                    value: recordarme,
                    onChanged: (value) {
                      setState(() {
                        recordarme = value;
                      });
                      Vibration.vibrate(duration: 3);
                    },
                    activeColor: Colors.white,
                    activeTrackColor: const Color.fromRGBO(1, 165, 113, 1),
                    inactiveThumbColor: Colors.white.withOpacity(0.6),
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ),

          Spacer(),

          // BOTÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Visibility(
              visible: emailValido,
              child: GestureDetector(
                child: Container(
                  height: h(54),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(1, 165, 113, 1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: !cargando
                        ? Text(
                            "Continuar",
                            style: TextStyle(
                              fontSize: sp(16),
                              fontFamily: "PoppinsBold",
                              color: Colors.white,
                            ),
                          )
                        : SizedBox(
                            height: h(23),
                            width: w(23),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 1,
                            ),
                          ),
                  ),
                ),
                onTap: () {
                  Vibration.vibrate(duration: 5);

                  setState(() {
                    cargando = true;
                  });

                  Future.delayed(Duration(milliseconds: 1500), () {
                    verificarExistenciaEmail(_controllerEmailLogin.text);
                  });
                },
              ),
            ),
          ),

          SizedBox(height: h(13)),
        ],
      ),
    );
  }

  Widget ingresarPassword({Key? key}) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: h(48)),

          /// TEXTO INDICADOR DE PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.layers,
                  size: sp(14),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Paso 2 de 2",
                  style: TextStyle(
                    fontSize: sp(12),
                    fontFamily: "Poppins",
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(10)),

          /// INDICADOR DE PASOS
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Container(
                  width: w(32),
                  height: h(4),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(1, 165, 113, 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: w(8)),
                Container(
                  width: w(32),
                  height: h(4),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(1, 165, 113, 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(33)),

          /// USUARIO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              onTap: () {
                setState(() => currentStep = 1);
                Future.delayed(const Duration(milliseconds: 300), () {
                  _focusEmail.requestFocus();
                });
              },
              child: Row(
                children: [
                  Container(
                    height: h(55),
                    width: h(55),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(1, 165, 113, 0.15),
                    ),
                    child: ClipOval(
                      child: avatarUser == ""
                          ? Container(
                              width: w(55),
                              height: w(55),
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
                  SizedBox(width: w(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hola, $nombreUser 👋",
                          style: TextStyle(
                            fontSize: sp(18),
                            fontFamily: "PoppinsBold",
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: h(4)),
                        Text(
                          emailUser,
                          style: TextStyle(
                            fontSize: sp(13),
                            fontFamily: "Poppins",
                            color: Colors.white.withOpacity(0.55),
                          ),
                        ),
                        SizedBox(height: h(6)),
                        Text(
                          "¿No sos vos?",
                          style: TextStyle(
                            fontSize: sp(12),
                            fontFamily: "Poppins",
                            color: const Color.fromRGBO(1, 165, 113, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h(40)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Ingresá tu clave",
              style: TextStyle(
                fontSize: sp(24),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(33)),

          /// INPUT CLAVE (LOGIN)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final filled = _controllerPasswordLogin.text.length > index;
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
                        : Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: filled
                          ? (claveErronea
                                ? Colors.red.withOpacity(0.85)
                                : const Color.fromRGBO(1, 165, 113, 1))
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: filled
                      ? (mostrarNumero
                            ? Center(
                                child: Text(
                                  _controllerPasswordLogin.text[index],
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
              controller: _controllerPasswordLogin,
              focusNode: _focusPassword,
              keyboardType: TextInputType.number,
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
                  iniciarSesion();
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
                height: h(54),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.helpCircle,
                        size: sp(13.8),
                        color: Colors.white.withOpacity(0.45),
                      ),
                      SizedBox(width: w(8)),
                      Text(
                        "Olvidé mi clave",
                        style: TextStyle(
                          fontSize: sp(15),
                          fontFamily: "PoppinsBold",
                          color: Colors.white.withOpacity(0.8),
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
        ],
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
              color: Colors.white,
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
                color: Colors.white.withOpacity(0.55),
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
}
