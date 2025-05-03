import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'create_room_screen.dart';
import 'map_screen.dart';
import 'room_detail_screen.dart'; // Asegúrate de importar la pantalla de detalles
import '../utils/room_notifier.dart'; // Add this import
import 'collection.dart'; // Importamos la pantalla de colección

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _supabase = Supabase.instance.client;
  final _tribeCodeController = TextEditingController();

  // Lista para almacenar las salas del usuario
  List<Map<String, dynamic>> _userRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRooms();

    // Add listener for room updates
    RoomNotifier.roomsUpdated.addListener(_handleRoomsUpdated);
  }

  @override
  void dispose() {
    _tribeCodeController.dispose();
    // Remove listener when widget is disposed
    RoomNotifier.roomsUpdated.removeListener(_handleRoomsUpdated);
    super.dispose();
  }

  // Handler for room updates
  void _handleRoomsUpdated() {
    _loadUserRooms();
  }

  // Cargar las salas del usuario
  Future<void> _loadUserRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        // Obtener todas las salas donde el usuario es miembro
        final response = await _supabase
            .from('room_users')
            .select('room_id')
            .eq('user_id', userId);

        // Obtener detalles de cada sala
        if (response != null && response.isNotEmpty) {
          List<String> roomIds =
              List<String>.from(response.map((item) => item['room_id']));

          final roomsResponse =
              await _supabase.from('rooms').select('*').inFilter('id', roomIds);

          if (roomsResponse != null) {
            // Para cada sala, obtenemos los usuarios
            List<Map<String, dynamic>> roomsWithUsers = [];

            for (var room in roomsResponse) {
              // Obtener los usuarios de esta sala
              final usersResponse = await _supabase
                  .from('room_users')
                  .select('user_id')
                  .eq('room_id', room['id']);

              // Obtener información de cada usuario
              List<Map<String, dynamic>> roomUsers = [];
              if (usersResponse != null && usersResponse.isNotEmpty) {
                List<String> userIds = List<String>.from(
                    usersResponse.map((item) => item['user_id']));

                // Agregamos la lista de IDs de usuario a la sala
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

  // Función para verificar si el usuario actual es administrador
  bool _isUserAdmin(String adminId) {
    final userId = _supabase.auth.currentUser?.id;
    return userId == adminId;
  }

  // Función para generar un código único de 6 caracteres
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

  // Función para crear una nueva sala
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

      // Generamos un código único para la sala
      final roomCode = _generateRoomCode();

      // Insertamos la nueva sala en la tabla rooms
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

  // Función para unirse a una sala mediante código
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

      // Check if the room exists
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

      // Check if the user is already a member of this room
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

      // Add the user to the room
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

      // Clear the text field
      _tribeCodeController.clear();

      // Reload user rooms
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
                // Título "Explore the beautiful places"
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

                // Barra de búsqueda
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
                        // Botón para unirse
                        GestureDetector(
                          onTap: () =>
                              _joinRoom(_tribeCodeController.text.trim()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Icon(Icons.login,
                                color: Color(0xFF1E6C71)),
                          ),
                        ),
                        // Ícono de QR con función interactiva
                        GestureDetector(
                          onTap: () {
                            // Aquí iría la función para abrir el escáner QR
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Abriendo escáner QR...')),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child:
                                Icon(Icons.qr_code_scanner, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Categorías con iconos
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCategoryItem(
                            Icons.add, true), // Botón 1: símbolo de +
                        _buildCategoryItem(
                            Icons.public, false), // Botón 2: mapa del mundo
                        _buildCategoryItem(
                            Icons.inventory_2, false), // Botón 3: baúl/cofre
                        _buildCategoryItem(Icons.people_alt,
                            false), // Botón 4: ícono de grupo/tribu
                      ],
                    ),
                  ),
                ),

                // Título "My Tribes" directamente después de las categorías
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

                // Lista de mis tribus/grupos
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
                                      final isAdmin = _isUserAdmin(room['admin_user_id']);
                                      
                                      // Only admins can delete rooms
                                      if (!isAdmin) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Only admin can delete tribes'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return false;
                                      }
                                      
                                      // Show confirmation dialog
                                      return await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: const Color(0xFFE8F3F3),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15),
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
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                onPressed: () => Navigator.of(context).pop(false),
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
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                onPressed: () => Navigator.of(context).pop(true),
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
                                      print('sala eliminada');
                                      try {
                                        // First delete all room_users associations
                                        await _supabase
                                            .from('room_users')
                                            .delete()
                                            .eq('room_id', room['id']);
                                            
                                        // Then delete the room itself
                                        await _supabase
                                            .from('rooms')
                                            .delete()
                                            .eq('id', room['id']);
                                            
                                        // Remove from local list and update UI
                                        setState(() {
                                          _userRooms.removeWhere((item) => item['id'] == room['id']);
                                        });
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Tribe deleted successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error deleting tribe: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: GestureDetector(
                                      onTap: () {
                                        // Navegar a la pantalla de detalles de la room
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
                                              // Círculo para avatar/icono
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  // Cambiar color a dorado si es admin
                                                  color: isAdmin
                                                      ? const Color(
                                                          0xFFFFD700) // Color dorado
                                                      : const Color(
                                                          0xFF1E6C71), // Color normal
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    room['name']?[0] ??
                                                        '?', // Primera letra del nombre
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
                                              // Nombre de la tribu
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
                                              // Indicador de personas
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

                // Espacio expansible para llenar el resto de la pantalla
                //const Expanded(child: SizedBox()),
              ],
            );
          },
        ),
      ),

      // Barra de navegación inferior
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
          // Navegación a la pantalla de colección cuando se presiona el botón de caja
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => CollectionScreen()));
        } else {
          // Manejar otros botones si es necesario
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
