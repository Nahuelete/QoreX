// ignore_for_file: use_key_in_widget_constructors, camel_case_types, unused_import, unused_element, deprecated_member_use, avoid_print

import 'package:bluetooth/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class bloqueadoPage extends StatefulWidget {
  @override
  State<bloqueadoPage> createState() => _bloqueadoPageState();
}

class _bloqueadoPageState extends State<bloqueadoPage> {
  //Datos Usuarios
  String uidUser = "";
  String nombreUser = "";
  String apellidoUser = "";
  String estadoUser = "";
  String emailUser = "";
  String avatarUser = "";
  String claveUser = "";
  String iniciales = "";
  String temaUser = "";

  //Steps
  int currentStep = 1;

  //Cargando
  bool cargando = false;

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
              estadoUser = data["Estado"] ?? "Bloqueado";
              temaUser = data["Tema"] ?? "Oscuro";
              iniciales = nombreUser.isNotEmpty && apellidoUser.isNotEmpty
                  ? "${nombreUser[0]}${apellidoUser[0]}".toUpperCase()
                  : "";
            });
          }
        });
  }

  @override
  void initState() {
    super.initState();
    leerShared();

    obtenerDatos();
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
            backgroundColor: Colors.transparent,
            systemOverlayStyle: temaUser == "Oscuro"
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            elevation: 0,
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
                  ? cuentaBloqueada(key: const ValueKey('bloqueado'))
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }

  Widget cuentaBloqueada({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double v) => v / 430 * screenWidth;
    double h(double v) => v / 932 * screenHeight;
    double sp(double v) =>
        v / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return SafeArea(
      key: key,
      child: Column(
        children: [
          SizedBox(height: h(33)),

          /// ICONO BLOQUEO
          Container(
            height: h(96),
            width: h(96),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.12),
            ),
            child: Center(
              child: Icon(
                LucideIcons.lock,
                size: sp(38),
                color: Colors.red.withOpacity(0.9),
              ),
            ),
          ),

          SizedBox(height: h(28)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Cuenta bloqueada",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "PoppinsBold",
                fontSize: sp(22),
                color: temaUser == "Oscuro" ? Colors.white : Colors.black,
              ),
            ),
          ),

          SizedBox(height: h(14)),

          /// DESCRIPCION
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(42)),
            child: Text(
              "Detectamos demasiados intentos fallidos al ingresar tu clave. "
              "Por tu seguridad, el acceso a esta cuenta fue bloqueado temporalmente.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(14),
                height: 1.5,
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.65)
                    : Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          SizedBox(height: h(26)),

          /// INFO VERIFICACION
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.all(w(16)),
              decoration: BoxDecoration(
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.shieldCheck,
                    size: sp(18),
                    color: const Color.fromRGBO(1, 165, 113, 1),
                  ),
                  SizedBox(width: w(12)),
                  Expanded(
                    child: Text(
                      "Para volver a usar tu cuenta, necesitamos verificar tu identidad. "
                      "Este proceso es rápido y protege tu información.",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: sp(13.5),
                        height: 1.45,
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.75)
                            : Colors.black.withOpacity(0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h(53)),

          /// TARJETA DATOS USUARIO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.all(w(16)),
              decoration: BoxDecoration(
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.12),
                ),
              ),
              child: Row(
                children: [
                  /// AVATAR
                  Container(
                    width: w(48),
                    height: w(48),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromRGBO(1, 165, 113, 1),
                    ),
                    child: Center(
                      child: Text(
                        iniciales,
                        style: TextStyle(
                          fontSize: sp(20),
                          fontFamily: "PoppinsBold",
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: w(13)),

                  /// INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$nombreUser $apellidoUser",
                          style: TextStyle(
                            fontFamily: "PoppinsBold",
                            fontSize: sp(15),
                            color: temaUser == "Oscuro"
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        SizedBox(height: h(5)),
                        Text(
                          emailUser,
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: sp(13),
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.6)
                                : Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ESTADO
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w(10),
                      vertical: h(5),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estadoUser,
                      style: TextStyle(
                        fontFamily: "PoppinsBold",
                        fontSize: sp(10),
                        color: Colors.red.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Spacer(),

          /// BOTON VERIFICAR IDENTIDAD
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(56),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(1, 165, 113, 1),
                      Color.fromRGBO(0, 190, 130, 1),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    "Verificar identidad",
                    style: TextStyle(
                      fontFamily: "PoppinsBold",
                      fontSize: sp(16),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);
                // ir a verificación de identidad
              },
            ),
          ),

          SizedBox(height: h(16)),

          /// AYUDA
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(50),
                decoration: BoxDecoration(
                  color: temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: temaUser == "Oscuro"
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.12),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Necesito ayuda",
                    style: TextStyle(
                      fontFamily: "PoppinsMedium",
                      fontSize: sp(14),
                      color: temaUser == "Oscuro"
                          ? Colors.white.withOpacity(0.8)
                          : Colors.black.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);
              },
            ),
          ),

          SizedBox(height: h(33)),
        ],
      ),
    );
  }
}
