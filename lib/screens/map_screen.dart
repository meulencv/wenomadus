import 'package:flutter/material.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/world_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Mapa de países seleccionados (código del país -> boolean)
  final Map<String, bool> _selectedCountries = {};
  
  // Color del mapa
  final Color _defaultColor = Colors.grey.shade300;
  final Color _selectedColor = Colors.amber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D51),
      appBar: AppBar(
        title: const Text('Mapa Interactivo'),
        backgroundColor: const Color(0xFF004D51),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mapa Interactivo Mundial',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Toca un país para seleccionarlo',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(20.0),
                minScale: 0.5,
                maxScale: 4.0,
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: WorldMap(
                    // Configuración del mapa mundial
                    styleOptions: MapStyleOptions(
                      defaultColor: _defaultColor,
                      defaultBorderColor: const Color(0xFF004D51),
                      defaultBorderStrokeWidth: 1.0,
                    ),
                    // Detectar toques en países
                    onCountryTap: (context, countryCode) {
                      setState(() {
                        // Alternar la selección del país
                        if (_selectedCountries.containsKey(countryCode)) {
                          _selectedCountries.remove(countryCode);
                        } else {
                          _selectedCountries[countryCode] = true;
                        }
                      });
                      
                      // Mostrar información sobre el país seleccionado
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _selectedCountries.containsKey(countryCode)
                                ? 'País $countryCode seleccionado'
                                : 'País $countryCode deseleccionado',
                          ),
                          duration: const Duration(seconds: 1),
                          backgroundColor: const Color(0xFF004D51),
                        ),
                      );
                    },
                    // Color personalizado para países seleccionados
                    countryColors: Map.fromEntries(
                      _selectedCountries.keys.map(
                        (code) => MapEntry(code, _selectedColor),
                      ),
                    ),
                    // Usar el mapa mundial
                    map: worldMap,
                  ),
                ),
              ),
            ),
            if (_selectedCountries.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Países Seleccionados: ${_selectedCountries.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _selectedCountries.keys
                    .map((countryCode) => Chip(
                          label: Text(countryCode),
                          backgroundColor: Colors.amber,
                          labelStyle: const TextStyle(color: Colors.black),
                          onDeleted: () {
                            setState(() {
                              _selectedCountries.remove(countryCode);
                            });
                          },
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
