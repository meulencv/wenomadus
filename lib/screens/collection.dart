import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _supabase = Supabase.instance.client;
  final List<CountryItem> allCountries = [
    CountryItem(name: 'Argentina', image: 'Argentina.jpeg'),
    CountryItem(name: 'Australia', image: 'Australia.jpeg'),
    CountryItem(name: 'Brazil', image: 'Brazil.jpeg'),
    CountryItem(name: 'Canada', image: 'Canada.jpeg'),
    CountryItem(name: 'China', image: 'China.jpeg'),
    CountryItem(name: 'Egypt', image: 'Egypt.jpeg'),
    CountryItem(name: 'France', image: 'France.jpeg'),
    CountryItem(name: 'Greece', image: 'Grece.jpeg'),
    CountryItem(name: 'Iceland', image: 'Iceland.jpeg'),
    CountryItem(name: 'India', image: 'India.jpeg'),
    CountryItem(name: 'Indonesia', image: 'Indonesia.jpeg'),
    CountryItem(name: 'Italy', image: 'Italy.jpeg'),
    CountryItem(name: 'Japan', image: 'Japan.jpeg'),
    CountryItem(name: 'Mexico', image: 'Mexico.jpeg'),
    CountryItem(name: 'Morocco', image: 'Morocco.jpeg'),
    CountryItem(name: 'New Zealand', image: 'NewZealand.jpeg'),
    CountryItem(name: 'Peru', image: 'Peru.jpeg'),
    CountryItem(name: 'Portugal', image: 'Portugal.jpeg'),
    CountryItem(name: 'South Africa', image: 'SouthAfrica.jpeg'),
    CountryItem(name: 'South Korea', image: 'SouthKorea.jpeg'),
    CountryItem(name: 'Spain', image: 'Spain.jpeg'),
    CountryItem(name: 'Thailand', image: 'Tailand.jpeg'),
    CountryItem(name: 'Turkey', image: 'Turkey.jpeg'),
    CountryItem(name: 'UAE', image: 'UAE.jpeg'),
    CountryItem(name: 'United Kingdom', image: 'UnitedKingdom.jpeg'),
    CountryItem(name: 'USA', image: 'USA.jpeg'),
    CountryItem(name: 'Vietnam', image: 'Vietnam.jpeg'),
  ];

  List<CountryItem> userCountries = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final ScrollController _scrollController = ScrollController();
  bool _showTopShadow = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _scrollController.addListener(() {
      if (_scrollController.offset > 20 && !_showTopShadow) {
        setState(() {
          _showTopShadow = true;
        });
      } else if (_scrollController.offset <= 20 && _showTopShadow) {
        setState(() {
          _showTopShadow = false;
        });
      }
    });

    _loadUserCountries();
  }

  Future<void> _loadUserCountries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Usuario no autenticado';
          _isLoading = false;
          userCountries = [];
        });
        return;
      }

      final response = await _supabase
          .from('user_characters')
          .select('characters')
          .eq('user_id', userId)
          .single();

      if (response != null && response.containsKey('characters')) {
        final List<dynamic> charactersList = response['characters'];

        if (charactersList.isNotEmpty) {
          final collectedCountryNames = charactersList
              .map((item) => (item as String).toLowerCase())
              .toSet();

          userCountries = allCountries
              .where((country) => collectedCountryNames.contains(country.name.toLowerCase()))
              .toList();
        } else {
          userCountries = [];
        }
      } else {
        userCountries = [];
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los países: $e';
        userCountries = [];
      });
      print('Error cargando países: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF004D51),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Country Collection",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF004D51),
                  const Color(0xFF1E6C71),
                  const Color(0xFF004D51).withOpacity(0.9),
                ],
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * 2 * math.pi,
                  child: child,
                );
              },
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.teal.withOpacity(0.7),
                      Colors.teal.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.tealAccent.withOpacity(0.3),
                    Colors.teal.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E6C71).withOpacity(0.9),
                            const Color(0xFF1E6C71).withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                                child: const Icon(
                                  Icons.public,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Collected",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "${userCountries.length}/${allCountries.length}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: userCountries.length == allCountries.length ? Colors.white : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: userCountries.length == allCountries.length
                                        ? [
                                            const Color(0xFFFFD700),
                                            const Color(0xFFF5DEB3),
                                            const Color(0xFFFFD700),
                                          ]
                                        : [
                                            Colors.grey.shade400,
                                            Colors.grey.shade600,
                                            Colors.grey.shade400,
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  userCountries.length == allCountries.length ? "Complete" : "In Progress",
                                  style: TextStyle(
                                    color: const Color(0xFF1E6C71),
                                    fontWeight: FontWeight.bold,
                                    fontSize: userCountries.length == allCountries.length ? 14 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : _errorMessage.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _loadUserCountries,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    child: const Text(
                                      "Reintentar",
                                      style: TextStyle(
                                        color: Color(0xFF1E6C71),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : userCountries.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.card_travel,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 64,
                                      ),
                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 32),
                                        child: Text(
                                          "¡Aún no tienes países en tu colección! Viaja para desbloquearlos.",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        ),
                                        child: const Text(
                                          "Volver al inicio",
                                          style: TextStyle(
                                            color: Color(0xFF1E6C71),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : NotificationListener<ScrollNotification>(
                                  onNotification: (scrollNotification) {
                                    if (scrollNotification is ScrollUpdateNotification) {
                                      setState(() {
                                        _showTopShadow = _scrollController.offset > 20;
                                      });
                                    }
                                    return false;
                                  },
                                  child: Stack(
                                    children: [
                                      GridView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.all(12),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                        ),
                                        itemCount: userCountries.length,
                                        itemBuilder: (context, index) {
                                          return _buildAnimatedCountryCard(userCountries[index], index);
                                        },
                                      ),
                                      if (_showTopShadow)
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 30,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  const Color(0xFF004D51).withOpacity(0.8),
                                                  const Color(0xFF004D51).withOpacity(0.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCountryCard(CountryItem country, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 500 + (index * 50)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          _showCountryDetail(country);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE8F3F3),
                const Color(0xFFE8F3F3).withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: Image.network(
                        'https://www.wenomad.us/NFT/Countries/${country.image}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFF1E6C71),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Color(0xFF1E6C71),
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.6),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E6C71).withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Text(
                  country.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryDetail(CountryItem country) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return TweenAnimationBuilder(
              duration: const Duration(milliseconds: 300),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3F3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Hero(
                      tag: 'country_${country.name}',
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            'https://www.wenomad.us/NFT/Countries/${country.image}',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        country.name,
                        style: const TextStyle(
                          color: Color(0xFF004D51),
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "This NFT country card is part of your global collection. Travel to this country to unlock special rewards and experiences!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF1E6C71),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6C71),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CountryItem {
  final String name;
  final String image;

  CountryItem({required this.name, required this.image});
}