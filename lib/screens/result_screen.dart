import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      setState(() {
        isLoading = false;
      });
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
                  ],
                ),
              ),
      ),
    );
  }
}
