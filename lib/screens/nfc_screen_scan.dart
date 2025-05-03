import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NFCScreenScan extends StatefulWidget {
  const NFCScreenScan({Key? key}) : super(key: key);

  @override
  State<NFCScreenScan> createState() => _NFCScreenScanState();
}

class _NFCScreenScanState extends State<NFCScreenScan> {
  bool _isScanning = false;
  String _scanStatus = "Buscando etiquetas NFC...";
  ValueNotifier<dynamic> _tagResult = ValueNotifier(null);
  final _supabase = Supabase.instance.client;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startNFCScan();
  }

  @override
  void dispose() {
    _stopNFCScan();
    super.dispose();
  }

  Future<void> _startNFCScan() async {
    setState(() {
      _isScanning = true;
      _scanStatus = "Buscando etiquetas NFC...";
    });

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();

      if (!isAvailable) {
        setState(() {
          _isScanning = false;
          _scanStatus = "NFC no disponible en este dispositivo";
        });
        return;
      }

      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          print('Etiqueta NFC detectada: ${tag.data}');
          _tagResult.value = tag.data;
          String decodedText = _decodePayload(tag.data);

          setState(() {
            _scanStatus = "¡Etiqueta detectada!";
          });

          // Guarda el resultado en Supabase
          if (decodedText.isNotEmpty &&
              decodedText != "No se encontró texto en el payload" &&
              decodedText != "Error al decodificar el payload") {
            await _saveNfcDataToSupabase(decodedText);
          }
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

  Future<void> _saveNfcDataToSupabase(String nfcData) async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _scanStatus = "Guardando datos...";
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _scanStatus = "Error: Usuario no identificado";
          _saving = false;
        });
        return;
      }

      // Intenta obtener el registro actual del usuario
      final response = await _supabase
          .from('user_characters')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Si no existe, crea un nuevo registro con un array que contiene el nuevo valor
        await _supabase.from('user_characters').insert({
          'user_id': userId,
          'characters': [nfcData]
        });
      } else {
        // Si existe, actualiza añadiendo el nuevo valor al array existente
        List<dynamic> characters =
            List<dynamic>.from(response['characters'] ?? []);

        // Verificar si el elemento ya existe para evitar duplicados
        if (!characters.contains(nfcData)) {
          characters.add(nfcData);
          await _supabase
              .from('user_characters')
              .update({'characters': characters}).eq('user_id', userId);
        }
      }

      setState(() {
        _scanStatus = "¡Datos guardados correctamente!";
        _saving = false;
      });
    } catch (e) {
      print('Error al guardar datos en Supabase: $e');
      setState(() {
        _scanStatus = "Error al guardar datos: $e";
        _saving = false;
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

  // Función para decodificar el payload
  String _decodePayload(dynamic tagData) {
    try {
      // Acceder al payload dentro de ndef -> cachedMessage -> records
      var records = tagData['ndef']?['cachedMessage']?['records'];
      if (records != null && records.isNotEmpty) {
        var payload = records[0]['payload'];
        // Saltar el byte de idioma (primeros 3 bytes, asumiendo formato [2, 101, 110])
        if (payload != null && payload.length > 3) {
          // Decodificar los bytes restantes como UTF-8
          return String.fromCharCodes(payload.sublist(3));
        }
      }
      return "No se encontró texto en el payload";
    } catch (e) {
      print('Error al decodificar el payload: $e');
      return "Error al decodificar el payload";
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
                  color: _isScanning
                      ? (_saving ? Colors.orange : Colors.green)
                      : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _saving ? Icons.cloud_upload : Icons.nfc,
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
                  // Usar la función para decodificar y mostrar solo el texto
                  String decodedText = _decodePayload(value);
                  return Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Información leída:\n$decodedText',
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
