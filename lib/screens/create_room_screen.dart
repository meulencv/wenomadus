import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({Key? key}) : super(key: key);

  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isCreating = false;
  String? _createdRoomCode;
  late ConfettiController _confettiController;

  // GlobalKey para capturar el widget como imagen
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Function to generate a unique 6-character code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Function to create a new room
  Future<void> _createRoom() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a room name')));
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to create a room')),
        );
        return;
      }

      // Generate a unique code for the room
      final roomCode = _generateRoomCode();

      // Start a transaction by using Supabase client
      // First, insert the new room
      await _supabase.from('rooms').insert({
        'id': roomCode,
        'name': _nameController.text.trim(),
        'admin_user_id': userId,
        'responses_list': [],
        'response_ai': {}
      });

      // Then, insert the relationship between user and room in room_users table
      await _supabase
          .from('room_users')
          .insert({'room_id': roomCode, 'user_id': userId});

      setState(() {
        _isCreating = false;
        _createdRoomCode = roomCode;
      });

      // Show confetti
      _confettiController.play();
    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating room: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to show QR dialog
  void _showQRDialog() {
    if (_createdRoomCode == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _nameController.text,
                  style: const TextStyle(
                    color: Color(0xFF004D51),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          QrImageView(
                            data: _createdRoomCode!,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF004D51),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _createdRoomCode!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Color(0xFF004D51),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "CLOSE",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _shareRoomCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D51),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5, right: 5),
                        child: const Row(
                          children: [
                            Icon(Icons.copy, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "COPY",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to share room code by copying to clipboard
  void _shareRoomCode() async {
    if (_createdRoomCode == null) return;

    try {
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(
          text:
              'Join my room "${_nameController.text}" with code: $_createdRoomCode'));

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room code copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Close dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error copying to clipboard: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D51),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D51),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Create New Room",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Room Information",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Room name field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "Room name",
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Create button
                if (_createdRoomCode == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isCreating
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF004D51)),
                            )
                          : const Text(
                              "CREATE ROOM",
                              style: TextStyle(
                                color: Color(0xFF004D51),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                // Room created information
                if (_createdRoomCode != null) ...[
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Room created successfully!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Room code:",
                                style: TextStyle(
                                  color: Color(0xFF004D51),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _createdRoomCode!,
                                style: const TextStyle(
                                  color: Color(0xFF004D51),
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Share this code with your friends so they can join your room.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF004D51),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Share button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showQRDialog,
                            icon: const Icon(
                              Icons.qr_code,
                              color: Color(0xFF004D51),
                            ),
                            label: const Text(
                              "SHOW QR CODE",
                              style: TextStyle(
                                color: Color(0xFF004D51),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Confetti controller
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }
}
