import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'create_room_screen.dart';
import 'map_screen.dart';
import 'room_detail_screen.dart';
import '../utils/room_notifier.dart';
import 'collection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _supabase = Supabase.instance.client;
  final _tribeCodeController = TextEditingController();
  List<Map<String, dynamic>> _userRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRooms();
    RoomNotifier.roomsUpdated.addListener(_handleRoomsUpdated);
  }

  @override
  void dispose() {
    _tribeCodeController.dispose();
    RoomNotifier.roomsUpdated.removeListener(_handleRoomsUpdated);
    super.dispose();
  }

  void _handleRoomsUpdated() {
    _loadUserRooms();
  }

  Future<void> _loadUserRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final response = await _supabase
            .from('room_users')
            .select('room_id')
            .eq('user_id', userId);

        if (response != null && response.isNotEmpty) {
          List<String> roomIds =
              List<String>.from(response.map((item) => item['room_id']));

          final roomsResponse =
              await _supabase.from('rooms').select('*').inFilter('id', roomIds);

          if (roomsResponse != null) {
            List<Map<String, dynamic>> roomsWithUsers = [];

            for (var room in roomsResponse) {
              final usersResponse = await _supabase
                  .from('room_users')
                  .select('user_id')
                  .eq('room_id', room['id']);

              List<Map<String, dynamic>> roomUsers = [];
              if (usersResponse != null && usersResponse.isNotEmpty) {
                List<String> userIds = List<String>.from(
                    usersResponse.map((item) => item['user_id']));
                room['user_ids'] = userIds;
                room['user_count'] = userIds.length;
              } else {
                room['user_ids'] = [];
                room['user_count'] = 0;
              }

              roomsWithUsers.add(room);
            }

            setState(() {
              _userRooms = roomsWithUsers;
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _userRooms = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading rooms: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isUserAdmin(String adminId) {
    final userId = _supabase.auth.currentUser?.id;
    return userId == adminId;
  }

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

  Future<void> _createRoom() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Debes iniciar sesión para crear una sala')),
        );
        return;
      }

      final roomCode = _generateRoomCode();

      await _supabase.from('rooms').insert({
        'id': roomCode,
        'admin_user_id': userId,
        'responses_list': [],
        'response_ai': {}
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sala creada con éxito. Código: $roomCode'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la sala: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _joinRoom(String roomId) async {
    if (roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a tribe code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to join a tribe'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final roomResponse = await _supabase
          .from('rooms')
          .select('id, name')
          .eq('id', roomId)
          .maybeSingle();

      if (roomResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tribe found with that code'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final memberResponse = await _supabase
          .from('room_users')
          .select()
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();

      if (memberResponse != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already a member of this tribe'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _supabase.from('room_users').insert({
        'room_id': roomId,
        'user_id': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have joined the tribe ${roomResponse['name']}'),
          backgroundColor: Colors.green,
        ),
      );

      _tribeCodeController.clear();
      await _loadUserRooms();
    } catch (e) {
      print('Error joining tribe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining tribe: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D51),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: RoomNotifier.roomsUpdated,
          builder: (context, value, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 15),
                  child: Text(
                    "Connect with your\ntribe",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tribeCodeController,
                            decoration: const InputDecoration(
                              hintText: "Tribe code...",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 15),
                            ),
                            onSubmitted: (value) => _joinRoom(value),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              _joinRoom(_tribeCodeController.text.trim()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Icon(Icons.login,
                                color: Color(0xFF1E6C71)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final scannedCode =
                                await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const QRScanScreen(),
                              ),
                            );
                            if (scannedCode != null && scannedCode is String) {
                              await _joinRoom(scannedCode);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child:
                                Icon(Icons.qr_code_scanner, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCategoryItem(Icons.add, true),
                        _buildCategoryItem(Icons.public, false),
                        _buildCategoryItem(Icons.inventory_2, false),
                        _buildCategoryItem(Icons.people_alt, false),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
                  child: Text(
                    "My Tribes",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _isLoading
                    ? const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      )
                    : _userRooms.isEmpty
                        ? const Expanded(
                            child: Center(
                              child: Text(
                                "You don't have any tribes yet.\nCreate one or join an existing tribe!",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _userRooms.length,
                              itemBuilder: (context, index) {
                                final room = _userRooms[index];
                                final isAdmin =
                                    _isUserAdmin(room['admin_user_id']);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: Dismissible(
                                    key: Key(room['id']),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: EdgeInsets.only(right: 20.0),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      final isAdmin =
                                          _isUserAdmin(room['admin_user_id']);

                                      if (!isAdmin) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Only admin can delete tribes'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return false;
                                      }

                                      return await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor:
                                                const Color(0xFFE8F3F3),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            title: const Text(
                                              'Delete Tribe',
                                              style: TextStyle(
                                                color: Color(0xFF004D51),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Text(
                                              'Are you sure you want to delete "${room['name']}" tribe? This action cannot be undone.',
                                              style: const TextStyle(
                                                color: Color(0xFF004D51),
                                              ),
                                            ),
                                            actions: <Widget>[
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: Color(0xFF1E6C71),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: const Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    onDismissed: (direction) async {
                                      try {
                                        await _supabase
                                            .from('room_users')
                                            .delete()
                                            .eq('room_id', room['id']);
                                        await _supabase
                                            .from('rooms')
                                            .delete()
                                            .eq('id', room['id']);
                                        setState(() {
                                          _userRooms.removeWhere((item) =>
                                              item['id'] == room['id']);
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Tribe deleted successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error deleting tribe: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RoomDetailScreen(
                                                    roomId: room['id']),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F3F3),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(15),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: isAdmin
                                                      ? const Color(0xFFFFD700)
                                                      : const Color(0xFF1E6C71),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    room['name']?[0] ?? '?',
                                                    style: TextStyle(
                                                      color: isAdmin
                                                          ? const Color(
                                                              0xFF004D51)
                                                          : Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      room['name'] ??
                                                          'Unknown Room',
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF004D51),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'Code: ${room['id']}',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        if (isAdmin) ...[
                                                          const SizedBox(
                                                              width: 8),
                                                          const Icon(
                                                            Icons.star,
                                                            color: Color(
                                                                0xFFFFD700),
                                                            size: 16,
                                                          ),
                                                          const Text(
                                                            "Admin",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ]
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF1E6C71),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.people,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${room['user_count'] ?? 0}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF004D51),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (icon == Icons.add) {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => CreateRoomScreen()));
        } else if (icon == Icons.public) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => MapScreen()));
        } else if (icon == Icons.inventory_2) {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => CollectionScreen()));
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF004D51) : Colors.white,
        ),
      ),
    );
  }
}

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Tribe QR Code'),
        backgroundColor: const Color(0xFF004D51),
      ),
      body: _buildQrView(context),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: const Color(0xFF1E6C71),
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      if (scanData.code != null) {
        controller.pauseCamera();
        Navigator.of(context).pop(scanData.code);
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
//    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
    }
  }
}
