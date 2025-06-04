import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/dialogs/map_popup.dart';
import '../widgets/dialogs/list_dialog.dart';
import '../utils/distance_utils.dart';
import '../services/local_properties_service.dart';
import '../screens/restaurant_detail_screen.dart';

class MapScreen extends StatelessWidget {
  final List<Map<String, dynamic>>? restaurants;
  
  const MapScreen({super.key, this.restaurants});

  @override
  Widget build(BuildContext context) {
    return MapScreenView(restaurants: restaurants);
  }
}

class MapScreenView extends StatefulWidget {
  final List<Map<String, dynamic>>? restaurants;
  
  const MapScreenView({super.key, this.restaurants});

  @override
  State<MapScreenView> createState() => _MapScreenViewState();
}

class _MapScreenViewState extends State<MapScreenView> {
  List<Map<String, dynamic>> _restaurants = [];
  bool _loading = true;
  String? _error;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  String? _apiKey;
  // Santa Clara, CA 95051
  double lat = 37.3467;
  double lng = -121.9842;
  
  // 添加状态管理变量
  String? _selectedRestaurantPlaceId;
  bool _showingDetails = false;
  
  // 添加取消标志
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // Load API key
    _loadApiKey();
    // 如果有传入的餐厅数据，直接使用
    if (widget.restaurants != null && widget.restaurants!.isNotEmpty) {
      setState(() {
        _restaurants = widget.restaurants!;
        _createMarkersFromRestaurants();
        _loading = false;
      });
    } else {
      // 没有传入数据时才获取位置并加载
      getCurrentLocation();
    }
  }

  Future<void> _loadApiKey() async {
    final apiKey = await LocalPropertiesService.getGoogleMapsApiKey();
    setState(() {
      _apiKey = apiKey;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    try {
      await Permission.location.request();
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return fetchNearbyRestaurants();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return fetchNearbyRestaurants();
      }
      if (permission == LocationPermission.deniedForever) return fetchNearbyRestaurants();
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 检查组件是否仍然挂载
      if (!mounted || _disposed) return;
      
      setState(() {
        lat = position.latitude;
        lng = position.longitude;
      });
      fetchNearbyRestaurants();
    } catch (e) {
      fetchNearbyRestaurants();
    }
  }

  Future<void> fetchNearbyRestaurants() async {
    // 检查组件是否仍然挂载
    if (!mounted || _disposed) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_apiKey == null) {
        await _loadApiKey();
      }
      if (_apiKey == null) {
        throw Exception('API key not available');
      }
      final url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=2000&type=restaurant&key=$_apiKey&language=en';
      final response = await http.get(Uri.parse(url));
      
      // 检查组件是否仍然挂载
      if (!mounted || _disposed) return;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        // 再次检查组件是否仍然挂载
        if (!mounted || _disposed) return;
        
        setState(() {
          _restaurants = results.map((e) => e as Map<String, dynamic>).toList();
          _markers = _restaurants.map((r) {
            final loc = r['geometry']['location'];
            return Marker(
              markerId: MarkerId(r['place_id']),
              position: LatLng(loc['lat'], loc['lng']),
              infoWindow: InfoWindow(title: r['name']),
            );
          }).toSet();
          _loading = false;
        });
      } else {
        // 检查组件是否仍然挂载
        if (!mounted || _disposed) return;
        
        setState(() {
          _error = 'Network error';
          _loading = false;
        });
      }
    } catch (e) {
      // 检查组件是否仍然挂载
      if (!mounted || _disposed) return;
      
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _moveToRestaurant(Map<String, dynamic> info) {
    final loc = info['geometry']['location'];
    _mapController?.animateCamera(CameraUpdate.newLatLng(
      LatLng(loc['lat'], loc['lng']),
    ));
  }

  void _createMarkersFromRestaurants() {
    _markers = _restaurants.map((r) {
      final loc = r['geometry']['location'];
      return Marker(
        markerId: MarkerId(r['place_id']),
        position: LatLng(loc['lat'], loc['lng']),
        infoWindow: InfoWindow(title: r['name']),
      );
    }).toSet();
    
    // 如果有餐厅数据，使用第一家餐厅的位置作为地图中心
    if (_restaurants.isNotEmpty) {
      final firstRestaurant = _restaurants.first;
      final loc = firstRestaurant['geometry']['location'];
      lat = loc['lat'];
      lng = loc['lng'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE95322),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF391713)),
          onPressed: () {
            if (_showingDetails) {
              // 如果正在显示详情，返回列表视图
              setState(() {
                _showingDetails = false;
                _selectedRestaurantPlaceId = null;
              });
            } else {
              // 如果在列表视图，返回上一页
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'What to eat today?',
          style: TextStyle(
            color: Color(0xFF391713),
            fontSize: 22,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Load failed: $_error'))
              : Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(lat, lng),
                            zoom: 13,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          markers: _markers,
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: _showingDetails && _selectedRestaurantPlaceId != null
                          ? _buildRestaurantDetail()
                          : _buildRestaurantList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRestaurantList() {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _restaurants.length,
      itemBuilder: (context, index) => _GoogleRestaurantCard(
        info: _restaurants[index],
        userLat: lat,
        userLng: lng,
        apiKey: _apiKey,
        onCardTap: () => _showRestaurantDetails(_restaurants[index]),
      ),
    );
  }

  Widget _buildRestaurantDetail() {
    final restaurant = _restaurants.firstWhere((r) => r['place_id'] == _selectedRestaurantPlaceId);
    final name = restaurant['name'] ?? '';
    final rating = restaurant['rating']?.toString() ?? '';
    final address = restaurant['vicinity'] ?? '';
    final types = restaurant['types'] as List<dynamic>? ?? [];
    
    final photoRef = (restaurant['photos'] != null && restaurant['photos'].isNotEmpty)
        ? restaurant['photos'][0]['photo_reference']
        : null;
    final imageUrl = photoRef != null && _apiKey != null
        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=$_apiKey'
        : null;
    
    return Column(
      children: [
        // 详情页面头部，包含关闭按钮
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Restaurant Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF391713),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF391713)),
                onPressed: () {
                  setState(() {
                    _showingDetails = false;
                    _selectedRestaurantPlaceId = null;
                  });
                },
              ),
            ],
          ),
        ),
        // 详情内容
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 餐厅图片
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 64),
                          ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // 餐厅名称
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF391713),
                  ),
                ),
                const SizedBox(height: 8),
                
                // 评分
                if (rating.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF391713),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                
                // 地址
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Color(0xFFE95322)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF79747E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 菜系类型
                if (types.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: types.take(3).map((type) => Chip(
                      label: Text(
                        type.toString().replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: const Color(0xFFE95322).withOpacity(0.1),
                      labelStyle: const TextStyle(color: Color(0xFFE95322)),
                    )).toList(),
                  ),
                const SizedBox(height: 24),
                
                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchMaps(restaurant),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE95322),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailScreen(
                                placeId: restaurant['place_id'],
                                initialName: name,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFE95322),
                          side: const BorderSide(color: Color(0xFFE95322)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchMaps(Map<String, dynamic> restaurant) async {
    final lat = restaurant['geometry']?['location']?['lat'];
    final lng = restaurant['geometry']?['location']?['lng'];
    if (lat != null && lng != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  void _showRestaurantDetails(Map<String, dynamic> restaurant) {
    // 先移动地图到餐厅位置
    _moveToRestaurant(restaurant);
    
    // 然后显示详情视图
    setState(() {
      _selectedRestaurantPlaceId = restaurant['place_id'];
      _showingDetails = true;
    });
  }
}

class _GoogleRestaurantCard extends StatelessWidget {
  final Map<String, dynamic> info;
  final double userLat;
  final double userLng;
  final String? apiKey;
  final VoidCallback onCardTap;
  const _GoogleRestaurantCard({
    required this.info,
    required this.userLat,
    required this.userLng,
    this.apiKey,
    required this.onCardTap,
  });
  @override
  Widget build(BuildContext context) {
    final name = info['name'] ?? '';
    final rating = info['rating']?.toString() ?? '-';
    final address = info['vicinity'] ?? '';
    final types = info['types'] as List<dynamic>? ?? [];
    
    // Get restaurant location
    final restaurantLat = info['geometry']?['location']?['lat'];
    final restaurantLng = info['geometry']?['location']?['lng'];
    
    // 尝试从餐厅名称推断菜系
    final cuisineFromName = _getCuisineFromName(name);
    final cuisineFromTypes = _getCuisineFromTypes(types);
    
    // 优先使用从名称推断的菜系，其次使用类型中的菜系
    final cuisineTypes = [
      if (cuisineFromName.isNotEmpty) cuisineFromName,
      if (cuisineFromTypes.isNotEmpty) cuisineFromTypes,
    ].take(2).join(' • ');
    
    final photoRef = (info['photos'] != null && info['photos'].isNotEmpty)
        ? info['photos'][0]['photo_reference']
        : null;
    final imageUrl = photoRef != null && apiKey != null
        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=$apiKey'
        : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onCardTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 93,
                        height: 93,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                      )
                    : const SizedBox(
                        width: 93,
                        height: 93,
                        child: Icon(Icons.image, size: 60, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          rating,
                          style: const TextStyle(
                            color: Color(0xFF79747E),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.star, color: Color(0xFFFFA500), size: 16),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      address,
                      style: const TextStyle(
                        color: Color(0xFF79747E),
                        fontSize: 12,
                        fontFamily: 'Roboto',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),                  if (cuisineTypes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant_menu,
                            size: 14,
                            color: Color(0xFFE95322),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cuisineTypes,
                              style: const TextStyle(
                                color: Color(0xFFE95322),
                                fontSize: 11,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],                  // Distance display
                    if (restaurantLat != null && restaurantLng != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DistanceUtils.calculateDistance(
                              userLat,
                              userLng,
                              restaurantLat.toDouble(),
                              restaurantLng.toDouble(),
                            ),
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Transform.rotate(
                      angle: 1.5708, // 90 degrees in radians
                      child: const Icon(Icons.navigation, color: Color(0xFFE95322)),
                    ),
                    onPressed: () {
                      final lat = info['geometry']?['location']?['lat'];
                      final lng = info['geometry']?['location']?['lng'];
                      final name = info['name'] ?? 'Restaurant';
                      final address = info['vicinity'] ?? '';
                      if (lat != null && lng != null) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => MapPopup(
                            latitude: lat.toDouble(),
                            longitude: lng.toDouble(),
                            restaurantName: name,
                            onAppleMapSelected: () async {
                              final url = 'http://maps.apple.com/?q=' + Uri.encodeComponent('$name $address');
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Couldn't open Apple Maps")),
                                );
                              }
                            },
                            onGoogleMapSelected: () async {
                              final url = 'https://www.google.com/maps/search/?api=1&query=' + Uri.encodeComponent('$name $address');
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Couldn't open Google Maps")),
                                );
                              }
                            },
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location information not available'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF391713)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ListDialog(
                          initialRestaurantLiked: false,
                          initialRestaurantDisliked: false,
                          initialCuisineLiked: false,
                          initialCuisineDisliked: false,
                          onLikeRestaurant: () {
                            // TODO: 处理喜欢餐厅
                            print('Like restaurant');
                          },
                          onDislikeRestaurant: () {
                            // TODO: 处理不喜欢餐厅
                            print('Dislike restaurant');
                          },
                          onLikeCuisine: () {
                            // TODO: 处理喜欢菜系
                            print('Like cuisine');
                          },
                          onDislikeCuisine: () {
                            // TODO: 处理不喜欢菜系
                            print('Dislike cuisine');
                          },
                          onCancel: () {
                            print('Cancel');
                          },
                          onConfirm: () {
                            print('Confirm');
                          },
                          description: 'You can mark this restaurant or cuisine as liked or disliked.',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCuisineType(String type) {
    // 将 Google Places API 的类型转换为更友好的显示名称
    final typeMap = {
      'restaurant': 'Restaurant',
      'meal_takeaway': 'Takeaway',
      'meal_delivery': 'Delivery',
      'bakery': 'Bakery',
      'bar': 'Bar',
      'cafe': 'Cafe',
      'night_club': 'Night Club',
      'chinese_restaurant': 'Chinese',
      'japanese_restaurant': 'Japanese',
      'korean_restaurant': 'Korean',
      'italian_restaurant': 'Italian',
      'french_restaurant': 'French',
      'mexican_restaurant': 'Mexican',
      'indian_restaurant': 'Indian',
      'thai_restaurant': 'Thai',
      'vietnamese_restaurant': 'Vietnamese',
      'american_restaurant': 'American',
      'mediterranean_restaurant': 'Mediterranean',
      'pizza_restaurant': 'Pizza',
      'seafood_restaurant': 'Seafood',
      'steakhouse': 'Steakhouse',
      'sushi_restaurant': 'Sushi',
      'fast_food_restaurant': 'Fast Food',
      'sandwich_shop': 'Sandwich',
      'ice_cream_shop': 'Ice Cream',
      'liquor_store': 'Liquor Store',
    };

    return typeMap[type] ?? type.replaceAll('_', ' ').toUpperCase();
  }

  String _getCuisineFromName(String name) {
    final lowerName = name.toLowerCase();
    
    // 根据餐厅名称中的关键词推断菜系
    final cuisineKeywords = {
      'chinese': ['chinese', 'china', 'beijing', 'shanghai', 'sichuan', 'szechuan', 'cantonese', 'dim sum', 'wok', 'dumpling', 'noodle house', 'panda', 'dragon', 'golden', 'lucky', 'mandarin'],
      'japanese': ['japanese', 'japan', 'sushi', 'ramen', 'tokyo', 'osaka', 'sakura', 'tempura', 'bento', 'izakaya', 'yakitori', 'teppanyaki', 'hibachi'],
      'korean': ['korean', 'korea', 'bbq', 'seoul', 'kimchi', 'bulgogi', 'bibimbap', 'grill'],
      'italian': ['italian', 'italy', 'pizza', 'pasta', 'pizzeria', 'ristorante', 'trattoria', 'osteria', 'roma', 'milano', 'venice', 'napoli'],
      'mexican': ['mexican', 'mexico', 'taco', 'burrito', 'cantina', 'casa', 'el ', 'la ', 'mariachi', 'azteca', 'guadalajara'],
      'thai': ['thai', 'thailand', 'pad', 'tom', 'bangkok', 'royal', 'elephant', 'orchid'],
      'vietnamese': ['vietnamese', 'vietnam', 'pho', 'banh', 'saigon', 'hanoi'],
      'indian': ['indian', 'india', 'curry', 'tandoor', 'naan', 'biryani', 'masala', 'punjabi', 'bombay', 'delhi'],
      'french': ['french', 'france', 'bistro', 'brasserie', 'cafe', 'paris', 'lyon', 'provence'],
      'american': ['american', 'grill', 'diner', 'steakhouse', 'burger', 'bbq', 'wings'],
      'mediterranean': ['mediterranean', 'greek', 'gyro', 'falafel', 'hummus', 'olive', 'santorini'],
      'seafood': ['seafood', 'fish', 'crab', 'lobster', 'oyster', 'shrimp', 'clam'],
    };
    
    for (final entry in cuisineKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerName.contains(keyword)) {
          return _formatCuisineDisplay(entry.key);
        }
      }
    }
    
    return '';
  }

  String _getCuisineFromTypes(List<dynamic> types) {
    // 从 Google Places types 中提取有意义的菜系信息
    final meaningfulTypes = <String>[];
    
    for (final type in types) {
      final typeStr = type.toString();
      if (!['establishment', 'point_of_interest', 'food', 'restaurant'].contains(typeStr)) {
        if (typeStr.contains('restaurant') || typeStr.contains('cuisine')) {
          meaningfulTypes.add(_formatCuisineType(typeStr));
        } else if (['bakery', 'cafe', 'bar', 'meal_takeaway', 'meal_delivery'].contains(typeStr)) {
          meaningfulTypes.add(_formatCuisineType(typeStr));
        }
      }
    }
    
    return meaningfulTypes.isNotEmpty ? meaningfulTypes.first : '';
  }
  
  String _formatCuisineDisplay(String cuisine) {
    final displayMap = {
      'chinese': 'Chinese',
      'japanese': 'Japanese',
      'korean': 'Korean',
      'italian': 'Italian',
      'mexican': 'Mexican',
      'thai': 'Thai',
      'vietnamese': 'Vietnamese',
      'indian': 'Indian',
      'french': 'French',
      'american': 'American',
      'mediterranean': 'Mediterranean',
      'seafood': 'Seafood',
    };
    
    return displayMap[cuisine] ?? cuisine.toUpperCase();
  }
}