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

class Lists extends StatelessWidget {
  const Lists({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RestaurantListBloc(),
      child: const ListsView(),
    );
  }
}

class ListsView extends StatefulWidget {
  const ListsView({super.key});

  @override
  State<ListsView> createState() => _ListsViewState();
}

class _ListsViewState extends State<ListsView> {
  List<Map<String, dynamic>> _restaurants = [];
  bool _loading = true;
  String? _error;
  String? _nextPageToken;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  // 你可以将API_KEY放到安全的地方
  static const String apiKey = 'AIzaSyBUUuCGzKK9z-yY2gHz1kvvTzhIufEkQZc';
  // Santa Clara, CA 95051
  double lat = 37.3467;
  double lng = -121.9842;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        if (_nextPageToken != null && !_isLoadingMore) {
          fetchNearbyRestaurants(loadMore: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('加载失败:\n$_error'))
              : ListView.builder(
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
    );
  }

  Future<void> fetchNearbyRestaurants({bool loadMore = false}) async {
    if (loadMore && (_nextPageToken == null || _isLoadingMore)) return;
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
        setState(() {
          if (loadMore) {
            _restaurants.addAll(results.map((e) => e as Map<String, dynamic>));
          } else {
            _restaurants = results.map((e) => e as Map<String, dynamic>).toList();
          }
          _nextPageToken = data['next_page_token'];
          _loading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _error = '网络错误';
          _loading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('fetchNearbyRestaurants error: '
          + e.toString());
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
}

class _GoogleRestaurantCard extends StatelessWidget {
  final Map<String, dynamic> info;
  const _GoogleRestaurantCard({super.key, required this.info});

  Future<bool> _isDislikedRestaurant(String userId, String placeId) async {
    final repo = UserPreferenceRepository();
    final pref = await repo.fetchPreference(userId);
    return pref?.dislikedRestaurants.contains(placeId) ?? false;
  }

  Future<bool> _isDislikedCuisine(String userId, String cuisine) async {
    final repo = UserPreferenceRepository();
    final pref = await repo.fetchPreference(userId);
    return pref?.dislikedCuisines.contains(cuisine) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final name = info['name'] ?? '';
    final rating = info['rating']?.toString() ?? '-';
    final address = info['vicinity'] ?? '';
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
                    bool dislikedRestaurant = false;
                    bool dislikedCuisine = false;
                    if (user != null) {
                      dislikedRestaurant = await _isDislikedRestaurant(user.uid, placeId);
                      dislikedCuisine = await _isDislikedCuisine(user.uid, cuisine);
                    }
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (context) => ListDialog(
                        initialRestaurantSelected: dislikedRestaurant,
                        initialCuisineSelected: dislikedCuisine,
                        onDislikeRestaurant: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null && info['place_id'] != null) {
                            final repo = UserPreferenceRepository();
                            await repo.updatePreferenceField(
                              user.uid,
                              {
                                'dislikedRestaurants': FieldValue.arrayUnion([info['place_id']])
                              },
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to disliked restaurants')),
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
                                'dislikedCuisines': FieldValue.arrayUnion([info['types'][0]])
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
                        description: 'You can mark this restaurant or cuisine as disliked. This will help us improve your recommendations.',
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