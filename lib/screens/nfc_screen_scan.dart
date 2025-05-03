import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Clase para representar un elemento coleccionable
class CollectibleItem {
  final String name;
  final String image;
  final String category;
  final String rarity;

  const CollectibleItem({
    required this.name,
    required this.image,
    required this.category,
    required this.rarity,
  });
}

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
  CollectibleItem? _scannedItem;

  // Listas de elementos coleccionables
  final List<CollectibleItem> foodItems = [
    CollectibleItem(
        name: 'Calcot Shiny',
        image: 'CalcotShiny.jpeg',
        category: 'Food',
        rarity: 'Shiny'),
  ];

  final List<CollectibleItem> stampsItems = [
    CollectibleItem(
        name: 'MNAC Barcelona',
        image: 'MNACBarcelonaCommon.jpeg',
        category: 'Stamps',
        rarity: 'Common'),
    CollectibleItem(
        name: 'Tibidabo Barcelona',
        image: 'TibidaboBarcelonaCommon.jpeg',
        category: 'Stamps',
        rarity: 'Common'),
    CollectibleItem(
        name: 'Tibidabo Barcelona Rare',
        image: 'TibidaboBarcelonaRare.jpeg',
        category: 'Stamps',
        rarity: 'Rare'),
    CollectibleItem(
        name: 'Tokyo Disneyland',
        image: 'TokyoDisneylandCommon.jpeg',
        category: 'Stamps',
        rarity: 'Common'),
    CollectibleItem(
        name: 'Tokyo Imperial Castle',
        image: 'TokyoImperialCastleRare.jpeg',
        category: 'Stamps',
        rarity: 'Rare'),
    CollectibleItem(
        name: 'Tokyo Imperial Castle Shiny',
        image: 'TokyoImperialCastleSHINY.jpeg',
        category: 'Stamps',
        rarity: 'Shiny'),
  ];

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

  // Función para decodificar el payload e identificar el elemento coleccionable
  String _decodePayload(dynamic tagData) {
    try {
      // Acceder al payload dentro de ndef -> cachedMessage -> records
      var records = tagData['ndef']?['cachedMessage']?['records'];
      if (records != null && records.isNotEmpty) {
        var payload = records[0]['payload'];
        // Saltar el byte de idioma (primeros 3 bytes, asumiendo formato [2, 101, 110])
        if (payload != null && payload.length > 3) {
          // Decodificar los bytes restantes como UTF-8
          String decodedText = String.fromCharCodes(payload.sublist(3));

          // Buscar el elemento coleccionable correspondiente
          _scannedItem = _findCollectibleItem(decodedText);

          return decodedText;
        }
      }
      return "No se encontró texto en el payload";
    } catch (e) {
      print('Error al decodificar el payload: $e');
      return "Error al decodificar el payload";
    }
  }

  // Función para encontrar el elemento coleccionable basado en el texto decodificado
  CollectibleItem? _findCollectibleItem(String decodedText) {
    // Buscar en la lista de alimentos con coincidencia exacta
    for (var item in foodItems) {
      if (decodedText == item.name) {
        return item;
      }
    }

    // Buscar en la lista de sellos con coincidencia exacta
    for (var item in stampsItems) {
      if (decodedText == item.name) {
        return item;
      }
    }

    // Si no hay coincidencia exacta, retornar null
    return null;
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

      // Simplificamos para guardar solo el nombre del elemento
      String itemName = nfcData;

      // Intenta obtener el registro actual del usuario
      final response = await _supabase
          .from('user_characters')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Si no existe, crea un nuevo registro con un array que contiene el nombre
        await _supabase.from('user_characters').insert({
          'user_id': userId,
          'characters': [itemName]
        });

        setState(() {
          _scanStatus = "¡Elemento guardado correctamente!";
          _saving = false;
        });
      } else {
        // Si existe, verificamos si ya contiene el elemento
        List<dynamic> characters =
            List<dynamic>.from(response['characters'] ?? []);

        // Verificar si el nombre ya existe para evitar duplicados
        if (!characters.contains(itemName)) {
          characters.add(itemName);
          await _supabase
              .from('user_characters')
              .update({'characters': characters}).eq('user_id', userId);

          setState(() {
            _scanStatus = "¡Elemento guardado correctamente!";
            _saving = false;
          });
        } else {
          setState(() {
            _scanStatus = "Este elemento ya está en tu colección";
            _saving = false;
          });
        }
      }
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
                child: _scannedItem != null
                    ? ClipOval(
                        child: Image.network(
                          'https://www.wenomad.us/NFT/${_scannedItem!.category}/${_scannedItem!.image}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              _saving ? Icons.cloud_upload : Icons.nfc,
                              size: 100,
                              color: Colors.white,
                            );
                          },
                        ),
                      )
                    : Icon(
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
              const SizedBox(height: 20),
              if (_scannedItem != null) ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _scannedItem!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoChip(_scannedItem!.category, Colors.blue),
                          const SizedBox(width: 8),
                          _buildInfoChip(_scannedItem!.rarity,
                              _getRarityColor(_scannedItem!.rarity)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
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

  // Widget para los chips de categoría y rareza
  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Función para obtener el color según la rareza del ítem
  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return Colors.purple;
      case 'shiny':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }
}
