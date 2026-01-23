// ignore_for_file: camel_case_types, use_key_in_widget_constructors, file_names, use_build_context_synchronously, deprecated_member_use, must_be_immutable, prefer_interpolation_to_compose_strings, avoid_print, prefer_final_fields, curly_braces_in_flow_control_structures, unused_field, unused_local_variable

import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:bluetooth/UI/notificaciones.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class aprobarTutoriaPage extends StatefulWidget {
  final String codePupilo;

  const aprobarTutoriaPage({super.key, required this.codePupilo});
  @override
  State<aprobarTutoriaPage> createState() => _aprobarTutoriaPageState();
}

class _aprobarTutoriaPageState extends State<aprobarTutoriaPage>
    with WidgetsBindingObserver {
  //Steps
  int currentStep = 1;

  //Cargando
  bool cargando = false;

  //Datos Pupilo
  String nombrePupilo = "";

  String apellidoPupilo = "";

  String codePupilo = "";

  String uidPupilo = "";

  String dniPupilo = "";

  String inicialesPupilo = "";

  String fechaNacimientoPupilo = "";

  //Datos User
  String uidUser = "";

  String nombreUser = "";

  String apellidoUser = "";

  Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();
    uidUser = prefs.getString('codeUser') ?? "";
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
            });
          }
        });
  }

  Future<void> obtenerDatosPupilo() async {
    FirebaseFirestore.instance
        .collection("TempUsers")
        .doc(widget.codePupilo)
        .snapshots()
        .listen((docSnapshot) async {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              nombrePupilo = data["nombre"] ?? "";
              apellidoPupilo = data["apellido"] ?? "";
              dniPupilo = data["dni"] ?? "";
              uidPupilo = data["uid"] ?? "";
              fechaNacimientoPupilo = data["fecha nacimiento"] ?? "";
              codePupilo = widget.codePupilo;
              inicialesPupilo =
                  nombrePupilo.isNotEmpty && apellidoPupilo.isNotEmpty
                  ? "${nombrePupilo[0]}${apellidoPupilo[0]}".toUpperCase()
                  : "";

              print(data["dni"]);
            });
          }
        });
  }

  Future<void> avanzarPaso() async {
    setState(() {
      currentStep++;
    });
  }

  //Escanear DNI Pupilo
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
    // Opcional: animación de espera
    await Future.delayed(const Duration(milliseconds: 1500));

    if (dni == dniPupilo) {
      print("VERIFICADO");
      setState(() {
        _isDetecting = false;
        cargando = false;
        _isComplete = true;
      });
      Future.delayed(Duration(milliseconds: 3800), () {
        setState(() {
          avanzarPaso();
          habilitarPupilo();
          WidgetsBinding.instance.removeObserver(this);
          _isDisposed = true;
          _cameraControllerDni?.dispose();
          _textRecognizer?.close();
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

      // Verificar si ya está registrado
      bool existe = await dniYaRegistrado(dni.toString());
      if (existe) {
        if (mounted) {
          setState(() {
            cargando = false;
          });
        }
        if (mounted) _initializeCamera();
        return;
      }

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
        dniPupilo = dni.toString();
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

  Future<bool> dniYaRegistrado(String dni) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Usuarios")
          .where("Dni", isEqualTo: dni)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error buscando el dni: $e");
      return false;
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
  //Fin Escanear DNI Pupilo

  String calcularFechaVencimiento(String fechaNacimiento) {
    // fechaNacimiento en formato dd/MM/yyyy
    final partes = fechaNacimiento.split('/');

    final dia = int.parse(partes[0]);
    final mes = int.parse(partes[1]);
    final anio = int.parse(partes[2]);

    final fecha18 = DateTime(anio + 18, mes, dia);

    return "${fecha18.day.toString().padLeft(2, '0')}/"
        "${fecha18.month.toString().padLeft(2, '0')}/"
        "${fecha18.year}";
  }

  Future<void> enviarNotificacionPupilo() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Tutor Aceptado #$uidPupilo")
        .set({
          "Nombre": nombreUser,
          "Apellido": apellidoUser,
          "Uid": uidUser,
          "FechaTime": DateTime.now(),
          "Fecha": fecha,
          "Hora": horaActual,
          "Involucra": [uidPupilo],
          "Leida": {uidPupilo: false},
          "Tipo": "Tutor Aceptado",
        });
  }

  Future<void> habilitarPupilo() async {
    final fecha = calcularFechaVencimiento(fechaNacimientoPupilo);

    //Actualizar Notificacion
    await FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Solicitud Tutor #$codePupilo")
        .update({"Estado": "Aceptado"});

    //Actualizar TempUsers
    await FirebaseFirestore.instance
        .collection("TempUsers")
        .doc(codePupilo)
        .update({"paso": 21});

    //Agregar Pupilo
    await FirebaseFirestore.instance
        .collection("Pupilos")
        .doc("Pupilo #$uidPupilo")
        .set({"Tutor": uidUser, "Pupilo": uidPupilo, "Vencimiento": fecha});

    //Notificacion Pupilo
    await enviarNotificacionPupilo();
  }

  @override
  void initState() {
    super.initState();
    leerShared();

    obtenerDatos();

    obtenerDatosPupilo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1117), Color(0xFF0F1117)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(3, 5, 25, 1),
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
                  if (FocusManager.instance.primaryFocus != null) {
                    FocusManager.instance.primaryFocus!.unfocus();
                  }

                  WidgetsBinding.instance.removeObserver(this);
                  _isDisposed = true;
                  _cameraControllerDni?.dispose();
                  _textRecognizer?.close();

                  Future.delayed(Duration(milliseconds: 150), () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: notificacionesPage(),
                      ),
                    );
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
                        currentStep != 3
                            ? "Aprobar Tutoria"
                            : "Tutoria Aprobada",
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
                      child: currentStep != 3
                          ? RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: sp(13),
                                  fontFamily: "Poppins",
                                  color: Colors.grey,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        "Habilita a $nombrePupilo $apellidoPupilo en ",
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
                            )
                          : RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: sp(13),
                                  fontFamily: "Poppins",
                                  color: Colors.grey,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        "Habilitaste a $nombrePupilo $apellidoPupilo en ",
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
                  ? aprobarTutoriaWidget(key: const ValueKey('aprobar'))
                  : currentStep == 2
                  ? escanearDniPupilo(key: const ValueKey('escanear'))
                  : currentStep == 3
                  ? pupiloHabilitado(key: const ValueKey('habilitado'))
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }

  Widget aprobarTutoriaWidget({Key? key}) {
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
                  LucideIcons.shieldCheck,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Aprobación del tutor",
                  style: TextStyle(
                    fontSize: sp(12),
                    fontFamily: "Poppins",
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(28)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Autorizá la cuenta",
              style: TextStyle(
                fontSize: sp(23),
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
              "Para aprobar la cuenta del menor necesitamos verificar su identidad.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
                height: 1.4,
              ),
            ),
          ),

          SizedBox(height: h(36)),

          /// CARD PUPILO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.all(w(16)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: w(64),
                    height: w(64),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromRGBO(1, 165, 113, 1),
                    ),
                    child: Center(
                      child: Text(
                        inicialesPupilo,
                        style: TextStyle(
                          fontSize: sp(22),
                          fontFamily: "PoppinsBold",
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: w(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombrePupilo +
                              " " +
                              apellidoPupilo, // ej: "Juan Pérez"
                          style: TextStyle(
                            fontSize: sp(15),
                            fontFamily: "PoppinsBold",
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: h(4)),
                        Text(
                          "Solicitud de cuenta para menor de edad",
                          style: TextStyle(
                            fontSize: sp(12),
                            fontFamily: "Poppins",
                            color: Colors.white.withOpacity(0.55),
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

          /// INFO DNI
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.creditCard,
                  size: sp(16),
                  color: Colors.white.withOpacity(0.4),
                ),
                SizedBox(width: w(10)),
                Expanded(
                  child: Text(
                    "Escaneá el DNI del pupilo. Usamos esta verificación solo para confirmar identidad y parentesco.",
                    style: TextStyle(
                      fontSize: sp(13),
                      fontFamily: "Poppins",
                      color: Colors.white.withOpacity(0.5),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Spacer(),

          /// BOTÓN ESCANEAR DNI
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(56),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(1, 165, 113, 1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.scanLine,
                      size: sp(18),
                      color: Colors.white,
                    ),
                    SizedBox(width: w(10)),
                    Text(
                      "Escanear DNI del pupilo",
                      style: TextStyle(
                        fontSize: sp(16),
                        fontFamily: "PoppinsBold",
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);

                setState(() {
                  cargando = true;
                });

                Future.delayed(Duration(seconds: 1), () {
                  setState(() {
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
                });
              },
            ),
          ),

          SizedBox(height: h(18)),
        ],
      ),
    );
  }

  Widget escanearDniPupilo({Key? key}) {
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
                  "Habilitar pupilo",
                  style: TextStyle(
                    fontSize: sp(12),
                    fontFamily: "Poppins",
                    color: Colors.white.withOpacity(0.45),
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
              "Escaneá el DNI del pupilo",
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

  Widget pupiloHabilitado({Key? key}) {
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

          /// ICONO PRINCIPAL
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Center(
              child: Container(
                width: w(78),
                height: w(78),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromRGBO(1, 165, 113, 1).withOpacity(0.15),
                ),
                child: Icon(
                  LucideIcons.userCheck,
                  size: sp(36),
                  color: const Color.fromRGBO(1, 165, 113, 1),
                ),
              ),
            ),
          ),

          SizedBox(height: h(30)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Center(
              child: Text(
                "Pupilo habilitado",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sp(24),
                  fontFamily: "PoppinsBold",
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: h(12)),

          /// DESCRIPCIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Center(
              child: Text(
                "$nombrePupilo $apellidoPupilo fue habilitado correctamente y quedó vinculado a tu cuenta como tutor.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sp(15),
                  fontFamily: "Poppins",
                  color: Colors.white.withOpacity(0.6),
                  height: 1.45,
                ),
              ),
            ),
          ),

          SizedBox(height: h(33)),

          /// CARD RELACIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.all(w(15)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  /// ICONO RELACIÓN
                  Container(
                    width: w(45),
                    height: w(45),
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
                      LucideIcons.heartHandshake,
                      size: sp(23),
                      color: const Color.fromRGBO(1, 165, 113, 1),
                    ),
                  ),

                  SizedBox(width: w(15)),

                  /// TEXTO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Vínculo creado",
                          style: TextStyle(
                            fontSize: sp(15),
                            fontFamily: "PoppinsBold",
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: h(5)),
                        Text(
                          "Ahora podés ver, administrar y acompañar su experiencia desde tu cuenta.",
                          style: TextStyle(
                            fontSize: sp(13),
                            fontFamily: "Poppins",
                            color: Colors.white.withOpacity(0.55),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Spacer(),

          /// BOTÓN CONTINUAR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(55),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(1, 165, 113, 1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    "Entendido",
                    style: TextStyle(
                      fontSize: sp(16),
                      fontFamily: "PoppinsBold",
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 15);

                Navigator.pushAndRemoveUntil(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: MenuPrincipalPage(),
                  ),
                  (_) => false,
                );
              },
            ),
          ),

          SizedBox(height: h(20)),
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
