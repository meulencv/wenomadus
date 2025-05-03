import 'package:flutter/material.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomId;

  const RoomDetailScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D51),
      appBar: AppBar(
        title: const Text('Detalles de la sala'),
        backgroundColor: const Color(0xFF1E6C71),
        elevation: 0,
      ),
      body: Center(
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
                'Código de la sala:',
                style: TextStyle(
                  color: Color(0xFF004D51),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                roomId,
                style: const TextStyle(
                  color: Color(0xFF004D51),
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
