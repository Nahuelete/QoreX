// ignore_for_file: camel_case_types, use_key_in_widget_constructors, deprecated_member_use, avoid_print, curly_braces_in_flow_control_structures, unused_field, unused_element, use_build_context_synchronously, prefer_final_fields, unused_local_variable, unnecessary_string_interpolations, unrelated_type_equality_checks, invalid_use_of_protected_member, prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, control_flow_in_finally, unnecessary_null_comparison, no_leading_underscores_for_local_identifiers, sort_child_properties_last, await_only_futures

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:bluetooth/UI/inicio.dart';
import 'package:bluetooth/UI/iniciarSesion.dart';
import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:bluetooth/main.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class registrarsePage extends StatefulWidget {
  final int pasoGuardado;

  const registrarsePage({super.key, required this.pasoGuardado});

  @override
  State<registrarsePage> createState() => _registrarsePageState();
}

class _registrarsePageState extends State<registrarsePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // =====================================================
  // ===================== VARIABLES =====================
  // =====================================================

  // --------------------- STEPS -------------------------
  /// Paso actual del flujo de registro
  int currentStep = 0;

  // -------------------- LOADING ------------------------
  /// Indica si hay una acción en progreso
  bool cargando = false;

  // ------------------ CONTROL DISPOSE ------------------
  /// Evita ejecutar lógica luego de dispose
  bool _isDisposed = false;

  // ------------------ DATOS USUARIO --------------------
  /// Código temporal del usuario
  String codeUser = "";

  ///Uid del usuario
  String uidUser = "";

  /// DNI del usuario
  String dniUser = "";

  /// Email del usuario
  String emailUser = "";

  /// Nombre del usuario
  String nombreUser = "";

  /// Apellido del usuario
  String apellidoUser = "";

  /// Edad del usuario
  int edadUser = 0;

  String fechaNacimiento = "";

  /// Telefono del usuario
  String telefonoUser = "";

  /// Genero del usuario
  String generoUser = "";

  /// Genero del usuario
  String claveUser = "";

  /// CBU del usuario
  String cbuUser = "";

  /// Alias del usuario
  String aliasUser = "";

  ///Tema del usuario
  String temaUser = "";

  ///Colors del usuario
  String colorUser = "";
  Color colorUI = Color.fromRGBO(1, 165, 113, 1);

  ///FaceID del usuario
  bool faceIdUser = false;

  // =====================================================
  // ===================== DNI ===========================
  // =====================================================

  /// Controlador de cámara para escaneo de DNI
  CameraController? _cameraControllerDni;

  /// Lista de cámaras disponibles (DNI)
  List<CameraDescription>? _camerasDni;

  /// Evita múltiples detecciones simultáneas
  bool _isDetecting = false;

  /// Indica si el escaneo fue completado correctamente
  bool _isComplete = false;

  /// Evita múltiples capturas de imagen
  bool _isTakingPicture = false;

  /// Reconocedor de texto (ML Kit)
  TextRecognizer? _textRecognizer;

  /// Imagen capturada del DNI
  XFile? _dniPhoto;

  // =====================================================
  // ==================== ROSTRO =========================
  // =====================================================

  /// Controlador de cámara para escaneo facial
  CameraController? _cameraControllerFace;

  /// Lista de cámaras disponibles (rostro)
  List<CameraDescription>? _camerasFace;

  /// Detector facial (ML Kit)
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(enableContours: true, enableClassification: true),
  );

  /// Evita múltiples detecciones faciales simultáneas
  bool _isDetectingFace = false;

  /// Indica si el stream facial ya comenzó
  bool _isFaceStreamStarted = false;

  /// Permite o no detectar rostros
  bool _canDetectFaces = false;

  /// Paso actual del escaneo facial
  int _currentStep = 0;

  /// Indica si un paso fue completado
  bool _stepCompleted = false;

  /// Muestra u oculta la cámara
  bool _showCamera = true;

  ///Verificar angulo valido
  double? _lastValidAngle;

  /// Texto que indica qué debe hacer el usuario
  String stepText = "Mirá directamente a la cámara";

  /// Controlador de animación del progreso circular
  late AnimationController _progressController;

  /// Animación del progreso circular
  late Animation<double> _progressAnimation;

  /// Timer para el conteo regresivo
  Timer? _countdownTimer;

  /// Valor del contador regresivo
  int _countdown = 3;

  /// Reproductor de audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Evita reproducir audio más de una vez
  bool _audio0Played = false;

  // =====================================================
  // ===================== FOCUS =========================
  // =====================================================

  FocusNode? _focusEmail;
  FocusNode? _focusNombre;
  FocusNode? _focusApellido;
  FocusNode? _focusTelefono;
  FocusNode? _focusEmailTutor;
  FocusNode? _focusCode;
  FocusNode? _focusAlias;

  // =====================================================
  // ================== CONTROLLERS ======================
  // =====================================================

  /// Controller email
  final TextEditingController _controllerEmail = TextEditingController();

  /// Controller código email
  final TextEditingController _controllerCodeEmail = TextEditingController();

  /// Controller nombre
  final TextEditingController _controllerNombre = TextEditingController();

  /// Controller apellido
  final TextEditingController _controllerApellido = TextEditingController();

  /// Controller nacimiento
  final TextEditingController _controllerNacimiento = TextEditingController();

  /// Controller telefono
  final TextEditingController _controllerTelefono = TextEditingController();

  /// Controller clave
  final TextEditingController _controllerClave = TextEditingController();

  /// Controller email tutor
  final TextEditingController _controllerEmailTutor = TextEditingController();

  ///Configuraciones Adicionales

  /// Controller alias
  final TextEditingController _controllerAlias = TextEditingController();

  // =====================================================
  // ================== FOCUS LISTENERS ==================
  // =====================================================

  bool _cancelarFocus = false;

  void _cancelarFocoAutomatico() {
    _cancelarFocus = true;
  }

  /// Mantiene el foco en Email
  void _onEmailFocusChange() {
    if (_focusEmail!.hasFocus && mounted && !_cancelarFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _cancelarFocus) return;
        _focusEmail!.requestFocus();
      });
    }
  }

  /// Mantiene el foco en Nombre si está vacío
  void _onNombreFocusChange() {
    if (_focusNombre!.hasFocus && mounted && !_cancelarFocus) {
      if (_controllerNombre.text.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _cancelarFocus) return;
          _focusNombre!.requestFocus();
        });
      }
    }
  }

  /// Mantiene el foco en Apellido si está vacío
  void _onApellidoFocusChange() {
    if (_focusApellido!.hasFocus && mounted && !_cancelarFocus) {
      if (_controllerApellido.text.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _cancelarFocus) return;
          _focusApellido!.requestFocus();
        });
      }
    }
  }

  /// Mantiene el foco en Telefono
  void _onTelefonoFocusChange() {
    if (_focusTelefono!.hasFocus && mounted && !_cancelarFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _cancelarFocus) return;
        _focusTelefono!.requestFocus();
      });
    }
  }

  /// Mantiene el foco en Email Tutor
  void _onEmailTutorFocusChange() {
    if (_focusEmailTutor!.hasFocus &&
        mounted &&
        !_cancelarFocus &&
        emailNoRegitrado == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _cancelarFocus) return;
        _focusEmailTutor!.requestFocus();
      });
    }
  }

  // =====================================================
  // ================= SHARED PREFERENCES ================
  // =====================================================

  /// Lee el código del usuario guardado localmente
  Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();
    codeUser = prefs.getString('codeUser') ?? "";
    claveUser = prefs.getString('claveUser') ?? "";
  }

  /// Guarda el código del usuario localmente
  Future<void> guardarDatos(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('codeUser', code);
  }

  // =====================================================
  // ================= OBTENER DATOS =====================
  // =====================================================

  /// Escucha cambios del usuario temporal en Firestore
  Future<void> obtenerDatos() async {
    await leerShared();

    if (codeUser.isEmpty) {
      print("❌ codeUser vacío, no se puede obtener datos");
      crearUsuarioTemporal();
      return; // ⚠️ Salir si no hay ID
    }

    FirebaseFirestore.instance
        .collection("TempUsers")
        .doc(codeUser)
        .snapshots()
        .listen((docSnapshot) async {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              nombreUser = data["nombre"] ?? "";
              apellidoUser = data["apellido"] ?? "";
              emailUser = data["email"] ?? "";
              dniUser = data["dni"] ?? "";
              edadUser = data["edad"] ?? 0;
              telefonoUser = data["telefono"] ?? "";
              generoUser = data["genero"] ?? "";
              colorUser = data["color"] ?? "";
              claveUser = data["clave"] ?? "";
              aliasUser = data["alias"] ?? "";
              cbuUser = data["cbu"] ?? "";
              recordarme = data["recordarme"] ?? false;
              temaUser = data["tema"] ?? "";
              uidUser = data["uid"] ?? "";
              uidTutor = data["uid tutor"] ?? "";
              currentStep = data["paso"] ?? 0;

              colorUI = obtenerColor(colorUser);
            });

            if (currentStep == 1) {
              _textRecognizer = GoogleMlKit.vision.textRecognizer();
              _initializeCamera();
              startLoop();
            }

            if (currentStep == 2) {
              _initializeCameraFace();
              inicializarAnimacionIndicadorRostro();
            }

            if (currentStep == 3) {
              _focusEmail = FocusNode();
              _focusEmail!.addListener(_onEmailFocusChange);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _focusEmail!.requestFocus();
              });
            }

            if (currentStep == 6) {
              _focusNombre = FocusNode();
              _focusNombre!.addListener(_onNombreFocusChange);

              _focusApellido = FocusNode();
              _focusApellido!.addListener(_onApellidoFocusChange);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _focusNombre!.requestFocus();
              });
            }

            if (currentStep == 9) {
              _focusTelefono = FocusNode();
              _focusTelefono!.addListener(_onTelefonoFocusChange);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _focusTelefono!.requestFocus();
              });
            }

            if (currentStep == 19) {
              _focusEmailTutor = FocusNode();
              _focusEmailTutor!.addListener(_onEmailTutorFocusChange);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _focusEmailTutor!.requestFocus();
              });
            }

            if (currentStep == 20) {
              obtenerDatosTutor();
            }
          }
        });
  }

  //Descifrar Color Usuario
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

  //Obtener los datos del tutor
  Future<void> obtenerDatosTutor() async {
    await leerShared();
    await obtenerDatos();

    FirebaseFirestore.instance
        .collection("Usuarios")
        .doc(uidTutor)
        .snapshots()
        .listen((docSnapshot) async {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;

            setState(() {
              nombreTutor = data["Nombre"] ?? "";
              apellidoTutor = data["Apellido"] ?? "";
              emailTutor = data["Email"] ?? "";
              avatarTutor = data["Avatar"] ?? "";
              uidTutor = data["Uid"] ?? "";
              inicialesTutor =
                  nombreTutor.isNotEmpty && apellidoTutor.isNotEmpty
                  ? "${nombreTutor[0]}${apellidoTutor[0]}".toUpperCase()
                  : "";
            });
          }
        });
  }

  // =====================================================
  // ================= USUARIO TEMPORAL ==================
  // =====================================================

  /// Crea un usuario temporal si no existe
  Future<void> crearUsuarioTemporal() async {
    await leerShared();
    await verificarPasoGuardado();

    if (currentStep == 0 && codeUser.isEmpty) {
      final firestore = FirebaseFirestore.instance;
      final random = Random();
      bool existe = true;

      while (existe) {
        codeUser = (10000 + random.nextInt(90000)).toString();
        final doc = await firestore.collection('TempUsers').doc(codeUser).get();
        existe = doc.exists;
      }

      guardarDatos(codeUser);

      await firestore.collection('TempUsers').doc(codeUser).set({
        'paso': 0,
        'creado': FieldValue.serverTimestamp(),
      });

      print('✅ Usuario temporal creado: $codeUser');
    }
  }

  /// Elimina el usuario temporal
  Future<void> borrarUsuarioTemporal() async {
    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).delete();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('codeUser');
  }

  // =====================================================
  // ================= CONTROL DE PASOS ==================
  // =====================================================

  /// Verifica el paso guardado y ejecuta acciones
  Future<void> verificarPasoGuardado() async {
    await leerShared();

    setState(() {
      currentStep = widget.pasoGuardado;
    });

    if (currentStep == 1) {
      _textRecognizer = GoogleMlKit.vision.textRecognizer();
      _initializeCamera();
      startLoop();
    }

    if (currentStep == 2) {
      _initializeCameraFace();
      inicializarAnimacionIndicadorRostro();
    }

    if (currentStep == 3) {
      _focusEmail = FocusNode();
      _focusEmail!.addListener(_onEmailFocusChange);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusEmail!.requestFocus();
      });
    }

    if (currentStep == 4) {
      _focusCode = FocusNode();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusCode!.requestFocus();
      });
    }

    if (currentStep == 6) {
      _focusNombre = FocusNode();
      _focusNombre!.addListener(_onNombreFocusChange);

      _focusApellido = FocusNode();
      _focusApellido!.addListener(_onApellidoFocusChange);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNombre!.requestFocus();
      });
    }

    if (currentStep == 9) {
      _focusTelefono = FocusNode();
      _focusTelefono!.addListener(_onTelefonoFocusChange);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusTelefono!.requestFocus();
      });
    }

    if (currentStep == 19) {
      _focusEmailTutor = FocusNode();
      _focusEmailTutor!.addListener(_onEmailTutorFocusChange);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusEmailTutor!.requestFocus();
      });
    }

    if (currentStep == 20) {
      obtenerDatosTutor();
    }
  }

  /// Avanza un paso del flujo
  Future<void> avanzarPaso() async {
    if (currentStep != 18) {
      setState(() {
        currentStep++;
      });
    }

    if (currentStep == 18) {
      setState(() {
        currentStep = 9;
      });
    }

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "paso": currentStep,
    });
  }

  /// Retrocede un paso del flujo
  Future<void> retrocederPaso() async {
    setState(() {
      currentStep--;
    });

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "paso": currentStep,
    });

    if (currentStep == 6) {
      _focusNombre = FocusNode();
      _focusApellido = FocusNode();

      setState(() {
        _controllerNombre.text = nombreUser;
        _controllerApellido.text = apellidoUser;
      });

      Future.delayed(const Duration(milliseconds: 250), () {
        _focusNombre!.requestFocus();
      });
    }

    if (currentStep == 3) {
      _focusEmail = FocusNode();

      setState(() {
        _controllerEmail.text = emailUser;
      });

      _focusEmail!.addListener(_onEmailFocusChange);

      Future.delayed(const Duration(milliseconds: 250), () {
        _focusEmail!.requestFocus();
      });
    }

    if (currentStep == 8) {
      _focusTelefono = FocusNode();

      setState(() {
        _controllerTelefono.text = telefonoUser;
      });

      _focusTelefono!.addListener(_onTelefonoFocusChange);

      Future.delayed(const Duration(milliseconds: 250), () {
        _focusTelefono!.requestFocus();
      });
    }
  }

  // =====================================================
  // ================ FUNCIONES DNI ======================
  // =====================================================

  //Escanear Dni
  Future<void> cargarDniTemp(String dni) async {
    try {
      await FirebaseFirestore.instance
          .collection("TempUsers")
          .doc(codeUser)
          .set({"dni": dniUser}, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          cargando = false; // ✅ terminó todo
        });
      }

      Future.delayed(Duration(milliseconds: 3800), () {
        setState(() {
          dniUser = dni;
          avanzarPaso();
          _initializeCameraFace();
          inicializarAnimacionIndicadorRostro();
        });
      });
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
      // 🔥 APENAS detecta el DNI
      if (mounted) {
        setState(() {
          cargando = true;
        });
      }

      print("DNI: $dni");

      bool existe = await dniYaRegistrado(dni.toString());

      if (existe) {
        if (mounted) {
          setState(() {
            cargando = false; // ⛔ si ya existe, apagás loading
          });
        }
        showFlushbar(context, "El DNI $dni ya se encuentra registrado.");
        if (mounted) _initializeCamera();
        return;
      }

      if (!mounted) return;
      setState(() {
        _isDetecting = true;
        dniUser = dni.toString();
      });

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      setState(() {
        _isComplete = true;
        cargarDniTemp(dni);
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
  //Fin escanear Dni

  // =====================================================
  // ============== FUNCIONES ROSTRO =====================
  // =====================================================
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
      case 6:
        assetPath = "audios/stepAlejateAudio.mp3";
        break;
      case 7:
        assetPath = "audios/stepAcercateAudio.mp3";
        break;
    }

    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print("Error reproduciendo audio: $e");
    }
  }

  double get progresoCircular => (_currentStep / 3).clamp(0.0, 1.0);

  void inicializarAnimacionIndicadorRostro() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: progresoCircular)
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );

    _progressController.forward();
  }

  void actualizarPaso() {
    _progressAnimation =
        Tween<double>(
          begin: _progressAnimation.value,
          end: progresoCircular,
        ).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );

    _progressController
      ..reset()
      ..forward();
  }

  //Control De Distancia
  static const double _faceTooFarRatio = 0.15; // Bajarlo
  static const double _faceTooCloseRatio = 0.65; // Bajarlo también
  DateTime? _lastDistanceWarning;
  bool _wasOutOfRange = false;
  DateTime? _lastFaceSeen;
  static const Duration _maxNoFaceDuration = Duration(seconds: 2);

  Future<void> _initializeCameraFace() async {
    _camerasFace = await availableCameras();
    if (_camerasFace == null || _camerasFace!.isEmpty) return;

    final frontCamera = _camerasFace!.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _camerasFace!.first,
    );

    _cameraControllerFace = CameraController(
      frontCamera,
      Platform.isAndroid ? ResolutionPreset.medium : ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await _cameraControllerFace!.initialize();
    if (!mounted) return;

    // 🔑 Esperar a que el preview esté realmente renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // El audio ahora se dispara cuando carga la camara
      //_playStepAudio(0);

      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;

      setState(() {
        _canDetectFaces = true;
        stepText = "Mira directamente a la cámara";
      });

      _startImageStream();
    });
  }


void _startImageStream() {
    if (_cameraControllerFace == null) return;
    if (!_cameraControllerFace!.value.isInitialized) return;

    if (_cameraControllerFace!.value.isStreamingImages ||
        _isFaceStreamStarted) {
      return;
    }

    _isFaceStreamStarted = true;
    DateTime? lastProcessed;

    _cameraControllerFace!.startImageStream((CameraImage image) async {
      if (!mounted || !_canDetectFaces || _isDetectingFace) return;

      if (lastProcessed != null &&
          DateTime.now()
                  .difference(lastProcessed!)
                  .compareTo(const Duration(milliseconds: 300)) <
              0) {
        return;
      }

      lastProcessed = DateTime.now();
      _isDetectingFace = true;

      try {
        InputImage inputImage;

        if (Platform.isAndroid) {
          // ANDROID: Convertir YUV420 a NV21 correctamente
          final int width = image.width;
          final int height = image.height;
          final int ySize = width * height;
          final int uvSize = width * height ~/ 2;

          final Uint8List nv21 = Uint8List(ySize + uvSize);

          // Copiar plano Y
          final yPlane = image.planes[0];
          if (yPlane.bytesPerRow == width) {
            nv21.setRange(0, ySize, yPlane.bytes);
          } else {
            for (int i = 0; i < height; i++) {
              nv21.setRange(
                i * width,
                (i + 1) * width,
                yPlane.bytes,
                i * yPlane.bytesPerRow,
              );
            }
          }

          // Copiar planos UV intercalados (formato NV21)
          final uPlane = image.planes[1];
          final vPlane = image.planes[2];
          int uvIndex = ySize;

          for (int i = 0; i < height ~/ 2; i++) {
            for (int j = 0; j < width ~/ 2; j++) {
              final int uvOffset =
                  i * uPlane.bytesPerRow + j * uPlane.bytesPerPixel!;
              nv21[uvIndex++] = vPlane.bytes[uvOffset];
              nv21[uvIndex++] = uPlane.bytes[uvOffset];
            }
          }

          // Obtener rotación del sensor
          final camera = _cameraControllerFace!.description;
          final sensorOrientation = camera.sensorOrientation;

          InputImageRotation rotation;
          if (sensorOrientation == 0) {
            rotation = InputImageRotation.rotation0deg;
          } else if (sensorOrientation == 90) {
            rotation = InputImageRotation.rotation90deg;
          } else if (sensorOrientation == 180) {
            rotation = InputImageRotation.rotation180deg;
          } else {
            rotation = InputImageRotation.rotation270deg;
          }

          inputImage = InputImage.fromBytes(
            bytes: nv21,
            metadata: InputImageMetadata(
              size: Size(width.toDouble(), height.toDouble()),
              rotation: rotation,
              format: InputImageFormat.nv21,
              bytesPerRow: width,
            ),
          );
        } else {
          // iOS: Combinar todos los planos BGRA8888
          final WriteBuffer allBytes = WriteBuffer();
          for (final Plane plane in image.planes) {
            allBytes.putUint8List(plane.bytes);
          }
          final bytes = allBytes.done().buffer.asUint8List();

          final rotation =
              InputImageRotationValue.fromRawValue(
                _cameraControllerFace!.description.sensorOrientation,
              ) ??
              InputImageRotation.rotation0deg;

          inputImage = InputImage.fromBytes(
            bytes: bytes,
            metadata: InputImageMetadata(
              size: Size(image.width.toDouble(), image.height.toDouble()),
              rotation: rotation,
              format: InputImageFormat.bgra8888,
              bytesPerRow: image.planes.first.bytesPerRow,
            ),
          );
        }

        final faces = await _faceDetector.processImage(inputImage);
        final now = DateTime.now();

        if (faces.isEmpty) {
          _lastFaceSeen ??= now;

          if (now.difference(_lastFaceSeen!) > _maxNoFaceDuration) {
            _handleFaceDistance(
              message: "Acercate un poco a la cámara",
              audioStep: 4,
            );
            _playStepAudio(7);
          }
          return;
        }

        _lastFaceSeen = null;
        final face = faces.first;
        bool validStep = false;

        final double ratio = face.boundingBox.width / image.width.toDouble();

        if (ratio < _faceTooFarRatio) {
          _handleFaceDistance(
            message: "Acercate un poco a la cámara",
            audioStep: 4,
          );
          _playStepAudio(7);
          return;
        }

        if (ratio > _faceTooCloseRatio) {
          _handleFaceDistance(
            message: "Alejate un poco de la cámara",
            audioStep: 4,
          );
          _playStepAudio(6);
          return;
        }

        // 🔑 LÓGICA CORREGIDA: INVERTIDA PARA ANDROID
        final double? angleY = face.headEulerAngleY;

        if (_currentStep == 0) {
          // Paso 0: Mirando al frente
          validStep = angleY != null && angleY.abs() < 15;
          if (validStep) {
            _lastValidAngle = angleY;
          }
        } else if (_currentStep == 1) {
          // Paso 1: "Gira a la DERECHA" - En Android es NEGATIVO
          if (Platform.isAndroid) {
            validStep = angleY != null && angleY < -25;
          } else {
            validStep = angleY != null && angleY > 25;
          }
          
          if (validStep) {
            _lastValidAngle = angleY;
          }
        } else if (_currentStep == 2) {
          // Paso 2: "Gira a la IZQUIERDA" - En Android es POSITIVO
          if (Platform.isAndroid) {
            validStep = angleY != null && angleY > 25;
          } else {
            validStep = angleY != null && angleY < -25;
          }
        }

        if (validStep && !_stepCompleted) {
          _handleValidStep();
        }

        if (_stepCompleted && !validStep) {
          _handleInvalidStep();
        }

      } catch (e, s) {
        debugPrint("❌ Error procesando stream: $e");
        debugPrint("Stack: $s");
      } finally {
        _isDetectingFace = false;
      }
    });
  }

  void _handleFaceDistance({required String message, required int audioStep}) {
    final now = DateTime.now();

    // Evita spam de audio/mensajes
    if (_lastDistanceWarning != null &&
        now.difference(_lastDistanceWarning!) < const Duration(seconds: 2)) {
      return;
    }

    _lastDistanceWarning = now;

    if (!mounted) return;

    setState(() {
      stepText = message;
    });

    _playStepAudio(audioStep);
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
          actualizarPaso();

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
            stepText = "Escaneo Completado";
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

  /// Cancela el escaneo facial, detiene la cámara y audios
  Future<void> cancelarEscaneoRostro() async {
    try {
      // Detener timer de conteo regresivo
      _countdownTimer?.cancel();
      _countdownTimer = null;
      _stepCompleted = false;

      // Detener stream de la cámara
      if (_cameraControllerFace != null) {
        if (_cameraControllerFace!.value.isStreamingImages) {
          try {
            await _cameraControllerFace!.stopImageStream();
          } catch (e) {
            debugPrint("⚠️ Error deteniendo image stream: $e");
          }
        }
        try {
          await _cameraControllerFace!.dispose();
        } catch (e) {
          debugPrint("⚠️ Error liberando CameraControllerFace: $e");
        }
        _cameraControllerFace = null;
      }

      // Reset de banderas
      _isFaceStreamStarted = false;
      _isDetectingFace = false;
      _canDetectFaces = false;

      // Detener audio
      try {
        await _audioPlayer.stop();
      } catch (_) {}

      _audio0Played = false;
    } catch (e) {
      debugPrint("❌ Error cancelando escaneo rostro: $e");
    }
  }

  Future<void> _finalizarValidacion() async {
    if (_isDisposed) return;

    try {
      // 🔒 Evitar múltiples finalizaciones
      _countdownTimer?.cancel();
      _countdownTimer = null;

      // 🛑 Detener stream solo si está activo
      if (_cameraControllerFace != null) {
        final controller = _cameraControllerFace!;

        if (controller.value.isInitialized &&
            controller.value.isStreamingImages) {
          try {
            await controller.stopImageStream();
          } catch (e) {
            debugPrint("⚠️ Error deteniendo image stream: $e");
          }
        }

        // 🧹 Liberar cámara
        try {
          await controller.dispose();
        } catch (e) {
          debugPrint("⚠️ Error disponiendo CameraControllerFace: $e");
        }

        _cameraControllerFace = null;
      }

      // 🔄 Reset de banderas de estado del stream
      _isFaceStreamStarted = false;
      _isDetectingFace = false;
      _canDetectFaces = false;

      // 🎧 Reproducir audio final UNA sola vez
      if (mounted) {
        _playStepAudio(3);
      }

      debugPrint("✅ Validación finalizada correctamente");

      // ⏭️ Acciones post-validación (si aplica)
      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        debugPrint("Escaneo Rostro Completado");
        setState(() {
          _focusEmail = FocusNode();
          _focusEmail!.addListener(_onEmailFocusChange);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _focusEmail!.requestFocus();
          });
          cargando = false;
        });
        avanzarPaso();
      });
    } catch (e, s) {
      debugPrint("❌ Error en _finalizarValidacion: $e");
      debugPrint("Stack: $s");
    }
  }
  //Fin Escanear Rostro

  // =====================================================
  // ============ VALIDACIONES EMAIL =====================
  // =====================================================
  bool emailValido = false;
  bool emailReenviado = false;

  /// Verifica el formato del email ingresado
  Future<void> verificarFormatoEmail() async {
    final email = _controllerEmail.text.trim();

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.(com|ar|edu|org|es)$');

    setState(() {
      emailValido = emailRegex.hasMatch(email);
    });
  }

  /// Verifica si el email ya existe en la colección Usuarios
  Future<void> verificarExistenciaEmail(String email) async {
    final emailIngresado = _controllerEmail.text;

    try {
      final query = await FirebaseFirestore.instance
          .collection("Usuarios")
          .where("Email", isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (!mounted) return;

      // ✅ Email NO existe → continuar registro
      if (query.docs.isEmpty) {
        setState(() {
          emailUser = emailIngresado.toLowerCase();
          cargando = false;
        });

        FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update(
          {"email": emailUser},
        );

        await sendEmailCode();
        if (!mounted) return;

        _focusCode = FocusNode();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusCode!.requestFocus();
        });

        avanzarPaso();
        return;
      }

      // ❌ Email ya registrado
      final data = query.docs.first.data();

      FocusManager.instance.primaryFocus?.unfocus();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => alertaEmailExistente(
          email: emailIngresado,
          nombre: "${data["Nombre"] ?? ""} ${data["Apellido"] ?? ""}",
          avatar: data["Avatar"] ?? "",
        ),
      );

      setState(() {
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      showFlushbar(context, "Error al verificar el email");
      setState(() {
        cargando = false;
      });
    }
  }

  /// Envía el código de verificación al email del usuario
  Future<int> sendEmailCode() async {
    final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");

    const serviceId = "service_z3hbbeh";
    const templateId = "template_1i3c9qh";
    const userId = "bc4FkZberPqwpjovF";

    final response = await http.post(
      url,
      headers: {"origin": "http:localhost", "Content-Type": "application/json"},
      body: json.encode({
        "service_id": serviceId,
        "template_id": templateId,
        "user_id": userId,
        "template_params": {"codigo": codeUser, "sender_email": emailUser},
      }),
    );

    return response.statusCode;
  }

  /// Verifica el código ingresado por el usuario
  void verificarCodeEmail() {
    final code = _controllerCodeEmail.text.trim();

    if (code.length != 5) {
      showFlushbar(context, "Ingresá el código completo");
      return;
    }

    // ✅ Código correcto
    if (code == codeUser) {
      Future.delayed(Duration(seconds: 1), () {
        avanzarPaso();
        Vibration.vibrate(duration: 5);
      });

      Future.delayed(const Duration(seconds: 3), () {
        _focusNombre = FocusNode();
        _focusNombre!.addListener(_onNombreFocusChange);

        _focusApellido = FocusNode();
        _focusApellido!.addListener(_onApellidoFocusChange);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNombre!.requestFocus();
        });
        avanzarPaso();
        Vibration.vibrate(duration: 5);
      });

      return;
    }

    // ❌ Código incorrecto
    Vibration.vibrate(duration: 50);
    showFlushbar(context, "Código incorrecto");

    setState(() {
      _controllerCodeEmail.clear();
    });
  }

  // =====================================================
  // ================= NOMBRE Y APELLIDO =================
  // =====================================================

  Future<void> generarColor() async {
    final random = Random();

    // 🎨 Colores posibles
    final List<String> colores = ["Verde", "Azul", "Naranja", "Violeta"];

    final String colorElegido = colores[random.nextInt(colores.length)];

    setState(() {
      colorUser = colorElegido;
    });
  }

  /// Guarda nombre y apellido del usuario
  Future<void> guardarNombreApellido() async {
    await generarColor();

    colorUI = obtenerColor(colorUser);

    setState(() {
      nombreUser =
          _controllerNombre.text[0].toUpperCase() +
          _controllerNombre.text.substring(1).toLowerCase();
      apellidoUser =
          _controllerApellido.text[0].toUpperCase() +
          _controllerApellido.text.substring(1).toLowerCase();
      cargando = false;

      _focusNombre = FocusNode();
      _focusNombre!.addListener(_onNombreFocusChange);
    });

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "nombre": nombreUser,
      "apellido": apellidoUser,
      "color": colorUser,
    });

    avanzarPaso();

    Future.delayed(const Duration(milliseconds: 250), () {
      _focusNombre!.requestFocus();
    });
  }

  // =====================================================
  // ================= NACIMIENTO =================
  // =====================================================
  int? edadCalculada;

  Future<void> guardarEdad(int edad) async {
    setState(() {
      edadUser = edad;
      fechaNacimiento = _controllerNacimiento.text;
      cargando = false;
      _focusTelefono = FocusNode();
      _focusTelefono!.addListener(_onEmailFocusChange);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusTelefono!.requestFocus();
      });
    });

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "edad": edad,
      "fecha nacimiento": fechaNacimiento,
    });

    if (edad < 18) {
      currentStep = 18;
      FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
        "paso": 18,
      });
    } else {
      _focusTelefono = FocusNode();
      _focusTelefono!.addListener(_onTelefonoFocusChange);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusTelefono!.requestFocus();
      });
      avanzarPaso();
    }
  }

  // =====================================================
  // ================= TELEFONO =================
  // =====================================================

  Future<void> verificarExistenciaTelefono() async {
    final query = await FirebaseFirestore.instance
        .collection("Usuarios")
        .where("Telefono", isEqualTo: "+54 " + _controllerTelefono.text)
        .limit(1)
        .get();

    String nombreAsociado = "";
    String apellidoAsociado = "";
    String avatarAsociado = "";
    String inicialesAsociado = "";

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();

      setState(() {
        nombreAsociado = data["Nombre"] ?? "";
        apellidoAsociado = data["Apellido"] ?? "";
        avatarAsociado = data["Avatar"] ?? "";
      });

      _focusTelefono!.unfocus();

      setState(() {
        cargando = false;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => alertaTelefonoExistente(
          telefono: _controllerTelefono.text,
          nombre: nombreAsociado,
          apellido: apellidoAsociado,
          avatar: avatarAsociado,
        ),
      );
    } else {
      guardarTelefono(_controllerTelefono.text);
    }
  }

  Future<void> guardarTelefono(String telefono) async {
    // Formatear número: 2914057815 → 291-405-7815
    String telefonoFormateado = telefono;
    if (telefono.length == 10) {
      final parte1 = telefono.substring(0, 3);
      final parte2 = telefono.substring(3, 6);
      final parte3 = telefono.substring(6);
      telefonoFormateado = "$parte1-$parte2-$parte3";
    }

    setState(() {
      telefonoUser = telefonoFormateado;
      cargando = false;
    });

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "telefono": "+54" + " " + telefonoFormateado,
    });

    avanzarPaso();
  }

  // =====================================================
  // ================= GENERO =================
  // =====================================================
  String generoSeleccionado = "";

  Future<void> guardarGenero() async {
    setState(() {
      generoUser = generoSeleccionado;
      cargando = false;
    });

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "genero": generoSeleccionado,
    });

    avanzarPaso();
  }

  // =====================================================
  // ================= CLAVE =================
  // =====================================================
  bool claveValida = false;
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

  Future<void> guardarClave(String clave) async {
    setState(() {
      claveUser = clave + "000";
      cargando = false;
    });

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "clave": claveUser,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('claveUser', claveUser);

    if (edadUser < 18) {
      crearUid();
      setState(() {
        currentStep = 19;
        FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update(
          {"paso": 19},
        );
        _focusEmailTutor = FocusNode();
        _focusEmailTutor!.addListener(_onEmailTutorFocusChange);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusEmailTutor!.requestFocus();
        });
      });
    } else {
      avanzarPaso();
    }
  }

  // =====================================================
  // ================= REGISTRARSE =================
  // =====================================================
  bool cargandoComenzar = false;
  bool cargandoOpcionales = false;

  final storage = FlutterSecureStorage();
  final auth = FirebaseAuth.instance;
  final localAuth = LocalAuthentication();

  Future<void> generarCbuAlias() async {
    Random random = Random();
    cbuUser = '';
    for (int i = 0; i < 22; i++) {
      setState(() {
        cbuUser += random.nextInt(10).toString();
      });
    }

    List<String> sufijos = [
      'ágil',
      'amable',
      'audaz',
      'brillante',
      'cálido',
      'cauteloso',
      'cómodo',
      'compasivo',
      'confiable',
      'creativo',
      'curioso',
      'decidido',
      'diligente',
      'dinámico',
      'disciplinado',
      'eficiente',
      'elocuente',
      'entusiasta',
      'equilibrado',
      'exitoso',
      'expresivo',
      'fácil',
      'fiel',
      'flexible',
      'fuerte',
      'generoso',
      'hábil',
      'honesto',
      'humilde',
      'imaginativo',
      'impresionante',
      'independiente',
      'ingenioso',
      'inteligente',
      'intuitivo',
      'jovial',
      'justo',
      'leal',
      'luminoso',
      'maduro',
      'magnífico',
      'meticuloso',
      'modesto',
      'optimista',
      'organizado',
      'paciente',
      'perseverante',
      'positivo',
      'práctico',
      'proactivo',
      'productivo',
      'profesional',
      'racional',
      'reflexivo',
      'resolutivo',
      'responsable',
      'sabio',
      'sensible',
      'sereno',
      'sincero',
      'sofisticado',
      'solidario',
      'talentoso',
      'tenaz',
      'tranquilo',
      'valiente',
      'vanguardista',
      'vibrante',
      'vigilante',
      'vivo',
      'voluntarioso',
      'vulnerable',
      'zelo',
      'adaptable',
      'afectuoso',
      'alegre',
      'amigable',
      'apasionado',
      'apegado',
      'aplicado',
      'artístico',
      'asertivo',
      'atento',
      'audaz',
      'auténtico',
      'bajo',
      'bello',
      'benévolo',
      'bravo',
      'cálido',
      'cándido',
      'cauteloso',
      'cercano',
      'cínico',
      'cómodo',
      'compasivo',
      'confiado',
      'conservador',
      'constante',
      'creativo',
      'curioso',
      'decidido',
      'delicado',
      'diligente',
      'disciplinado',
      'eficaz',
      'eficiente',
      'elocuente',
      'entusiasta',
      'equilibrado',
      'exitoso',
      'expresivo',
      'fácil',
      'fiel',
      'flexible',
      'fuerte',
      'generoso',
      'hábil',
      'honesto',
      'humilde',
      'imaginativo',
      'impresionante',
      'independiente',
      'ingenioso',
      'inteligente',
      'intuitivo',
      'jovial',
      'justo',
      'leal',
      'luminoso',
      'maduro',
      'magnífico',
      'meticuloso',
      'modesto',
      'optimista',
      'organizado',
      'paciente',
      'perseverante',
      'positivo',
      'práctico',
      'proactivo',
      'productivo',
      'profesional',
      'racional',
      'reflexivo',
      'resolutivo',
      'responsable',
      'sabio',
      'sensible',
      'sereno',
      'sincero',
      'sofisticado',
      'solidario',
      'talentoso',
      'tenaz',
      'tranquilo',
      'valiente',
      'vanguardista',
      'vibrante',
      'vigilante',
      'vivo',
      'voluntarioso',
      'vulnerable',
      'zelo',
      'adaptable',
      'afectuoso',
      'alegre',
      'amigable',
      'apasionado',
      'apegado',
      'aplicado',
      'artístico',
      'asertivo',
      'atento',
      'audaz',
      'auténtico',
      'bajo',
      'bello',
      'benévolo',
      'bravo',
      'cálido',
      'cándido',
      'cauteloso',
      'cercano',
      'cínico',
      'cómodo',
      'compasivo',
      'confiado',
      'conservador',
      'constante',
      'creativo',
      'curioso',
      'decidido',
      'delicado',
      'diligente',
      'disciplinado',
      'eficaz',
      'eficiente',
      'elocuente',
      'entusiasta',
      'equilibrado',
      'exitoso',
      'expresivo',
      'fácil',
      'fiel',
      'flexible',
      'fuerte',
      'generoso',
      'hábil',
      'honesto',
      'humilde',
      'imaginativo',
      'impresionante',
      'independiente',
      'ingenioso',
      'inteligente',
      'intuitivo',
      'jovial',
      'justo',
      'leal',
      'luminoso',
      'maduro',
      'magnífico',
      'meticuloso',
      'modesto',
      'optimista',
      'organizado',
      'paciente',
      'perseverante',
      'positivo',
      'práctico',
      'proactivo',
      'productivo',
      'profesional',
      'racional',
      'reflexivo',
      'resolutivo',
      'responsable',
      'sabio',
      'sensible',
      'sereno',
      'sincero',
      'sofisticado',
      'solidario',
      'talentoso',
      'tenaz',
      'tranquilo',
      'valiente',
      'vanguardista',
      'vibrante',
      'vigilante',
      'vivo',
      'voluntarioso',
      'vulnerable',
      'zelo',
      'adaptable',
      'afectuoso',
      'alegre',
      'amigable',
      'apasionado',
      'apegado',
      'aplicado',
      'artístico',
      'asertivo',
      'atento',
      'audaz',
      'auténtico',
      'bajo',
      'bello',
      'benévolo',
      'bravo',
      'cálido',
      'cándido',
      'cauteloso',
      'cercano',
      'cínico',
      'cómodo',
      'compasivo',
      'confiado',
      'conservador',
      'constante',
      'creativo',
      'curioso',
      'decidido',
      'delicado',
      'diligente',
      'disciplinado',
      'eficaz',
      'eficiente',
      'elocuente',
      'entusiasta',
      'equilibrado',
      'exitoso',
      'expresivo',
      'fácil',
      'fiel',
      'flexible',
      'fuerte',
      'generoso',
      'hábil',
      'honesto',
      'humilde',
      'imaginativo',
      'impresionante',
      'independiente',
      'ingenioso',
      'inteligente',
      'intuitivo',
      'jovial',
      'justo',
      'leal',
      'luminoso',
      'maduro',
      'magnífico',
      'meticuloso',
      'modesto',
      'optimista',
      'organizado',
      'paciente',
      'perseverante',
      'positivo',
      'práctico',
      'proactivo',
      'productivo',
      'profesional',
      'racional',
      'reflexivo',
      'resolutivo',
      'responsable',
      'sabio',
      'sensible',
      'sereno',
      'sincero',
      'sofisticado',
      'solidario',
      'talentoso',
      'tenaz',
      'tranquilo',
      'valiente',
      'vanguardista',
      'vibrante',
      'vigilante',
      'vivo',
      'voluntarioso',
      'vulnerable',
      'zelo',
    ];

    String palabra = sufijos[random.nextInt(sufijos.length)];
    String palabra2 = sufijos[random.nextInt(sufijos.length)];

    setState(() {
      //aliasUser = nameUser.replaceAll(" ", "").toLowerCase() + "." + palabra.toLowerCase();
      aliasUser =
          palabra.toLowerCase() + "." + palabra2.toLowerCase() + "." + "QX";
    });
  }

  Future<void> habilitarUsuarioTransacciones() async {
    try {
      FirebaseFirestore.instance.collection("BusquedaUsers").doc(aliasUser).set(
        {"Uid": uidUser, "Nombre": nombreUser, "Tipo": "Alias"},
      );

      FirebaseFirestore.instance.collection("BusquedaUsers").doc(cbuUser).set({
        "Uid": uidUser,
        "Nombre": nombreUser,
        "Tipo": "CBU",
      });

      FirebaseFirestore.instance.collection("BusquedaUsers").doc(emailUser).set(
        {"Uid": uidUser, "Nombre": nombreUser, "Tipo": "Email"},
      );
    } catch (e) {
      print("Error al habilitar usuario: $e");
    }
  }

  Future<void> enviarNotificacionRegistrado() async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Registrado #$uidUser")
        .set({
          "Nombre": nombreUser,
          "Apellido": apellidoUser,
          "Uid": codeUser,
          "Email": emailUser,
          "Dni": dniUser,
          "FechaTime": DateTime.now(),
          "Fecha": fecha,
          "Hora": horaActual,
          "Involucra": [uidUser],
          "Leida": {uidUser: false},
          "Tipo": "Registrado",
        });
  }

  Future<void> guardarTokenFCM() async {
    final messaging = FirebaseMessaging.instance;

    final token = await messaging.getToken();

    if (token == null) return;

    await FirebaseFirestore.instance.collection("Usuarios").doc(uidUser).set({
      "fcmToken": token,
    }, SetOptions(merge: true));
  }

  String hashClave(String clave) {
    return BCrypt.hashpw(clave, BCrypt.gensalt());
  }

  Future<void> iniciarSesion() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailUser.trim(),
        password: claveUser,
      );
    } on FirebaseAuthException catch (e) {
      print(e.code);
    }
  }

  Future<void> registrarse() async {
    if (!mounted) return;

    bool registroOk = false;

    try {
      final ahora = DateTime.now();
      final fecha = DateFormat('dd-MM-yyyy').format(ahora);

      final String claveHash = hashClave(claveUser);

      // Registrar usuario en Auth
      UserCredential? userCredential;

      if (uidUser.isEmpty) {
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailUser.trim(),
              password: claveUser,
            );
      }

      // Ahora userCredential está disponible
      if (userCredential != null && userCredential.user != null) {
        uidUser = userCredential.user!.uid;
      }

      if (cargandoComenzar == true || currentStep == 17) {
        // SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('codeUser', uidUser);
        await prefs.setString('claveUser', claveUser);
      }

      await storage.write(key: 'codeUser', value: uidUser);
      await storage.write(key: 'claveUser', value: claveUser);

      // Habilitar Usuario
      await generarCbuAlias();
      await habilitarUsuarioTransacciones();

      // Firestore
      await FirebaseFirestore.instance.collection("Usuarios").doc(uidUser).set({
        "Uid": uidUser,
        "Dni": dniUser,
        "Email": emailUser,
        "Nombre": nombreUser,
        "Apellido": apellidoUser,
        "Edad": edadUser,
        "Telefono": telefonoUser,
        "Genero": generoUser,
        "Registrado": fecha.replaceAll("-", "/"),
        "Mostrar Saldo": true,
        "Tema": "Oscuro",
        "Recordarme": false,
        "Tarjeta": "No",
        "CBU": cbuUser,
        "Alias": aliasUser,
        "Saldo": 0,
        "Clave": claveHash,
        "Estado": "Habilitado",
        "Color": colorUser,
      });

      await guardarTokenFCM();

      await enviarNotificacionRegistrado();

      registroOk = true;

      print("REGISTRO COMPLETADO");
    } catch (e) {
      print("ERROR EN REGISTRO: $e");

      if (mounted) {
        showFlushbar(context, "Error al registrar usuario");
        setState(() {
          cargando = false;
        });
      }
    } finally {
      if (!mounted) return;

      if (registroOk && cargandoComenzar || registroOk && currentStep == 17) {
        await iniciarSesion();

        Vibration.vibrate(duration: 15);

        Navigator.pushAndRemoveUntil(
          context,
          PageTransition(
            type: PageTransitionType.leftToRight,
            child: MenuPrincipalPage(),
          ),
          (_) => false,
        );

        //Eliminar TempUsers
        FirebaseFirestore.instance
            .collection("TempUsers")
            .doc(codeUser)
            .delete();

        setState(() {
          cargandoComenzar = false;
          cargando = false;
        });
      } else if (registroOk && cargandoOpcionales) {
        setState(() {
          cargandoOpcionales = false;
        });

        FirebaseFirestore.instance
            .collection("TempUsers")
            .doc(codeUser)
            .update({
              "tema": "Oscuro",
              "alias": aliasUser,
              "cbu": cbuUser,
              "recordarme": false,
              "mostrar saldo": true,
              "uid": uidUser,
            });

        avanzarPaso();

        _focusAlias = FocusNode();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusEmailTutor!.requestFocus();
        });
      }

      setState(() {
        cargando = false;
      });
    }
  }

  // =====================================================
  // ================= INGRESAR TUTOR =================
  // =====================================================
  bool emailTutorValido = false;
  bool emailNoRegitrado = false;

  String nombreTutor = "";
  String uidTutor = "";
  String apellidoTutor = "";
  String emailTutor = "";
  String avatarTutor = "";
  String inicialesTutor = "";

  /// Verifica el formato del email ingresado
  Future<void> verificarFormatoEmailTutor() async {
    final email = _controllerEmailTutor.text.trim();

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.(com|ar|edu|org|es)$');

    setState(() {
      emailTutorValido = emailRegex.hasMatch(email);
    });
  }

  /// Verifica si el email ya existe en la colección Usuarios
  Future<void> verificarExistenciaEmailTutor(String email) async {
    final emailIngresado = _controllerEmailTutor.text;

    try {
      final query = await FirebaseFirestore.instance
          .collection("Usuarios")
          .where("Email", isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (!mounted) return;

      // ✅ Email existe → continuar
      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();

        setState(() {
          emailTutor = data["Email"] ?? "";
          uidTutor = data["Uid"] ?? "";
          nombreTutor = data["Nombre"] ?? "";
          apellidoTutor = data["Apellido"] ?? "";
          avatarTutor = data["Avatar"] ?? "";
          inicialesTutor = nombreTutor.isNotEmpty && apellidoTutor.isNotEmpty
              ? "${nombreTutor[0]}${apellidoTutor[0]}".toUpperCase()
              : "";
          cargando = false;
        });

        FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update(
          {"email tutor": emailTutor, "uid tutor": uidTutor},
        );

        enviarNotificacionTutor(uidTutor);

        avanzarPaso();
        return;
      } else {
        setState(() {
          emailNoRegitrado = true;
        });

        _focusEmailTutor!.unfocus();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 23),
              child: Container(
                padding: const EdgeInsets.all(23),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(23, 27, 51, 1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// ICONO
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromRGBO(
                          1,
                          165,
                          113,
                          1,
                        ).withOpacity(0.15),
                      ),
                      child: const Icon(
                        LucideIcons.userX,
                        size: 25,
                        color: Color.fromRGBO(1, 165, 113, 1),
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// TITULO
                    const Text(
                      "Tutor no registrado",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: "PoppinsBold",
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// DESCRIPCIÓN
                    Text(
                      "$emailIngresado\nno pertenece a un tutor registrado.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: "Poppins",
                        color: Colors.white.withOpacity(0.65),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// ACLARACIÓN
                    Text(
                      "Para continuar, tu tutor deberá crear una cuenta y luego autorizar tu registro.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: "Poppins",
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),

                    SizedBox(height: 23),

                    /// BOTONES
                    GestureDetector(
                      child: Container(
                        height: 43,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.13),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "Cambiar email",
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: "PoppinsMedium",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        Vibration.vibrate(duration: 5);

                        setState(() {
                          emailNoRegitrado = false;
                        });

                        Navigator.pop(context);

                        _focusEmailTutor!.requestFocus();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );

        setState(() {
          cargando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      showFlushbar(context, "Error al verificar el email");
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> enviarNotificacionTutor(String uidTutor) async {
    final ahora = DateTime.now();
    final fecha = DateFormat('dd-MM-yyyy').format(ahora);
    final horaActual =
        "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

    FirebaseFirestore.instance
        .collection("Notificaciones")
        .doc("Notificacion Solicitud Tutor #$codeUser")
        .set({
          "De": nombreUser + " " + apellidoUser,
          "De uid": codeUser,
          "Email": emailUser,
          "Dni": dniUser,
          "Estado": "Espera",
          "FechaTime": DateTime.now(),
          "Fecha": fecha,
          "Hora": horaActual,
          "Involucra": [uidTutor],
          "Leida": {uidTutor: false},
          "Tipo": "Tutor Solicitado",
        });
  }

  Future<void> crearUid() async {
    // Registrar usuario en Auth
    final UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: emailUser.trim(),
          password: claveUser,
        );

    uidUser = userCredential.user!.uid;

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "uid": uidUser,
    });
  }

  // =====================================================
  // ================= CONFIGURACIONES ADICIONALES =================
  // =====================================================

  // =====================================================
  // ================= ALIAS =================
  // =====================================================
  bool aliasValido = false;
  bool aliasExistente = false;
  bool aliasCaractEspeciales = false;
  String aliasNuevo = "";

  bool aliasSinCaracteresEspeciales(String aliasBase) {
    final regex = RegExp(r'^[a-zA-Z0-9]+$');
    return regex.hasMatch(aliasBase);
  }

  Future<void> verificarExistenciaAlias() async {
    FirebaseFirestore.instance
        .collection("BusquedaUsers")
        .doc(aliasNuevo)
        .snapshots()
        .listen((docSnapshot) async {
          if (docSnapshot.exists) {
            setState(() {
              aliasExistente = true;
            });
          } else {
            setState(() {
              aliasExistente = false;
            });
          }
        });
  }

  Future<void> guardarAlias(String alias) async {
    setState(() {
      aliasUser = alias.contains(".QX") ? alias : alias + ".QX";
    });

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "alias": aliasUser,
    });

    setState(() {
      cargando = false;
    });

    avanzarPaso();
  }

  // =====================================================
  // ================= SELECCIONAR TEMA =================
  // =====================================================
  bool temaOscuro = true;
  String temaSeleccionado = "Oscuro";

  Future<void> guardarTema() async {
    setState(() {
      temaUser = temaSeleccionado;
    });

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "tema": temaUser,
    });

    setState(() {
      cargando = false;
    });

    avanzarPaso();
  }

  // =====================================================
  // ================= HABILITAR FACE ID =================
  // =====================================================
  bool faceIdHabilitado = false;

  Future<void> guardarFaceID() async {
    setState(() {
      faceIdUser = faceIdHabilitado;
    });

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "face id": faceIdUser,
    });

    setState(() {
      cargando = false;
    });

    avanzarPaso();
  }

  // =====================================================
  // ================= RECORDARME =================
  // =====================================================
  bool recordarSesion = false;

  Future<void> guardarRecordarme() async {
    setState(() {
      recordarme = recordarSesion;
    });

    FirebaseFirestore.instance.collection("TempUsers").doc(codeUser).update({
      "recordarme": recordarme,
    });

    setState(() {
      cargando = false;
    });

    avanzarPaso();
  }

  // =====================================================
  // ================= OPCIONES FINALIZADAS =================
  // =====================================================
  Future<void> guardarOpcionales() async {
    await registrarse();

    FirebaseFirestore.instance.collection("Usuarios").doc(uidUser).update({
      "Alias": aliasUser,
      "Tema": temaUser,
      "Face ID": faceIdUser,
      "Recordarme": recordarme,
    });
  }

  // =====================================================
  // ================= FUNCIONES PRINCIPALES =================
  // =====================================================
  @override
  void initState() {
    super.initState();

    leerShared();

    verificarPasoGuardado();

    obtenerDatos();

    //crearUsuarioTemporal();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelarFocus = true;
    _isDisposed = true;
    _cameraControllerDni?.dispose();
    _textRecognizer?.close();
    _countdownTimer?.cancel();
    _cameraControllerFace?.dispose();
    _faceDetector.close();
    _audioPlayer.dispose();
    _isFaceStreamStarted = false;

    _focusEmail?.removeListener(_onEmailFocusChange);
    _focusNombre?.removeListener(_onNombreFocusChange);
    _focusApellido?.removeListener(_onApellidoFocusChange);
    _focusTelefono?.removeListener(_onTelefonoFocusChange);
    _focusEmailTutor?.removeListener(_onEmailTutorFocusChange);

    _focusEmail?.dispose();
    _focusNombre?.dispose();
    _focusApellido?.dispose();
    _focusTelefono?.dispose();
    _focusEmailTutor?.dispose();
    _focusCode?.dispose();
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
                    if (currentStep == 0 || currentStep == 1) {
                      Vibration.vibrate(duration: 5);
                      borrarUsuarioTemporal();

                      if (FocusManager.instance.primaryFocus != null) {
                        FocusManager.instance.primaryFocus!.unfocus();
                      }

                      Future.delayed(Duration(milliseconds: 150), () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: inicioPage(),
                          ),
                          (_) => false,
                        );
                      });
                    } else if (currentStep == 2 ||
                        currentStep == 3 ||
                        currentStep == 5 ||
                        currentStep == 6 ||
                        currentStep == 9 ||
                        currentStep == 12 ||
                        currentStep == 13 ||
                        currentStep == 17 ||
                        currentStep == 18 ||
                        currentStep == 19 ||
                        currentStep == 20 ||
                        currentStep == 21) {
                      Vibration.vibrate(duration: 5);

                      if (FocusManager.instance.primaryFocus != null) {
                        FocusManager.instance.primaryFocus!.unfocus();
                      }

                      Future.delayed(Duration(milliseconds: 150), () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: inicioPage(),
                          ),
                          (_) => false,
                        );
                      });

                      if (currentStep == 2) {
                        cancelarEscaneoRostro();
                      }
                    } else {
                      Vibration.vibrate(duration: 5);

                      retrocederPaso();
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
                          currentStep == 12
                              ? "Cuenta Creada"
                              : currentStep > 12 && currentStep < 17
                              ? "Configuracion Adicional"
                              : currentStep == 17
                              ? "Perfil Completado"
                              : "Crear Cuenta",
                          style: TextStyle(
                            fontSize: sp(18),
                            color: Colors.white,
                            fontFamily: "PoppinsBold",
                          ),
                        ),
                      ),
                    ),
                    currentStep == 12
                        ? ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: sp(10),
                                    fontFamily: "Poppins",
                                    color: Colors.grey,
                                  ),
                                  children: [
                                    TextSpan(text: "Te uniste a "),
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
                          )
                        : currentStep > 12 && currentStep < 17
                        ? ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: sp(10),
                                    fontFamily: "Poppins",
                                    color: Colors.grey,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Configura al 100% tu cuenta de ",
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
                          )
                        : currentStep == 17
                        ? ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: sp(10),
                                    fontFamily: "Poppins",
                                    color: Colors.grey,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: generoUser == "Femenino"
                                          ? "Bienvenida a "
                                          : "Bienvenido a ",
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
                          )
                        : ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w(300)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: sp(10),
                                    fontFamily: "Poppins",
                                    color: Colors.grey,
                                  ),
                                  children: [
                                    TextSpan(text: "Registrate en "),
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
              child: currentStep == 18
                  ? avisoMenorEdad(key: const ValueKey('aviso menor'))
                  : currentStep == 19
                  ? ingresarEmailTutor(key: const ValueKey('enviar tutor'))
                  : currentStep == 20
                  ? solicitudTutorEnviada(key: const ValueKey('tutor enviada'))
                  : currentStep == 21
                  ? tutorAceptoSolicitud(key: const ValueKey('tutor aceptada'))
                  : currentStep == 0
                  ? prepararRegistro(key: const ValueKey('preparar'))
                  : currentStep == 1
                  ? escanearDni(key: const ValueKey('dni'))
                  : currentStep == 2
                  ? escanearRostro(key: const ValueKey('rostro'))
                  : currentStep == 3
                  ? ingresarEmail(key: const ValueKey('email'))
                  : currentStep == 4
                  ? verificarEmailCodigo(key: const ValueKey('code email'))
                  : currentStep == 5
                  ? emailVerificado(key: const ValueKey('email verificado'))
                  : currentStep == 6
                  ? ingresarNombreApellido(
                      key: const ValueKey('nombre apellido'),
                    )
                  : currentStep == 7
                  ? mostrarNombreApellido(
                      key: const ValueKey('mostrar nombre apellido'),
                    )
                  : currentStep == 8
                  ? ingresarFechaNacimiento(key: const ValueKey('nacimiento'))
                  : currentStep == 9
                  ? ingresarTelefono(key: const ValueKey('telefono'))
                  : currentStep == 10
                  ? seleccionarGenero(key: const ValueKey('genero'))
                  : currentStep == 11
                  ? crearClave(key: const ValueKey('clave'))
                  : currentStep == 12
                  ? registroFinalizado(key: const ValueKey('finalizado'))
                  : currentStep == 13
                  ? configurarAlias(key: const ValueKey('alias'))
                  : currentStep == 14
                  ? configurarTema(key: const ValueKey('tema'))
                  : currentStep == 15
                  ? configurarFaceID(key: const ValueKey('faceID'))
                  : currentStep == 16
                  ? configurarRecordarSesion(key: const ValueKey('recordarme'))
                  : currentStep == 17
                  ? configuracionOpcionalFinalizada(
                      key: const ValueKey('opcinales finalizado'),
                    )
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }

  Widget prepararRegistro({Key? key}) {
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

          /// TEXTO SUPERIOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.userPlus,
                  size: sp(14),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Registro",
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
              "Antes de empezar",
              style: TextStyle(
                fontSize: sp(26),
                fontFamily: "PoppinsBold",
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),

          SizedBox(height: h(12)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Para validar tu identidad vas a necesitar lo siguiente:",
              style: TextStyle(
                fontSize: sp(14),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),

          SizedBox(height: h(40)),

          /// ITEM DNI
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.all(w(16)),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(23, 27, 51, 1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    height: h(44),
                    width: h(44),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromRGBO(1, 165, 113, 0.15),
                    ),
                    child: Icon(
                      LucideIcons.creditCard,
                      color: const Color.fromRGBO(1, 165, 113, 1),
                      size: sp(20),
                    ),
                  ),
                  SizedBox(width: w(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tu DNI",
                          style: TextStyle(
                            fontSize: sp(15),
                            fontFamily: "PoppinsBold",
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: h(4)),
                        Text(
                          "Lo vas a escanear para verificar tu identidad",
                          style: TextStyle(
                            fontSize: sp(13),
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

          SizedBox(height: h(16)),

          /// ITEM ILUMINACIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.all(w(16)),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(23, 27, 51, 1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    height: h(44),
                    width: h(44),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromRGBO(1, 165, 113, 0.15),
                    ),
                    child: Icon(
                      LucideIcons.sun,
                      color: const Color.fromRGBO(1, 165, 113, 1),
                      size: sp(20),
                    ),
                  ),
                  SizedBox(width: w(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Buena iluminación",
                          style: TextStyle(
                            fontSize: sp(15),
                            fontFamily: "PoppinsBold",
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: h(4)),
                        Text(
                          "Necesaria para el escaneo facial",
                          style: TextStyle(
                            fontSize: sp(13),
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

          Spacer(),

          /// BOTÓN CONTINUAR
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

          SizedBox(height: h(13)),
        ],
      ),
    );
  }

  Widget escanearDni({Key? key}) {
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
                  "Paso 1 de 8",
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
              children: List.generate(8, (index) {
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

  Widget escanearRostro({Key? key}) {
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
                  LucideIcons.scanFace,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(5)),
                Text(
                  "Paso 2 de 8",
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
              children: List.generate(8, (index) {
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

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Escaneá tu rostro",
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
              "Colocá tu rostro dentro del círculo y mirá al frente",
              style: TextStyle(
                fontSize: sp(13),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),

          SizedBox(height: h(28)),

          /// 🔹 TEXTO INDICADOR DE ACCIÓN (NUEVO)
          Center(
            child: Text(
              stepText,
              style: TextStyle(
                fontSize: sp(13),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),

          SizedBox(height: h(28)),

          /// AREA CAMARA + PROGRESO CIRCULAR
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// PROGRESO CIRCULAR ANIMADO
                SizedBox(
                  width: w(276),
                  height: w(276),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (_, __) {
                      return CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 3,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation(
                          Color.fromRGBO(1, 165, 113, 1),
                        ),
                      );
                    },
                  ),
                ),

                /// CONTENEDOR CAMARA
                Container(
                  width: w(260),
                  height: w(260),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromRGBO(1, 165, 113, 1),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      /// CAMARA
                      ClipOval(
                        child: SizedBox(
                          width: w(252),
                          height: w(252),
                          child:
                              _cameraControllerFace != null &&
                                  _cameraControllerFace!.value.isInitialized
                              ? Builder(
                                  builder: (_) {
                                    /// 🔑 ACÁ ES EL MOMENTO EXACTO
                                    /// El CircularProgressIndicator YA NO se muestra
                                    if (!_audio0Played) {
                                      _audio0Played = true;

                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (mounted) {
                                              _playStepAudio(0);
                                            }
                                          });
                                    }

                                    /// CONTENIDO CUANDO LA CÁMARA YA ESTÁ LISTA
                                    if (_currentStep > 2) {
                                      /// COMPLETADO
                                      return Center(
                                        child: Container(
                                          width: w(252),
                                          height: w(252),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color.fromRGBO(
                                                1,
                                                165,
                                                113,
                                                1,
                                              ),
                                              width: w(1),
                                            ),
                                          ),
                                          child: Container(
                                            width: w(230),
                                            height: w(230),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color.fromRGBO(
                                                1,
                                                165,
                                                113,
                                                1,
                                              ).withOpacity(0.3),
                                            ),
                                            child: Center(
                                              child: LottieBuilder.asset(
                                                "assets/scanFaceComplete.json",
                                                repeat: false,
                                                width: w(200),
                                                height: w(200),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    /// PREVIEW DE CÁMARA
                                    return FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _cameraControllerFace!
                                            .value
                                            .previewSize!
                                            .height,
                                        height: _cameraControllerFace!
                                            .value
                                            .previewSize!
                                            .width,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CameraPreview(
                                              _cameraControllerFace!,
                                            ),

                                            /// CONTADOR
                                            Text(
                                              (_countdown > 0 && _stepCompleted)
                                                  ? '$_countdown'
                                                  : '',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                fontSize: sp(133),
                                                fontFamily: "PoppinsBold",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: CircularProgressIndicator(
                                    color: Color.fromRGBO(1, 165, 113, 1),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(32)),

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
                    "Asegurate de estar en un lugar bien iluminado y sin accesorios que cubran tu rostro.",
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
          SizedBox(height: h(40)),

          /// PASO
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
                  "Paso 3 de 8",
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

          /// INDICADOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: List.generate(8, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(33),
                    height: h(5),
                    decoration: BoxDecoration(
                      color: index < 3
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
              "Ingresá tu email",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Usaremos este email para enviarte notificaciones y confirmar tu identidad.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(28)),

          /// INPUT EMAIL
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: TextField(
              keyboardType: TextInputType.emailAddress,
              focusNode: _focusEmail,
              autofocus: true,
              controller: _controllerEmail,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: null,
              cursorColor: Color.fromRGBO(1, 165, 113, 1),
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: "ejemplo@email.com",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontFamily: "Poppins",
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                prefixIcon: Icon(
                  LucideIcons.atSign,
                  color: Colors.white.withOpacity(0.4),
                  size: sp(18),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(1, 165, 113, 1),
                    width: 1.2,
                  ),
                ),
              ),
              onChanged: (value) {
                verificarFormatoEmail();
              },
            ),
          ),

          SizedBox(height: h(23)),

          /// INFO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.info,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.4),
                ),
                SizedBox(width: w(8)),
                Expanded(
                  child: Text(
                    "Asegurate de ingresar un email válido al que tengas acceso.",
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
                    verificarExistenciaEmail(_controllerEmail.text);
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
              focusNode: _focusCode,
              autoDisposeControllers: false,
              length: 5,
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

  Widget emailVerificado({Key? key}) {
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
          /// ICONO
          Container(
            width: w(120),
            height: w(120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(1, 165, 113, 0.15),
            ),
            child: Center(
              child: Icon(
                LucideIcons.check,
                size: sp(52),
                color: const Color.fromRGBO(1, 165, 113, 1),
              ),
            ),
          ),

          SizedBox(height: h(28)),

          /// TITULO
          Text(
            "Correo verificado",
            style: TextStyle(
              fontSize: sp(22),
              fontFamily: "PoppinsBold",
              color: Colors.white,
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTEXTO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(60)),
            child: Text(
              "Tu dirección de correo fue confirmada correctamente.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sp(14),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget ingresarNombreApellido({Key? key}) {
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
                  LucideIcons.user,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(5)),
                Text(
                  "Paso 4 de 8",
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

          /// INDICADOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: List.generate(8, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(33),
                    height: h(5),
                    decoration: BoxDecoration(
                      color: index < 4
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
              "Ingresá tus datos",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Escribí tu nombre y apellido tal como figuran en tu DNI.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(28)),

          /// INPUT NOMBRE
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: TextField(
              controller: _controllerNombre,
              focusNode: _focusNombre,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              cursorColor: const Color.fromRGBO(1, 165, 113, 1),
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: "Nombre",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontFamily: "Poppins",
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                prefixIcon: Icon(
                  LucideIcons.user,
                  color: Colors.white.withOpacity(0.4),
                  size: sp(18),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(1, 165, 113, 1),
                    width: 1.2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_focusApellido);
              },
            ),
          ),

          SizedBox(height: h(16)),

          /// INPUT APELLIDO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: TextField(
              controller: _controllerApellido,
              focusNode: _focusApellido,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              cursorColor: const Color.fromRGBO(1, 165, 113, 1),
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: "Apellido",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontFamily: "Poppins",
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                prefixIcon: Icon(
                  LucideIcons.userCheck,
                  color: Colors.white.withOpacity(0.4),
                  size: sp(18),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(1, 165, 113, 1),
                    width: 1.2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          Spacer(),

          /// BOTÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Visibility(
              visible:
                  _controllerNombre.text.isNotEmpty &&
                  _controllerApellido.text.isNotEmpty,
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
                    guardarNombreApellido();
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

  Widget mostrarNombreApellido({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    final String iniciales = nombreUser.isNotEmpty && apellidoUser.isNotEmpty
        ? "${nombreUser[0]}${apellidoUser[0]}".toUpperCase()
        : "";

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
                  LucideIcons.userCheck,
                  size: sp(14),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Confirmacion de nombre",
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
              "Confirmá tus datos",
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
              "Así se mostrará tu nombre dentro de la app.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(40)),

          /// TARJETA USUARIO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.all(w(20)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  /// AVATAR
                  Container(
                    width: w(64),
                    height: w(64),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorUI,
                    ),
                    child: Center(
                      child: Text(
                        iniciales,
                        style: TextStyle(
                          fontSize: sp(22),
                          fontFamily: "PoppinsBold",
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: w(15)),

                  /// DATOS
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w(183)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "$nombreUser $apellidoUser",
                            style: TextStyle(
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h(5)),
                      Text(
                        "Titular de la cuenta",
                        style: TextStyle(
                          fontSize: sp(13),
                          fontFamily: "Poppins",
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),

                  Spacer(),

                  GestureDetector(
                    child: Container(
                      height: h(33),
                      width: w(33),
                      decoration: BoxDecoration(color: Colors.transparent),
                      child: Center(
                        child: Icon(
                          LucideIcons.pencil,
                          color: Colors.white,
                          size: sp(17),
                        ),
                      ),
                    ),
                    onTap: () {
                      Vibration.vibrate(duration: 5);

                      retrocederPaso();
                    },
                  ),
                ],
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
                  size: sp(15),
                  color: Colors.white.withOpacity(0.4),
                ),
                SizedBox(width: w(8)),
                Expanded(
                  child: Text(
                    "Este nombre será visible dentro de la aplicación y en futuras operaciones.",
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

          Spacer(),

          /// BOTÓN
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
                  child: !cargando
                      ? Text(
                          "Confirmar y continuar",
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
                  setState(() {
                    cargando = false;
                  });
                  avanzarPaso();
                });
              },
            ),
          ),

          SizedBox(height: h(13)),
        ],
      ),
    );
  }

  Widget ingresarFechaNacimiento({Key? key}) {
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
                  LucideIcons.calendar,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(5)),
                Text(
                  "Paso 5 de 8",
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

          /// INDICADOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: List.generate(8, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(33),
                    height: h(5),
                    decoration: BoxDecoration(
                      color: index < 6
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
              "Fecha de nacimiento",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: sp(13),
                  fontFamily: "Poppins",
                  color: Colors.white.withOpacity(0.55),
                ),
                children: [
                  const TextSpan(text: "Ingresá tu fecha en formato "),
                  TextSpan(
                    text: "día",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: "Poppins",
                    ),
                  ),
                  const TextSpan(text: " / "),
                  TextSpan(
                    text: "mes",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: "Poppins",
                    ),
                  ),
                  const TextSpan(text: " / "),
                  TextSpan(
                    text: "año.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: "Poppins",
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h(28)),

          /// INPUT FECHA
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: TextField(
              controller: _controllerNacimiento,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: null,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FechaNacimientoFormatter()],
              cursorColor: Color.fromRGBO(1, 165, 113, 1),
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: "DD/MM/AAAA",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontFamily: "Poppins",
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                prefixIcon: Icon(
                  LucideIcons.cake,
                  color: Colors.white.withOpacity(0.4),
                  size: sp(18),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(1, 165, 113, 1),
                    width: 1.2,
                  ),
                ),
              ),
              onChanged: (value) {
                if (value.length == 10) {
                  final parts = value.split('/');
                  try {
                    final day = int.parse(parts[0]);
                    final month = int.parse(parts[1]);
                    final year = int.parse(parts[2]);

                    // VALIDACIÓN DE MES
                    if (month < 1 || month > 12) {
                      setState(() => edadCalculada = null);
                      return;
                    }

                    // DÍAS MÁXIMOS POR MES
                    int maxDay;

                    if (month == 2) {
                      // Febrero (bisiesto)
                      final isLeapYear =
                          (year % 4 == 0 && year % 100 != 0) ||
                          (year % 400 == 0);
                      maxDay = isLeapYear ? 29 : 28;
                    } else if ([4, 6, 9, 11].contains(month)) {
                      maxDay = 30;
                    } else {
                      maxDay = 31;
                    }

                    // VALIDACIÓN DE DÍA
                    if (day < 1 || day > maxDay) {
                      setState(() => edadCalculada = null);
                      return;
                    }

                    final int anioActual = DateTime.now().year;

                    // VALIDACIÓN DE AÑO
                    if (year < 1920 || year > anioActual) {
                      setState(() => edadCalculada = null);
                      return;
                    }

                    final birthDate = DateTime(year, month, day);
                    final now = DateTime.now();

                    int age = now.year - birthDate.year;
                    if (now.month < birthDate.month ||
                        (now.month == birthDate.month &&
                            now.day < birthDate.day)) {
                      age--;
                    }

                    setState(() {
                      edadCalculada = age >= 0 ? age : null;
                    });
                  } catch (_) {
                    setState(() => edadCalculada = null);
                  }
                } else {
                  setState(() => edadCalculada = null);
                }
              },
            ),
          ),

          SizedBox(height: h(20)),

          /// EDAD
          if (edadCalculada != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w(40)),
              child: Container(
                padding: EdgeInsets.all(w(16)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.userCheck,
                      size: sp(18),
                      color: const Color.fromRGBO(1, 165, 113, 1),
                    ),
                    SizedBox(width: w(10)),
                    Text(
                      "Edad: $edadCalculada años",
                      style: TextStyle(
                        fontSize: sp(15),
                        fontFamily: "PoppinsBold",
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Spacer(),

          /// BOTÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Visibility(
              visible: edadCalculada != null,
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
                    guardarEdad(edadCalculada!);
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

  Widget ingresarTelefono({Key? key}) {
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
                  LucideIcons.phone,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(5)),
                Text(
                  "Paso 6 de 8",
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

          /// INDICADOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: List.generate(8, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(33),
                    height: h(5),
                    decoration: BoxDecoration(
                      color: index < 6
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
              "Ingresá tu teléfono",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Lo usaremos para validaciones de seguridad y contacto importante.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(28)),

          /// INPUT TELÉFONO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: TextField(
              controller: _controllerTelefono,
              focusNode: _focusTelefono,
              enableSuggestions: false,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TelefonoFormatter(),
              ],
              autofocus: true,
              cursorColor: Color.fromRGBO(1, 165, 113, 1),
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: "000 123 4567",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontFamily: "Poppins",
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w(12)),
                  child: Center(
                    widthFactor: 0,
                    child: Text(
                      "+54",
                      style: TextStyle(
                        fontSize: sp(14),
                        fontFamily: "PoppinsBold",
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(1, 165, 113, 1),
                    width: 1.2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          SizedBox(height: h(13)),

          /// FORMATO TELÉFONO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(43)),
            child: Text(
              _controllerTelefono.text.length < 3
                  ? "Código de área (3 dígitos)"
                  : _controllerTelefono.text.length == 12
                  ? ""
                  : "Número completo",
              style: TextStyle(
                fontSize: sp(13),
                fontFamily: "Poppins",
                color: Colors.white60,
              ),
            ),
          ),

          SizedBox(height: h(23)),

          /// INFO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.info,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.4),
                ),
                SizedBox(width: w(8)),
                Expanded(
                  child: Text(
                    "Ingresá un número activo. Podremos usarlo para verificación o recuperación de tu cuenta.",
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

          Spacer(),

          /// BOTÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Visibility(
              visible: _controllerTelefono.text.length == 12,
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
                onTap: () async {
                  Vibration.vibrate(duration: 5);

                  setState(() {
                    cargando = true;
                  });

                  Future.delayed(const Duration(milliseconds: 1500), () {
                    verificarExistenciaTelefono();
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

  Widget seleccionarGenero({Key? key}) {
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
                  LucideIcons.user,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(5)),
                Text(
                  "Paso 7 de 8",
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

          /// INDICADOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: List.generate(8, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(33),
                    height: h(5),
                    decoration: BoxDecoration(
                      color: index < 7
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: h(36)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Seleccioná tu género",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Esta información nos ayuda a personalizar tu experiencia.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(32)),

          /// OPCIÓN FEMENINO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: h(18),
                  horizontal: w(16),
                ),
                decoration: BoxDecoration(
                  color: generoSeleccionado == "Femenino"
                      ? const Color.fromRGBO(1, 165, 113, 0.15)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: generoSeleccionado == "Femenino"
                        ? const Color.fromRGBO(1, 165, 113, 1)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.userCircle,
                      size: sp(20),
                      color: generoSeleccionado == "Femenino"
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.6),
                    ),
                    SizedBox(width: w(14)),
                    Text(
                      "Femenino",
                      style: TextStyle(
                        fontSize: sp(15),
                        fontFamily: generoSeleccionado == "Femenino"
                            ? "PoppinsBold"
                            : "Poppins",
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                setState(() {
                  generoSeleccionado = "Femenino";
                });
              },
            ),
          ),

          SizedBox(height: h(14)),

          /// OPCIÓN MASCULINO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: h(18),
                  horizontal: w(16),
                ),
                decoration: BoxDecoration(
                  color: generoSeleccionado == "Masculino"
                      ? const Color.fromRGBO(1, 165, 113, 0.15)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: generoSeleccionado == "Masculino"
                        ? const Color.fromRGBO(1, 165, 113, 1)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.userCircle,
                      size: sp(20),
                      color: generoSeleccionado == "Masculino"
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.6),
                    ),
                    SizedBox(width: w(14)),
                    Text(
                      "Masculino",
                      style: TextStyle(
                        fontSize: sp(15),
                        fontFamily: generoSeleccionado == "Masculino"
                            ? "PoppinsBold"
                            : "Poppins",
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                setState(() {
                  generoSeleccionado = "Masculino";
                });
              },
            ),
          ),

          SizedBox(height: h(14)),

          /// OPCIÓN OTRO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: h(18),
                  horizontal: w(16),
                ),
                decoration: BoxDecoration(
                  color: generoSeleccionado == "Prefiero no decirlo"
                      ? const Color.fromRGBO(1, 165, 113, 0.15)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: generoSeleccionado == "Prefiero no decirlo"
                        ? const Color.fromRGBO(1, 165, 113, 1)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.users,
                      size: sp(20),
                      color: generoSeleccionado == "Prefiero no decirlo"
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.6),
                    ),
                    SizedBox(width: w(14)),
                    Text(
                      "Prefiero no decirlo",
                      style: TextStyle(
                        fontSize: sp(15),
                        fontFamily: generoSeleccionado == "Prefiero no decirlo"
                            ? "PoppinsBold"
                            : "Poppins",
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                setState(() {
                  generoSeleccionado = "Prefiero no decirlo";
                });
              },
            ),
          ),

          Spacer(),

          /// BOTÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Visibility(
              visible: generoSeleccionado != "",
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
                onTap: () async {
                  Vibration.vibrate(duration: 5);

                  setState(() {
                    cargando = true;
                  });

                  Future.delayed(const Duration(milliseconds: 1500), () {
                    guardarGenero();
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

  Widget crearClave({Key? key}) {
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
                  LucideIcons.lock,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(5)),
                Text(
                  "Paso 8 de 8",
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

          /// INDICADOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: List.generate(8, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(33),
                    height: h(5),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(1, 165, 113, 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: h(36)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Creá tu clave",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Será tu clave personal para acceder a tu cuenta.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(40)),

          /// PIN VISUAL
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

          SizedBox(height: h(30)),

          /// INPUT OCULTO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: TextField(
              controller: _controllerClave,
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

          /// BOTÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Visibility(
              visible: _controllerClave.text.length == 5 && claveValida,
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
                            "Finalizar registro",
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
                onTap: () async {
                  Vibration.vibrate(duration: 5);

                  setState(() {
                    cargando = true;
                  });

                  Future.delayed(const Duration(milliseconds: 2500), () {
                    guardarClave(_controllerClave.text);
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

  Widget registroFinalizado({Key? key}) {
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

          /// ICONO + PASO FINAL
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.checkCircle2,
                  size: sp(16),
                  color: const Color.fromRGBO(1, 165, 113, 1),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Registro completado",
                  style: TextStyle(
                    fontSize: sp(12),
                    fontFamily: "Poppins",
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h(33)),

          /// NOMBRE
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "$nombreUser,",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(8)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "¡Tu cuenta ya está lista!",
              style: TextStyle(
                fontSize: sp(24),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(13)),

          /// TEXTO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Podés comenzar a usar la aplicación ahora o continuar configurando opciones adicionales para personalizar tu experiencia aún más.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),

          SizedBox(height: h(43)),

          /// CARD INFO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.all(w(18)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.settings,
                    size: sp(16.8),
                    color: Colors.white.withOpacity(0.6),
                  ),
                  SizedBox(width: w(13)),
                  Expanded(
                    child: Text(
                      "Las configuraciones adicionales pueden hacerse ahora o más adelante desde tu perfil.",
                      style: TextStyle(
                        fontSize: sp(13.8),
                        fontFamily: "Poppins",
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Spacer(),

          /// BOTÓN PRINCIPAL
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(53),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 135, 92),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: !cargandoComenzar
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /// TEXTO
                          Text(
                            "Comenzar a usar",
                            style: TextStyle(
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                              color: Colors.white,
                            ),
                          ),

                          /// LOGO
                          Image.asset(
                            "assets/logoAppCompleto.png",
                            height: h(133),
                            fit: BoxFit.contain,
                          ),
                        ],
                      )
                    : Center(
                        child: SizedBox(
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
                if (cargandoOpcionales == false) {
                  Vibration.vibrate(duration: 5);

                  setState(() {
                    cargandoComenzar = true;
                  });

                  registrarse();
                }
              },
            ),
          ),

          SizedBox(height: h(13)),

          /// BOTÓN SECUNDARIO
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
                  child: !cargandoOpcionales
                      ? Text(
                          "Configurar opciones ahora",
                          style: TextStyle(
                            fontSize: sp(15),
                            fontFamily: "PoppinsBold",
                            color: Colors.white.withOpacity(0.9),
                          ),
                        )
                      : Center(
                          child: SizedBox(
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
              onTap: () {
                if (cargandoComenzar == false) {
                  Vibration.vibrate(duration: 5);

                  setState(() {
                    cargandoOpcionales = true;
                  });

                  registrarse();
                }
              },
            ),
          ),

          SizedBox(height: h(20)),
        ],
      ),
    );
  }

  //Configuraciones Adicionales
  Widget configurarAlias({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    bool mantieneAliasActual = _controllerAlias.text.trim() == aliasUser;

    bool _actualizandoAlias = false;
    const String _sufijoAlias = ".QX";

    return SafeArea(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: h(33)),

          /// PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.atSign,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(5)),
                Text(
                  "Paso 1 de 4",
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

          /// INDICADOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: List.generate(4, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(32),
                    height: h(4),
                    decoration: BoxDecoration(
                      color: index == 0
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
              "Alias de pago",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Este alias se usa para recibir pagos. Podés cambiarlo o seguir usando el actual.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(28)),

          /// USAR ALIAS ACTUAL (SELECCIONABLE)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(w(14)),
                decoration: BoxDecoration(
                  color: mantieneAliasActual
                      ? const Color.fromRGBO(1, 165, 113, 0.12)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: mantieneAliasActual && !_actualizandoAlias
                        ? const Color.fromRGBO(1, 165, 113, 1)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      mantieneAliasActual && !_actualizandoAlias
                          ? LucideIcons.checkCircle
                          : LucideIcons.circle,
                      size: sp(18),
                      color: mantieneAliasActual && !_actualizandoAlias
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.45),
                    ),
                    SizedBox(width: w(10)),
                    Expanded(
                      child: Text(
                        "Seguir usando @$aliasUser",
                        style: TextStyle(
                          fontSize: sp(14),
                          fontFamily: "PoppinsMedium",
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);
                if (aliasValido == false && !_actualizandoAlias) {
                  setState(() {
                    _controllerAlias.text = aliasUser;
                    aliasValido = true;
                  });
                } else {
                  setState(() {
                    _controllerAlias.clear();
                    aliasValido = false;
                  });
                }
              },
            ),
          ),

          SizedBox(height: h(23)),

          /// INPUT NUEVO ALIAS
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
                      LucideIcons.edit3,
                      size: sp(18),
                      color: Colors.white.withOpacity(0.5),
                    ),
                    SizedBox(width: w(12)),
                    Expanded(
                      child: TextField(
                        controller: _controllerAlias,
                        cursorColor: Color.fromRGBO(1, 165, 113, 1),
                        style: TextStyle(
                          fontSize: sp(15),
                          fontFamily: "Poppins",
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: aliasUser,
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                          ),
                          border: InputBorder.none,

                          // 🟢 SUFIJO FIJO EN VERDE
                          suffix: Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Text(
                              ".QX",
                              style: TextStyle(
                                fontSize: sp(15),
                                fontFamily: "Poppins",
                                color: const Color.fromRGBO(1, 165, 113, 1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        onChanged: (value) {
                          final base = value.trim();

                          setState(() {
                            aliasCaractEspeciales =
                                base.length >= 8 &&
                                !RegExp(r'^[a-zA-Z0-9.]+$').hasMatch(base);

                            aliasValido =
                                base.length >= 8 && !base.contains(" ");

                            aliasNuevo = "$base.QX";
                          });

                          verificarExistenciaAlias();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: h(18)),

          /// INFO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.info,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.4),
                ),
                SizedBox(width: w(8)),
                Expanded(
                  child: Text(
                    "Podras cambiarlo nuevamente desde configuracion.",
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

          Spacer(),

          /// BOTÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(54),
                decoration: BoxDecoration(
                  color:
                      aliasValido &&
                              !aliasExistente &&
                              !aliasCaractEspeciales ||
                          mantieneAliasActual
                      ? const Color.fromRGBO(1, 165, 113, 1)
                      : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: !cargando
                      ? Text(
                          mantieneAliasActual
                              ? "Continuar con este alias"
                              : aliasExistente
                              ? "Alias en uso"
                              : !aliasValido
                              ? "Minimo 8 caracteres"
                              : aliasCaractEspeciales
                              ? "No se permiten caracteres especiales"
                              : "Guardar nuevo alias",
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
              onTap: aliasValido && !aliasExistente && !aliasCaractEspeciales
                  ? () {
                      Vibration.vibrate(duration: 5);

                      setState(() {
                        cargando = true;
                      });

                      Future.delayed(const Duration(milliseconds: 1500), () {
                        guardarAlias(_controllerAlias.text);
                      });
                    }
                  : null,
            ),
          ),

          SizedBox(height: h(13)),
        ],
      ),
    );
  }

  Widget configurarTema({Key? key}) {
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
          SizedBox(height: h(33)),

          /// PASO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.palette,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(5)),
                Text(
                  "Paso 2 de 4",
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

          /// INDICADOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: List.generate(4, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(32),
                    height: h(4),
                    decoration: BoxDecoration(
                      color: index <= 1
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: h(36)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Tema de la app",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Elegí cómo querés ver la aplicación.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(32)),

          /// TEMA OSCURO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(w(16)),
                decoration: BoxDecoration(
                  color: temaOscuro
                      ? const Color.fromRGBO(1, 165, 113, 0.12)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: temaOscuro
                        ? const Color.fromRGBO(1, 165, 113, 1)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      temaOscuro ? LucideIcons.checkCircle : LucideIcons.circle,
                      color: temaOscuro
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.45),
                      size: sp(20),
                    ),
                    SizedBox(width: w(14)),
                    Icon(LucideIcons.moon, size: sp(20), color: Colors.white),
                    SizedBox(width: w(12)),
                    Expanded(
                      child: Text(
                        "Tema oscuro",
                        style: TextStyle(
                          fontSize: sp(15),
                          fontFamily: "PoppinsMedium",
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);
                setState(() {
                  temaOscuro = true;
                  temaSeleccionado = "Oscuro";
                });
              },
            ),
          ),

          SizedBox(height: h(16)),

          /// TEMA CLARO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(w(16)),
                decoration: BoxDecoration(
                  color: !temaOscuro
                      ? const Color.fromRGBO(1, 165, 113, 0.12)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: !temaOscuro
                        ? const Color.fromRGBO(1, 165, 113, 1)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      !temaOscuro
                          ? LucideIcons.checkCircle
                          : LucideIcons.circle,
                      color: !temaOscuro
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.45),
                      size: sp(20),
                    ),
                    SizedBox(width: w(14)),
                    Icon(LucideIcons.sun, size: sp(20), color: Colors.white),
                    SizedBox(width: w(12)),
                    Expanded(
                      child: Text(
                        "Tema claro",
                        style: TextStyle(
                          fontSize: sp(15),
                          fontFamily: "PoppinsMedium",
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Vibration.vibrate(duration: 5);
                setState(() {
                  temaOscuro = false;
                  temaSeleccionado = "Claro";
                });
              },
            ),
          ),

          Spacer(),

          /// BOTÓN
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

                Future.delayed(const Duration(milliseconds: 1500), () {
                  guardarTema();
                });
              },
            ),
          ),

          SizedBox(height: h(13)),
        ],
      ),
    );
  }

  Widget configurarFaceID({Key? key}) {
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
                  LucideIcons.scanFace,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Paso 3 de 4",
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

          /// INDICADOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: List.generate(4, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(32),
                    height: h(4),
                    decoration: BoxDecoration(
                      color: index <= 2
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: h(36)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Ingreso con Face ID",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Podés usar Face ID para ingresar de forma rápida y segura, sin escribir tu contraseña.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(30)),

          /// CARD FACE ID
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(w(16)),
              decoration: BoxDecoration(
                color: faceIdHabilitado
                    ? const Color.fromRGBO(1, 165, 113, 0.12)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: faceIdHabilitado
                      ? const Color.fromRGBO(1, 165, 113, 1)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  /// ICONO
                  Container(
                    width: w(44),
                    height: w(44),
                    decoration: BoxDecoration(
                      color: faceIdHabilitado
                          ? const Color.fromRGBO(1, 165, 113, 0.18)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      LucideIcons.scanFace,
                      size: sp(22),
                      color: faceIdHabilitado
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.55),
                    ),
                  ),

                  SizedBox(width: w(14)),

                  /// TEXTO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faceIdHabilitado
                              ? "Face ID habilitado"
                              : "Habilitar Face ID",
                          style: TextStyle(
                            fontSize: sp(15),
                            fontFamily: "PoppinsBold",
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: h(4)),
                        Text(
                          faceIdHabilitado
                              ? "Vas a poder ingresar con tu rostro"
                              : "Podés activarlo ahora o más tarde",
                          style: TextStyle(
                            fontSize: sp(13),
                            fontFamily: "Poppins",
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// SWITCH
                  GestureDetector(
                    onTap: () {
                      Vibration.vibrate(duration: 5);
                      setState(() {
                        faceIdHabilitado = !faceIdHabilitado;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: w(50),
                      height: h(28),
                      padding: EdgeInsets.all(w(3)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: faceIdHabilitado
                            ? const Color.fromRGBO(1, 165, 113, 1)
                            : Colors.white.withOpacity(0.2),
                      ),
                      child: Align(
                        alignment: faceIdHabilitado
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: w(22),
                          height: w(22),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

                Future.delayed(const Duration(milliseconds: 1500), () {
                  guardarFaceID();
                });
              },
            ),
          ),

          SizedBox(height: h(13)),
        ],
      ),
    );
  }

  Widget configurarRecordarSesion({Key? key}) {
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
                  LucideIcons.logIn,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Paso 4 de 4",
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

          /// INDICADOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: List.generate(4, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: w(8)),
                  child: Container(
                    width: w(32),
                    height: h(4),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(1, 165, 113, 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: h(36)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Inicio de sesión",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(10)),

          /// SUBTITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Elegí cómo querés que funcione el ingreso a tu cuenta.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          SizedBox(height: h(30)),

          /// OPCIÓN 1 — RECORDAR SESIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              onTap: () {
                Vibration.vibrate(duration: 6);
                setState(() {
                  recordarSesion = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(w(16)),
                decoration: BoxDecoration(
                  color: recordarSesion
                      ? const Color.fromRGBO(1, 165, 113, 0.12)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: recordarSesion
                        ? const Color.fromRGBO(1, 165, 113, 1)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    /// ICONO
                    Container(
                      width: w(44),
                      height: w(44),
                      decoration: BoxDecoration(
                        color: recordarSesion
                            ? const Color.fromRGBO(1, 165, 113, 0.18)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        LucideIcons.unlock,
                        size: sp(22),
                        color: recordarSesion
                            ? const Color.fromRGBO(1, 165, 113, 1)
                            : Colors.white.withOpacity(0.55),
                      ),
                    ),

                    SizedBox(width: w(14)),

                    /// TEXTO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Recordar inicio de sesión",
                            style: TextStyle(
                              fontSize: sp(15),
                              fontFamily: "PoppinsMedium",
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: h(4)),
                          Text(
                            "No se cerrará tu sesión al salir",
                            style: TextStyle(
                              fontSize: sp(13),
                              fontFamily: "Poppins",
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      recordarSesion
                          ? LucideIcons.checkCircle
                          : LucideIcons.circle,
                      size: sp(20),
                      color: recordarSesion
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.35),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: h(18)),

          /// OPCIÓN 2 — CERRAR SESIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              onTap: () {
                Vibration.vibrate(duration: 6);
                setState(() {
                  recordarSesion = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(w(16)),
                decoration: BoxDecoration(
                  color: !recordarSesion
                      ? const Color.fromRGBO(1, 165, 113, 0.12)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: !recordarSesion
                        ? const Color.fromRGBO(1, 165, 113, 1)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    /// ICONO
                    Container(
                      width: w(44),
                      height: w(44),
                      decoration: BoxDecoration(
                        color: !recordarSesion
                            ? const Color.fromRGBO(1, 165, 113, 0.18)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        LucideIcons.lock,
                        size: sp(22),
                        color: !recordarSesion
                            ? const Color.fromRGBO(1, 165, 113, 1)
                            : Colors.white.withOpacity(0.55),
                      ),
                    ),

                    SizedBox(width: w(14)),

                    /// TEXTO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Cerrar sesión al salir",
                            style: TextStyle(
                              fontSize: sp(15),
                              fontFamily: "PoppinsMedium",
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: h(4)),
                          Text(
                            "Tu cuenta se cerrará siempre",
                            style: TextStyle(
                              fontSize: sp(13),
                              fontFamily: "Poppins",
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      !recordarSesion
                          ? LucideIcons.checkCircle
                          : LucideIcons.circle,
                      size: sp(20),
                      color: !recordarSesion
                          ? const Color.fromRGBO(1, 165, 113, 1)
                          : Colors.white.withOpacity(0.35),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: h(33)),

          /// ACLARACIÓN DE SEGURIDAD
          Visibility(
            visible: recordarSesion,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w(40)),
              child: Container(
                padding: EdgeInsets.all(w(13)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      size: sp(18),
                      color: Colors.white.withOpacity(0.6),
                    ),
                    SizedBox(width: w(10)),
                    Expanded(
                      child: Text(
                        "Por seguridad, cada vez que ingreses a la app se te pedirá confirmar tu identidad con tu clave o Face ID.",
                        style: TextStyle(
                          fontSize: sp(13),
                          fontFamily: "Poppins",
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Spacer(),

          /// BOTÓN FINALIZAR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(53),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(1, 165, 113, 1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: !cargando
                      ? Text(
                          "Continuar",
                          style: TextStyle(
                            fontSize: sp(15),
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

                Future.delayed(const Duration(milliseconds: 2000), () {
                  guardarRecordarme();
                });
              },
            ),
          ),

          SizedBox(height: h(13)),
        ],
      ),
    );
  }

  Widget configuracionOpcionalFinalizada({Key? key}) {
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
          SizedBox(height: h(70)),

          /// ICONO PRINCIPAL
          Container(
            width: w(110),
            height: w(110),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color.fromRGBO(1, 165, 113, 1),
                  Colors.green.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(1, 165, 113, 1).withOpacity(0.45),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Icon(LucideIcons.check, size: sp(46), color: Colors.white),
            ),
          ),

          SizedBox(height: h(33)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "¡Registro completo!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sp(26),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(13)),

          /// DESCRIPCIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(48)),
            child: Text(
              "Tu cuenta ya está lista. Completaste el registro y las configuraciones adicionales para una experiencia más segura y personalizada.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),

          SizedBox(height: h(36)),

          /// RESUMEN VISUAL
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.all(w(18)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  /// ITEM 1
                  Row(
                    children: [
                      Icon(
                        LucideIcons.userCheck,
                        size: sp(18),
                        color: const Color.fromRGBO(1, 165, 113, 1),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Cuenta creada correctamente",
                          style: TextStyle(
                            fontSize: sp(14),
                            fontFamily: "PoppinsMedium",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(14)),
                  Divider(color: Colors.white.withOpacity(0.08)),
                  SizedBox(height: h(14)),

                  /// ITEM 2
                  Row(
                    children: [
                      Icon(
                        LucideIcons.atSign,
                        size: sp(18),
                        color: const Color.fromRGBO(1, 165, 113, 1),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Alias y perfil configurados",
                          style: TextStyle(
                            fontSize: sp(14),
                            fontFamily: "PoppinsMedium",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(14)),
                  Divider(color: Colors.white.withOpacity(0.08)),
                  SizedBox(height: h(14)),

                  /// ITEM 3
                  Row(
                    children: [
                      Icon(
                        LucideIcons.palette,
                        size: sp(18),
                        color: const Color.fromRGBO(1, 165, 113, 1),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Preferencias de la app guardadas",
                          style: TextStyle(
                            fontSize: sp(14),
                            fontFamily: "PoppinsMedium",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h(14)),
                  Divider(color: Colors.white.withOpacity(0.08)),
                  SizedBox(height: h(14)),

                  /// ITEM 4
                  Row(
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        size: sp(18),
                        color: const Color.fromRGBO(1, 165, 113, 1),
                      ),
                      SizedBox(width: w(12)),
                      Expanded(
                        child: Text(
                          "Seguridad activada",
                          style: TextStyle(
                            fontSize: sp(14),
                            fontFamily: "PoppinsMedium",
                            color: Colors.white,
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

          /// BOTÓN PRINCIPAL
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(53),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 135, 92),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: !cargando
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /// TEXTO
                          Text(
                            "Comenzar a usar",
                            style: TextStyle(
                              fontSize: sp(15),
                              fontFamily: "PoppinsBold",
                              color: Colors.white,
                            ),
                          ),

                          /// LOGO
                          Image.asset(
                            "assets/logoAppCompleto.png",
                            height: h(133),
                            fit: BoxFit.contain,
                          ),
                        ],
                      )
                    : Center(
                        child: SizedBox(
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
                if (cargando == false) {
                  Vibration.vibrate(duration: 5);

                  setState(() {
                    cargando = true;
                  });

                  registrarse();
                  guardarOpcionales();
                }
              },
            ),
          ),

          SizedBox(height: h(18)),

          /// TEXTO FINAL
          Text(
            "Podés modificar estas opciones cuando quieras desde tu perfil.",
            style: TextStyle(
              fontSize: sp(12),
              fontFamily: "Poppins",
              color: Colors.white.withOpacity(0.45),
            ),
          ),

          SizedBox(height: h(20)),
        ],
      ),
    );
  }

  //Tutor
  Widget solicitudTutorEnviada({Key? key}) {
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
            child: Container(
              width: w(63),
              height: w(63),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromRGBO(1, 165, 113, 1).withOpacity(0.15),
              ),
              child: Icon(
                LucideIcons.checkCircle,
                size: sp(30),
                color: const Color.fromRGBO(1, 165, 113, 1),
              ),
            ),
          ),

          SizedBox(height: h(23)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Solicitud enviada",
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(12)),

          /// DESCRIPCIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Tu solicitud fue enviada correctamente. El tutor deberá aprobarla para que puedas comenzar a usar la aplicación.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ),

          SizedBox(height: h(33)),

          /// CARD TUTOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Container(
              padding: EdgeInsets.all(w(15)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  /// AVATAR
                  Container(
                    height: h(55),
                    width: h(55),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(1, 165, 113, 0.15),
                    ),
                    child: ClipOval(
                      child: avatarTutor == ""
                          ? Container(
                              width: w(55),
                              height: w(55),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color.fromRGBO(1, 165, 113, 1),
                              ),
                              child: Center(
                                child: Text(
                                  inicialesTutor,
                                  style: TextStyle(
                                    fontSize: sp(23),
                                    fontFamily: "PoppinsBold",
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Image.asset(avatarTutor, fit: BoxFit.cover),
                    ),
                  ),

                  SizedBox(width: w(13)),

                  /// DATOS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreTutor + " " + apellidoTutor,
                          style: TextStyle(
                            fontSize: sp(15),
                            fontFamily: "PoppinsBold",
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: h(5)),
                        Text(
                          emailTutor,
                          style: TextStyle(
                            fontSize: sp(13),
                            fontFamily: "Poppins",
                            color: Colors.white.withOpacity(0.55),
                          ),
                        ),
                        SizedBox(height: h(5)),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: sp(13),
                              color: Colors.white.withOpacity(0.45),
                            ),
                            SizedBox(width: w(5)),
                            Text(
                              "Pendiente de aprobación",
                              style: TextStyle(
                                fontSize: sp(13),
                                fontFamily: "Poppins",
                                color: Colors.white.withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h(23)),

          /// INFO EXTRA
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              children: [
                Icon(
                  LucideIcons.info,
                  size: sp(13),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(8)),
                Expanded(
                  child: Text(
                    "Te avisaremos cuando el tutor apruebe tu solicitud.",
                    style: TextStyle(
                      fontSize: sp(13),
                      fontFamily: "Poppins",
                      color: Colors.white.withOpacity(0.45),
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

  Widget tutorAceptoSolicitud({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    obtenerDatosTutor();

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
                  LucideIcons.heartHandshake,
                  size: sp(35),
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
                "Solicitud aprobada",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sp(25),
                  fontFamily: "PoppinsBold",
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: h(13)),

          /// DESCRIPCIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Center(
              child: Text(
                "Tu tutor aceptó la solicitud y ya podés usar la aplicación.",
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

          /// CARD TUTOR
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
                  /// AVATAR TUTOR
                  Container(
                    height: h(48),
                    width: h(48),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(1, 165, 113, 0.15),
                    ),
                    child: ClipOval(
                      child: avatarTutor == ""
                          ? Container(
                              width: w(48),
                              height: w(48),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color.fromRGBO(1, 165, 113, 1),
                              ),
                              child: Center(
                                child: Text(
                                  inicialesTutor,
                                  style: TextStyle(
                                    fontSize: sp(20),
                                    fontFamily: "PoppinsBold",
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Image.asset(avatarTutor, fit: BoxFit.cover),
                    ),
                  ),

                  SizedBox(width: w(15)),

                  /// DATOS TUTOR
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(250)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              nombreTutor + " " + apellidoTutor,
                              style: TextStyle(
                                fontSize: sp(15),
                                fontFamily: "PoppinsBold",
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h(5)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w(250)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Tutor responsable",
                              style: TextStyle(
                                fontSize: sp(13),
                                fontFamily: "Poppins",
                                color: Colors.white.withOpacity(0.55),
                              ),
                            ),
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
                      color: const Color.fromRGBO(
                        1,
                        165,
                        113,
                        1,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Activo",
                      style: TextStyle(
                        fontSize: sp(10),
                        fontFamily: "PoppinsMedium",
                        color: const Color.fromRGBO(1, 165, 113, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Spacer(),

          /// BOTÓN COMENZAR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: GestureDetector(
              child: Container(
                height: h(56),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(1, 165, 113, 1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: !cargando
                      ? Text(
                          "Entendido",
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
                  setState(() {
                    currentStep = 12;
                    cargando = false;
                  });

                  FirebaseFirestore.instance
                      .collection("TempUsers")
                      .doc(codeUser)
                      .update({"paso": 12});
                });
              },
            ),
          ),

          SizedBox(height: h(20)),
        ],
      ),
    );
  }

  //Ingresar Tutor
  Widget ingresarEmailTutor({Key? key}) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double w(double width) => width / 430 * screenWidth;
    double h(double height) => height / 932 * screenHeight;
    double sp(double size) =>
        size / 430 * (screenWidth < screenHeight ? screenWidth : screenHeight);

    return SafeArea(
      key: key,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: h(33)),

                    /// INDICADOR
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w(40)),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.shieldAlert,
                            size: sp(14),
                            color: Colors.white.withOpacity(0.45),
                          ),
                          SizedBox(width: w(6)),
                          Text(
                            "Autorización requerida",
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
                        "Necesitamos un tutor",
                        style: TextStyle(
                          fontSize: sp(24),
                          fontFamily: "PoppinsBold",
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),

                    SizedBox(height: h(12)),

                    /// SUBTITULO
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w(40)),
                      child: Text(
                        "Para terminar de crear tu cuenta, un adulto responsable debe autorizar el acceso.",
                        style: TextStyle(
                          fontSize: sp(14),
                          fontFamily: "Poppins",
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                    ),

                    SizedBox(height: h(33)),

                    /// INPUT EMAIL TUTOR
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w(40)),
                      child: Container(
                        height: h(58),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(23, 27, 51, 1),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: w(16)),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.mailCheck,
                                size: sp(18),
                                color: Colors.white.withOpacity(0.5),
                              ),
                              SizedBox(width: w(13)),
                              Expanded(
                                child: TextField(
                                  controller: _controllerEmailTutor,
                                  focusNode: _focusEmailTutor,
                                  autofocus: true,
                                  keyboardType: TextInputType.emailAddress,
                                  cursorColor: Color.fromRGBO(1, 165, 113, 1),
                                  style: TextStyle(
                                    fontSize: sp(15),
                                    fontFamily: "Poppins",
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Email del tutor responsable",
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) {
                                    verificarFormatoEmailTutor();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: h(33)),

                    /// BLOQUE INFO
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w(40)),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w(15),
                          vertical: h(13),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                LucideIcons.info,
                                size: sp(15),
                                color: const Color.fromRGBO(1, 165, 113, 1),
                              ),
                            ),
                            SizedBox(width: w(13)),
                            Expanded(
                              child: Text(
                                "Le enviaremos una notificacion al tutor para que apruebe tu cuenta.",
                                style: TextStyle(
                                  fontSize: sp(12),
                                  fontFamily: "Poppins",
                                  color: Colors.white.withOpacity(0.6),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Spacer(),

                    /// BOTÓN
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w(40)),
                      child: Visibility(
                        visible: emailTutorValido,
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
                                      "Enviar solicitud al tutor",
                                      style: TextStyle(
                                        fontSize: sp(15),
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

                            Future.delayed(
                              const Duration(milliseconds: 2500),
                              () {
                                verificarExistenciaEmailTutor(
                                  _controllerEmailTutor.text,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: h(20)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  //Menor De Edad
  Widget avisoMenorEdad({Key? key}) {
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
                  LucideIcons.shieldAlert,
                  size: sp(15),
                  color: Colors.white.withOpacity(0.45),
                ),
                SizedBox(width: w(6)),
                Text(
                  "Aviso importante",
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

          /// ICONO CENTRAL
          Center(
            child: Container(
              width: w(88),
              height: w(88),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromRGBO(1, 165, 113, 1).withOpacity(0.15),
              ),
              child: Icon(
                LucideIcons.alertTriangle,
                size: sp(40),
                color: const Color.fromRGBO(1, 165, 113, 1),
              ),
            ),
          ),

          SizedBox(height: h(36)),

          /// TITULO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Cuenta con supervisión",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sp(23),
                fontFamily: "PoppinsBold",
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: h(14)),

          /// DESCRIPCIÓN
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Text(
              "Detectamos que sos menor de 18 años. Para completar el proceso de registro, más adelante será necesaria la aprobación de un tutor legal.",
              style: TextStyle(
                fontSize: sp(15),
                fontFamily: "Poppins",
                color: Colors.white.withOpacity(0.55),
                height: 1.45,
              ),
            ),
          ),

          SizedBox(height: h(22)),

          /// INFO SUAVE
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(40)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.info,
                  size: sp(14),
                  color: Colors.white.withOpacity(0.4),
                ),
                SizedBox(width: w(6)),
                Flexible(
                  child: Text(
                    "Podés continuar ahora y completar este paso más adelante.",
                    style: TextStyle(
                      fontSize: sp(13),
                      fontFamily: "Poppins",
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Spacer(),

          /// BOTÓN CONTINUAR (idéntico a los otros)
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
                  child: !cargando
                      ? Text(
                          "Entendido",
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
              onTap: () async {
                Vibration.vibrate(duration: 5);

                setState(() {
                  cargando = true;
                });

                Future.delayed(const Duration(milliseconds: 1500), () {
                  avanzarPaso();
                  setState(() {
                    cargando = false;
                  });
                });
              },
            ),
          ),

          SizedBox(height: h(16)),
        ],
      ),
    );
  }

  //Email En Uso
  Widget alertaEmailExistente({
    required String email,
    required String nombre,
    required String avatar,
  }) {
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
        padding: EdgeInsets.all(w(24)),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(18, 18, 18, 1),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ICONO
            Center(
              child: Container(
                width: w(56),
                height: w(56),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withOpacity(0.15),
                ),
                child: Icon(
                  LucideIcons.alertTriangle,
                  color: Colors.orangeAccent,
                  size: sp(25),
                ),
              ),
            ),

            SizedBox(height: h(20)),

            /// TITULO
            Center(
              child: Text(
                "Este email ya está registrado",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sp(18),
                  fontFamily: "PoppinsBold",
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: h(10)),

            /// DESCRIPCION
            Center(
              child: Text(
                "El email que ingresaste ya está asociado a una cuenta existente.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sp(14),
                  fontFamily: "Poppins",
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),

            SizedBox(height: h(28)),

            /// ACCIONES
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    child: Container(
                      height: h(46),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: Center(
                        child: Text(
                          "Cancelar",
                          style: TextStyle(
                            fontSize: sp(14),
                            fontFamily: "Poppins",
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _focusEmail!.requestFocus();
                    },
                  ),
                ),
                SizedBox(width: w(12)),
                Expanded(
                  child: GestureDetector(
                    child: Container(
                      height: h(46),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color.fromRGBO(1, 165, 113, 1),
                      ),
                      child: Center(
                        child: Text(
                          "Iniciar sesión",
                          style: TextStyle(
                            fontSize: sp(14),
                            fontFamily: "PoppinsBold",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageTransition(
                          type: PageTransitionType.leftToRight,
                          child: iniciarSesionPage(),
                        ),
                        (_) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //Telefono En Uso
  Widget alertaTelefonoExistente({
    required String telefono,
    required String nombre,
    required String apellido,
    required String avatar,
  }) {
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
        padding: EdgeInsets.all(w(24)),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(18, 18, 18, 1),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ICONO
            Center(
              child: Container(
                width: w(56),
                height: w(56),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withOpacity(0.15),
                ),
                child: Icon(
                  LucideIcons.alertTriangle,
                  color: Colors.orangeAccent,
                  size: sp(25),
                ),
              ),
            ),

            SizedBox(height: h(20)),

            /// TITULO
            Center(
              child: Text(
                "Este teléfono ya está registrado",
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
                "El número ya está asociado a la cuenta de:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sp(14),
                  fontFamily: "Poppins",
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),

            SizedBox(height: h(10)),

            /// NOMBRE USUARIO
            Center(
              child: Text(
                "$nombre $apellido",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sp(16),
                  fontFamily: "PoppinsBold",
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: h(28)),

            /// ACCIONES
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    child: Container(
                      height: h(46),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: Center(
                        child: Text(
                          "Cancelar",
                          style: TextStyle(
                            fontSize: sp(14),
                            fontFamily: "Poppins",
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _focusTelefono?.requestFocus();
                    },
                  ),
                ),
                SizedBox(width: w(12)),
                Expanded(
                  child: GestureDetector(
                    child: Container(
                      height: h(46),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color.fromRGBO(1, 165, 113, 1),
                      ),
                      child: Center(
                        child: Text(
                          "Iniciar sesión",
                          style: TextStyle(
                            fontSize: sp(14),
                            fontFamily: "PoppinsBold",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageTransition(
                          type: PageTransitionType.leftToRight,
                          child: iniciarSesionPage(),
                        ),
                        (_) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ================= NACIMIENTO =================
// =====================================================
class FechaNacimientoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si está borrando → no reformatear
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length > 8) {
      text = text.substring(0, 8);
    }

    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 || i == 3) buffer.write('/');
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// =====================================================
// ================= TELEFONO =================
// =====================================================
class TelefonoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);

    String formatted = '';
    int selectionIndex = newValue.selection.baseOffset;

    int digitIndex = 0;
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) {
        formatted += ' ';
        if (digitIndex < selectionIndex) selectionIndex++;
      }
      formatted += digits[i];
      digitIndex++;
    }

    // ⚠️ Evita que el cursor quede fuera del texto
    if (selectionIndex > formatted.length) {
      selectionIndex = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
