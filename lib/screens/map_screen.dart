import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Controlador del mapa
  final MapController _mapController = MapController();

  // Lista de países visitados (códigos ISO)
  final Set<String> _visitedCountries = {'ESP', 'FRA', 'ITA', 'USA', 'MEX'};

  // Mapa de información de países (nombre, coordenadas del centro)
  final Map<String, Map<String, dynamic>> _countriesInfo = {
    'ESP': {
      'name': 'Spain',
      'center': const LatLng(40.4168, -3.7038),
      'color': Colors.amber,
    },
    'FRA': {
      'name': 'France',
      'center': const LatLng(46.2276, 2.2137),
      'color': Colors.amber,
    },
    'ITA': {
      'name': 'Italy',
      'center': const LatLng(41.8719, 12.5675),
      'color': Colors.amber,
    },
    'USA': {
      'name': 'United States',
      'center': const LatLng(37.0902, -95.7129),
      'color': Colors.amber,
    },
    'MEX': {
      'name': 'Mexico',
      'center': const LatLng(23.6345, -102.5528),
      'color': Colors.amber,
    },
    'DEU': {
      'name': 'Germany',
      'center': const LatLng(51.1657, 10.4515),
      'color': Colors.amber,
    },
    'GBR': {
      'name': 'United Kingdom',
      'center': const LatLng(55.3781, -3.4360),
      'color': Colors.amber,
    },
    'JPN': {
      'name': 'Japan',
      'center': const LatLng(36.2048, 138.2529),
      'color': Colors.amber,
    },
    'BRA': {
      'name': 'Brazil',
      'center': const LatLng(-14.235, -51.9253),
      'color': Colors.amber,
    },
    'CAN': {
      'name': 'Canada',
      'center': const LatLng(56.1304, -106.3468),
      'color': Colors.amber,
    },
  };

  // Centro inicial del mapa (coordenadas aproximadas del centro del mundo)
  final LatLng _initialCenter = const LatLng(20.0, 0.0);

  // Zoom inicial
  final double _initialZoom = 2.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D51),
      appBar: AppBar(
        title: const Text(
          'Visited Countries',
          style: TextStyle(color: Colors.white),
        ),
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
              'Map of Visited Countries',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap on a country to mark it as visited',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _initialCenter,
                    zoom: _initialZoom,
                    maxZoom: 18.0,
                    minZoom: 1.0,
                    onTap: _handleMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.wenomadus',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    // Capa de marcadores para países visitados
                    MarkerLayer(
                      markers: _getCountryMarkers(),
                    ),
                  ],
                ),
              ),
            ),
            if (_visitedCountries.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Visited Countries: ${_visitedCountries.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _visitedCountries
                    .where((code) => _countriesInfo.containsKey(code))
                    .map((code) => Chip(
                          label: Text(_countriesInfo[code]!['name'] as String),
                          backgroundColor: Colors.amber,
                          labelStyle: const TextStyle(color: Colors.black),
                          onDeleted: () {
                            setState(() {
                              _visitedCountries.remove(code);
                            });
                          },
                        ))
                    .toList(),
              ),
            ],
            // Agregar botón para simular búsqueda de países
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showCountrySelector,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Add Visited Country'),
            ),
          ],
        ),
      ),
    );
  }

  // Generar marcadores para representar países visitados
  List<Marker> _getCountryMarkers() {
    final List<Marker> markers = [];

    for (final countryCode in _visitedCountries) {
      if (_countriesInfo.containsKey(countryCode)) {
        final countryData = _countriesInfo[countryCode]!;
        final center = countryData['center'] as LatLng;
        final name = countryData['name'] as String;

        markers.add(
          Marker(
            point: center,
            width: 60,
            height: 60,
            builder: (ctx) => GestureDetector(
              onTap: () {
                // Mostrar información del país
                _showCountryInfo(countryCode);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Tooltip(
                  message: name,
                  child: const Icon(Icons.flag, color: Colors.black),
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  // Mostrar información del país
  void _showCountryInfo(String countryCode) {
    if (_countriesInfo.containsKey(countryCode)) {
      final countryData = _countriesInfo[countryCode]!;
      final name = countryData['name'] as String;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visited country: $name'),
          action: SnackBarAction(
            label: 'Remove',
            onPressed: () {
              setState(() {
                _visitedCountries.remove(countryCode);
              });
            },
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF004D51),
        ),
      );
    }
  }

  // Manejar toques en el mapa
  void _handleMapTap(TapPosition tapPosition, LatLng latLng) {
    // Aquí podríamos implementar una búsqueda basada en coordenadas
    // para detectar en qué país se ha tocado, pero eso requeriría
    // una base de datos de polígonos de países que está fuera del alcance

    // En su lugar, mostraremos el selector de países
    _showCountrySelector();
  }

  // Mostrar un selector de países
  void _showCountrySelector() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF004D51),
            title: const Text(
              'Select Visited Country',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: _countriesInfo.entries
                    .map(
                      (entry) => ListTile(
                        title: Text(
                          entry.value['name'] as String,
                          style: TextStyle(
                            color: _visitedCountries.contains(entry.key)
                                ? Colors.amber
                                : Colors.white,
                          ),
                        ),
                        leading: Icon(
                          _visitedCountries.contains(entry.key)
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: _visitedCountries.contains(entry.key)
                              ? Colors.amber
                              : Colors.white,
                        ),
                        onTap: () {
                          // Update both the main state and dialog state
                          setState(() {
                            if (_visitedCountries.contains(entry.key)) {
                              _visitedCountries.remove(entry.key);
                            } else {
                              _visitedCountries.add(entry.key);
                            }
                          });

                          // Also update the dialog UI immediately
                          setDialogState(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('Close', style: TextStyle(color: Colors.amber)),
              ),
            ],
          );
        });
      },
    );
  }
}
