import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class ResultScreen extends StatefulWidget {
  final dynamic responsesList;
  final dynamic responseAi;
  final String roomId;

  const ResultScreen({
    Key? key,
    required this.responsesList,
    required this.responseAi,
    required this.roomId,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> questions = [];
  Map<String, dynamic>? travelRecommendation;
  bool isLoadingRecommendation = false;
  double? cheapestFlightPrice;
  String? cheapestFlightDate;
  bool isLoadingFlightPrice = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  // Fetch questions from Supabase
  Future<void> _fetchQuestions() async {
    try {
      final response = await Supabase.instance.client
          .from('questions')
          .select('id, text')
          .order('id', ascending: true);
      setState(() {
        questions = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });

      // Fetch travel recommendation and flight price
      await _getTravelRecommendation();
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Get travel recommendation based on user responses
  Future<void> _getTravelRecommendation() async {
    if (questions.isEmpty || widget.responsesList == null) return;

    setState(() {
      isLoadingRecommendation = true;
    });

    try {
      // Check for existing recommendation
      Map<String, dynamic>? existingRecommendation;
      if (widget.responseAi is Map) {
        existingRecommendation = widget.responseAi;
      } else if (widget.responseAi is String && widget.responseAi.isNotEmpty) {
        try {
          existingRecommendation = jsonDecode(widget.responseAi);
        } catch (e) {
          debugPrint('Error parsing responseAi: $e');
        }
      }

      if (existingRecommendation != null &&
          existingRecommendation.containsKey('ciudad') &&
          existingRecommendation.containsKey('pais') &&
          existingRecommendation.containsKey('iata') &&
          existingRecommendation.containsKey('descripcion') &&
          existingRecommendation.containsKey('itinerario')) {
        setState(() {
          travelRecommendation = existingRecommendation;
          isLoadingRecommendation = false;
        });
        // Fetch flight price for existing recommendation
        await _fetchCheapestFlightPrice(existingRecommendation['iata']);
        return;
      }

      // Fetch new recommendation
      List<dynamic> responses = [];
      if (widget.responsesList is String) {
        responses = jsonDecode(widget.responsesList);
      } else if (widget.responsesList is List) {
        responses = widget.responsesList;
      }

      String questionsString = '';
      for (int i = 0; i < questions.length; i++) {
        if (i < responses.length && responses[i] != null) {
          final questionText = questions[i]['text'];
          final response = responses[i] == 1
              ? 'Yes'
              : 'No'; // Translated 'Sí'/'No' to 'Yes'/'No'
          questionsString += '${i + 1}. $questionText: $response\n';
        }
      }

      final recommendation = await getTravelRecommendation(questionsString);
      await _saveRecommendationToSupabase(recommendation);

      setState(() {
        travelRecommendation = recommendation;
        isLoadingRecommendation = false;
      });

      // Fetch flight price for new recommendation
      await _fetchCheapestFlightPrice(recommendation['iata']);
    } catch (e) {
      debugPrint('Error getting travel recommendation: $e');
      setState(() {
        isLoadingRecommendation = false;
      });
    }
  }

  // Fetch the cheapest flight price from Skyscanner API
  Future<void> _fetchCheapestFlightPrice(String destinationIata) async {
    setState(() {
      isLoadingFlightPrice = true;
    });

    try {
      const String originIata = 'BCN';
      final String apiKey = 'sh967490139224896692439644109194';
      final String baseUrl =
          'https://partners.api.skyscanner.net/apiservices/v3/flights/indicative/search';

      final url = Uri.parse(baseUrl);
      final headers = {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      };

      final payload = {
        "query": {
          "market": "ES",
          "locale": "en-US", // Changed to en-US for English
          "currency": "EUR",
          "queryLegs": [
            {
              "originPlace": {
                "queryPlace": {"iata": originIata}
              },
              "destinationPlace": {
                "queryPlace": {"iata": destinationIata}
              },
              "anytime": true
            }
          ]
        }
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['content'] != null &&
            result['content']['results'] != null &&
            result['content']['results']['quotes'] != null) {
          final quotes = result['content']['results']['quotes'];
          double? minPrice;
          String? flightDate;

          for (var quoteId in quotes.keys) {
            final quote = quotes[quoteId];
            if (quote['minPrice'] != null &&
                quote['minPrice']['amount'] != null) {
              final price = double.parse(quote['minPrice']['amount']);
              final outboundLeg = quote['outboundLeg'];

              if (minPrice == null || price < minPrice) {
                minPrice = price;

                if (outboundLeg != null &&
                    outboundLeg['departureDateTime'] != null) {
                  final dateTime = outboundLeg['departureDateTime'];
                  flightDate =
                      '${dateTime['day']}/${dateTime['month']}/${dateTime['year']}';
                }
              }
            }
          }

          setState(() {
            cheapestFlightPrice = minPrice;
            if (flightDate != null) {
              cheapestFlightDate = flightDate;
            }
            isLoadingFlightPrice = false;
          });
        } else {
          setState(() {
            cheapestFlightPrice = null;
            cheapestFlightDate = null;
            isLoadingFlightPrice = false;
          });
        }
      } else {
        debugPrint('Skyscanner API error: ${response.statusCode}');
        setState(() {
          cheapestFlightPrice = null;
          cheapestFlightDate = null;
          isLoadingFlightPrice = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching flight price: $e');
      setState(() {
        cheapestFlightPrice = null;
        cheapestFlightDate = null;
        isLoadingFlightPrice = false;
      });
    }
  }

  // Save recommendation to Supabase
  Future<void> _saveRecommendationToSupabase(
      Map<String, dynamic> recommendation) async {
    try {
      await Supabase.instance.client
          .from('rooms')
          .update({'response_ai': recommendation}).eq('id', widget.roomId);
      debugPrint('Recommendation saved to Supabase successfully');
    } catch (e) {
      debugPrint('Error saving recommendation to Supabase: $e');
    }
  }

  // Get travel recommendation from Google Generative AI
  Future<Map<String, dynamic>> getTravelRecommendation(
      String questionsString) async {
    final String apiKey = 'AIzaSyBlOgS6ZQgWLsJx2Fk-nORlJOYViaWCilo';
    final String baseUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

    String prompt =
        'Based on the following travel preferences, recommend ONE SPECIFIC CITY (not a country) that fits these preferences:\n\n';
    prompt += questionsString;
    prompt +=
        '\nReturn a JSON with exactly this format. Focus on a single specific city (not a country) and provide at least 5 activities or places to visit within that city in the itinerario array. Each place should have detailed descriptions. Include the IATA code for the city’s main airport:\n';
    prompt += '''{
      "ciudad": "City name",
      "pais": "Country name",
      "iata": "IATA code of the city’s main airport (e.g., BCN for Barcelona, CDG for Paris)",
      "descripcion": "Description of the city and why it fits the preferences (at least 100 words)",
      "itinerario": [
        {
          "nombre": "Place or activity name",
          "descripcion": "Detailed description of what to do and see at this place or activity (at least 50 words)",
          "dias": "Number of days or hours recommended to spend here",
          "imagen": "Short description of an iconic image for this place (for example: 'historic plaza with fountain')"
        }
      ]
    }''';

    final url = Uri.parse('$baseUrl?key=$apiKey');
    final headers = {'Content-Type': 'application/json'};
    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'maxOutputTokens': 2048,
        'temperature': 0.4,
      },
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['candidates'] != null && result['candidates'].isNotEmpty) {
          String text = result['candidates'][0]['content']['parts'][0]['text'];
          final jsonStart = text.indexOf('{');
          final jsonEnd = text.lastIndexOf('}') + 1;
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonStr = text.substring(jsonStart, jsonEnd);
            return jsonDecode(jsonStr);
          }
        }
        return {'error': 'No valid candidates in response'};
      } else {
        return {'error': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Exception: $e'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D51),
      appBar: AppBar(
        title: const Text('Result'), // Translated 'Resultado' to 'Result'
        backgroundColor: const Color(0xFF1E6C71),
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room: ${widget.roomId}', // Translated 'Sala' to 'Room'
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Travel Recommendation:', // Translated 'Recomendación de viaje' to 'Travel Recommendation'
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004D51),
                            ),
                          ),
                          const SizedBox(height: 15),
                          isLoadingRecommendation
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF004D51)))
                              : travelRecommendation != null
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(15),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E6C71)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                travelRecommendation!
                                                        .containsKey('ciudad')
                                                    ? '${travelRecommendation!['ciudad']}, ${travelRecommendation!['pais']}'
                                                    : '${travelRecommendation!['pais']}',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  color: Color(0xFF1E6C71),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                '${travelRecommendation!['descripcion']}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFF1E6C71),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Display cheapest flight price
                                        isLoadingFlightPrice
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        color:
                                                            Color(0xFF1E6C71)))
                                            : cheapestFlightPrice != null
                                                ? Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                        color: const Color(
                                                                0xFF1E6C71)
                                                            .withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Recommended flight from Barcelona: €${cheapestFlightPrice!.toStringAsFixed(2)}', // Translated 'Vuelo recomendado desde Barcelona' to 'Recommended flight from Barcelona'
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Color(
                                                                0xFF1E6C71),
                                                          ),
                                                        ),
                                                        if (cheapestFlightDate !=
                                                            null)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 5),
                                                            child: Text(
                                                              'Flight date: $cheapestFlightDate', // Translated 'Fecha del vuelo' to 'Flight date'
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                color: Color(
                                                                    0xFF1E6C71),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  )
                                                : const Text(
                                                    'No flight prices found', // Translated 'No se encontraron precios de vuelos' to 'No flight prices found'
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Suggested Itinerary:', // Translated 'Itinerario sugerido' to 'Suggested Itinerary'
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Color(0xFF1E6C71),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        if (travelRecommendation![
                                                    'itinerario'] !=
                                                null &&
                                            travelRecommendation!['itinerario']
                                                    .length >
                                                0)
                                          ...List.generate(
                                            travelRecommendation!['itinerario']
                                                .length,
                                            (index) {
                                              final place =
                                                  travelRecommendation![
                                                      'itinerario'][index];
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 15),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.05),
                                                      blurRadius: 5,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFF1E6C71)
                                                            .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12,
                                                          horizontal: 15),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFF1E6C71),
                                                        borderRadius:
                                                            BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  9),
                                                          topRight:
                                                              Radius.circular(
                                                                  9),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              '${place['nombre']}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                          if (place['dias'] !=
                                                              null)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          5),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            15),
                                                              ),
                                                              child: Text(
                                                                '${place['dias']}',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Color(
                                                                      0xFF1E6C71),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              15),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (place['imagen'] !=
                                                              null)
                                                            Container(
                                                              width: double
                                                                  .infinity,
                                                              height: 100,
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      bottom:
                                                                          15),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFFEEEEEE),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child: Center(
                                                                child: Text(
                                                                  '${place['imagen']}',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                    color: Color(
                                                                        0xFF666666),
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                              ),
                                                            ),
                                                          Text(
                                                            '${place['descripcion']}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 15,
                                                              color: Color(
                                                                  0xFF333333),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          )
                                        else
                                          const Text(
                                            'No places available in the itinerary', // Translated 'No hay lugares disponibles en el itinerario' to 'No places available in the itinerary'
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    )
                                  : const Text(
                                      'No recommendation available', // Translated 'No hay recomendación disponible' to 'No recommendation available'
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
