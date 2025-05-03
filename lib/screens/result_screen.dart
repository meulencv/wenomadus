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

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

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

      // Una vez que tenemos las preguntas, podemos obtener la recomendación
      _getTravelRecommendation();
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getTravelRecommendation() async {
    if (questions.isEmpty || widget.responsesList == null) return;

    setState(() {
      isLoadingRecommendation = true;
    });

    try {
      // Convertir responsesList a una lista
      List<dynamic> responses = [];
      if (widget.responsesList is String) {
        responses = jsonDecode(widget.responsesList);
      } else if (widget.responsesList is List) {
        responses = widget.responsesList;
      }

      // Crear el string de preguntas y respuestas
      String questionsString = '';
      for (int i = 0; i < questions.length; i++) {
        if (i < responses.length && responses[i] != null) {
          final questionText = questions[i]['text'];
          final response = responses[i] == 1 ? 'Sí' : 'No';
          questionsString += '${i + 1}. $questionText: $response\n';
        }
      }

      // Obtener la recomendación
      final recommendation = await getTravelRecommendation(questionsString);

      // Guardar la recomendación en Supabase
      await _saveRecommendationToSupabase(recommendation);

      setState(() {
        travelRecommendation = recommendation;
        isLoadingRecommendation = false;
      });
    } catch (e) {
      debugPrint('Error getting travel recommendation: $e');
      setState(() {
        isLoadingRecommendation = false;
      });
    }
  }

  Future<void> _saveRecommendationToSupabase(
      Map<String, dynamic> recommendation) async {
    try {
      // Actualizar el campo response_ai en la tabla rooms para la sala actual
      await Supabase.instance.client
          .from('rooms')
          .update({'response_ai': recommendation}).eq('id', widget.roomId);

      debugPrint('Recomendación guardada en Supabase correctamente');
    } catch (e) {
      debugPrint('Error al guardar la recomendación en Supabase: $e');
    }
  }

  Future<Map<String, dynamic>> getTravelRecommendation(
      String questionsString) async {
    // Replace with your Gemini API key or use a secure method to load it
    final String apiKey = 'AIzaSyBlOgS6ZQgWLsJx2Fk-nORlJOYViaWCilo';
    final String baseUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

    // Create prompt using the provided questions string
    String prompt =
        'Based on the following travel preferences, recommend ONE SPECIFIC CITY (not a country) that fits these preferences:\n\n';
    prompt += questionsString;
    prompt +=
        '\nReturn a JSON with exactly this format. Focus on a single specific city (not a country) and provide at least 5 activities or places to visit within that city in the itinerario array. Each place should have detailed descriptions:\n';
    prompt += '''{
      "ciudad": "City name",
      "pais": "Country name",
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
          // Extract JSON from response
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
    // Convertir responsesList a una lista para mostrar
    List<dynamic> responses = [];
    if (widget.responsesList != null) {
      if (widget.responsesList is String) {
        // Si viene como string JSON, parsearlo
        responses = jsonDecode(widget.responsesList);
      } else if (widget.responsesList is List) {
        responses = widget.responsesList;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF004D51),
      appBar: AppBar(
        title: const Text('Resultado'),
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
                      'Sala: ${widget.roomId}',
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
                            'Respuestas registradas:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004D51),
                            ),
                          ),
                          const SizedBox(height: 15),
                          responses.isNotEmpty
                              ? Column(
                                  children:
                                      List.generate(responses.length, (index) {
                                    // Saltarse las respuestas nulas
                                    if (responses[index] == null) {
                                      return const SizedBox.shrink();
                                    }

                                    // Obtener el título de la pregunta (índice + 1 = id de la pregunta)
                                    String questionTitle =
                                        'Pregunta ${index + 1}';

                                    // Buscar la pregunta correspondiente por ID
                                    final questionIndex = questions.indexWhere(
                                        (q) => q['id'] == index + 1);
                                    if (questionIndex >= 0) {
                                      questionTitle =
                                          questions[questionIndex]['text'];
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: Text(
                                        '$questionTitle: ${responses[index] == 1 ? 'Sí' : 'No'}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF1E6C71),
                                        ),
                                      ),
                                    );
                                  }),
                                )
                              : const Text(
                                  'No hay respuestas registradas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (widget.responseAi != null)
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E6C71),
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
                              'Sugerencia de destino:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              widget.responseAi is String &&
                                      widget.responseAi.isNotEmpty
                                  ? widget.responseAi
                                  : widget.responseAi is Map
                                      ? jsonEncode(widget.responseAi)
                                      : 'No hay sugerencia disponible',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
                            'Recomendación de viaje:',
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
                                        const Text(
                                          'Itinerario sugerido:',
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
                                            'No hay lugares disponibles en el itinerario',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    )
                                  : const Text(
                                      'No hay recomendación disponible',
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
