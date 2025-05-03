import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'result_screen.dart';

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
  bool isRoomCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkRoomCompletion();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _checkRoomCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isRoomCompleted =
          prefs.getBool('room_${widget.roomId}_completed') ?? false;
    });
    if (!isRoomCompleted) {
      await _fetchQuestions();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _markRoomAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('room_${widget.roomId}_completed', true);
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
      await _markRoomAsCompleted();
    } catch (e) {
      debugPrint('Error updating room responses: $e');
    }
  }

  Future<void> _navigateToResultScreen() async {
    try {
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
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // La imagen de fondo solo se muestra cuando hay preguntas y la sala no está completada
            if (isRoomCompleted && !questions.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.2, // 80% transparencia
                  child: Image.asset(
                    'assets/going.png', // Corregido a extensión png estándar
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Column(
              children: [
                Expanded(
                  child: !isRoomCompleted && questions.isNotEmpty
                      ? CardSwiper(
                          controller: controller,
                          cardsCount: questions.length,
                          onSwipe: _onSwipe,
                          onEnd: _onEnd,
                          allowedSwipeDirection:
                              const AllowedSwipeDirection.only(
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  spreadRadius: 3,
                                  blurRadius: 7,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.explore,
                                  color: Color(0xFF004D51),
                                  size: 50,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'See where we\'re going!!!',
                                  style: TextStyle(
                                    color: Color(0xFF004D51),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton(
                                  onPressed: _navigateToResultScreen,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E6C71),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: const Text(
                                    'Discover Destination',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
      isRoomCompleted = true;
    });
    _updateRoomResponses();
  }
}
