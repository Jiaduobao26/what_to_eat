import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/restaurant_list_bloc.dart';
import '../widgets/dialogs/map_popup.dart';
import '../widgets/dialogs/list_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../repositories/user_preference_repository.dart';
import '../models/preference.dart' as pref_models;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/nearby_restaurant_provider.dart';
import 'package:provider/provider.dart';
import '../utils/distance_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_properties_service.dart';

class Lists extends StatelessWidget {
  final Function(List<Map<String, dynamic>>)? onRestaurantsChanged;
  
  const Lists({super.key, this.onRestaurantsChanged});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RestaurantListBloc(),
      child: ListsView(onRestaurantsChanged: onRestaurantsChanged),
    );
  }
}

class ListsView extends StatefulWidget {
  final Function(List<Map<String, dynamic>>)? onRestaurantsChanged;
  
  const ListsView({super.key, this.onRestaurantsChanged});

  @override
  State<ListsView> createState() => _ListsViewState();
}

class _ListsViewState extends State<ListsView> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _allRestaurants = []; // Store all restaurants for filtering
  bool _loading = true;
  String? _error;
  String? _nextPageToken;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasLoaded = false;
  NearbyRestaurantProvider? _provider; // 保存Provider引用
    // Distance filter variables
  double _selectedDistance = 10.0; // Default 10 miles
  final TextEditingController _customDistanceController = TextEditingController();
  final List<double> _presetDistances = [2.0, 5.0, 10.0]; // Preset distance options

  // API key from configuration file
  String? _apiKey;
  // Santa Clara, CA 95051
  double lat = 37.3467;
  double lng = -121.9842;

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    
    // Load API key from configuration
    _loadApiKey();
    
    // 设置滚动监听器
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        print('Scroll reached bottom: nextPageToken=$_nextPageToken, isLoadingMore=$_isLoadingMore');
        if (_nextPageToken != null && !_isLoadingMore) {
          print('Triggering load more...');
          fetchNearbyRestaurants(loadMore: true);
        }
      }
    });
    
    // 首先检查Provider中是否已有数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = Provider.of<NearbyRestaurantProvider>(context, listen: false);
      if (_provider!.hasLoaded && _provider!.restaurants.isNotEmpty && !_hasLoaded) {
        // 使用Provider中的数据
        setState(() {
          _allRestaurants = _provider!.restaurants;
          lat = _provider!.lat;
          lng = _provider!.lng;
          _loading = false;
          _hasLoaded = true;
        });
        
        // Apply distance filter
        _filterRestaurantsByDistance();
      } else if (!_hasLoaded) {
        // Provider中没有数据，开始加载
        _startBackgroundLoading();
        _hasLoaded = true;
      }
      
      // 监听Provider数据变化
      _provider!.addListener(_onProviderDataChanged);
    });
  }
  @override
  void dispose() {
    _scrollController.dispose();
    _customDistanceController.dispose();
    // 使用保存的Provider引用，安全地移除listener
    _provider?.removeListener(_onProviderDataChanged);
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await LocalPropertiesService.getGoogleMapsApiKey();
    setState(() {
      _apiKey = apiKey;
    });
  }

  void _onProviderDataChanged() {
    if (_provider != null && _provider!.hasLoaded && _provider!.restaurants.isNotEmpty && mounted) {
      setState(() {
        _allRestaurants = _provider!.restaurants;
        lat = _provider!.lat;
        lng = _provider!.lng;
        _loading = false;
        _hasLoaded = true;
        _error = _provider!.error;
      });
      
      // Apply distance filter
      _filterRestaurantsByDistance();
      
      // 通知父组件餐厅数据已更新
      widget.onRestaurantsChanged?.call(_restaurants);
    }
  }

  void _filterRestaurantsByDistance() {
    print('Filtering by distance: selectedDistance=$_selectedDistance, allRestaurants=${_allRestaurants.length}');
    if (_allRestaurants.isEmpty) return;
    
    final filteredRestaurants = _allRestaurants.where((restaurant) {
      final restaurantLat = restaurant['geometry']?['location']?['lat'];
      final restaurantLng = restaurant['geometry']?['location']?['lng'];
      
      if (restaurantLat == null || restaurantLng == null) {
        return true; // Include restaurants without location data
      }
      
      final distance = DistanceUtils.calculateDistanceInMiles(
        lat,
        lng,
        restaurantLat.toDouble(),
        restaurantLng.toDouble(),
      );
      
      return distance <= _selectedDistance;
    }).toList();
    
    print('After distance filter: ${filteredRestaurants.length} restaurants');
    
    setState(() {
      _restaurants = filteredRestaurants;
    });
    
    // 通知父组件餐厅数据已更新
    widget.onRestaurantsChanged?.call(_restaurants);
    
    // If filtered results are too few and we have more data to load, try to load more restaurants
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_restaurants.length < 10 && _nextPageToken != null && !_isLoadingMore && mounted) {
        print('Filtered results too few (${_restaurants.length}), loading more...');
        fetchNearbyRestaurants(loadMore: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('加载失败:\n$_error'))
              : Column(
                  children: [
                    // Distance filter UI
                    _buildDistanceFilter(),
                    // Restaurant list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          // 重置Provider状态
                          _provider?.reset();
                          
                          // 重置本地状态
                          _hasLoaded = false;
                          _restaurants.clear();
                          _allRestaurants.clear();
                          _nextPageToken = null;
                          
                          // 重新开始预加载
                          await _provider?.preloadRestaurants();
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                          itemCount: _restaurants.length + (_nextPageToken != null ? 1 : 0),
                          itemBuilder: (context, index) {                            if (index < _restaurants.length) {
                              return _GoogleRestaurantCard(
                                info: _restaurants[index],
                                apiKey: _apiKey,
                              );
                            } else {
                              // 加载更多loading
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> fetchNearbyRestaurants({bool loadMore = false}) async {
    print('fetchNearbyRestaurants called: loadMore=$loadMore, nextPageToken=$_nextPageToken, isLoadingMore=$_isLoadingMore');
    if (loadMore && (_nextPageToken == null || _isLoadingMore)) {
      print('Early return: nextPageToken=$_nextPageToken, isLoadingMore=$_isLoadingMore');
      return;
    }
    if (!mounted) return;
    setState(() {
      if (!loadMore) _loading = true;
      _error = null;
      if (loadMore) _isLoadingMore = true;
    });    try {
      // Ensure API key is loaded before making the request
      if (_apiKey == null) {
        await _loadApiKey();
      }
      
      if (_apiKey == null) {
        throw Exception('API key not available');
      }
      
      String url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=2000&type=restaurant&key=$_apiKey&language=en';
      if (loadMore && _nextPageToken != null) {
        url += '&pagetoken=$_nextPageToken';
      }
      print('Fetching URL: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        print('API response: ${results.length} restaurants, nextPageToken=${data['next_page_token']}');
        
        // 过滤用户不喜欢的餐厅和菜系
        final filteredResults = await _filterDislikedRestaurants(results.map((e) => e as Map<String, dynamic>).toList());
        print('After filtering: ${filteredResults.length} restaurants');
          if (!mounted) return;
        setState(() {
          if (loadMore) {
            _allRestaurants.addAll(filteredResults);
          } else {
            _allRestaurants = filteredResults;
          }
          _nextPageToken = data['next_page_token'];
          _loading = false;
          _isLoadingMore = false;
        });
        
        print('Updated state: allRestaurants=${_allRestaurants.length}, nextPageToken=$_nextPageToken');
        
        // Apply distance filter to update displayed restaurants
        _filterRestaurantsByDistance();
        
        // 更新 Provider
        _provider?.updateRestaurants(_allRestaurants);
      } else {
        print('HTTP error: ${response.statusCode}');
        if (!mounted) return;
        setState(() {
          _error = '网络错误';
          _loading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('fetchNearbyRestaurants error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      print('getCurrentLocation: start');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('getCurrentLocation: serviceEnabled = $serviceEnabled');
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      print('getCurrentLocation: permission = $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('getCurrentLocation: requestPermission = $permission');
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      print('getCurrentLocation: position = $position');
      if (!mounted) return;
      setState(() {
        lat = position.latitude;
        lng = position.longitude;
      });
      fetchNearbyRestaurants();
    } catch (e) {
      print('getCurrentLocation error: $e');
      // 定位失败，继续用默认值
      fetchNearbyRestaurants();
    }
  }

  Future<List<Map<String, dynamic>>> _filterDislikedRestaurants(List<Map<String, dynamic>> restaurants) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return restaurants;

    try {
      final repo = UserPreferenceRepository();
      final pref = await repo.fetchPreference(user.uid);
      if (pref == null) return restaurants;

      final dislikedRestaurantIds = pref.dislikedRestaurantIds;
      final dislikedCuisines = pref.dislikedCuisines;

      return restaurants.where((restaurant) {
        final placeId = restaurant['place_id'] as String? ?? '';
        final types = restaurant['types'] as List<dynamic>? ?? [];
        
        // 检查餐厅是否在不喜欢列表中
        if (dislikedRestaurantIds.contains(placeId)) {
          return false;
        }
        
        // 检查菜系是否在不喜欢列表中
        for (final type in types) {
          if (dislikedCuisines.contains(type.toString())) {
            return false;
          }
        }
        
        return true;
      }).toList();
    } catch (e) {
      print('_filterDislikedRestaurants error: $e');
      return restaurants; // 如果过滤失败，返回原始列表
    }
  }

  Widget _buildDistanceFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: Color(0xFFE95322)),
              const SizedBox(width: 8),
              Text(
                'Within ${_selectedDistance == _selectedDistance.toInt() ? _selectedDistance.toInt() : _selectedDistance} miles',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Preset distance buttons
              ..._presetDistances.map((distance) {
                final isSelected = _selectedDistance == distance;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDistance = distance;
                      });
                      _filterRestaurantsByDistance();
                      
                      // Show a brief feedback to user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Filtering restaurants within ${distance.toInt()} miles'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE95322) : Colors.white,
                        border: Border.all(
                          color: isSelected ? const Color(0xFFE95322) : const Color(0xFFD1D5DB),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${distance.toInt()} mi',
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              // Custom input button
              GestureDetector(
                onTap: _showCustomDistanceDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _presetDistances.contains(_selectedDistance) ? Colors.white : const Color(0xFFE95322),
                    border: Border.all(
                      color: _presetDistances.contains(_selectedDistance) ? const Color(0xFFD1D5DB) : const Color(0xFFE95322),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: _presetDistances.contains(_selectedDistance) ? const Color(0xFF6B7280) : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Custom',
                        style: TextStyle(
                          color: _presetDistances.contains(_selectedDistance) ? const Color(0xFF6B7280) : Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
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
    );
  }

  void _showCustomDistanceDialog() {
    _customDistanceController.text = _selectedDistance.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Custom Distance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customDistanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Distance (miles)',
                border: OutlineInputBorder(),
                suffixText: 'mi',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final customDistance = double.tryParse(_customDistanceController.text);
              if (customDistance != null && customDistance > 0) {
                setState(() {
                  _selectedDistance = customDistance;
                });
                _filterRestaurantsByDistance();
                Navigator.pop(context);
                
                // Show feedback to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Filtering restaurants within ${customDistance == customDistance.toInt() ? customDistance.toInt() : customDistance} miles'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid distance')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE95322),
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  // 后台加载方法，不会显示loading状态给用户
  Future<void> _startBackgroundLoading() async {
    try {
      await getCurrentLocation();
    } catch (e) {
      print('Background loading error: $e');
      // 即使出错也继续，使用默认位置
      await fetchNearbyRestaurants();
    }
  }
}

class _GoogleRestaurantCard extends StatelessWidget {
  final Map<String, dynamic> info;
  final String? apiKey;
  
  const _GoogleRestaurantCard({
    required this.info,
    this.apiKey,
  });

  Future<bool> _isLikedRestaurant(String userId, String placeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Guest user - check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final likedRestaurantsStr = prefs.getStringList('guest_liked_restaurants') ?? [];
      return likedRestaurantsStr.any((str) {
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          return map['id'] == placeId;
        } catch (e) {
          return str == placeId; // Fallback for old format
        }
      });
    }
    
    final repo = UserPreferenceRepository();
    final pref = await repo.fetchPreference(userId);
    return pref?.likedRestaurantIds.contains(placeId) ?? false;
  }

  Future<bool> _isDislikedRestaurant(String userId, String placeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Guest user - check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final dislikedRestaurantsStr = prefs.getStringList('guest_disliked_restaurants') ?? [];
      return dislikedRestaurantsStr.any((str) {
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          return map['id'] == placeId;
        } catch (e) {
          return str == placeId; // Fallback for old format
        }
      });
    }
    
    final repo = UserPreferenceRepository();
    final pref = await repo.fetchPreference(userId);
    return pref?.dislikedRestaurantIds.contains(placeId) ?? false;
  }

  Future<bool> _isLikedCuisine(String userId, String cuisine) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Guest user - check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final likedCuisines = prefs.getStringList('guest_liked_cuisines') ?? [];
      return likedCuisines.contains(cuisine);
    }
    
    final repo = UserPreferenceRepository();
    final pref = await repo.fetchPreference(userId);
    return pref?.likedCuisines.contains(cuisine) ?? false;
  }

  Future<bool> _isDislikedCuisine(String userId, String cuisine) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Guest user - check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final dislikedCuisines = prefs.getStringList('guest_disliked_cuisines') ?? [];
      return dislikedCuisines.contains(cuisine);
    }
    
    final repo = UserPreferenceRepository();
    final pref = await repo.fetchPreference(userId);
    return pref?.dislikedCuisines.contains(cuisine) ?? false;
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
                      color: Color(0xFF391713),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (address.isNotEmpty)
                    Text(
                      address,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  if (types.isNotEmpty)
                    Text(
                      types.join(', '),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
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
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => MapPopup(
                        onAppleMapSelected: () {
                          // 处理 Apple Map 选择
                          print('Apple Map selected');
                        },
                        onGoogleMapSelected: () {
                          // 处理 Google Map 选择
                          print('Google Map selected');
                        },
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF391713)),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    final placeId = info['place_id'] ?? '';
                    final cuisine = (info['types'] != null && info['types'].isNotEmpty) ? info['types'][0] : '';
                    
                    bool likedRestaurant = false;
                    bool dislikedRestaurant = false;
                    bool likedCuisine = false;
                    bool dislikedCuisine = false;
                    
                    // Check preferences for both authenticated and guest users
                    if (user != null) {
                      likedRestaurant = await _isLikedRestaurant(user.uid, placeId);
                      dislikedRestaurant = await _isDislikedRestaurant(user.uid, placeId);
                      likedCuisine = await _isLikedCuisine(user.uid, cuisine);
                      dislikedCuisine = await _isDislikedCuisine(user.uid, cuisine);
                    } else {
                      // Guest user - pass empty string as userId, functions handle guest logic internally
                      likedRestaurant = await _isLikedRestaurant('', placeId);
                      dislikedRestaurant = await _isDislikedRestaurant('', placeId);
                      likedCuisine = await _isLikedCuisine('', cuisine);
                      dislikedCuisine = await _isDislikedCuisine('', cuisine);
                    }

                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (context) => ListDialog(
                        initialRestaurantLiked: likedRestaurant,
                        initialRestaurantDisliked: dislikedRestaurant,
                        initialCuisineLiked: likedCuisine,
                        initialCuisineDisliked: dislikedCuisine,
                        onLikeRestaurant: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (info['place_id'] != null && info['name'] != null) {
                            if (user != null) {
                              // Authenticated user - save to Firebase
                              final repo = UserPreferenceRepository();
                              final pref = await repo.fetchPreference(user.uid) ?? 
                                  pref_models.Preference(userId: user.uid);
                              
                              // 创建餐厅信息对象
                              final restaurantInfo = pref_models.RestaurantInfo(
                                id: info['place_id'],
                                name: info['name'],
                                address: info['vicinity'],
                                lat: info['geometry']?['location']?['lat']?.toDouble(),
                                lng: info['geometry']?['location']?['lng']?.toDouble(),
                                types: (info['types'] as List?)?.map((e) => e.toString()).toList(),
                              );
                              
                              // 添加到喜欢列表，从不喜欢列表移除
                              final updatedLiked = List<pref_models.RestaurantInfo>.from(pref.likedRestaurants);
                              final updatedDisliked = List<pref_models.RestaurantInfo>.from(pref.dislikedRestaurants);
                              
                              // 移除重复项
                              updatedLiked.removeWhere((r) => r.id == restaurantInfo.id);
                              updatedDisliked.removeWhere((r) => r.id == restaurantInfo.id);
                              
                              // 添加到喜欢列表
                              updatedLiked.add(restaurantInfo);
                              
                              final updatedPref = pref_models.Preference(
                                userId: user.uid,
                                likedRestaurants: updatedLiked,
                                dislikedRestaurants: updatedDisliked,
                                likedCuisines: pref.likedCuisines,
                                dislikedCuisines: pref.dislikedCuisines,
                              );
                              
                              await repo.setPreference(updatedPref);
                            } else {
                              // Guest user - save to SharedPreferences
                              final prefs = await SharedPreferences.getInstance();
                              final restaurantInfo = pref_models.RestaurantInfo(
                                id: info['place_id'],
                                name: info['name'],
                                address: info['vicinity'],
                                lat: info['geometry']?['location']?['lat']?.toDouble(),
                                lng: info['geometry']?['location']?['lng']?.toDouble(),
                                types: (info['types'] as List?)?.map((e) => e.toString()).toList(),
                              );
                              
                              // Get current preferences
                              final likedRestaurantsStr = prefs.getStringList('guest_liked_restaurants') ?? [];
                              final dislikedRestaurantsStr = prefs.getStringList('guest_disliked_restaurants') ?? [];
                              
                              // Parse existing data
                              final likedRestaurants = <pref_models.RestaurantInfo>[];
                              final dislikedRestaurants = <pref_models.RestaurantInfo>[];
                              
                              for (final str in likedRestaurantsStr) {
                                try {
                                  final map = jsonDecode(str) as Map<String, dynamic>;
                                  likedRestaurants.add(pref_models.RestaurantInfo.fromMap(map));
                                } catch (e) {
                                  likedRestaurants.add(pref_models.RestaurantInfo(id: str, name: str));
                                }
                              }
                              
                              for (final str in dislikedRestaurantsStr) {
                                try {
                                  final map = jsonDecode(str) as Map<String, dynamic>;
                                  dislikedRestaurants.add(pref_models.RestaurantInfo.fromMap(map));
                                } catch (e) {
                                  dislikedRestaurants.add(pref_models.RestaurantInfo(id: str, name: str));
                                }
                              }
                              
                              // Remove from both lists first
                              likedRestaurants.removeWhere((r) => r.id == restaurantInfo.id);
                              dislikedRestaurants.removeWhere((r) => r.id == restaurantInfo.id);
                              
                              // Add to liked list
                              likedRestaurants.add(restaurantInfo);
                              
                              // Save back to SharedPreferences
                              await prefs.setStringList('guest_liked_restaurants', 
                                  likedRestaurants.map((r) => jsonEncode(r.toMap())).toList());
                              await prefs.setStringList('guest_disliked_restaurants', 
                                  dislikedRestaurants.map((r) => jsonEncode(r.toMap())).toList());
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to liked restaurants')),
                            );
                          }
                        },
                        onDislikeRestaurant: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (info['place_id'] != null && info['name'] != null) {
                            if (user != null) {
                              // Authenticated user - save to Firebase
                              final repo = UserPreferenceRepository();
                              final pref = await repo.fetchPreference(user.uid) ?? 
                                  pref_models.Preference(userId: user.uid);
                              
                              // 创建餐厅信息对象
                              final restaurantInfo = pref_models.RestaurantInfo(
                                id: info['place_id'],
                                name: info['name'],
                                address: info['vicinity'],
                                lat: info['geometry']?['location']?['lat']?.toDouble(),
                                lng: info['geometry']?['location']?['lng']?.toDouble(),
                                types: (info['types'] as List?)?.map((e) => e.toString()).toList(),
                              );
                              
                              // 添加到不喜欢列表，从喜欢列表移除
                              final updatedLiked = List<pref_models.RestaurantInfo>.from(pref.likedRestaurants);
                              final updatedDisliked = List<pref_models.RestaurantInfo>.from(pref.dislikedRestaurants);
                              
                              // 移除重复项
                              updatedLiked.removeWhere((r) => r.id == restaurantInfo.id);
                              updatedDisliked.removeWhere((r) => r.id == restaurantInfo.id);
                              
                              // 添加到不喜欢列表
                              updatedDisliked.add(restaurantInfo);
                              
                              final updatedPref = pref_models.Preference(
                                userId: user.uid,
                                likedRestaurants: updatedLiked,
                                dislikedRestaurants: updatedDisliked,
                                likedCuisines: pref.likedCuisines,
                                dislikedCuisines: pref.dislikedCuisines,
                              );
                              
                              await repo.setPreference(updatedPref);
                            } else {
                              // Guest user - save to SharedPreferences
                              final prefs = await SharedPreferences.getInstance();
                              final restaurantInfo = pref_models.RestaurantInfo(
                                id: info['place_id'],
                                name: info['name'],
                                address: info['vicinity'],
                                lat: info['geometry']?['location']?['lat']?.toDouble(),
                                lng: info['geometry']?['location']?['lng']?.toDouble(),
                                types: (info['types'] as List?)?.map((e) => e.toString()).toList(),
                              );
                              
                              // Get current preferences
                              final likedRestaurantsStr = prefs.getStringList('guest_liked_restaurants') ?? [];
                              final dislikedRestaurantsStr = prefs.getStringList('guest_disliked_restaurants') ?? [];
                              
                              // Parse existing data
                              final likedRestaurants = <pref_models.RestaurantInfo>[];
                              final dislikedRestaurants = <pref_models.RestaurantInfo>[];
                              
                              for (final str in likedRestaurantsStr) {
                                try {
                                  final map = jsonDecode(str) as Map<String, dynamic>;
                                  likedRestaurants.add(pref_models.RestaurantInfo.fromMap(map));
                                } catch (e) {
                                  likedRestaurants.add(pref_models.RestaurantInfo(id: str, name: str));
                                }
                              }
                              
                              for (final str in dislikedRestaurantsStr) {
                                try {
                                  final map = jsonDecode(str) as Map<String, dynamic>;
                                  dislikedRestaurants.add(pref_models.RestaurantInfo.fromMap(map));
                                } catch (e) {
                                  dislikedRestaurants.add(pref_models.RestaurantInfo(id: str, name: str));
                                }
                              }
                              
                              // Remove from both lists first
                              likedRestaurants.removeWhere((r) => r.id == restaurantInfo.id);
                              dislikedRestaurants.removeWhere((r) => r.id == restaurantInfo.id);
                              
                              // Add to disliked list
                              dislikedRestaurants.add(restaurantInfo);
                              
                              // Save back to SharedPreferences
                              await prefs.setStringList('guest_liked_restaurants', 
                                  likedRestaurants.map((r) => jsonEncode(r.toMap())).toList());
                              await prefs.setStringList('guest_disliked_restaurants', 
                                  dislikedRestaurants.map((r) => jsonEncode(r.toMap())).toList());
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to disliked restaurants')),
                            );
                          }
                        },
                        onLikeCuisine: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (info['types'] != null && info['types'].isNotEmpty) {
                            if (user != null) {
                              // Authenticated user - save to Firebase
                              final repo = UserPreferenceRepository();
                              await repo.updatePreferenceField(
                                user.uid,
                                {
                                  'likedCuisines': FieldValue.arrayUnion([info['types'][0]]),
                                  'dislikedCuisines': FieldValue.arrayRemove([info['types'][0]]),
                                },
                              );
                            } else {
                              // Guest user - save to SharedPreferences
                              final prefs = await SharedPreferences.getInstance();
                              final likedCuisines = prefs.getStringList('guest_liked_cuisines') ?? [];
                              final dislikedCuisines = prefs.getStringList('guest_disliked_cuisines') ?? [];
                              
                              final cuisine = info['types'][0] as String;
                              
                              // Remove from disliked if exists
                              dislikedCuisines.remove(cuisine);
                              
                              // Add to liked if not already there
                              if (!likedCuisines.contains(cuisine)) {
                                likedCuisines.add(cuisine);
                              }
                              
                              await prefs.setStringList('guest_liked_cuisines', likedCuisines);
                              await prefs.setStringList('guest_disliked_cuisines', dislikedCuisines);
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to liked cuisines')),
                            );
                          }
                        },
                        onDislikeCuisine: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (info['types'] != null && info['types'].isNotEmpty) {
                            if (user != null) {
                              // Authenticated user - save to Firebase
                              final repo = UserPreferenceRepository();
                              await repo.updatePreferenceField(
                                user.uid,
                                {
                                  'dislikedCuisines': FieldValue.arrayUnion([info['types'][0]]),
                                  'likedCuisines': FieldValue.arrayRemove([info['types'][0]]),
                                },
                              );
                            } else {
                              // Guest user - save to SharedPreferences
                              final prefs = await SharedPreferences.getInstance();
                              final likedCuisines = prefs.getStringList('guest_liked_cuisines') ?? [];
                              final dislikedCuisines = prefs.getStringList('guest_disliked_cuisines') ?? [];
                              
                              final cuisine = info['types'][0] as String;
                              
                              // Remove from liked if exists
                              likedCuisines.remove(cuisine);
                              
                              // Add to disliked if not already there
                              if (!dislikedCuisines.contains(cuisine)) {
                                dislikedCuisines.add(cuisine);
                              }
                              
                              await prefs.setStringList('guest_liked_cuisines', likedCuisines);
                              await prefs.setStringList('guest_disliked_cuisines', dislikedCuisines);
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to disliked cuisines')),
                            );
                          }
                        },
                        onCancel: () {
                          print('Cancel');
                        },
                        onConfirm: () {
                          print('Confirm');
                        },
                        description: 'You can mark this restaurant or cuisine as liked or disliked. This will help us improve your recommendations.',
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
