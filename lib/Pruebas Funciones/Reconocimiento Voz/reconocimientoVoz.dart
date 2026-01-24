// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, unused_element, unused_field, avoid_print, use_build_context_synchronously, prefer_is_empty, deprecated_member_use, prefer_final_fields

/*
import 'dart:ui';

import 'package:bluetooth/Pruebas%20Funciones/V1.0.0/avisoVerificacion.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class reconocimientoVozPage extends StatefulWidget {
  @override
  State<reconocimientoVozPage> createState() => _reconocimientoVozPageState();
}

class _reconocimientoVozPageState extends State<reconocimientoVozPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  final LocalAuthentication auth = LocalAuthentication();
  String _lastWords = "";
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isAuthenticating = false;
  bool _speechInitialized = false;

  // Página activa
  bool _pageActive = true;

  // Datos Pago
  String user = "";
  String amount = "";

  // Datos Cobro
  String deUser = "";
  String deAmount = "";

  // Foco App
  bool _isAppInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  @override
  void dispose() {
    _pageActive = false; // La página ya no está activa
    _desactivarMic(); // Solo aquí desactivamos completamente el mic
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isAppInactive = state != AppLifecycleState.resumed;

      if (_isAppInactive) {
        // Pausamos la escucha pero no desactivamos completamente
        if (_speech.isListening) _speech.stop();
      } else {
        // Si volvemos de estar inactivos, reiniciamos la escucha
        if (_speechAvailable && !_isListening && !_isAuthenticating)
          _startListening();
      }
    });
  }

  Future<void> _initSpeech() async {
    if (_speechInitialized) return; // evita inicializar varias veces

    _speechAvailable = await _speech.initialize(
      onStatus: _handleStatus,
      onError: (error) => print("ERROR: $error"),
    );

    _speechInitialized = true;

    if (_speechAvailable && _pageActive && !_isListening) _startListening();
  }

  void _handleStatus(String status) async {
    print("STATUS: $status");

    if (_pageActive && !_isAuthenticating && !_isAppInactive) {
      if (status == "notListening" || status == "done") {
        setState(() => _isListening = false);
        await Future.delayed(const Duration(milliseconds: 500));
        if (_pageActive && !_isListening) await _restartListening();
      }
    }
  }

  Future<void> _desactivarMic() async {
    if (_speech.isListening) await _speech.stop();
    await _speech.cancel();
    setState(() => _isListening = false);
  }

  Future<void> _restartListening() async {
    if (!_pageActive || _isAuthenticating) return;

    if (!_speechInitialized) await _initSpeech();

    if (_speechAvailable && _pageActive && !_isListening)
      await _startListening();
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || !_pageActive) return;

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) async {
        String fraseActual = result.recognizedWords.toLowerCase();
        setState(() => _lastWords = fraseActual);

        // Detecta comando Pagar
        final pagarRegex = RegExp(r'pagar (\d+) a (.+)');
        final pagarMatch = pagarRegex.firstMatch(fraseActual);

        if (pagarMatch != null && !_isAuthenticating) {
          final monto = pagarMatch.group(1)!;
          final usuario = pagarMatch.group(2)!;

          _isAuthenticating = true;
          setState(() {
            amount = monto;
            user = usuario;
          });

          await _speech.stop();
          setState(() {
            _isListening = false;
            _lastWords = "";
          });

          await _confirmPayment(monto, usuario);

          _isAuthenticating = false;
          if (_pageActive) await _startListening();
          return;
        }

        // Detecta comando Cobrar
        final cobrarRegex = RegExp(r'cobrar (\d+) a (.+)');
        final cobrarMatch = cobrarRegex.firstMatch(fraseActual);

        if (cobrarMatch != null && !_isAuthenticating) {
          final monto = cobrarMatch.group(1)!;
          final usuario = cobrarMatch.group(2)!;

          _isAuthenticating = true;
          setState(() {
            deAmount = monto;
            deUser = usuario;
          });

          await _speech.stop();
          setState(() {
            _isListening = false;
            _lastWords = "";
          });

          await _confirmCobro(monto, usuario);

          _isAuthenticating = false;
          if (_pageActive) await _startListening();
          return;
        }
      },
      localeId: 'es_ES',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    );
  }

  Future<void> _confirmPayment(String monto, String usuario) async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: "Confirma con FaceID / Huella / PIN",
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      print("Error de autenticación: $e");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authenticated
              ? "✅ Pago de $monto confirmado a $usuario"
              : "❌ Pago cancelado",
        ),
      ),
    );

    _resetState();

    if (authenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => verificacionDniPage()),
      );
    }
  }

  Future<void> _confirmCobro(String monto, String usuario) async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: "Confirma con FaceID / Huella / PIN",
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      print("Error de autenticación: $e");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authenticated
              ? "✅ Cobro de $monto a $usuario confirmado"
              : "❌ Cobro cancelado",
        ),
      ),
    );

    _resetState();

    if (authenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => verificacionDniPage()),
      );
    }
  }

  void _resetState() {
    setState(() {
      _lastWords = "";
      amount = "";
      user = "";
      deAmount = "";
      deUser = "";
    });

    if (_speechAvailable && !_isAuthenticating && _pageActive) {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reconocimiento De Voz")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isListening
                  ? "Escuchando..."
                  : "Di un comando como: 'Pagar 100 a Juan'",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
*/
