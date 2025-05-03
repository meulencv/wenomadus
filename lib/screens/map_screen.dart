import 'package:flutter/material.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Set to keep track of selected countries
  final Set<String> _selectedCountries = {};
  
  // Color for selected countries
  final Color _selectedColor = Colors.amber;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D51),
      appBar: AppBar(
        title: const Text('Map View'),
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
              'Interactive World Map',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap on a country to select or unselect it',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SimpleWorldMap(
                // Map configuration
                map: Maps.worldMap,
                // Country hover callbacks
                onCountrySelected: (country) {
                  setState(() {
                    if (_selectedCountries.contains(country)) {
                      _selectedCountries.remove(country);
                    } else {
                      _selectedCountries.add(country);
                    }
                  });
                  // Show country name when tapped
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected: $country'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: const Color(0xFF004D51),
                    ),
                  );
                },
                // Country colors
                countryColors: Map.fromEntries(
                  _selectedCountries.map(
                    (countryCode) => MapEntry(countryCode, _selectedColor),
                  ),
                ),
                // Default styling
                defaultCountryColor: Colors.grey.shade300,
                defaultCountryBorderColor: const Color(0xFF004D51),
                countryBorderWidth: 1.0,
              ),
            ),
            if (_selectedCountries.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Selected Countries: ${_selectedCountries.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _selectedCountries
                    .map((code) => Chip(
                          label: Text(code),
                          backgroundColor: _selectedColor,
                          labelStyle: const TextStyle(color: Colors.black),
                          onDeleted: () {
                            setState(() {
                              _selectedCountries.remove(code);
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
