// ignore_for_file: use_key_in_widget_constructors, camel_case_types, unused_import, unused_element, deprecated_member_use, avoid_print, unused_field, use_build_context_synchronously, curly_braces_in_flow_control_structures, prefer_interpolation_to_compose_strings, unused_local_variable, unnecessary_import

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
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
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

  //Cargando
  bool cargando = false;
  bool cargandoCambiar = false;
  bool cargandoMismo = false;

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
              child: currentStep == 1
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
              onTap: () {
                Vibration.vibrate(duration: 5);
              },
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
                    "No puedo usar Face ID",
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
            ),
          ),

          SizedBox(height: h(33)),
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
              onTap: () {
                Vibration.vibrate(duration: 8);
                solicitarBiometria();
              },
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
            ),
          ),

          SizedBox(height: h(16)),

          /// OTRA OPCION
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              onTap: () {
                Vibration.vibrate(duration: 5);
                // navegar a validación alternativa
              },
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
                    "Usar otra forma de verificación",
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
            ),
          ),

          SizedBox(height: h(36)),
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
