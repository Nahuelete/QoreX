// ignore_for_file: file_names, use_key_in_widget_constructors, camel_case_types, deprecated_member_use, unused_field, prefer_final_fields, unused_element, avoid_print, unused_local_variable, await_only_futures, use_build_context_synchronously

import 'dart:async';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/escaneoFacial.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class escanearDniPage extends StatefulWidget {
  @override
  State<escanearDniPage> createState() => _escanearDniPageState();
}

class _escanearDniPageState extends State<escanearDniPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;
  late AnimationController _controllerIconMovimiento;
  late Animation<double> _animationIconMovimiento;
  late AnimationController _iconAccederController;
  late Animation<double> _iconAccederAnimation;

  final ScrollController _scrollController = ScrollController();

  bool muestraVis = true;

  String codeUser = "";
  String dniUser = "";

  CameraController? _cameraControllerDni;
  List<CameraDescription>? _camerasDni;
  bool _isDetecting = false;
  bool _isComplete = false;
  late TextRecognizer _textRecognizer;
  XFile? _dniPhoto;

  Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();
    codeUser = prefs.getString('nombreUser') ?? "";
    print("NOMBRE SHARED: ${codeUser.isEmpty ? "Sin Nombre" : codeUser}");
  }

  Future<void> cargarDniTemp() async {
    await leerShared();
    try {
      await FirebaseFirestore.instance
          .collection("TempUsers")
          .doc(codeUser)
          .update({"dni": dniUser, "estado": "face"});
    } catch (e) {
      print("Error actualizando TempUsers: $e");
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
    if (_cameraControllerDni == null ||
        !_cameraControllerDni!.value.isInitialized)
      return;

    try {
      final XFile picture = await _cameraControllerDni!.takePicture();
      _dniPhoto = picture;
      await processDni(picture);
    } catch (e) {
      print("Error al tomar la foto: $e");
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
      print("DNI: $dni");
      bool existe = await dniYaRegistrado(dni);

      if (existe) {
        showFlushbar(context, "El DNI $dni ya se encuentra registrado.");
        if (mounted) _initializeCamera();
        return;
      }

      if (!mounted) return;
      setState(() {
        _isDetecting = true;
        dniUser = dni;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _isComplete = true;
        cargarDniTemp();
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

      if (!mounted) return;
      try {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.leftToRight,
            child: escaneoFacialPage(),
          ),
        );
      } catch (e) {
        print("Error navegando: $e");
      }
    } else {
      print("DNI no detectado");
      if (mounted)
        showFlushbar(
          context,
          "No pudimos comprobar tu DNI. Intenta Nuevamente.",
        );
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(237.5); // siempre arriba
      }
    });

    _textRecognizer = GoogleMlKit.vision.textRecognizer();
    _initializeCamera();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _controllerContainerMovimiento = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    _animationContainerMovimiento = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_controllerContainerMovimiento);
    _startFloating();

    _controllerIconMovimiento = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    _animationIconMovimiento = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_controllerIconMovimiento);
    _startFloatingIcon();

    _iconAccederController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _iconAccederAnimation = Tween<double>(begin: -5.0, end: 3.0).animate(
      CurvedAnimation(parent: _iconAccederController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    try {
      _controller.stop();
      _controller.dispose();
      _controllerContainerMovimiento.stop();
      _controllerContainerMovimiento.dispose();
      _controllerIconMovimiento.stop();
      _controllerIconMovimiento.dispose();
      _iconAccederController.stop();
      _iconAccederController.dispose();
      _cameraControllerDni?.dispose();
      _textRecognizer.close();
    } catch (e) {
      print("Error en dispose: $e");
    }
    super.dispose();
  }

  void _startFloating() {
    final random = Random();

    void animateNext() {
      // Movimiento más amplio: entre -15 y +15 en lugar de -5 a +5
      final double newEnd = -20 + random.nextDouble() * 30;
      // Duración más variada: entre 1.5s y 3s
      final int newDuration = 1500 + random.nextInt(1500);

      final tween =
          Tween<double>(
            begin: _animationContainerMovimiento.value,
            end: newEnd,
          ).animate(
            CurvedAnimation(
              parent: _controllerContainerMovimiento,
              curve: Curves.easeInOutSine,
            ),
          );

      _animationContainerMovimiento = tween;

      _controllerContainerMovimiento.duration = Duration(
        milliseconds: newDuration,
      );
      _controllerContainerMovimiento.forward(from: 0).whenComplete(animateNext);
    }

    animateNext();
  }

  void _startFloatingIcon() {
    final random = Random();

    void animateNext() {
      // Movimiento más amplio: entre -15 y +15 en lugar de -5 a +5
      final double newEnd = -3 + random.nextDouble() * 5;
      // Duración más variada: entre 1.5s y 3s
      final int newDuration = 1500 + random.nextInt(1500);

      final tween =
          Tween<double>(
            begin: _animationIconMovimiento.value,
            end: newEnd,
          ).animate(
            CurvedAnimation(
              parent: _controllerIconMovimiento,
              curve: Curves.easeInOutSine,
            ),
          );

      _animationIconMovimiento = tween;

      _controllerIconMovimiento.duration = Duration(milliseconds: newDuration);
      _controllerIconMovimiento.forward(from: 0).whenComplete(animateNext);
    }

    animateNext();
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
  Widget build(BuildContext context) {
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
        body: Stack(
          children: [
            SizedBox(child: muestraDni()),
            SizedBox(child: escanearDni()),
          ],
        ),
      ),
    );
  }

  Widget muestraDni() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: (muestraVis == true ? true : false),
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            reverse: true,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: w(18), right: w(18)),
                child: Container(
                  padding: EdgeInsets.all(1.3), // grosor del borde degradado
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color.fromRGBO(1, 165, 113, 1).withOpacity(0.3),
                        Color.fromRGBO(33, 13, 243, 1).withOpacity(0.3),
                        Color.fromRGBO(165, 53, 253, 1).withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color.fromRGBO(20, 25, 50, 1),
                          Color.fromRGBO(30, 43, 60, 1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(17), // radio interno
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: h(43)),
                          child: AnimatedBuilder(
                            animation: _controllerContainerMovimiento,
                            builder: (context, child) {
                              final curved = Curves.easeInOut.transform(
                                _controllerContainerMovimiento.value,
                              );
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Onda sincronizada con el botón
                                  Transform.scale(
                                    scale:
                                        1 +
                                        curved *
                                            0.7, // 🔹 cuando botón crece, onda también
                                    child: Opacity(
                                      opacity: 0.15 - (curved * 0.15),
                                      child: Container(
                                        width: w(120),
                                        height: h(120),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromRGBO(
                                                1,
                                                165,
                                                113,
                                                1,
                                              ).withOpacity(0.10),
                                              Colors.green.shade600.withOpacity(
                                                0.10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Botón con respiro
                                  Transform.scale(
                                    scale: 1 + (curved * 0.05),
                                    child: AnimatedBuilder(
                                      animation: _animationContainerMovimiento,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            _animationContainerMovimiento.value,
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        width: w(100),
                                        height: h(100),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromRGBO(1, 165, 113, 1),
                                              Colors.green.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(
                                                0.7,
                                              ),
                                              blurRadius: 20,
                                              spreadRadius: 3,
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(7),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: w(0.1),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    15,
                                                  ), // radio un poco menor
                                            ),
                                            child: AnimatedBuilder(
                                              animation:
                                                  _animationContainerMovimiento,
                                              builder: (context, child) {
                                                return Transform.translate(
                                                  offset: Offset(
                                                    0,
                                                    _animationContainerMovimiento
                                                        .value,
                                                  ),
                                                  child: child,
                                                );
                                              },
                                              child: Icon(
                                                Icons.document_scanner,
                                                color: Colors.white,
                                                size: sp(43),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(height: h(13)),
                        Center(
                          child: Text(
                            textAlign: TextAlign.center,
                            "Cómo escanear tu DNI",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "PoppinsBold",
                              fontSize: sp(28),
                            ),
                          ),
                        ),
                        SizedBox(height: h(13)),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: w(23)),
                            child: Text(
                              textAlign: TextAlign.center,
                              "Sigue estas instrucciones para un escaneo exitoso.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontFamily: "Poppins",
                                fontSize: sp(18),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h(33)),
                        Center(
                          child: Container(
                            width: w(300),
                            height: h(180),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color.fromRGBO(
                                  1,
                                  165,
                                  113,
                                  1,
                                ), // contorno verde
                                width: w(1),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                20,
                              ), // mismo radio que el contenedor
                              child: Container(
                                width: w(300),
                                height: h(180),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color.fromRGBO(3, 5, 25, 1),
                                      Color.fromRGBO(13, 20, 40, 1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: LottieBuilder.asset(
                                    "assets/muestraScanDni.json",
                                    repeat: true,
                                    width: w(213),
                                    height: h(213),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h(33)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(23)),
                          child: Container(
                            height: h(93),
                            width: w(300),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w(13),
                                  ),
                                  child: Container(
                                    height: h(43),
                                    width: w(43),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color.fromRGBO(1, 165, 113, 1),
                                          Colors.green.shade600,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: AnimatedBuilder(
                                        animation: _animationIconMovimiento,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(
                                              0,
                                              _animationIconMovimiento.value,
                                            ),
                                            child: child,
                                          );
                                        },
                                        child: Icon(
                                          LucideIcons.eye,
                                          color: Colors.white,
                                          size: sp(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: w(5)),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(213),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Buena iluminación",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: sp(18),
                                            fontFamily: "Poppins",
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(213),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Asegúrate de tener suficiente\nluz para que el texto sea legible.",
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
                        ),
                        SizedBox(height: h(23)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(23)),
                          child: Container(
                            height: h(113),
                            width: w(300),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w(13),
                                  ),
                                  child: Container(
                                    height: h(43),
                                    width: w(43),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color.fromRGBO(33, 13, 243, 1),
                                          Colors.blue,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: AnimatedBuilder(
                                        animation: _animationIconMovimiento,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(
                                              0,
                                              _animationIconMovimiento.value,
                                            ),
                                            child: child,
                                          );
                                        },
                                        child: Icon(
                                          LucideIcons.file,
                                          color: Colors.white,
                                          size: sp(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: w(5)),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(213),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Documento completo",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: sp(18),
                                            fontFamily: "Poppins",
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(213),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Coloca todo el DNI dentro\ndel marco, sin cortar\nningún borde.",
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
                        ),
                        SizedBox(height: h(23)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(23)),
                          child: Container(
                            height: h(113),
                            width: w(300),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: w(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w(13),
                                  ),
                                  child: Container(
                                    height: h(43),
                                    width: w(43),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color.fromRGBO(200, 90, 0, 1),
                                          Colors.orange.shade600,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: AnimatedBuilder(
                                        animation: _animationIconMovimiento,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(
                                              0,
                                              _animationIconMovimiento.value,
                                            ),
                                            child: child,
                                          );
                                        },
                                        child: Icon(
                                          LucideIcons.activity,
                                          color: Colors.white,
                                          size: sp(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: w(5)),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(213),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Sin movimiento",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: sp(18),
                                            fontFamily: "Poppins",
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(213),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Mantén el documento quieto\ndurante el escaneo.",
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
                        ),
                        SizedBox(height: h(33)),
                        GestureDetector(
                          child: Container(
                            height: h(53),
                            width: w(300),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromRGBO(1, 165, 113, 1),
                                  Colors.green.shade600,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Entendido",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: sp(20),
                                  ),
                                ),
                                SizedBox(width: w(13)),
                                AnimatedBuilder(
                                  animation: _iconAccederAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                        _iconAccederAnimation.value,
                                        0,
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: Icon(
                                    LucideIcons.checkCheck,
                                    color: Colors.white,
                                    size: sp(20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              muestraVis = false;
                              // Detener y liberar AnimationControllers
                              _controller.stop();
                              _controller.dispose();

                              _controllerContainerMovimiento.stop();
                              _controllerContainerMovimiento.dispose();

                              _controllerIconMovimiento.stop();
                              _controllerIconMovimiento.dispose();
                            });
                          },
                        ),
                        SizedBox(height: h(33)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return IgnorePointer(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _CirclePatternPainter(
                    animationValue: _controller.value,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget escanearDni() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Funciones de adaptación responsiva
    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);
    return Visibility(
      visible: (muestraVis == true ? false : true),
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              reverse: true,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(left: w(18), right: w(18)),
                  child: Container(
                    padding: EdgeInsets.all(1.3), // grosor del borde degradado
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color.fromRGBO(1, 165, 113, 1).withOpacity(0.3),
                          Color.fromRGBO(33, 13, 243, 1).withOpacity(0.3),
                          Color.fromRGBO(165, 53, 253, 1).withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        height: h(523),
                        width: w(400),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Color.fromRGBO(20, 25, 50, 1),
                              Color.fromRGBO(30, 43, 60, 1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            17,
                          ), // radio interno
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(top: h(13)),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: w(18)),
                                  child: GestureDetector(
                                    child: Container(
                                      height: h(48),
                                      width: w(48),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.fromRGBO(20, 25, 50, 1),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: w(1),
                                        ),
                                      ),
                                      child: Icon(
                                        LucideIcons.arrowLeft,
                                        color: Colors.white.withOpacity(0.7),
                                        size: sp(20),
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        muestraVis = true;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 200),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      "Escanea tu DNI",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "PoppinsBold",
                                        fontSize: sp(25),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: h(13)),
                              Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 200),
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    "Coloca tu documento dentro del\nmarco.",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: "Poppins",
                                      fontSize: sp(20),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: h(33)),
                              Center(
                                child:
                                    _cameraControllerDni != null &&
                                        _cameraControllerDni!
                                            .value
                                            .isInitialized
                                    ? (_isComplete == true
                                          ? Stack(
                                              children: [
                                                Center(
                                                  child: Container(
                                                    width: w(300),
                                                    height: h(180),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color: Color.fromRGBO(
                                                          1,
                                                          165,
                                                          113,
                                                          1,
                                                        ), // contorno verde
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Container(
                                                      width: w(300),
                                                      height: h(180),
                                                      decoration: BoxDecoration(
                                                        color: Color.fromRGBO(
                                                          1,
                                                          165,
                                                          113,
                                                          1,
                                                        ).withOpacity(0.3),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
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
                                                ),
                                              ],
                                            )
                                          : Stack(
                                              children: [
                                                Center(
                                                  child: Container(
                                                    width: w(300),
                                                    height: h(180),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color: Color.fromRGBO(
                                                          1,
                                                          165,
                                                          113,
                                                          1,
                                                        ), // contorno verde
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ), // mismo radio que el contenedor
                                                      child: FittedBox(
                                                        fit: BoxFit.cover,
                                                        child: SizedBox(
                                                          width:
                                                              _cameraControllerDni!
                                                                  .value
                                                                  .previewSize!
                                                                  .height,
                                                          height:
                                                              _cameraControllerDni!
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
                                              ],
                                            ))
                                    : CircularProgressIndicator(
                                        color: Color.fromRGBO(1, 165, 113, 1),
                                      ),
                              ),
                              Visibility(
                                visible: (_cameraControllerDni != null
                                    ? false
                                    : true),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 200),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Error al inicializar la camara.",
                                        style: TextStyle(
                                          color: Color.fromARGB(
                                            255,
                                            242,
                                            96,
                                            63,
                                          ),
                                          fontWeight: FontWeight.w300,
                                          fontFamily: "Poppins",
                                          fontSize: sp(18),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: h(53)),
                              GestureDetector(
                                child: Container(
                                  height: h(53),
                                  width: w(300),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromRGBO(1, 165, 113, 1),
                                        Colors.green.shade600,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: 250,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            (_isDetecting == true
                                                ? (_isComplete == true
                                                      ? "DNI Verificado"
                                                      : "Verificando DNI")
                                                : "Escanear DNI"),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: "Poppins",
                                              fontSize: sp(20),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: w(23)),
                                      AnimatedBuilder(
                                        animation: _iconAccederAnimation,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(
                                              _iconAccederAnimation.value,
                                              0,
                                            ),
                                            child: child,
                                          );
                                        },
                                        child: (_isDetecting == true
                                            ? (_isComplete == true
                                                  ? Icon(
                                                      LucideIcons.checkCircle,
                                                      color: Colors.white,
                                                    )
                                                  : SizedBox(
                                                      height: 23,
                                                      width: 23,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                        backgroundColor:
                                                            Colors.transparent,
                                                      ),
                                                    ))
                                            : Icon(
                                                LucideIcons.scan,
                                                color: Colors.white,
                                                size: 20,
                                              )),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  if (_isComplete != true) {
                                    await _cameraControllerDni!.pausePreview();
                                    _takePicture();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return IgnorePointer(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _CirclePatternPainter(
                    animationValue: _controller.value,
                  ),
                ),
              );
            },
          ),
        ],
      ),
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
      Offset(0.15, 0.15),
      Offset(0.6, 0.3),
      Offset(0.7, 0.8),
      Offset(0.1, 0.8),
      Offset(0.8, 0.3),
    ];

    final radii = [10.0, 5.0, 10.0, 8.0, 8.0, 10.0, 8.0, 10.0, 8.0, 10.0];
    final opacities = [
      0.1,
      0.15,
      0.12,
      0.08,
      0.10,
      0.08,
      0.10,
      0.08,
      0.10,
      0.08,
    ];

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
