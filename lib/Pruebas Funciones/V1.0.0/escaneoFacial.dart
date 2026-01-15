// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, deprecated_member_use, avoid_print, prefer_final_fields, unused_element, curly_braces_in_flow_control_structures, unused_field, use_build_context_synchronously

import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/verificacionCompletada.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart'
    show PageTransition, PageTransitionType;
import 'package:vibration/vibration.dart';

class escaneoFacialPage extends StatefulWidget {
  final XFile? dniPhoto;

  const escaneoFacialPage({super.key, this.dniPhoto});

  @override
  State<escaneoFacialPage> createState() => _escaneoFacialPageState();
}

class _escaneoFacialPageState extends State<escaneoFacialPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  late AnimationController _controllerContainerMovimiento;
  late Animation<double> _animationContainerMovimiento;

  late AnimationController _controllerIconMovimiento;
  late Animation<double> _animationIconMovimiento;

  late AnimationController _iconAccederController;
  late Animation<double> _iconAccederAnimation;

  late AnimationController _controllerColorText;
  late Animation<Color?> _colorAnimationText;

  final ScrollController _scrollController = ScrollController();

  bool muestraVis = true;

  int _countdown = 3;
  Timer? _countdownTimer;

  bool _canDetectFaces = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playStepAudio(int step) async {
    String assetPath = "";
    switch (step) {
      case 0:
        assetPath = "audios/step1Audio.mp3";
        break;
      case 1:
        assetPath = "audios/step2Audio.mp3";
        break;
      case 2:
        assetPath = "audios/step3Audio.mp3";
        break;
      case 3:
        assetPath = "audios/stepFinalizadoAudio.mp3";
        break;
      case 4:
        assetPath = "audios/stepErrorAudio.mp3";
        break;
      case 5:
        assetPath = "audios/pip.mp3";
        break;
    }

    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print("Error reproduciendo audio: $e");
    }
  }

  CameraController? _cameraControllerFace;
  List<CameraDescription>? _camerasFace;
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(enableContours: true, enableClassification: true),
  );

  bool _isDetecting = false;
  bool _stepCompleted = false;
  bool _showCamera = true;
  int _currentStep = 0;
  String stepText = "Mira directamente a la cámara";

  Future<void> _initializeCamera() async {
    _camerasFace = await availableCameras();
    if (_camerasFace == null || _camerasFace!.isEmpty) return;

    final frontCamera = _camerasFace!.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _camerasFace!.first,
    );

    _cameraControllerFace = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    await _cameraControllerFace!.initialize();
    if (!mounted) return;

    await _waitForMuestraFalse();

    _playStepAudio(0);

    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    setState(() {
      _canDetectFaces = true;
      stepText = "Mira directamente a la cámara";
    });

    _startImageStream();
  }

  Future<void> _waitForMuestraFalse() async {
    while (muestraVis) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _startImageStream() {
    DateTime? lastProcessed;

    _cameraControllerFace?.startImageStream((CameraImage image) async {
      if (!_canDetectFaces || _isDetecting) return;

      if (lastProcessed != null &&
          DateTime.now().difference(lastProcessed!) <
              const Duration(milliseconds: 300)) {
        return;
      }
      lastProcessed = DateTime.now();
      _isDetecting = true;

      try {
        final inputImage = InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );

        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isNotEmpty) {
          final face = faces.first;
          bool validStep = false;

          if (_currentStep == 0) validStep = face.headEulerAngleY!.abs() < 10;
          if (_currentStep == 1) validStep = face.headEulerAngleY! > 25;
          if (_currentStep == 2) validStep = face.headEulerAngleY! < -25;

          if (validStep && !_stepCompleted) {
            _handleValidStep();
          }

          if (_stepCompleted && !validStep) {
            _handleInvalidStep();
          }
        }
      } catch (e) {
        print("Error procesando stream: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  void _handleValidStep() {
    _stepCompleted = true;
    _countdown = 3;
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) return;

      setState(() {
        if (_countdown > 0) {
          stepText = "Mantén la posición...";
          _playStepAudio(5);
          _countdown--;
        } else {
          timer.cancel();
          _stepCompleted = false;
          _currentStep++;

          if (_currentStep == 1) {
            Vibration.vibrate(duration: 15);
            stepText = "Gira la cabeza a la derecha";
            _playStepAudio(_currentStep);
          } else if (_currentStep == 2) {
            Vibration.vibrate(duration: 15);
            stepText = "Gira la cabeza a la izquierda";
            _playStepAudio(_currentStep);
          } else if (_currentStep > 2) {
            Vibration.vibrate(duration: 15);
            _finalizarValidacion();
          }
        }
      });
    });
  }

  void _handleInvalidStep() {
    _countdownTimer?.cancel();
    _stepCompleted = false;
    _playStepAudio(4);
    if (!mounted) return;
    Vibration.vibrate(duration: 50);
    setState(() {
      stepText = "Posición incorrecta ❌\nVuelve a intentarlo";
    });
  }

  Future<void> _finalizarValidacion() async {
    try {
      if (_cameraControllerFace != null) {
        if (_cameraControllerFace!.value.isStreamingImages) {
          await _cameraControllerFace?.stopImageStream();
        }
        await _cameraControllerFace?.dispose();
        _cameraControllerFace = null;
      }

      try {
        await _faceDetector.close();
      } catch (e) {
        debugPrint("⚠️ Error cerrando FaceDetector: $e");
      }

      debugPrint("✅ Validación finalizada correctamente");
      _playStepAudio(3);
      Future.delayed(Duration(seconds: 5), () {
        try {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.leftToRight, // 👉 derecha a izquierda
              child: verificacionCompletadaPage(),
            ),
          );
        } catch (e) {
          print("Error navegando: $e");
        }
      });
    } catch (e, s) {
      debugPrint("❌ Error en _finalizarValidacion: $e");
      debugPrint("Stack: $s");
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    Vibration.vibrate(duration: 5);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(295.5); // siempre arriba
      }
    });

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

    _controllerColorText = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _colorAnimationText = ColorTween(
      begin: Colors.grey,
      end: Color.fromRGBO(1, 165, 113, 1),
    ).animate(_controllerColorText);
  }

  @override
  void dispose() {
    _controller.dispose();
    _controllerContainerMovimiento.dispose();
    _controllerIconMovimiento.dispose();
    _iconAccederController.dispose();
    _controllerColorText.dispose();
    _countdownTimer?.cancel();
    _cameraControllerFace?.dispose();
    _faceDetector.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startFloating() {
    final random = Random();
    void animateNext() {
      final double newEnd = -20 + random.nextDouble() * 30;
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
      final double newEnd = -3 + random.nextDouble() * 5;
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
            SizedBox(child: muestraScanFace()),
            SizedBox(child: escanearFace()),
          ],
        ),
      ),
    );
  }

  Widget muestraScanFace() {
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
                                          padding: EdgeInsets.all(7),
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
                                                LucideIcons.scanFace,
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
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: Text(
                              textAlign: TextAlign.center,
                              "Cómo hacer la verificación facial",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "PoppinsBold",
                                fontSize: sp(27),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h(13)),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: w(23)),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w(300)),
                              child: Text(
                                textAlign: TextAlign.center,
                                "Sigue estas instrucciones para un reconocimiento exitoso.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontFamily: "Poppins",
                                  fontSize: sp(18),
                                ),
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
                                    "assets/muestraScanFace.json",
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
                            height: h(113),
                            width: w(350),
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
                                          LucideIcons.sun,
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
                                        maxWidth: w(300),
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
                                    SizedBox(height: h(5)),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(280),
                                      ),
                                      child: Text(
                                        "Asegúrate de estar en un lugar\nbien iluminado, evita sombras\nen tu rostro.",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: sp(15),
                                          fontFamily: "Poppins",
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
                            height: h(120),
                            width: w(350),
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
                                          LucideIcons.volume2,
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
                                        maxWidth: w(280),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Volumen activado",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: sp(18),
                                            fontFamily: "Poppins",
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    Text(
                                      "Comproba tener volumen alto.\nSe te indicara que hacer en\ncada paso.",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: sp(15),
                                        fontFamily: "Poppins",
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
                            width: w(350),
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
                                          LucideIcons.smile,
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
                                        maxWidth: w(280),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Expresión natural",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: sp(18),
                                            fontFamily: "Poppins",
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h(5)),
                                    Text(
                                      "Mantén una expresión neutral\ny relajada durante el escaneo.",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: sp(15),
                                        fontFamily: "Poppins",
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
                            width: w(350),
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

  Widget escanearFace() {
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
                        height: h(553),
                        width: w(360),
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
                                  constraints: BoxConstraints(maxWidth: w(300)),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      "Verificación Facial",
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
                                child: AnimatedBuilder(
                                  animation: _colorAnimationText,
                                  builder: (context, child) {
                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: w(300),
                                      ),
                                      child: Text(
                                        textAlign: TextAlign.center,
                                        stepText,
                                        style: TextStyle(
                                          color: _colorAnimationText.value,
                                          fontFamily: "Poppins",
                                          fontSize: sp(20),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: h(33)),
                              Center(
                                child:
                                    _cameraControllerFace != null &&
                                        _cameraControllerFace!
                                            .value
                                            .isInitialized
                                    ? (_currentStep > 2
                                          ? Stack(
                                              children: [
                                                Center(
                                                  child: Container(
                                                    width: w(300),
                                                    height: h(180),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
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
                                                    child: Container(
                                                      width: w(230),
                                                      height: h(230),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Color.fromRGBO(
                                                          1,
                                                          165,
                                                          113,
                                                          1,
                                                        ).withOpacity(0.3),
                                                        //borderRadius: BorderRadius.circular(20)
                                                      ),
                                                      child: Center(
                                                        child: LottieBuilder.asset(
                                                          "assets/scanFaceComplete.json",
                                                          repeat: false,
                                                          width: w(200),
                                                          height: h(200),
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
                                                  child: AnimatedBuilder(
                                                    animation:
                                                        _colorAnimationText,
                                                    builder: (context, child) {
                                                      return Container(
                                                        width: w(
                                                          230,
                                                        ), // diámetro del círculo
                                                        height: h(230),
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            color:
                                                                _colorAnimationText
                                                                    .value ??
                                                                Color.fromRGBO(
                                                                  1,
                                                                  165,
                                                                  113,
                                                                  1,
                                                                ), // borde verde
                                                            width: w(3),
                                                          ),
                                                        ),
                                                        child: ClipOval(
                                                          child: FittedBox(
                                                            fit: BoxFit.cover,
                                                            child: SizedBox(
                                                              width: _cameraControllerFace!
                                                                  .value
                                                                  .previewSize!
                                                                  .height,
                                                              height:
                                                                  _cameraControllerFace!
                                                                      .value
                                                                      .previewSize!
                                                                      .width,
                                                              child: Stack(
                                                                children: [
                                                                  CameraPreview(
                                                                    _cameraControllerFace!,
                                                                  ),
                                                                  Center(
                                                                    child: Text(
                                                                      (_countdown >
                                                                                  0 &&
                                                                              _stepCompleted)
                                                                          ? '$_countdown'
                                                                          : '',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .white
                                                                            .withOpacity(
                                                                              0.5,
                                                                            ),
                                                                        fontSize:
                                                                            sp(
                                                                              133,
                                                                            ),
                                                                        fontFamily:
                                                                            "PoppinsBold",
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ))
                                    : CircularProgressIndicator(
                                        color: Color.fromRGBO(1, 165, 113, 1),
                                      ),
                              ),
                              SizedBox(height: h(53)),
                              Visibility(
                                visible: (_cameraControllerFace != null
                                    ? false
                                    : true),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: w(300),
                                    ),
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
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: w(13),
                                ),
                                child: IntrinsicWidth(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: w(13),
                                      vertical: h(10),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: w(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize
                                          .min, //Que solo ocupe lo necesario
                                      children: [
                                        AnimatedBuilder(
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
                                          child: Container(
                                            height: h(30),
                                            width: w(30),
                                            decoration: BoxDecoration(
                                              color: Color.fromRGBO(
                                                200,
                                                90,
                                                0,
                                                1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                (_currentStep > 2
                                                    ? LucideIcons.checkCircle
                                                    : LucideIcons.alertCircle),
                                                color: Colors.white,
                                                size: sp(18),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: w(10)),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: w(250),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              (_currentStep > 2
                                                  ? "Completaste la verificacion facial."
                                                  : "Te indicaremos los pasos a seguir."),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: (sp(16.8)),
                                                fontFamily: "Poppins",
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
