import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;

  const RoomDetailScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  _RoomDetailScreenState createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final CardSwiperController controller = CardSwiperController();
  List<Map<String, dynamic>> questions = [];
  final List<String> swipeResults = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response =
          await Supabase.instance.client.from('questions').select().order('id');

      setState(() {
        questions = (response as List<dynamic>).cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al obtener preguntas: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : questions.isNotEmpty
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
                                  questions[index]['text'] ?? 'Sin texto',
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
                                  'Resultados finales:',
                                  style: TextStyle(
                                    color: Color(0xFF004D51),
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...swipeResults.map(
                                  (result) => Text(
                                    result,
                                    style: const TextStyle(
                                      color: Color(0xFF004D51),
                                      fontSize: 16,
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
    String questionText = questions[previousIndex]['text'] ?? 'Sin texto';
    String result;
    if (direction == CardSwiperDirection.right) {
      result = '$questionText: SÍ';
      debugPrint('Card $questionText swiped RIGHT (Yes)');
    } else {
      result = '$questionText: NO';
      debugPrint('Card $questionText swiped LEFT (No)');
    }
    setState(() {
      swipeResults.add(result);
    });
    return true;
  }

  void _onEnd() {
    setState(() {
      questions.clear();
    });
  }
}
