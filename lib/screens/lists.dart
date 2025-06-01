import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/restaurant_list_bloc.dart';
import '../widgets/dialogs/map_popup.dart';
import '../widgets/dialogs/list_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../repositories/user_preference_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/nearby_restaurant_provider.dart';
import 'package:provider/provider.dart';

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
  bool _loading = true;
  String? _error;
  String? _nextPageToken;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasLoaded = false;

  // 你可以将API_KEY放到安全的地方
  static const String apiKey = 'AIzaSyBUUuCGzKK9z-yY2gHz1kvvTzhIufEkQZc';
  // Santa Clara, CA 95051
  double lat = 37.3467;
  double lng = -121.9842;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // 首先检查Provider中是否已有数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NearbyRestaurantProvider>(context, listen: false);
      if (provider.hasLoaded && provider.restaurants.isNotEmpty && !_hasLoaded) {
        // 使用Provider中的数据
        setState(() {
          _restaurants = provider.restaurants;
          lat = provider.lat;
          lng = provider.lng;
          _loading = false;
          _hasLoaded = true;
        });
        
        // 通知父组件餐厅数据已更新
        widget.onRestaurantsChanged?.call(_restaurants);
      } else if (!_hasLoaded) {
        // Provider中没有数据，开始加载
        _startBackgroundLoading();
        _hasLoaded = true;
      }
      
      // 监听Provider数据变化
      provider.addListener(_onProviderDataChanged);
    });
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        if (_nextPageToken != null && !_isLoadingMore) {
          fetchNearbyRestaurants(loadMore: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final provider = Provider.of<NearbyRestaurantProvider>(context, listen: false);
    provider.removeListener(_onProviderDataChanged);
    super.dispose();
  }
  
  void _onProviderDataChanged() {
    final provider = Provider.of<NearbyRestaurantProvider>(context, listen: false);
    if (provider.hasLoaded && provider.restaurants.isNotEmpty && mounted) {
      setState(() {
        _restaurants = provider.restaurants;
        lat = provider.lat;
        lng = provider.lng;
        _loading = false;
        _hasLoaded = true;
        _error = provider.error;
      });
      
      // 通知父组件餐厅数据已更新
      widget.onRestaurantsChanged?.call(_restaurants);
    }
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
              : RefreshIndicator(
                  onRefresh: () async {
                    // 重置Provider状态
                    final provider = Provider.of<NearbyRestaurantProvider>(context, listen: false);
                    provider.reset();
                    
                    // 重置本地状态
                    _hasLoaded = false;
                    _restaurants.clear();
                    _nextPageToken = null;
                    
                    // 重新开始预加载
                    await provider.preloadRestaurants();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                    itemCount: _restaurants.length + (_nextPageToken != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _restaurants.length) {
                        return _GoogleRestaurantCard(info: _restaurants[index]);
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
    );
  }

  Future<void> fetchNearbyRestaurants({bool loadMore = false}) async {
    if (loadMore && (_nextPageToken == null || _isLoadingMore)) return;
    if (!mounted) return;
    setState(() {
      if (!loadMore) _loading = true;
      _error = null;
      if (loadMore) _isLoadingMore = true;
    });
    try {
      String url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=2000&type=restaurant&key=$apiKey&language=en';
      if (loadMore && _nextPageToken != null) {
        url += '&pagetoken=$_nextPageToken';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        // 过滤用户不喜欢的餐厅和菜系
        final filteredResults = await _filterDislikedRestaurants(results.map((e) => e as Map<String, dynamic>).toList());
        
        if (!mounted) return;
        setState(() {
          if (loadMore) {
            _restaurants.addAll(filteredResults);
          } else {
            _restaurants = filteredResults;
          }
          _nextPageToken = data['next_page_token'];
          _loading = false;
          _isLoadingMore = false;
        });
        
        // 通知父组件餐厅数据已更新
        widget.onRestaurantsChanged?.call(_restaurants);
        
        // 更新 Provider
        final provider = Provider.of<NearbyRestaurantProvider>(context, listen: false);
        provider.updateRestaurants(_restaurants);
      } else {
        if (!mounted) return;
        setState(() {
          _error = '网络错误';
          _loading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('fetchNearbyRestaurants error: '
          + e.toString());
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
      print('getCurrentLocation: serviceEnabled = '
          + serviceEnabled.toString());
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      print('getCurrentLocation: permission = '
          + permission.toString());
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('getCurrentLocation: requestPermission = '
            + permission.toString());
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      print('getCurrentLocation: position = '
          + position.toString());
      if (!mounted) return;
      setState(() {
        lat = position.latitude;
        lng = position.longitude;
      });
      fetchNearbyRestaurants();
    } catch (e) {
      print('getCurrentLocation error: '
          + e.toString());
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

      final dislikedRestaurants = pref.dislikedRestaurants;
      final dislikedCuisines = pref.dislikedCuisines;

      return restaurants.where((restaurant) {
        final placeId = restaurant['place_id'] as String? ?? '';
        final types = restaurant['types'] as List<dynamic>? ?? [];
        
        // 检查餐厅是否在不喜欢列表中
        if (dislikedRestaurants.contains(placeId)) {
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

  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${_ListsViewState.apiKey}&fields=editorial_summary,website,types,international_phone_number';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    return null;
  }

  String _getCuisineFromEditorialSummary(String? summary) {
    if (summary == null || summary.isEmpty) return '';
    
    final lowerSummary = summary.toLowerCase();
    final cuisineKeywords = {
      'chinese': ['chinese', 'china', 'sichuan', 'szechuan', 'cantonese', 'mandarin'],
      'japanese': ['japanese', 'japan', 'sushi', 'ramen', 'tempura', 'yakitori'],
      'korean': ['korean', 'korea', 'kimchi', 'bulgogi', 'bibimbap'],
      'italian': ['italian', 'italy', 'pizza', 'pasta', 'mediterranean'],
      'mexican': ['mexican', 'mexico', 'taco', 'burrito', 'latin'],
      'thai': ['thai', 'thailand', 'pad thai', 'curry'],
      'vietnamese': ['vietnamese', 'vietnam', 'pho', 'banh'],
      'indian': ['indian', 'india', 'curry', 'tandoor', 'biryani'],
      'french': ['french', 'france', 'bistro', 'brasserie'],
      'american': ['american', 'burger', 'steakhouse', 'grill'],
      'seafood': ['seafood', 'fish', 'crab', 'lobster', 'oyster'],
    };
    
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
      'seafood': 'Seafood',
    };
    
    for (final entry in cuisineKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerSummary.contains(keyword)) {
          return displayMap[entry.key] ?? entry.key.toUpperCase();
        }
      }
    }
    
    return '';
  }

  // 建议：使用 Google Places Text Search API 来获取更准确的菜系信息
  // 例如：搜索 "Chinese restaurant near me" 而不是普通的 nearby search
  Future<void> fetchRestaurantsByCuisine(String cuisine, {bool loadMore = false}) async {
    // 这是一个示例方法，展示如何按菜系搜索
    try {
      String url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$cuisine restaurant&location=$lat,$lng&radius=2000&key=$apiKey&language=en';
      if (loadMore && _nextPageToken != null) {
        url += '&pagetoken=$_nextPageToken';
      }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        // 处理结果...
        print('Found ${results.length} $cuisine restaurants');
      }
    } catch (e) {
      print('Error fetching $cuisine restaurants: $e');
    }
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
  const _GoogleRestaurantCard({super.key, required this.info});

  Future<bool> _isLikedRestaurant(String userId, String placeId) async {
    final repo = UserPreferenceRepository();
    final pref = await repo.fetchPreference(userId);
    return pref?.likedRestaurants.contains(placeId) ?? false;
  }

  Future<bool> _isDislikedRestaurant(String userId, String placeId) async {
    final repo = UserPreferenceRepository();
    final pref = await repo.fetchPreference(userId);
    return pref?.dislikedRestaurants.contains(placeId) ?? false;
  }

  Future<bool> _isLikedCuisine(String userId, String cuisine) async {
    final repo = UserPreferenceRepository();
    final pref = await repo.fetchPreference(userId);
    return pref?.likedCuisines.contains(cuisine) ?? false;
  }

  Future<bool> _isDislikedCuisine(String userId, String cuisine) async {
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
    final imageUrl = photoRef != null
        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=${_ListsViewState.apiKey}'
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
                  ),
                  if (cuisineTypes.isNotEmpty) ...[
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
                    if (user != null) {
                      likedRestaurant = await _isLikedRestaurant(user.uid, placeId);
                      dislikedRestaurant = await _isDislikedRestaurant(user.uid, placeId);
                      likedCuisine = await _isLikedCuisine(user.uid, cuisine);
                      dislikedCuisine = await _isDislikedCuisine(user.uid, cuisine);
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
                          if (user != null && info['place_id'] != null) {
                            final repo = UserPreferenceRepository();
                            await repo.updatePreferenceField(
                              user.uid,
                              {
                                'likedRestaurants': FieldValue.arrayUnion([info['place_id']]),
                                'dislikedRestaurants': FieldValue.arrayRemove([info['place_id']]),
                              },
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to liked restaurants')),
                            );
                          }
                        },
                        onDislikeRestaurant: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null && info['place_id'] != null) {
                            final repo = UserPreferenceRepository();
                            await repo.updatePreferenceField(
                              user.uid,
                              {
                                'dislikedRestaurants': FieldValue.arrayUnion([info['place_id']]),
                                'likedRestaurants': FieldValue.arrayRemove([info['place_id']]),
                              },
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to disliked restaurants')),
                            );
                          }
                        },
                        onLikeCuisine: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null && info['types'] != null && info['types'].isNotEmpty) {
                            final repo = UserPreferenceRepository();
                            await repo.updatePreferenceField(
                              user.uid,
                              {
                                'likedCuisines': FieldValue.arrayUnion([info['types'][0]]),
                                'dislikedCuisines': FieldValue.arrayRemove([info['types'][0]]),
                              },
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to liked cuisines')),
                            );
                          }
                        },
                        onDislikeCuisine: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null && info['types'] != null && info['types'].isNotEmpty) {
                            final repo = UserPreferenceRepository();
                            await repo.updatePreferenceField(
                              user.uid,
                              {
                                'dislikedCuisines': FieldValue.arrayUnion([info['types'][0]]),
                                'likedCuisines': FieldValue.arrayRemove([info['types'][0]]),
                              },
                            );
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