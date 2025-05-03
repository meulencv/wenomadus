import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> with TickerProviderStateMixin {
  // Changed from SingleTickerProviderStateMixin to TickerProviderStateMixin
  late AnimationController _animationController;
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  // Collection categories
  final List<String> _categories = ['Countries', 'Food', 'Stamps'];

  // Define collectibles for each category
  final List<CollectibleItem> countriesItems = [
    CollectibleItem(name: 'Argentina', image: 'Argentina.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Australia', image: 'Australia.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Brazil', image: 'Brazil.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Canada', image: 'Canada.jpeg', category: 'Countries'),
    CollectibleItem(name: 'China', image: 'China.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Egypt', image: 'Egypt.jpeg', category: 'Countries'),
    CollectibleItem(name: 'France', image: 'France.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Greece', image: 'Grece.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Iceland', image: 'Iceland.jpeg', category: 'Countries'),
    CollectibleItem(name: 'India', image: 'India.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Indonesia', image: 'Indonesia.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Italy', image: 'Italy.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Japan', image: 'Japan.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Mexico', image: 'Mexico.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Morocco', image: 'Morocco.jpeg', category: 'Countries'),
    CollectibleItem(name: 'New Zealand', image: 'NewZealand.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Peru', image: 'Peru.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Portugal', image: 'Portugal.jpeg', category: 'Countries'),
    CollectibleItem(name: 'South Africa', image: 'SouthAfrica.jpeg', category: 'Countries'),
    CollectibleItem(name: 'South Korea', image: 'SouthKorea.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Spain', image: 'Spain.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Thailand', image: 'Tailand.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Turkey', image: 'Turkey.jpeg', category: 'Countries'),
    CollectibleItem(name: 'UAE', image: 'UAE.jpeg', category: 'Countries'),
    CollectibleItem(name: 'United Kingdom', image: 'UnitedKingdom.jpeg', category: 'Countries'),
    CollectibleItem(name: 'USA', image: 'USA.jpeg', category: 'Countries'),
    CollectibleItem(name: 'Vietnam', image: 'Vietnam.jpeg', category: 'Countries'),
  ];

  final List<CollectibleItem> foodItems = [
    CollectibleItem(name: 'Calcot Shiny', image: 'CalcotShiny.jpeg', category: 'Food', rarity: 'Shiny'),
  ];

  final List<CollectibleItem> stampsItems = [
    CollectibleItem(name: 'MNAC Barcelona', image: 'MNACBarcelonaCommon.jpeg', category: 'Stamps', rarity: 'Common'),
    CollectibleItem(name: 'Tibidabo Barcelona', image: 'TibidaboBarcelonaCommon.jpeg', category: 'Stamps', rarity: 'Common'),
    CollectibleItem(name: 'Tibidabo Barcelona Rare', image: 'TibidaboBarcelonaRare.jpeg', category: 'Stamps', rarity: 'Rare'),
    CollectibleItem(name: 'Tokyo Disneyland', image: 'TokyoDisneylandCommon.jpeg', category: 'Stamps', rarity: 'Common'),
    CollectibleItem(name: 'Tokyo Imperial Castle', image: 'TokyoImperialCastleRare.jpeg', category: 'Stamps', rarity: 'Rare'),
    CollectibleItem(name: 'Tokyo Imperial Castle Shiny', image: 'TokyoImperialCastleSHINY.jpeg', category: 'Stamps', rarity: 'Shiny'),
  ];

  // Map to hold all collectible items by category
  late Map<String, List<CollectibleItem>> collectiblesByCategory;

  // Set of collected item names by category
  Map<String, Set<String>> collectedItemsByCategory = {
    'Countries': {},
    'Food': {},
    'Stamps': {}
  };

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

    _tabController = TabController(length: _categories.length, vsync: this);

    // Initialize collectibles map
    collectiblesByCategory = {
      'Countries': countriesItems,
      'Food': foodItems,
      'Stamps': stampsItems,
    };

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

    _loadUserCollectibles();
  }

  Future<void> _loadUserCollectibles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      collectedItemsByCategory = {
        'Countries': {},
        'Food': {},
        'Stamps': {}
      };
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      try {
        final response = await _supabase
            .from('user_characters')
            .select('characters')
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null && response.containsKey('characters')) {
          final List<dynamic> charactersList = response['characters'];

          if (charactersList.isNotEmpty) {
            // Process the collected items
            for (var item in charactersList) {
              String itemName = (item as String).toLowerCase();

              // Determine which category this item belongs to
              bool found = false;
              for (String category in _categories) {
                for (CollectibleItem collectible in collectiblesByCategory[category]!) {
                  if (collectible.name.toLowerCase() == itemName) {
                    collectedItemsByCategory[category]!.add(itemName);
                    found = true;
                    break;
                  }
                }
                if (found) break;
              }
            }
          }
        }
      } catch (e) {
        print('Error in query: $e');
        if (!e.toString().contains('no rows returned') && !e.toString().contains('not found')) {
          setState(() {
            _errorMessage = 'Error loading collections: $e';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading collections: $e';
      });
      print('Error loading collections: $e');
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
    _tabController.dispose();
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
          "Collectibles Gallery",
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabController,
              // Remove the indicator completely since we'll handle it with tab decoration
              indicator: const BoxDecoration(
                color: Colors.transparent,
              ),
              labelColor: const Color(0xFF004D51),
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              // Don't add padding in TabBar, we'll handle it in each tab
              indicatorPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: List.generate(_categories.length, (index) {
                return Container(
                  decoration: BoxDecoration(
                    color: _tabController.index == index 
                        ? Colors.white 
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      color: _tabController.index == index 
                          ? const Color(0xFF004D51)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }),
              onTap: (_) {
                setState(() {}); // Refresh UI on tab change
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient and decorations
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

          // Animated decorative elements
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

          // Tab content
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 106), // Adjust for AppBar + TabBar
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return _buildCategoryTab(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String category) {
    final items = collectiblesByCategory[category] ?? [];
    final collectedItems = collectedItemsByCategory[category] ?? {};

    return Column(
      children: [
        // Stats container at the top
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
                        child: Icon(
                          _getCategoryIcon(category),
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
                            "${collectedItems.length}/${items.length}",
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
                      color: collectedItems.length == items.length ? Colors.white : Colors.white.withOpacity(0.7),
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
                            colors: collectedItems.length == items.length
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
                          collectedItems.length == items.length ? "Complete" : "In Progress",
                          style: TextStyle(
                            color: const Color(0xFF1E6C71),
                            fontWeight: FontWeight.bold,
                            fontSize: collectedItems.length == items.length ? 14 : 12,
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

        // Grid of collectible items
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : _errorMessage.isNotEmpty
                  ? _buildErrorMessage()
                  : items.isEmpty
                      ? _buildEmptyMessage(category)
                      : _buildCollectiblesGrid(items, collectedItems, category),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Center(
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
            onPressed: _loadUserCollectibles,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              "Retry",
              style: TextStyle(
                color: Color(0xFF1E6C71),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(category),
            color: Colors.white.withOpacity(0.7),
            size: 64,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "No $category found in this collection. More will be added soon!",
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
              "Back to Home",
              style: TextStyle(
                color: Color(0xFF1E6C71),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectiblesGrid(List<CollectibleItem> items, Set<String> collectedItems, String category) {
    // Sort items: first collected (alphabetically), then uncollected (alphabetically)
    final sortedItems = [...items];
    sortedItems.sort((a, b) {
      // Check if a is collected and b is not
      final isACollected = collectedItems.contains(a.name.toLowerCase());
      final isBCollected = collectedItems.contains(b.name.toLowerCase());
      
      if (isACollected && !isBCollected) {
        return -1; // a comes first
      } else if (!isACollected && isBCollected) {
        return 1; // b comes first
      } else {
        // Both are collected or both are uncollected, sort alphabetically
        return a.name.compareTo(b.name);
      }
    });

    return NotificationListener<ScrollNotification>(
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
            itemCount: sortedItems.length,
            itemBuilder: (context, index) {
              final item = sortedItems[index];
              final isCollected = collectedItems.contains(item.name.toLowerCase());
              return _buildAnimatedCollectibleCard(item, index, isCollected);
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
    );
  }

  Widget _buildAnimatedCollectibleCard(CollectibleItem item, int index, bool isCollected) {
    // Get rarity-based colors for special items
    final (cardColor, borderColor, glowColor) = _getRarityColors(item.rarity);

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
          _showCollectibleDetail(item, isCollected);
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCollected
                      ? cardColor
                      : [
                          Colors.grey.shade200,
                          Colors.grey.shade300,
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
                  if (isCollected && item.rarity == 'Shiny')
                    BoxShadow(
                      color: glowColor,
                      spreadRadius: 1,
                      blurRadius: 12,
                    ),
                ],
                border: Border.all(
                  color: isCollected
                      ? borderColor
                      : Colors.grey.withOpacity(0.3),
                  width: isCollected && item.rarity != null ? 2 : 1,
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
                          child: ColorFiltered(
                            colorFilter: ColorFilter.matrix(
                              isCollected
                                  ? [
                                      1, 0, 0, 0, 0,
                                      0, 1, 0, 0, 0,
                                      0, 0, 1, 0, 0,
                                      0, 0, 0, 1, 0,
                                    ]
                                  : [
                                      0.5, 0, 0, 0, 0,
                                      0, 0.5, 0, 0, 0,
                                      0, 0, 0.5, 0, 0,
                                      0, 0, 0, 1, 0,
                                    ],
                            ),
                            child: Image.network(
                              'https://www.wenomad.us/NFT/${item.category}/${item.image}',
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
                        ),
                        // Special effect for shiny collectibles
                        if (isCollected && item.rarity == 'Shiny')
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment(_animationController.value * 2 - 1, 0),
                                      end: Alignment(_animationController.value * 2, 1),
                                      colors: [
                                        Colors.white.withOpacity(0),
                                        Colors.white.withOpacity(0.3),
                                        Colors.white.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (isCollected)
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
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (!isCollected)
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        // Rarity badge
                        if (item.rarity != null && isCollected)
                          Positioned(
                            top: 5,
                            left: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRarityBadgeColor(item.rarity),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 3,
                                  )
                                ],
                              ),
                              child: Text(
                                item.rarity ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
                      color: isCollected
                          ? const Color(0xFF1E6C71).withOpacity(0.8)
                          : Colors.grey.withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      item.name,
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
            if (isCollected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF1E6C71),
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCollectibleDetail(CollectibleItem item, bool isCollected) {
    final (_, _, glowColor) = _getRarityColors(item.rarity);

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
                      tag: 'collectible_${item.category}_${item.name}',
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
                            if (isCollected && item.rarity == 'Shiny')
                              BoxShadow(
                                color: glowColor,
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                          ],
                          border: isCollected && item.rarity == 'Shiny'
                              ? Border.all(color: glowColor, width: 2)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ColorFiltered(
                                colorFilter: ColorFilter.matrix(
                                  isCollected
                                      ? [
                                          1, 0, 0, 0, 0,
                                          0, 1, 0, 0, 0,
                                          0, 0, 1, 0, 0,
                                          0, 0, 0, 1, 0,
                                        ]
                                      : [
                                          0.5, 0, 0, 0, 0,
                                          0, 0.5, 0, 0, 0,
                                          0, 0, 0.5, 0, 0,
                                          0, 0, 0, 1, 0,
                                        ],
                                ),
                                child: Image.network(
                                  'https://www.wenomad.us/NFT/${item.category}/${item.image}',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            // Animated shine effect for Shiny items
                            if (isCollected && item.rarity == 'Shiny')
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: LinearGradient(
                                          begin: Alignment(_animationController.value * 2 - 1, 0),
                                          end: Alignment(_animationController.value * 2, 1),
                                          colors: [
                                            Colors.white.withOpacity(0),
                                            Colors.white.withOpacity(0.3),
                                            Colors.white.withOpacity(0),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (item.rarity != null && isCollected)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRarityBadgeColor(item.rarity).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: _getRarityBadgeColor(item.rarity), width: 1),
                        ),
                        child: Text(
                          "${item.rarity} Collectible",
                          style: TextStyle(
                            color: _getRarityBadgeColor(item.rarity),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (!isCollected)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Not Collected Yet",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isCollected)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Collected",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: Color(0xFF004D51),
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _getCollectibleDescription(item, isCollected),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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

  // Helper methods
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Countries':
        return Icons.public;
      case 'Food':
        return Icons.restaurant;
      case 'Stamps':
        return Icons.bookmark;
      default:
        return Icons.collections;
    }
  }

  Color _getRarityBadgeColor(String? rarity) {
    if (rarity == null) return Colors.grey;

    switch (rarity) {
      case 'Common':
        return Colors.blue;
      case 'Rare':
        return Colors.purple;
      case 'Shiny':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  (List<Color>, Color, Color) _getRarityColors(String? rarity) {
    if (rarity == null) {
      return (
        [const Color(0xFFE8F3F3), const Color(0xFFE8F3F3).withOpacity(0.95)],
        Colors.white.withOpacity(0.5),
        Colors.transparent
      );
    }

    switch (rarity) {
      case 'Common':
        return (
          [const Color(0xFFE8F3F3), const Color(0xFFE8F3F3).withOpacity(0.95)],
          Colors.blueAccent.withOpacity(0.5),
          Colors.blue.withOpacity(0.3)
        );
      case 'Rare':
        return (
          [const Color(0xFFF1E6FF), const Color(0xFFF1E6FF).withOpacity(0.95)],
          Colors.purpleAccent.withOpacity(0.5),
          Colors.purple.withOpacity(0.3)
        );
      case 'Shiny':
        return (
          [const Color(0xFFFFF8E1), const Color(0xFFFFF8E1).withOpacity(0.95)],
          Colors.amber.withOpacity(0.5),
          Colors.amber.withOpacity(0.3)
        );
      default:
        return (
          [const Color(0xFFE8F3F3), const Color(0xFFE8F3F3).withOpacity(0.95)],
          Colors.white.withOpacity(0.5),
          Colors.transparent
        );
    }
  }

  String _getCollectibleDescription(CollectibleItem item, bool isCollected) {
    // Base description based on category
    String baseDescription = '';
    switch (item.category) {
      case 'Countries':
        baseDescription = isCollected
            ? "Congratulations! You have collected the ${item.name} NFT card for your global collection."
            : "Travel to ${item.name} to unlock this NFT country card for your global collection.";
        break;
      case 'Food':
        baseDescription = isCollected
            ? "You've added this delicious ${item.name} to your culinary collection!"
            : "Try this local delicacy to add it to your food collection.";
        break;
      case 'Stamps':
        baseDescription = isCollected
            ? "You've stamped your journey with this beautiful ${item.name} collectible!"
            : "Visit this landmark to collect this special stamp.";
        break;
      default:
        baseDescription = isCollected
            ? "You've added this item to your collection!"
            : "Explore to unlock this collectible.";
    }

    // Add rarity-based description
    String rarityDescription = '';
    if (item.rarity != null) {
      switch (item.rarity) {
        case 'Common':
          rarityDescription = isCollected
              ? " This common collectible is a fine addition to your gallery."
              : " This is a common collectible that you can easily find.";
          break;
        case 'Rare':
          rarityDescription = isCollected
              ? " This rare collectible is an impressive find that few travelers have acquired!"
              : " This rare collectible is harder to find and worth the search.";
          break;
        case 'Shiny':
          rarityDescription = isCollected
              ? " This SHINY collectible is an extraordinary treasure that only the most dedicated explorers have found!"
              : " This ultra-rare SHINY collectible is a true treasure that few have discovered.";
          break;
      }
    }

    return baseDescription + rarityDescription + (isCollected ? " Enjoy the special rewards and experiences it unlocks!" : " Begin your adventure to add it to your collection!");
  }
}

class CollectibleItem {
  final String name;
  final String image;
  final String category;
  final String? rarity;

  CollectibleItem({
    required this.name,
    required this.image,
    required this.category,
    this.rarity,
  });
}