// ignore_for_file: use_key_in_widget_constructors, camel_case_types, unused_import, unused_element, deprecated_member_use, avoid_print, unused_field, use_build_context_synchronously, curly_braces_in_flow_control_structures, prefer_interpolation_to_compose_strings, unused_local_variable, unnecessary_import

import 'dart:convert';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:another_flushbar/flushbar_route.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:bluetooth/UI/iniciarSesion.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:bluetooth/main.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class bloqueadoPage extends StatefulWidget {
  @override
  State<bloqueadoPage> createState() => _bloqueadoPageState();
}

class _bloqueadoPageState extends State<bloqueadoPage>
    with WidgetsBindingObserver {
  //Datos Usuarios
  String uidUser = "";
  String nombreUser = "";
  String dniUser = "";
  String apellidoUser = "";
  String estadoUser = "";
  String emailUser = "";
  String avatarUser = "";
  String claveUser = "";
  String iniciales = "";
  String temaUser = "";
  String colorUser = "";
  Color colorUI = Color.fromRGBO(1, 165, 113, 1);

  //Steps
  int currentStep = 1;

  //Controller
  final TextEditingController _controllerCodeEmail = TextEditingController();
  final TextEditingController _controllerMensaje = TextEditingController();

  //Cargando
  bool cargando = false;
  bool cargandoCambiar = false;
  bool cargandoMismo = false;
  bool cargandoVolver = false;
  bool cargandoAyuda = false;

  //Focus
  FocusNode? _focusCode;
  FocusNode? _focusContacto;

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
              dniUser = data["Dni"] ?? "";
              claveUser = data["Clave"] ?? "";
              uidUser = data["Uid"] ?? "";
              colorUser = data["Color"] ?? "";
              estadoUser = data["Estado"] ?? "Bloqueado";
              temaUser = data["Tema"] ?? "Oscuro";
              iniciales = nombreUser.isNotEmpty && apellidoUser.isNotEmpty
                  ? "${nombreUser[0]}${apellidoUser[0]}".toUpperCase()
                  : "";
              colorUI = obtenerColor(colorUser);
            });
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

  Future<void> avanzarPaso() async {
    setState(() {
      currentStep++;
    });
  }

  Future<void> desbloquearCuenta() async {
    FirebaseFirestore.instance.collection("Usuarios").doc(uidUser).update({
      "Estado": "Habilitado",
    });

    Navigator.pushAndRemoveUntil(
      context,
      PageTransition(
        type: PageTransitionType.leftToRight,
        child: MenuPrincipalPage(),
      ),
      (_) => false,
    );
  }

  //Escanear DNI
  String dniObtenido = "";

  /// Controlador de cámara para escaneo de DNI
  CameraController? _cameraControllerDni;

  /// Lista de cámaras disponibles (DNI)
  List<CameraDescription>? _camerasDni;

  /// Evita múltiples detecciones simultáneas
  bool _isDetecting = false;

  /// Evita ejecutar lógica luego de dispose
  bool _isDisposed = false;

  /// Indica si el escaneo fue completado correctamente
  bool _isComplete = false;

  /// Evita múltiples capturas de imagen
  bool _isTakingPicture = false;

  /// Reconocedor de texto (ML Kit)
  TextRecognizer? _textRecognizer;

  /// Imagen capturada del DNI
  XFile? _dniPhoto;

  Future<bool> verificarDni(String dni) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (dni == dniUser) {
      print("VERIFICADO");
      setState(() {
        _isDetecting = false;
        cargando = false;
        _isComplete = true;
      });
      Future.delayed(const Duration(milliseconds: 3800), () {
        if (!mounted) return;

        _isDisposed = true; // 🔥 CORTA EL LOOP
        _isComplete = true;

        _cameraControllerDni?.dispose();
        _cameraControllerDni = null;
        _textRecognizer?.close();

        setState(() {
          avanzarPaso(); // ✅ ahora sí cambia la UI
        });
      });
      return true;
    } else {
      print("DNI INCORRECTO");
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => alertaDniIncorrecto(),
      );
      WidgetsBinding.instance.removeObserver(this);
      _isDisposed = true;
      _cameraControllerDni?.dispose();
      _textRecognizer?.close();
      return false;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      var status = await Permission.camera.request();
      if (!status.isGranted) return;

      _camerasDni = await availableCameras();
      if (_camerasDni == null || _camerasDni!.isEmpty) return;

      _cameraControllerDni = CameraController(
        _camerasDni!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraControllerDni!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Error inicializando cámara: $e");
    }
  }

  Future<void> _takePicture() async {
    if (_isDisposed) return;
    if (_isTakingPicture) return;

    if (_cameraControllerDni == null ||
        !_cameraControllerDni!.value.isInitialized)
      return;

    _isTakingPicture = true;

    try {
      final XFile picture = await _cameraControllerDni!.takePicture();
      if (_isDisposed) return;

      _dniPhoto = picture;
      await processDni(picture);
    } catch (e) {
      if (!_isDisposed) {
        print("Error al tomar la foto: $e");
      }
    } finally {
      _isTakingPicture = false;
    }
  }

  Future<String> extractTextFromImage(XFile file) async {
    final InputImage inputImage = InputImage.fromFilePath(file.path);
    final TextRecognizer textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    await textRecognizer.close();
    return recognizedText.text;
  }

  String? extractDni(String scannedText) {
    final RegExp dniRegex = RegExp(r'\b\d{2}\.\d{3}\.\d{3}\b');

    final match = dniRegex.firstMatch(scannedText);

    return match?.group(0);
  }

  Future<void> processDni(XFile? file) async {
    if (file == null) return;

    final scannedText = await extractTextFromImage(file);
    final dni = extractDni(scannedText);

    if (dni != null) {
      if (mounted) {
        setState(() {
          cargando = true;
        });
      }

      print("DNI escaneado: $dni");

      // Verificar que coincida con el pupilo
      bool verificado = await verificarDni(dni.toString());
      if (!verificado) {
        if (mounted) {
          //showFlushbar(context, "El DNI no coincide con el pupilo.");
          setState(() {
            cargando = false;
          });
          _initializeCamera();
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _isDetecting = true;

        //_isComplete = true; // ✅ solo si DNI verificado
      });

      Vibration.vibrate(duration: 15);

      await Future.delayed(const Duration(milliseconds: 4000));
      if (!mounted) return;

      try {
        if (_cameraControllerDni != null &&
            _cameraControllerDni!.value.isStreamingImages) {
          await _cameraControllerDni!.stopImageStream();
        }
        await _cameraControllerDni?.dispose();
        _cameraControllerDni = null;
      } catch (e) {
        print("Error liberando cámara: $e");
      }

      print("ESCANEADO CORRECTAMENTE");
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    } else {
      if (mounted) _initializeCamera();
    }
  }

  Future<void> startLoop() async {
    while (!_isComplete && !_isDisposed) {
      await Future.delayed(const Duration(seconds: 5));

      if (_isComplete || _isDisposed) break;
      if (_isTakingPicture) continue;

      await _cameraControllerDni!.pausePreview();
      await _takePicture();
    }
  }
  //Fin Escanear DNI

  //Face ID
  final storage = FlutterSecureStorage();
  final auth = FirebaseAuth.instance;
  final localAuth = LocalAuthentication();

  Future<void> solicitarBiometria() async {
    bool canCheck = await localAuth.canCheckBiometrics;
    bool authenticated = false;

    //Setear Estado

    if (!canCheck) {
      print('El dispositivo no soporta biometría');
      setState(() {
        //currentStep = 3;  VER
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
        currentStep = 4;
      });

      if (e.code == "NotEnrolled" ||
          e.code == "LockedOut" ||
          e.code == "PermanentlyLockedOut") {
        return;
      }

      if (e.code == "Canceled") {
        print("El usuario canceló la autenticación");
        setState(() {
          currentStep = 4;
        });
        return;
      }
    }

    if (authenticated) {
      setState(() {
        currentStep = 5;
      });
    } else {
      print('Autenticación biométrica fallida');
      setState(() {
        currentStep = 4;
      });
    }
  }

  //Verificar Por Email
  String code = "";
  bool emailReenviado = false;

  Future<void> generarCodigo() async {
    final random = Random.secure();

    setState(() {
      code = (10000 + random.nextInt(90000)).toString();
    });
  }

  Future<int> sendEmailCode() async {
    await generarCodigo();

    final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");

    const serviceId = "service_z3hbbeh";
    const templateId = "template_p29hdhe";
    const userId = "bc4FkZberPqwpjovF";

    final response = await http.post(
      url,
      headers: {"origin": "http:localhost", "Content-Type": "application/json"},
      body: json.encode({
        "service_id": serviceId,
        "template_id": templateId,
        "user_id": userId,
        "template_params": {"codigo": code, "sender_email": emailUser},
      }),
    );

    return response.statusCode;
  }

  void verificarCodeEmail() {
    final codeIngresado = _controllerCodeEmail.text.trim();

    // ✅ Código correcto
    if (code == codeIngresado) {
      Future.delayed(Duration(seconds: 1), () {
        Vibration.vibrate(duration: 5);
        setState(() {
          currentStep = 5;
        });
      });

      return;
    }

    // ❌ Código incorrecto
    Vibration.vibrate(duration: 50);
    showFlushbar(context, "Código incorrecto");

    setState(() {
      _focusCode?.requestFocus();
      _controllerCodeEmail.clear();
    });
  }

  //Contactar Soporte
  String tituloGenerado = "";

  Future<void> generarTituloIA() async {
    final texto = _controllerMensaje.text.trim();
    if (texto.length < 10) return;

    setState(() {
      cargando = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization":
              "Bearer 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",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
                  "Generá un título corto y claro (máx 5 palabras) para el problema del usuario. Sin comillas.",
            },
            {"role": "user", "content": texto},
          ],
          "temperature": 0.4,
          "max_tokens": 20,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final titulo = data["choices"][0]["message"]["content"];

        setState(() {
          tituloGenerado = titulo.trim();
        });
      } else {
        debugPrint("Error IA: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error IA: $e");
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> enviarReporte() async {
    String codeReporte = "";

    final random = Random.secure();

    setState(() {
      codeReporte = (10000 + random.nextInt(90000)).toString();
    });

    FirebaseFirestore.instance
        .collection("ReportesBloqueados")
        .doc(codeReporte)
        .set({
          "De": "$nombreUser $apellidoUser",
          "Uid De": uidUser,
          "Problema": _controllerMensaje.text,
          "Titulo": tituloGenerado,
          "Codigo": codeReporte,
        });
  }

  //Cambiar Clave
  final TextEditingController _controllerNuevaClave = TextEditingController();

  bool claveValida = false;
  bool claveCambiada = false;
  bool _mostrarNumeroPlano = false;
  int _indicePlano = -1;

  bool esClaveValida(String value) {
    if (value.length < 3) return true;

    for (int i = 0; i < value.length - 2; i++) {
      final a = int.parse(value[i]);
      final b = int.parse(value[i + 1]);
      final c = int.parse(value[i + 2]);

      // Secuencia ascendente o descendente
      final asc = b == a + 1 && c == b + 1;
      final desc = b == a - 1 && c == b - 1;

      // Repetición de 3 números iguales
      final repeat = a == b && b == c;

      if (asc || desc || repeat) return false;
    }
    return true;
  }

  String hashClave(String clave) {
    return BCrypt.hashpw(clave, BCrypt.gensalt());
  }

  /// Re-autenticar al usuario con su contraseña actual (Firebase Auth)
  Future<bool> reautenticarUsuario(String claveActual) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return false;

    // 🔐 Leer datos desde storage
    final uidGuardado = await storage.read(key: 'codeUser'); // UID del usuario
    final claveGuardada = await storage.read(
      key: 'claveUser',
    ); // Clave plana guardada

    print(uidGuardado);
    print(claveGuardada);

    try {
      final credential = EmailAuthProvider.credential(
        email: emailUser,
        password: claveGuardada!,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      print("Error re-autenticando: ${e.code}");
      return false;
    }
  }

  /// Guardar la nueva clave (Firestore, Firebase Auth, SharedPreferences)
  Future<void> guardarClave(String claveNueva, String claveActual) async {
    setState(() {
      cargando = true;
    });

    final nuevaClaveCompleta = claveNueva;
    final claveHash = hashClave(nuevaClaveCompleta);

    try {
      // 1️⃣ Firestore
      if (uidUser.isEmpty) throw Exception("UID vacío");
      await FirebaseFirestore.instance
          .collection("Usuarios")
          .doc(uidUser)
          .update({"Clave": claveHash});

      // 2️⃣ Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no logueado");

      bool reautenticado = await reautenticarUsuario(claveActual);
      if (!reautenticado) throw Exception("No se pudo re-autenticar");

      await user.updatePassword(nuevaClaveCompleta);

      // 3️⃣ Local Storage
      await storage.write(key: 'codeUser', value: uidUser);
      await storage.write(key: 'claveUser', value: nuevaClaveCompleta);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('claveUser', nuevaClaveCompleta);

      // 4️⃣ Actualizar estado solo si todo salió bien
      setState(() {
        claveUser = nuevaClaveCompleta;
        claveCambiada = true;
      });

      avanzarPaso();

      print("✅ Clave actualizada correctamente en todos los pasos");
    } catch (e) {
      print("❌ Error al actualizar clave, no se aplicaron cambios: $e");

      // Opcional: mostrar un dialogo al usuario
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => alertaErrorCambiarClave(),
        );
      }
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  void showFlushbar(BuildContext context, String message) {
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

  @override
  void initState() {
    super.initState();
    leerShared();

    obtenerDatos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraControllerDni?.dispose();
    _textRecognizer?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraControllerDni == null ||
        !_cameraControllerDni!.value.isInitialized)
      return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraControllerDni?.dispose();
      _cameraControllerDni = null;
    }

    if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
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
                stops: const [0.01, 1.0],
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
              child: currentStep == -1
                  ? verificarEmailCodigo(key: const ValueKey('verificar email'))
                  : currentStep == 0
                  ? noPuedoUsarFaceId(key: const ValueKey('no face id'))
                  : currentStep == 1
                  ? cuentaBloqueada(key: const ValueKey('bloqueado'))
                  : currentStep == 2
                  ? escanearDniBloqueo(key: const ValueKey('escanear dni'))
                  : currentStep == 3
                  ? desbloqueoFaceId(key: const ValueKey('face id'))
                  : currentStep == 4
                  ? errorFaceId(key: const ValueKey('error face id'))
                  : currentStep == 5
                  ? decisionCambiarClave(key: const ValueKey('decision clave'))
                  : currentStep == 6
                  ? cambiarClave(key: const ValueKey('cambiar clave'))
                  : currentStep == 7
                  ? avisoClaveCambiada(key: const ValueKey('clave cambiada'))
                  : currentStep == 8
                  ? verificacionExitosa(key: const ValueKey('desbloqueado'))
                  : currentStep == 9
                  ? necesitoAyuda(key: const ValueKey('ayuda'))
                  : currentStep == 10
                  ? problemasIdentidad(
                      key: const ValueKey('problemas indentidad'),
                    )
                  : currentStep == 11
                  ? seguridadActividadSospechosa(
                      key: const ValueKey('actividad sospechosa'),
                    )
                  : currentStep == 12
                  ? contactarSoporte(key: const ValueKey('contactar soporte'))
                  : currentStep == 13
                  ? contactoSoporteEnviado(
                      key: const ValueKey('soporte enviado'),
                    )
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
                      color: colorUI,
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
                height: h(55),
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
                  child: !cargando
                      ? Text(
                          "Verificar identidad",
                          style: TextStyle(
                            fontFamily: "PoppinsBold",
                            fontSize: sp(16),
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
                  avanzarPaso();

                  setState(() {
                    cargando = false;
                  });

                  //Escanear Dni
                  _textRecognizer = GoogleMlKit.vision.textRecognizer();
                  _initializeCamera();

                  startLoop();
                  //Fin Escanear Dni
                });
              },
            ),
          ),

          SizedBox(height: h(15)),

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
                  child: !cargandoAyuda
                      ? Text(
                          "Necesito ayuda",
                          style: TextStyle(
                            fontFamily: "PoppinsMedium",
                            fontSize: sp(14),
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.8)
                                : Colors.black.withOpacity(0.8),
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
                  cargandoAyuda = true;
                });

                Future.delayed(Duration(milliseconds: 1500), () {
                  setState(() {
                    currentStep = 9;
                    cargandoAyuda = false;
                  });
                });
              },
            ),
          ),

          SizedBox(height: h(33)),
        ],
      ),
    );
  }

  Widget escanearDniBloqueo({Key? key}) {
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

          /// PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.userPlus,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Desbloquear cuenta",
                  style: TextStyle(
                    fontSize: sp(12),
                    fontFamily: "Poppins",
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(23)),

          /// TEXTO PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  Icons.document_scanner_rounded,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(5)),
                Text(
                  "Paso 1 de 2",
                  style: TextStyle(
                    fontSize: sp(13),
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
              children: List.generate(2, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(33),
                    height: h(5),
                    decoration: BoxDecoration(
                      color: index < 1
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: h(33)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Escaneá tu DNI",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Colocá el frente del DNI dentro del marco",
              style: TextStyle(
                fontSize: sp(13),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),

          SizedBox(height: h(28)),

          /// AREA CAMARA
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(33)),
            child: Center(
              child:
                  _cameraControllerDni != null &&
                      _cameraControllerDni!.value.isInitialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        /// CONTENIDO ORIGINAL
                        _isComplete == true
                            ? Center(
                                child: Container(
                                  width: w(300),
                                  height: h(260),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color.fromRGBO(
                                        1,
                                        165,
                                        113,
                                        1,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        1,
                                        165,
                                        113,
                                        1,
                                      ).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: LottieBuilder.asset(
                                        "assets/escanDniComplete.json",
                                        repeat: false,
                                        width: w(213),
                                        height: h(213),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Container(
                                  width: w(300),
                                  height: h(180),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color.fromRGBO(
                                        1,
                                        165,
                                        113,
                                        1,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _cameraControllerDni!
                                            .value
                                            .previewSize!
                                            .height,
                                        height: _cameraControllerDni!
                                            .value
                                            .previewSize!
                                            .width,
                                        child: CameraPreview(
                                          _cameraControllerDni!,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                        /// OVERLAY DE CARGA (NUEVO)
                        if (cargando)
                          Container(
                            width: w(300),
                            height: _isComplete ? h(260) : h(180),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: w(32),
                                  height: w(32),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: const Color.fromRGBO(1, 165, 113, 1),
                                  ),
                                ),
                                SizedBox(height: h(14)),
                                Text(
                                  "Comprobando DNI...",
                                  style: TextStyle(
                                    fontSize: sp(14),
                                    fontFamily: "Poppins",
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  : const CircularProgressIndicator(
                      color: Color.fromRGBO(1, 165, 113, 1),
                    ),
            ),
          ),

          SizedBox(height: h(20)),

          /// INFO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.info,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.4),
                ),
                SizedBox(width: w(8)),
                Expanded(
                  child: Text(
                    "Asegurate de que el DNI esté bien iluminado y enfocado",
                    style: TextStyle(
                      fontSize: sp(13),
                      fontFamily: "Poppins",
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget desbloqueoFaceId({Key? key}) {
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
          SizedBox(height: h(48)),

          /// PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.userPlus,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Desbloquear cuenta",
                  style: TextStyle(
                    fontSize: sp(12),
                    fontFamily: "Poppins",
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(23)),

          /// TEXTO PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.scanFace,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(5)),
                Text(
                  "Paso 2 de 2",
                  style: TextStyle(
                    fontSize: sp(13),
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
              children: List.generate(2, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(33),
                    height: h(5),
                    decoration: BoxDecoration(
                      color: index < 2
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: h(33)),

          /// ICONO FACE ID
          Container(
            height: h(120),
            width: h(120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(1, 165, 113, 0.12),
            ),
            child: Center(
              child: Icon(
                LucideIcons.scanFace,
                size: sp(48),
                color: const Color.fromRGBO(1, 165, 113, 1),
              ),
            ),
          ),

          SizedBox(height: h(30)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Verificación de identidad",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "PoppinsBold",
                fontSize: sp(22),
                color: temaUser == "Oscuro" ? Colors.white : Colors.black,
              ),
            ),
          ),

          SizedBox(height: h(14)),

          /// TEXTO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(42)),
            child: Text(
              "Para desbloquear tu cuenta necesitamos confirmar que sos vos. "
              "Usá Face ID para validar tu identidad de forma segura.",
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

          SizedBox(height: h(30)),

          /// INFO SEGURIDAD
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
                    LucideIcons.lock,
                    size: sp(18),
                    color: const Color.fromRGBO(1, 165, 113, 1),
                  ),
                  SizedBox(width: w(12)),
                  Expanded(
                    child: Text(
                      "Tu información biométrica no se almacena ni se comparte. "
                      "La validación se realiza únicamente en tu dispositivo.",
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

          Spacer(),

          /// BOTON FACE ID
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.scanFace,
                        color: Colors.white,
                        size: sp(18),
                      ),
                      SizedBox(width: w(10)),
                      Text(
                        "Verificarme con Face ID",
                        style: TextStyle(
                          fontFamily: "PoppinsBold",
                          fontSize: sp(16),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);
                solicitarBiometria();
              },
            ),
          ),

          SizedBox(height: h(15)),

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
                  child: !cargando
                      ? Text(
                          "No puedo usar Face ID",
                          style: TextStyle(
                            fontFamily: "PoppinsMedium",
                            fontSize: sp(14),
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.8)
                                : Colors.black.withOpacity(0.8),
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
                  setState(() {
                    currentStep = 0;
                    cargando = false;
                  });
                });
              },
            ),
          ),

          SizedBox(height: h(33)),
        ],
      ),
    );
  }

  Widget decisionCambiarClave({Key? key}) {
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
          SizedBox(height: h(48)),

          /// ICONO PRINCIPAL
          Container(
            height: h(120),
            width: h(120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(33, 13, 243, 0.12),
            ),
            child: Center(
              child: Icon(
                LucideIcons.keyRound,
                size: sp(44),
                color: const Color.fromRGBO(33, 13, 243, 1),
              ),
            ),
          ),

          SizedBox(height: h(30)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "¿Querés cambiar tu clave?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "PoppinsBold",
                fontSize: sp(23),
                color: temaUser == "Oscuro" ? Colors.white : Colors.black,
              ),
            ),
          ),

          SizedBox(height: h(14)),

          /// TEXTO DESCRIPTIVO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(44)),
            child: Text(
              "Por seguridad, te recomendamos actualizar tu clave antes de desbloquear la cuenta. "
              "Si preferís, podés seguir usando la misma.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(14.5),
                height: 1.5,
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.65)
                    : Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          Spacer(),

          /// OPCION CAMBIAR CLAVE
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(55),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(1, 165, 113, 1),
                      Color.fromRGBO(0, 190, 130, 1),
                    ],
                  ),
                ),
                child: Center(
                  child: !cargandoCambiar
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.lock,
                              color: Colors.white,
                              size: sp(18),
                            ),
                            SizedBox(width: w(10)),
                            Text(
                              "Cambiar clave ahora",
                              style: TextStyle(
                                fontFamily: "PoppinsBold",
                                fontSize: sp(16),
                                color: Colors.white,
                              ),
                            ),
                          ],
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
                  cargandoCambiar = true;
                });

                Future.delayed(Duration(milliseconds: 1500), () {
                  avanzarPaso();

                  setState(() {
                    cargandoCambiar = false;
                  });
                });
              },
            ),
          ),

          SizedBox(height: h(18)),

          /// OPCION SEGUIR CON LA MISMA
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(50),
                decoration: BoxDecoration(
                  color: temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: temaUser == "Oscuro"
                        ? Colors.white.withOpacity(0.14)
                        : Colors.black.withOpacity(0.14),
                  ),
                ),
                child: Center(
                  child: !cargandoMismo
                      ? Text(
                          "Seguir con la misma clave",
                          style: TextStyle(
                            fontFamily: "PoppinsBold",
                            fontSize: sp(15),
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.85)
                                : Colors.black.withOpacity(0.85),
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
                  cargandoMismo = true;
                });

                Future.delayed(Duration(milliseconds: 1500), () {
                  setState(() {
                    currentStep = 7;
                    cargandoMismo = false;
                  });
                });
              },
            ),
          ),

          SizedBox(height: h(23)),

          /// INFO DE TRANQUILIDAD
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(43)),
            child: Text(
              "Podrás cambiar tu clave en cualquier momento desde la configuración.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(13),
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.55)
                    : Colors.black.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(1)),
        ],
      ),
    );
  }

  Widget verificacionExitosa({Key? key}) {
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
          SizedBox(height: h(48)),

          /// ICONO ÉXITO
          Container(
            height: h(140),
            width: h(140),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color.fromRGBO(1, 165, 113, 0.25),
                  Color.fromRGBO(1, 165, 113, 0.12),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                LucideIcons.checkCircle2,
                size: sp(54),
                color: const Color.fromRGBO(1, 165, 113, 1),
              ),
            ),
          ),

          SizedBox(height: h(32)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Verificación completada",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "PoppinsBold",
                fontSize: sp(23),
                color: temaUser == "Oscuro" ? Colors.white : Colors.black,
              ),
            ),
          ),

          SizedBox(height: h(15)),

          /// TEXTO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(42)),
            child: Text(
              "Tu identidad fue confirmada correctamente. "
              "Ya podés volver a usar tu cuenta con normalidad.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(14.5),
                height: 1.5,
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.65)
                    : Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          SizedBox(height: h(26)),

          /// INFO SEGURIDAD
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
                children: [
                  Icon(
                    LucideIcons.shieldCheck,
                    size: sp(18),
                    color: const Color.fromRGBO(1, 165, 113, 1),
                  ),
                  SizedBox(width: w(12)),
                  Expanded(
                    child: Text(
                      "Este proceso protege tu cuenta ante accesos no autorizados.",
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

          Spacer(),

          /// CONTINUAR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(58),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(1, 165, 113, 1),
                      Color.fromRGBO(0, 190, 130, 1),
                    ],
                  ),
                ),
                child: Center(
                  child: !cargando
                      ? Text(
                          "Desbloquear mi cuenta",
                          style: TextStyle(
                            fontFamily: "PoppinsBold",
                            fontSize: sp(16),
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
                  desbloquearCuenta();

                  setState(() {
                    cargando = false;
                  });
                });
              },
            ),
          ),

          SizedBox(height: h(33)),
        ],
      ),
    );
  }

  //No Face ID
  Widget noPuedoUsarFaceId({Key? key}) {
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
          SizedBox(height: h(48)),

          /// PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.userPlus,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Desbloquear cuenta",
                  style: TextStyle(
                    fontSize: sp(12),
                    fontFamily: "Poppins",
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(23)),

          /// TEXTO PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.mail,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(5)),
                Text(
                  "Paso 2 de 2",
                  style: TextStyle(
                    fontSize: sp(13),
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
              children: List.generate(2, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(33),
                    height: h(5),
                    decoration: BoxDecoration(
                      color: index < 2
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: h(33)),

          /// ICONO EMAIL
          Container(
            height: h(120),
            width: h(120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(1, 165, 113, 0.12),
            ),
            child: Center(
              child: Icon(
                LucideIcons.mailCheck,
                size: sp(46),
                color: const Color.fromRGBO(1, 165, 113, 1),
              ),
            ),
          ),

          SizedBox(height: h(30)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Verificación por email",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "PoppinsBold",
                fontSize: sp(22),
                color: temaUser == "Oscuro" ? Colors.white : Colors.black,
              ),
            ),
          ),

          SizedBox(height: h(14)),

          /// TEXTO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(43)),
            child: Text(
              "Te enviaremos un código de seguridad al email asociado a tu cuenta "
              "para confirmar tu identidad y desbloquear el acceso.",
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

          /// INFO EMAIL
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
                children: [
                  Icon(
                    LucideIcons.mail,
                    size: sp(18),
                    color: const Color.fromRGBO(1, 165, 113, 1),
                  ),
                  SizedBox(width: w(12)),
                  Expanded(
                    child: Text(
                      emailUser,
                      style: TextStyle(
                        fontFamily: "PoppinsBold",
                        fontSize: sp(14),
                        color: temaUser == "Oscuro"
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Spacer(),

          /// BOTÓN EMAIL
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(55),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(1, 165, 113, 1),
                      Color.fromRGBO(0, 190, 130, 1),
                    ],
                  ),
                ),
                child: Center(
                  child: !cargando
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.send,
                              color: Colors.white,
                              size: sp(18),
                            ),
                            SizedBox(width: w(10)),
                            Text(
                              "Enviar código por email",
                              style: TextStyle(
                                fontFamily: "PoppinsBold",
                                fontSize: sp(16),
                                color: Colors.white,
                              ),
                            ),
                          ],
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
                  sendEmailCode();

                  setState(() {
                    currentStep = -1;
                    _focusCode = FocusNode();
                    cargando = false;
                  });
                });
              },
            ),
          ),

          SizedBox(height: h(15)),

          /// VOLVER A FACE ID
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
                  child: !cargandoVolver
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.scanFace,
                              size: sp(16),
                              color: temaUser == "Oscuro"
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.black.withOpacity(0.8),
                            ),
                            SizedBox(width: w(8)),
                            Text(
                              "Volver a Face ID",
                              style: TextStyle(
                                fontFamily: "PoppinsMedium",
                                fontSize: sp(14),
                                color: temaUser == "Oscuro"
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.black.withOpacity(0.8),
                              ),
                            ),
                          ],
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
                  cargandoVolver = true;
                });

                Future.delayed(Duration(milliseconds: 1500), () {
                  setState(() {
                    _focusCode = FocusNode();
                    currentStep = 3;
                    cargandoVolver = false;
                  });
                });
              },
            ),
          ),

          SizedBox(height: h(33)),
        ],
      ),
    );
  }

  //Verificar Email
  Widget verificarEmailCodigo({Key? key}) {
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
          SizedBox(height: h(40)),

          /// PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.mailCheck,
                  size: sp(14),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Verificación de email",
                  style: TextStyle(
                    fontSize: sp(12),
                    fontFamily: "Poppins",
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(8)),

          /// Email
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              emailUser,
              style: TextStyle(
                fontSize: sp(10),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),

          SizedBox(height: h(48)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Ingresá el código",
              style: TextStyle(
                fontSize: sp(24),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(12)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Te enviamos un código de 5 dígitos a tu email para verificar tu cuenta.",
              style: TextStyle(
                fontSize: sp(14),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(33)),

          /// INPUT CODIGO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: PinCodeTextField(
              appContext: context,
              controller: _controllerCodeEmail,
              autoDisposeControllers: false,
              length: 5,
              focusNode: _focusCode,
              autoFocus: true,
              keyboardType: TextInputType.number,
              animationType: AnimationType.scale,
              cursorColor: Colors.white,
              textStyle: TextStyle(
                fontSize: sp(20),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(14),
                fieldHeight: h(56),
                fieldWidth: w(52),
                activeColor: const Color.fromRGBO(1, 165, 113, 1),
                selectedColor: Colors.white.withOpacity(0.5),
                inactiveColor: Colors.white.withOpacity(0.2),
                activeFillColor: Colors.white.withOpacity(0.05),
                selectedFillColor: Colors.white.withOpacity(0.05),
                inactiveFillColor: Colors.white.withOpacity(0.03),
              ),
              enableActiveFill: true,
              animationDuration: const Duration(milliseconds: 300),
              onChanged: (value) {},
              onCompleted: (value) {
                verificarCodeEmail();
              },
            ),
          ),

          SizedBox(height: h(32)),

          /// REENVIAR
          Center(
            child: Container(
              height: h(43),
              width: w(300),
              color: Colors.transparent,
              child: GestureDetector(
                child: Center(
                  child: cargando
                      ? SizedBox(
                          height: h(23),
                          width: w(23),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 1,
                          ),
                        )
                      : !emailReenviado
                      ? RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: sp(10),
                              fontFamily: "Poppins",
                              color: const Color.fromRGBO(1, 165, 113, 1),
                            ),
                            children: const [
                              TextSpan(text: "¿No recibiste el código? "),
                              TextSpan(
                                text: "Reenviar",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          "Código reenviado",
                          style: TextStyle(
                            fontSize: sp(13),
                            fontFamily: "Poppins",
                            color: const Color.fromRGBO(1, 165, 113, 1),
                          ),
                        ),
                ),
                onTap: () async {
                  if (!emailReenviado) {
                    Vibration.vibrate(duration: 5);
                    setState(() {
                      cargando = true;
                    });

                    await sendEmailCode();
                    Future.delayed(Duration(milliseconds: 1500), () {
                      setState(() {
                        emailReenviado = true;
                        cargando = false;
                      });
                      Vibration.vibrate(duration: 5);
                    });

                    Future.delayed(Duration(seconds: 15), () {
                      setState(() {
                        emailReenviado = false;
                      });
                      Vibration.vibrate(duration: 3);
                    });
                  }
                },
              ),
            ),
          ),

          SizedBox(height: h(24)),

          /// INFO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.info,
                  size: sp(16),
                  color: Colors.white.withOpacity(0.4),
                ),
                SizedBox(width: w(10)),
                Expanded(
                  child: Text(
                    "Revisá también la carpeta de spam o correo no deseado.",
                    style: TextStyle(
                      fontSize: sp(13),
                      fontFamily: "Poppins",
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Cambiar Clave
  Widget cambiarClave({Key? key}) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: h(48)),

          /// PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.userPlus,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Desbloquear cuenta",
                  style: TextStyle(
                    fontSize: sp(12),
                    fontFamily: "Poppins",
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(23)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Cambiar clave",
              style: TextStyle(
                fontFamily: "PoppinsBold",
                fontSize: sp(24),
                color: temaUser == "Oscuro" ? Colors.white : Colors.black,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Elegí una nueva clave de 5 dígitos para proteger tu cuenta.",
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(14.5),
                height: 1.5,
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black.withOpacity(0.6),
              ),
            ),
          ),

          SizedBox(height: h(23)),

          /// PASO 1
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Nueva clave",
              style: TextStyle(
                fontFamily: "PoppinsMedium",
                fontSize: sp(14),
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.8)
                    : Colors.black.withOpacity(0.8),
              ),
            ),
          ),

          SizedBox(height: h(18)),

          /// PIN VISUAL
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final filled = _controllerNuevaClave.text.length > index;
                final mostrarNumero =
                    _mostrarNumeroPlano && _indicePlano == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: w(48),
                  height: w(48),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? (claveValida
                              ? const Color.fromRGBO(1, 165, 113, 1)
                              : Colors.red.withOpacity(0.8))
                        : Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: filled
                          ? (claveValida
                                ? const Color.fromRGBO(1, 165, 113, 1)
                                : Colors.red.withOpacity(0.8))
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: filled
                      ? (mostrarNumero
                            ? Center(
                                child: Text(
                                  _controllerNuevaClave.text[index],
                                  style: TextStyle(
                                    fontSize: sp(18),
                                    fontFamily: "PoppinsBold",
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  claveValida
                                      ? LucideIcons.check
                                      : LucideIcons.x,
                                  size: sp(18),
                                  color: Colors.white,
                                ),
                              ))
                      : null,
                );
              }),
            ),
          ),

          /// INPUT OCULTO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: TextField(
              controller: _controllerNuevaClave,
              autofocus: true,
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
                final valido = esClaveValida(value);

                setState(() {
                  claveValida = value.length < 5 || valido;
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
              },
            ),
          ),

          /// AVISO ERROR
          if (!claveValida)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(40)),
              child: Container(
                padding: EdgeInsets.all(w(14)),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: sp(18),
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: w(10)),
                    Expanded(
                      child: Text(
                        "La clave no puede contener números consecutivos (ej: 123, 321 o 111).",
                        style: TextStyle(
                          fontSize: sp(13),
                          fontFamily: "Poppins",
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Spacer(),

          /// BOTON GUARDAR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Visibility(
              visible: _controllerNuevaClave.text.length == 5 && claveValida,
              child: GestureDetector(
                child: Container(
                  height: h(56),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(1, 165, 113, 1),
                        Color.fromRGBO(0, 190, 130, 1),
                      ],
                    ),
                  ),
                  child: Center(
                    child: !cargando
                        ? Text(
                            "Actualizar clave",
                            style: TextStyle(
                              fontFamily: "PoppinsBold",
                              fontSize: sp(16),
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
                onTap: () async {
                  Vibration.vibrate(duration: 5);

                  setState(() {
                    cargando = true;
                  });

                  await guardarClave(
                    _controllerNuevaClave.text + "000",
                    claveUser,
                  );

                  setState(() {
                    cargando = false;
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

  //Calve Cambiada
  Widget avisoClaveCambiada({Key? key}) {
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
          SizedBox(height: h(80)),

          /// ICONO PRINCIPAL
          Container(
            height: h(110),
            width: h(110),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color.fromRGBO(1, 165, 113, 0.18),
                  Color.fromRGBO(1, 165, 113, 0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Container(
                height: h(70),
                width: h(70),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(1, 165, 113, 1),
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),

          SizedBox(height: h(32)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Clave actualizada",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "PoppinsBold",
                fontSize: sp(24),
                color: temaUser == "Oscuro" ? Colors.white : Colors.black,
              ),
            ),
          ),

          SizedBox(height: h(12)),

          /// DESCRIPCION
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Tu nueva clave se guardó correctamente.\nAhora tu cuenta está protegida con mayor seguridad.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(14.5),
                height: 1.6,
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.65)
                    : Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          SizedBox(height: h(36)),

          /// TARJETA RESUMEN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(32)),
            child: Container(
              padding: EdgeInsets.all(w(18)),
              decoration: BoxDecoration(
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: h(46),
                    width: h(46),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromRGBO(1, 165, 113, 0.18),
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      color: Color.fromRGBO(1, 165, 113, 1),
                      size: 22,
                    ),
                  ),
                  SizedBox(width: w(14)),
                  Expanded(
                    child: Text(
                      "La próxima vez que ingreses, usá tu nueva clave o Face ID si lo tenés activado.",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: sp(13.5),
                        height: 1.4,
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Spacer(),

          /// BOTON CONTINUAR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(56),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(1, 165, 113, 1),
                      Color.fromRGBO(0, 190, 130, 1),
                    ],
                  ),
                ),
                child: Center(
                  child: !cargando
                      ? Text(
                          "Continuar",
                          style: TextStyle(
                            fontFamily: "PoppinsBold",
                            fontSize: sp(16),
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
                  avanzarPaso();

                  setState(() {
                    cargando = false;
                  });
                });
              },
            ),
          ),

          SizedBox(height: h(33)),
        ],
      ),
    );
  }

  //Alerta Error Cambiar Clave
  Widget alertaErrorCambiarClave() {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: w(24)),
      child: Container(
        padding: EdgeInsets.all(w(23)),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(18, 18, 18, 1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ICONO
            Center(
              child: Container(
                width: w(55),
                height: w(55),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.15),
                ),
                child: Icon(
                  LucideIcons.xCircle,
                  color: Colors.redAccent,
                  size: sp(25),
                ),
              ),
            ),

            SizedBox(height: h(20)),

            /// TITULO
            Center(
              child: Text(
                "Error inesperado",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sp(18),
                  fontFamily: "PoppinsBold",
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: h(10)),

            /// DESCRIPCIÓN
            Center(
              child: Text(
                "Tuvimos un error al actualizar tu contraseña. Por favor, intenta nuevamente.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sp(14),
                  fontFamily: "Poppins",
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),

            SizedBox(height: h(28)),

            /// BOTÓN CERRAR
            GestureDetector(
              child: Container(
                height: h(46),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color.fromRGBO(1, 165, 113, 1),
                ),
                child: Center(
                  child: Text(
                    "Cerrar",
                    style: TextStyle(
                      fontSize: sp(14),
                      fontFamily: "PoppinsBold",
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);

                //Escanear Dni
                setState(() {
                  _isDisposed = false;
                });

                _textRecognizer = GoogleMlKit.vision.textRecognizer();
                _initializeCamera();

                startLoop();
                //Fin Escanear Dni
              },
            ),
          ],
        ),
      ),
    );
  }

  //Error Face ID
  Widget errorFaceId({Key? key}) {
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
          SizedBox(height: h(48)),

          /// ICONO ERROR
          Container(
            height: h(120),
            width: h(120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.12),
            ),
            child: Center(
              child: Icon(
                LucideIcons.scanFace,
                size: sp(46),
                color: Colors.redAccent,
              ),
            ),
          ),

          SizedBox(height: h(30)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "No se pudo verificar tu identidad",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "PoppinsBold",
                fontSize: sp(22),
                color: temaUser == "Oscuro" ? Colors.white : Colors.black,
              ),
            ),
          ),

          SizedBox(height: h(14)),

          /// TEXTO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(42)),
            child: Text(
              "El escaneo con Face ID fue cancelado o no pudo completarse. "
              "Podés intentarlo nuevamente o elegir otra forma de validación.",
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

          SizedBox(height: h(28)),

          /// INFO
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
                  Icon(LucideIcons.info, size: sp(18), color: Colors.redAccent),
                  SizedBox(width: w(12)),
                  Expanded(
                    child: Text(
                      "Asegurate de tener buena iluminación y que Face ID esté "
                      "habilitado en tu dispositivo.",
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

          Spacer(),

          /// REINTENTAR
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
                    "Intentar nuevamente",
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
                solicitarBiometria();
              },
            ),
          ),

          SizedBox(height: h(16)),

          /// OTRA OPCION
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
                  child: !cargando
                      ? Text(
                          "Usar otra forma de verificación",
                          style: TextStyle(
                            fontFamily: "PoppinsMedium",
                            fontSize: sp(14),
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.8)
                                : Colors.black.withOpacity(0.8),
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
                  setState(() {
                    currentStep = 0;
                    cargando = false;
                  });
                });
              },
            ),
          ),

          SizedBox(height: h(36)),
        ],
      ),
    );
  }

  //Ayuda
  Widget necesitoAyuda({Key? key}) {
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
          SizedBox(height: h(50)),

          /// ICONO PRINCIPAL
          Container(
            height: h(120),
            width: h(120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(1, 165, 113, 0.14),
            ),
            child: Center(
              child: Icon(
                LucideIcons.helpCircle,
                size: sp(48),
                color: const Color.fromRGBO(1, 165, 113, 1),
              ),
            ),
          ),

          SizedBox(height: h(30)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "¿Necesitás ayuda?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "PoppinsBold",
                fontSize: sp(24),
                color: temaUser == "Oscuro" ? Colors.white : Colors.black,
              ),
            ),
          ),

          SizedBox(height: h(14)),

          /// DESCRIPCIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(44)),
            child: Text(
              "Elegí una opción para resolver tu problema de forma rápida y segura. Estamos para ayudarte.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(14.5),
                height: 1.55,
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.65)
                    : Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          SizedBox(height: h(36)),

          /// OPCIONES
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(32)),
            child: Column(
              children: [
                /// OPCIÓN 1
                GestureDetector(
                  child: Container(
                    padding: EdgeInsets.all(w(18)),
                    decoration: BoxDecoration(
                      color: temaUser == "Oscuro"
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: w(48),
                          width: w(48),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: Icon(
                            LucideIcons.userCheck,
                            size: sp(20),
                            color: const Color.fromRGBO(1, 165, 113, 1),
                          ),
                        ),
                        SizedBox(width: w(14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Verificación de identidad",
                                style: TextStyle(
                                  fontFamily: "PoppinsBold",
                                  fontSize: sp(15),
                                  color: temaUser == "Oscuro"
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              SizedBox(height: h(6)),
                              Text(
                                "Problemas para validar tu identidad o completar la verificación.",
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: sp(13),
                                  height: 1.4,
                                  color: temaUser == "Oscuro"
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: sp(18),
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Vibration.vibrate(duration: 5);
                    setState(() {
                      currentStep = 10;
                    });
                  },
                ),

                SizedBox(height: h(15)),

                /// OPCIÓN 2
                GestureDetector(
                  child: Container(
                    padding: EdgeInsets.all(w(18)),
                    decoration: BoxDecoration(
                      color: temaUser == "Oscuro"
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: w(48),
                          width: w(48),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: Icon(
                            LucideIcons.shieldAlert,
                            size: sp(20),
                            color: const Color.fromRGBO(1, 165, 113, 1),
                          ),
                        ),
                        SizedBox(width: w(13)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Seguridad de la cuenta",
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
                                "Actividad sospechosa o accesos no reconocidos.",
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: sp(13),
                                  height: 1.4,
                                  color: temaUser == "Oscuro"
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: sp(18),
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Vibration.vibrate(duration: 5);
                    setState(() {
                      currentStep = 11;
                    });
                  },
                ),
              ],
            ),
          ),

          Spacer(),

          /// CONTACTO SOPORTE
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(56),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(33, 13, 243, 1),
                      Color.fromRGBO(78, 58, 255, 1),
                    ],
                  ),
                ),
                child: Center(
                  child: !cargando
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.messageCircle,
                              size: sp(18),
                              color: Colors.white,
                            ),
                            SizedBox(width: w(10)),
                            Text(
                              "Contactar soporte",
                              style: TextStyle(
                                fontFamily: "PoppinsBold",
                                fontSize: sp(16),
                                color: Colors.white,
                              ),
                            ),
                          ],
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
                  setState(() {
                    currentStep = 12;
                    _focusContacto = FocusNode();
                    cargando = false;
                  });

                  Future.delayed(Duration(milliseconds: 300), () {
                    _focusContacto?.requestFocus();
                  });
                });
              },
            ),
          ),

          SizedBox(height: h(23)),

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
                    "Volver",
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

                setState(() {
                  currentStep = 1;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget problemasIdentidad({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double v) => v / 430 * screenWidth;
    double h(double v) => v / 932 * screenHeight;
    double sp(double v) =>
        v / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: h(52)),

          /// ICONO PRINCIPAL
          Container(
            height: h(92),
            width: h(92),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(1, 165, 113, 0.14),
            ),
            child: Center(
              child: Icon(
                LucideIcons.userX,
                size: sp(42),
                color: const Color.fromRGBO(1, 165, 113, 1),
              ),
            ),
          ),

          SizedBox(height: h(26)),

          /// TITULO
          Text(
            "Problemas de identidad",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "PoppinsBold",
              fontSize: sp(20),
              color: temaUser == "Oscuro" ? Colors.white : Colors.black,
            ),
          ),

          SizedBox(height: h(10)),

          /// DESCRIPCIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(38)),
            child: Text(
              "Si la verificación no pudo completarse correctamente, revisá estos consejos antes de volver a intentarlo.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(14),
                height: 1.45,
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.65)
                    : Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          SizedBox(height: h(34)),

          /// TARJETA DE CONSEJOS
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(28)),
            child: Container(
              padding: EdgeInsets.all(w(22)),
              decoration: BoxDecoration(
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.045)
                    : Colors.black.withOpacity(0.055),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER TARJETA
                  Row(
                    children: [
                      Icon(
                        LucideIcons.lightbulb,
                        size: sp(18),
                        color: const Color.fromRGBO(1, 165, 113, 1),
                      ),
                      SizedBox(width: w(10)),
                      Text(
                        "Consejos útiles",
                        style: TextStyle(
                          fontFamily: "PoppinsBold",
                          fontSize: sp(15),
                          color: temaUser == "Oscuro"
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(20)),

                  /// TIP 1
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.scanFace,
                        size: sp(16),
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Realizá la verificación en un lugar bien iluminado y mantené el rostro completamente visible.",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: sp(13.5),
                            height: 1.45,
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.72)
                                : Colors.black.withOpacity(0.72),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(16)),

                  /// TIP 2
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.glasses,
                        size: sp(16),
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Evitá usar gorras, lentes oscuros u objetos que cubran parte del rostro.",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: sp(13.5),
                            height: 1.45,
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.72)
                                : Colors.black.withOpacity(0.72),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(16)),

                  /// TIP 3
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.mail,
                        size: sp(16),
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Si estás esperando un código por email, revisá la bandeja de spam o correo no deseado.",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: sp(13.5),
                            height: 1.45,
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.72)
                                : Colors.black.withOpacity(0.72),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(16)),

                  /// TIP 4
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: sp(16),
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Esperá unos minutos antes de volver a intentarlo para evitar bloqueos temporales.",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: sp(13.5),
                            height: 1.45,
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.72)
                                : Colors.black.withOpacity(0.72),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(16)),

                  /// TIP 5 DESTACADO
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        size: sp(16),
                        color: const Color.fromRGBO(1, 165, 113, 1),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Durante todo el proceso, tu cuenta permanece protegida y segura.",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: sp(13.5),
                            height: 1.45,
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.85)
                                : Colors.black.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Spacer(),
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
                    "Volver",
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

                setState(() {
                  currentStep = 9;
                });
              },
            ),
          ),

          SizedBox(height: h(13)),
        ],
      ),
    );
  }

  Widget seguridadActividadSospechosa({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double v) => v / 430 * screenWidth;
    double h(double v) => v / 932 * screenHeight;
    double sp(double v) =>
        v / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: h(52)),

          /// ICONO PRINCIPAL
          Container(
            height: h(96),
            width: h(96),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.16),
            ),
            child: Center(
              child: Icon(
                LucideIcons.shieldAlert,
                size: sp(44),
                color: Colors.orange,
              ),
            ),
          ),

          SizedBox(height: h(26)),

          /// TITULO
          Text(
            "Seguridad de la cuenta",
            style: TextStyle(
              fontFamily: "PoppinsBold",
              fontSize: sp(20),
              color: temaUser == "Oscuro" ? Colors.white : Colors.black,
            ),
          ),

          SizedBox(height: h(8)),

          /// SUBTITULO
          Text(
            "Actividad sospechosa o accesos no reconocidos",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: sp(14),
              height: 1.4,
              color: temaUser == "Oscuro"
                  ? Colors.white.withOpacity(0.65)
                  : Colors.black.withOpacity(0.65),
            ),
          ),

          SizedBox(height: h(33)),

          /// TARJETA INFORMATIVA
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(28)),
            child: Container(
              padding: EdgeInsets.all(w(22)),
              decoration: BoxDecoration(
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.045)
                    : Colors.black.withOpacity(0.055),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        size: sp(18),
                        color: Colors.orange,
                      ),
                      SizedBox(width: w(10)),
                      Text(
                        "¿Qué puede haber pasado?",
                        style: TextStyle(
                          fontFamily: "PoppinsBold",
                          fontSize: sp(15),
                          color: temaUser == "Oscuro"
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(20)),

                  /// ITEM 1
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: sp(16),
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Inicio de sesión desde una ubicación o dispositivo poco habitual.",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: sp(13.5),
                            height: 1.45,
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.72)
                                : Colors.black.withOpacity(0.72),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(16)),

                  /// ITEM 2
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.key,
                        size: sp(16),
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Múltiples intentos fallidos de ingreso a la cuenta.",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: sp(13.5),
                            height: 1.45,
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.72)
                                : Colors.black.withOpacity(0.72),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(16)),

                  /// ITEM 3
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.wifiOff,
                        size: sp(16),
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Accesos desde redes no seguras o conexiones inestables.",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: sp(13.5),
                            height: 1.45,
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.72)
                                : Colors.black.withOpacity(0.72),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(24)),

                  /// MENSAJE TRANQUILIZADOR
                  Container(
                    padding: EdgeInsets.all(w(14)),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.shieldCheck,
                          size: sp(16),
                          color: Colors.orange,
                        ),
                        SizedBox(width: w(10)),
                        Expanded(
                          child: Text(
                            "Para denunciar actividad sospechosa verifica tus ultimos ingresos a tu acuenta. Si no coinciden con ninguna de las propuestas anteriores, contactate a soporte.",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: sp(13),
                              height: 1.4,
                              color: temaUser == "Oscuro"
                                  ? Colors.white.withOpacity(0.85)
                                  : Colors.black.withOpacity(0.85),
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

          SizedBox(height: h(28)),

          /// PIE
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(42)),
            child: Text(
              "Estas medidas nos ayudan a proteger tu dinero y tu información personal.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(12.8),
                height: 1.45,
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.55)
                    : Colors.black.withOpacity(0.55),
              ),
            ),
          ),

          Spacer(),
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
                    "Volver",
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

                setState(() {
                  currentStep = 9;
                });
              },
            ),
          ),

          SizedBox(height: h(13)),
        ],
      ),
    );
  }

  Widget contactarSoporte({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double v) => v / 430 * screenWidth;
    double h(double v) => v / 932 * screenHeight;
    double sp(double v) =>
        v / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    TextEditingController mensajeController = TextEditingController();

    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: h(23)),

          /// ICONO
          Container(
            height: h(80),
            width: h(80),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(1, 165, 113, 0.16),
            ),
            child: Center(
              child: Icon(
                LucideIcons.headphones,
                size: sp(33),
                color: const Color.fromRGBO(1, 165, 113, 1),
              ),
            ),
          ),

          SizedBox(height: h(13)),

          /// TITULO
          Text(
            "Contactar a Soporte",
            style: TextStyle(
              fontFamily: "PoppinsBold",
              fontSize: sp(20),
              color: temaUser == "Oscuro" ? Colors.white : Colors.black,
            ),
          ),

          SizedBox(height: h(8)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Contanos qué pasó y te ayudamos a resolverlo",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(14),
                height: 1.45,
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.65)
                    : Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          SizedBox(height: h(23)),

          /// CAMPO MENSAJE
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(28)),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w(18), vertical: h(10)),
              decoration: BoxDecoration(
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITULO
                  Text(
                    "Mensaje",
                    style: TextStyle(
                      fontFamily: "PoppinsMedium",
                      fontSize: sp(13),
                      color: temaUser == "Oscuro"
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.7),
                    ),
                  ),

                  SizedBox(height: h(8)),

                  /// INPUT
                  TextField(
                    controller: _controllerMensaje,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    maxLength: 150,
                    focusNode: _focusContacto,
                    autofocus: true,
                    cursorColor: Color.fromRGBO(1, 165, 113, 1),
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: sp(13),
                      color: temaUser == "Oscuro" ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          "Describí brevemente el problema que estás teniendo…",
                      hintStyle: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: sp(13),
                        color: temaUser == "Oscuro"
                            ? Colors.white.withOpacity(0.4)
                            : Colors.black.withOpacity(0.4),
                      ),
                      counterText: "",
                      border: InputBorder.none,
                    ),
                  ),

                  SizedBox(height: h(5)),

                  /// DIVISOR
                  Container(
                    height: 1,
                    color: temaUser == "Oscuro"
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                  ),

                  SizedBox(height: h(10)),

                  /// FILA ENVIAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Máx. 150 caracteres",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: sp(11.5),
                          color: temaUser == "Oscuro"
                              ? Colors.white.withOpacity(0.45)
                              : Colors.black.withOpacity(0.45),
                        ),
                      ),

                      GestureDetector(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w(15),
                            vertical: h(8),
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(1, 165, 113, 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: !cargando
                              ? Row(
                                  children: [
                                    Icon(
                                      LucideIcons.send,
                                      size: sp(13),
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: w(5)),
                                    Text(
                                      "Enviar",
                                      style: TextStyle(
                                        fontFamily: "PoppinsBold",
                                        fontSize: sp(12.5),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox(
                                  height: h(13),
                                  width: w(13),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 1,
                                  ),
                                ),
                        ),
                        onTap: () {
                          Vibration.vibrate(duration: 5);

                          setState(() {
                            cargando = true;
                          });

                          Future.delayed(
                            Duration(milliseconds: 1500),
                            () async {
                              if (_controllerMensaje.text.length < 10) {
                                showFlushbar(context, "Describí tu problema.");
                                setState(() {
                                  cargando = false;
                                });
                              } else {
                                await generarTituloIA();
                                //Enviar Eamil Usuario
                                enviarReporte();
                                setState(() {
                                  _focusContacto?.unfocus();
                                  currentStep = 13;
                                  cargando = false;
                                });
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Spacer(),

          /// VOLVER ATRÁS
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(35)),
            child: GestureDetector(
              child: Container(
                height: h(50),
                decoration: BoxDecoration(
                  color: temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: temaUser == "Oscuro"
                        ? Colors.white.withOpacity(0.14)
                        : Colors.black.withOpacity(0.14),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Volver",
                    style: TextStyle(
                      fontFamily: "PoppinsMedium",
                      fontSize: sp(14),
                      color: temaUser == "Oscuro"
                          ? Colors.white.withOpacity(0.85)
                          : Colors.black.withOpacity(0.85),
                    ),
                  ),
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);

                setState(() {
                  _focusContacto?.unfocus();
                });

                Future.delayed(Duration(milliseconds: 300), () {
                  currentStep = 9;
                });
              },
            ),
          ),

          SizedBox(height: h(13)),
        ],
      ),
    );
  }

  Widget contactoSoporteEnviado({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double v) => v / 430 * screenWidth;
    double h(double v) => v / 932 * screenHeight;
    double sp(double v) =>
        v / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    /// CONCLUSIÓN SIMBÓLICA DEL MENSAJE
    /// (esto luego puede venir del backend / IA)
    final String resumenMensaje = "Problemas para verificar mi identidad";

    return SafeArea(
      key: key,
      child: Column(
        children: [
          SizedBox(height: h(70)),

          /// ICONO PRINCIPAL
          Container(
            height: h(130),
            width: h(130),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(1, 165, 113, 0.15),
            ),
            child: Center(
              child: Icon(
                LucideIcons.checkCircle2,
                size: sp(56),
                color: const Color.fromRGBO(1, 165, 113, 1),
              ),
            ),
          ),

          SizedBox(height: h(32)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Solicitud enviada",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "PoppinsBold",
                fontSize: sp(23),
                color: temaUser == "Oscuro" ? Colors.white : Colors.black,
              ),
            ),
          ),

          SizedBox(height: h(14)),

          /// DESCRIPCIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(44)),
            child: Text(
              "Recibimos tu mensaje correctamente. "
              "Nuestro equipo de soporte ya está revisando tu caso.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: sp(14.5),
                height: 1.5,
                color: temaUser == "Oscuro"
                    ? Colors.white.withOpacity(0.65)
                    : Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          SizedBox(height: h(28)),

          /// RESUMEN DEL MENSAJE
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.all(w(18)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.messageCircle,
                    size: sp(18),
                    color: const Color.fromRGBO(1, 165, 113, 1),
                  ),
                  SizedBox(width: w(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Motivo del contacto",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: sp(12.5),
                            color: temaUser == "Oscuro"
                                ? Colors.white.withOpacity(0.55)
                                : Colors.black.withOpacity(0.55),
                          ),
                        ),
                        SizedBox(height: h(6)),
                        Text(
                          tituloGenerado,
                          style: TextStyle(
                            fontFamily: "PoppinsBold",
                            fontSize: sp(14.5),
                            color: temaUser == "Oscuro"
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h(26)),

          /// INFO TRANQUILIDAD
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
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: sp(18),
                    color: const Color.fromRGBO(1, 165, 113, 1),
                  ),
                  SizedBox(width: w(12)),
                  Expanded(
                    child: Text(
                      "Te responderemos a la brevedad por el medio asociado a tu cuenta. "
                      "No necesitás realizar ninguna otra acción.",
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

          Spacer(),

          /// VOLVER
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(56),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: temaUser == "Oscuro"
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.08),
                  border: Border.all(
                    color: temaUser == "Oscuro"
                        ? Colors.white.withOpacity(0.14)
                        : Colors.black.withOpacity(0.14),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Volver",
                    style: TextStyle(
                      fontFamily: "PoppinsBold",
                      fontSize: sp(15.5),
                      color: temaUser == "Oscuro"
                          ? Colors.white.withOpacity(0.85)
                          : Colors.black.withOpacity(0.85),
                    ),
                  ),
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);
                setState(() {
                  currentStep = 1;
                });
              },
            ),
          ),

          SizedBox(height: h(32)),
        ],
      ),
    );
  }

  //Dni Incorrecto
  Widget alertaDniIncorrecto() {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: w(24)),
      child: Container(
        padding: EdgeInsets.all(w(23)),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(18, 18, 18, 1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ICONO
            Center(
              child: Container(
                width: w(55),
                height: w(55),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.15),
                ),
                child: Icon(
                  LucideIcons.xCircle,
                  color: Colors.redAccent,
                  size: sp(25),
                ),
              ),
            ),

            SizedBox(height: h(20)),

            /// TITULO
            Center(
              child: Text(
                "DNI incorrecto",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sp(18),
                  fontFamily: "PoppinsBold",
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: h(10)),

            /// DESCRIPCIÓN
            Center(
              child: Text(
                "El DNI que escaneaste no coincide. Por favor, intenta nuevamente.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sp(14),
                  fontFamily: "Poppins",
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),

            SizedBox(height: h(28)),

            /// BOTÓN CERRAR
            GestureDetector(
              child: Container(
                height: h(46),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color.fromRGBO(1, 165, 113, 1),
                ),
                child: Center(
                  child: Text(
                    "Cerrar",
                    style: TextStyle(
                      fontSize: sp(14),
                      fontFamily: "PoppinsBold",
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);

                //Escanear Dni
                setState(() {
                  _isDisposed = false;
                });

                _textRecognizer = GoogleMlKit.vision.textRecognizer();
                _initializeCamera();

                startLoop();
                //Fin Escanear Dni
              },
            ),
          ],
        ),
      ),
    );
  }
}
