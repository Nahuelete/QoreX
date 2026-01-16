// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/UI/iniciarSesion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:vibration/vibration.dart';

class recuperarPasswordPage extends StatefulWidget {
  @override
  State<recuperarPasswordPage> createState() => _recuperarPasswordPageState();
}

class _recuperarPasswordPageState extends State<recuperarPasswordPage>
    with WidgetsBindingObserver {
  //Controllers
  final TextEditingController _controllerEmailRecuperar =
      TextEditingController();

  //Steps
  int currentStep = 1;

  //Abrir Teclado
  late FocusNode _focusEmailRecuperar;

  //Validar Email
  bool emailValido = false;

  bool verificarFocoEmail = true;

  //Cargando
  bool cargando = false;

  Future<void> verificarFormatoEmail() async {
    String email = _controllerEmailRecuperar.text.trim();
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

        setState(() {
          currentStep = 2;
          FocusScope.of(context).unfocus();
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
    if (!_focusEmailRecuperar.hasFocus && mounted && verificarFocoEmail) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        Future.delayed(Duration(milliseconds: 1), () {
          if (mounted) _focusEmailRecuperar.requestFocus();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _focusEmailRecuperar = FocusNode();

    _focusEmailRecuperar.addListener(_onEmailFocusChange);

    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) _focusEmailRecuperar.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusEmailRecuperar.removeListener(_onEmailFocusChange);
    _focusEmailRecuperar.dispose();
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
          colors: [Color.fromRGBO(3, 5, 25, 1), Color.fromRGBO(13, 20, 40, 1)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            backgroundColor: Color.fromRGBO(3, 5, 25, 1),
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
                    Vibration.vibrate(duration: 5);

                    setState(() {
                      verificarFocoEmail = false;
                    });

                    if (FocusManager.instance.primaryFocus != null) {
                      FocusManager.instance.primaryFocus!.unfocus();
                    }

                    Future.delayed(Duration(milliseconds: 100), () {
                      Navigator.pop(context);
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
                          "Recuperar Clave",
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
                              TextSpan(
                                text: "Recupera el acceso a tu cuenta de ",
                              ),
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
                  ? recuperarClave(key: const ValueKey('recuperarClave'))
                  : emailEnviado(key: const ValueKey('emailEnviado')),
            ),
          ],
        ),
      ),
    );
  }

  Widget recuperarClave({Key? key}) {
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
          SizedBox(height: h(23)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Recuperar clave",
              style: TextStyle(
                fontSize: sp(26),
                fontFamily: "PoppinsBold",
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),

          SizedBox(height: h(12)),

          /// DESCRIPCIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Te enviaremos un correo con instrucciones para crear una nueva clave.",
              style: TextStyle(
                fontSize: sp(13),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
                height: 1.5,
              ),
            ),
          ),

          SizedBox(height: h(36)),

          /// INPUT EMAIL
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              height: h(58),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(23, 27, 51, 1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w(15)),
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
                        controller: _controllerEmailRecuperar,
                        focusNode: _focusEmailRecuperar,
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: Colors.white,
                        style: TextStyle(
                          fontSize: sp(15),
                          fontFamily: "Poppins",
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: "Email",
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: h(18)),
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

          const Spacer(),

          /// BOTÓN ENVIAR
          Visibility(
            visible: emailValido,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w(40)),
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
                            "Enviar instrucciones",
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
                    verificarExistenciaEmail(_controllerEmailRecuperar.text);
                  });
                },
              ),
            ),
          ),

          SizedBox(height: h(16)),
        ],
      ),
    );
  }

  Widget emailEnviado({Key? key}) {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: h(80)),

          /// ICONO PRINCIPAL
          Container(
            height: h(95),
            width: h(95),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(1, 165, 113, 0.15),
            ),
            child: Icon(
              LucideIcons.mailCheck,
              size: sp(40),
              color: const Color.fromRGBO(1, 165, 113, 1),
            ),
          ),

          SizedBox(height: h(33)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Correo enviado",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sp(25),
                fontFamily: "PoppinsBold",
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),

          SizedBox(height: h(13)),

          /// DESCRIPCIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(50)),
            child: Text(
              "Te enviamos un correo con las instrucciones para crear una nueva clave.\nRevisá tu bandeja de entrada o spam.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sp(13),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
                height: 1.6,
              ),
            ),
          ),

          const Spacer(),

          /// BOTÓN VOLVER AL LOGIN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(54),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(1, 165, 113, 1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    "Volver a iniciar sesion",
                    style: TextStyle(
                      fontSize: sp(16),
                      fontFamily: "PoppinsBold",
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: iniciarSesionPage(),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: h(24)),
        ],
      ),
    );
  }
}
