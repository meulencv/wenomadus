import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'result_screen.dart'; // Importamos la nueva pantalla

class RoomDetailScreen extends StatefulWidget {
  final String roomId;

  const RoomDetailScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  _RoomDetailScreenState createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final CardSwiperController controller = CardSwiperController();
  final List<Map<String, dynamic>> questions = [];
  final List<int?> binaryResponses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await Supabase.instance.client
          .from('questions')
          .select('text')
          .order('id', ascending: true);
      setState(() {
        questions.addAll(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateRoomResponses() async {
    try {
      await Supabase.instance.client.rpc(
        'update_room_responses',
        params: {
          'room_id_input': widget.roomId,
          'new_responses': binaryResponses,
        },
      );
      debugPrint(
          'Successfully updated room responses for room ${widget.roomId}');
    } catch (e) {
      debugPrint('Error updating room responses: $e');
    }
  }

  Future<void> _navigateToResultScreen() async {
    try {
      // Obtener los datos de la sala
      final response = await Supabase.instance.client
          .from('rooms')
          .select('responses_list, response_ai')
          .eq('id', widget.roomId)
          .single();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            responsesList: response['responses_list'],
            responseAi: response['response_ai'],
            roomId: widget.roomId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error al cargar resultados: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar los resultados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF004D51),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF004D51),
      appBar: AppBar(
        title: const Text('Detalles de la sala'),
        backgroundColor: const Color(0xFF1E6C71),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Código de la sala:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.roomId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: questions.isNotEmpty
                  ? CardSwiper(
                      controller: controller,
                      cardsCount: questions.length,
                      onSwipe: _onSwipe,
                      onEnd: _onEnd,
                      allowedSwipeDirection: const AllowedSwipeDirection.only(
                        left: true,
                        right: true,
                      ),
                      numberOfCardsDisplayed: 3,
                      backCardOffset: const Offset(40, 40),
                      padding: const EdgeInsets.all(24.0),
                      cardBuilder: (
                        context,
                        index,
                        horizontalThresholdPercentage,
                        verticalThresholdPercentage,
                      ) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              questions[index]['text'],
                              style: const TextStyle(
                                color: Color(0xFF004D51),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '¡No hay más cartas!',
                              style: TextStyle(
                                color: Color(0xFF004D51),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Respuestas finales:',
                              style: TextStyle(
                                color: Color(0xFF004D51),
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              binaryResponses.toString(),
                              style: const TextStyle(
                                color: Color(0xFF004D51),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _navigateToResultScreen,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E6C71),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                              child: const Text(
                                'Decidir lugar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    int response;
    if (direction == CardSwiperDirection.right) {
      response = 1;
      debugPrint('Card ${questions[previousIndex]['text']} swiped RIGHT (Yes)');
    } else {
      response = 0;
      debugPrint('Card ${questions[previousIndex]['text']} swiped LEFT (No)');
    }
    setState(() {
      binaryResponses.add(response);
    });
    return true;
  }

  void _onEnd() {
    setState(() {
      questions.clear();
    });
    _updateRoomResponses();
  }
}
