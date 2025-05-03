import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NFCScreenScan extends StatefulWidget {
  const NFCScreenScan({Key? key}) : super(key: key);

  @override
  State<NFCScreenScan> createState() => _NFCScreenScanState();
}

class _NFCScreenScanState extends State<NFCScreenScan> {
  bool _isScanning = false;
  String _scanStatus = "Buscando etiquetas NFC...";
  ValueNotifier<dynamic> _tagResult = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    // Iniciar el escaneo NFC automáticamente al abrir la pantalla
    _startNFCScan();
  }

  @override
  void dispose() {
    // Detener el escaneo al cerrar la pantalla
    _stopNFCScan();
    super.dispose();
  }

  Future<void> _startNFCScan() async {
    setState(() {
      _isScanning = true;
      _scanStatus = "Buscando etiquetas NFC...";
    });

    try {
      // Verificar si NFC está disponible
      bool isAvailable = await NfcManager.instance.isAvailable();
      
      if (!isAvailable) {
        setState(() {
          _isScanning = false;
          _scanStatus = "NFC no disponible en este dispositivo";
        });
        return;
      }

      // Iniciar la sesión NFC y escuchar las etiquetas
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          print('Etiqueta NFC detectada: ${tag.data}');
          
          // Almacenar los datos en la notificación de valor
          _tagResult.value = tag.data;
          
          setState(() {
            _scanStatus = "¡Etiqueta detectada!";
          });
          
          // Opcional: detener la sesión después de leer una etiqueta
          // NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      print('Error al iniciar el escaneo NFC: $e');
      setState(() {
        _isScanning = false;
        _scanStatus = "Error al iniciar el escaneo NFC: $e";
      });
    }
  }

  void _stopNFCScan() {
    try {
      NfcManager.instance.stopSession();
      setState(() {
        _isScanning = false;
        _scanStatus = "Escaneo detenido";
      });
    } catch (e) {
      print('Error al detener el escaneo NFC: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D51),
      appBar: AppBar(
        title: const Text(
          "Escaneo NFC",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF004D51),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: _isScanning ? Colors.green : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.nfc,
                  size: 100,
                  color: _isScanning ? Colors.white : Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  _scanStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ValueListenableBuilder<dynamic>(
                valueListenable: _tagResult,
                builder: (context, value, _) {
                  if (value == null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Información leída:\n${value.toString()}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}