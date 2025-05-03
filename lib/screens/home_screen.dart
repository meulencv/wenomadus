import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'create_room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _supabase = Supabase.instance.client;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D51),
      body: SafeArea(
        child: Column(
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
                        decoration: InputDecoration(
                          hintText: "Tribe code...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15),
                        ),
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
                        child: Icon(Icons.qr_code_scanner, color: Colors.grey),
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5, // Número de tribus
                itemBuilder: (context, index) {
                  // Nombres de ejemplo para las tribus
                  final tribeNames = [
                    "Hackathon Team",
                    "UPC Amigos",
                    "Gaming Squad",
                    "Study Group",
                    "Weekend Trip"
                  ];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3F3),
                        borderRadius: BorderRadius.circular(15),
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
                                color: Color(0xFF1E6C71),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  tribeNames[index]
                                      [0], // Primera letra del nombre
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Nombre de la tribu
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tribeNames[index],
                                    style: TextStyle(
                                      color: const Color(0xFF004D51),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "${index + 3} members",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
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
                },
              ),
            ),

            // Espacio expansible para llenar el resto de la pantalla
            //const Expanded(child: SizedBox()),
          ],
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
