import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../widgets/dialogs/map_popup.dart';
import '../widgets/dialogs/list_dialog.dart';
import 'package:go_router/go_router.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapScreenView();
  }
}

class MapScreenView extends StatefulWidget {
  const MapScreenView({super.key});

  @override
  State<MapScreenView> createState() => _MapScreenViewState();
}

class _MapScreenViewState extends State<MapScreenView> {
  List<Map<String, dynamic>> _restaurants = [];
  bool _loading = true;
  String? _error;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  static const String apiKey = 'AIzaSyBUUuCGzKK9z-yY2gHz1kvvTzhIufEkQZc';
  // Santa Clara, CA 95051
  double lat = 37.3467;
  double lng = -121.9842;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=2000&type=restaurant&key=$apiKey&language=en';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
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
        setState(() {
          _error = 'Network error';
          _loading = false;
        });
      }
    } catch (e) {
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
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).maybePop();
            } else {
              context.go('/lists');
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
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _restaurants.length,
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () => _moveToRestaurant(_restaurants[index]),
                          child: _GoogleRestaurantCard(info: _restaurants[index]),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _GoogleRestaurantCard extends StatelessWidget {
  final Map<String, dynamic> info;
  const _GoogleRestaurantCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final name = info['name'] ?? '';
    final rating = info['rating']?.toString() ?? '-';
    final address = info['vicinity'] ?? '';
    final photoRef = (info['photos'] != null && info['photos'].isNotEmpty)
        ? info['photos'][0]['photo_reference']
        : null;
    final imageUrl = photoRef != null
        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=${_MapScreenViewState.apiKey}'
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
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ListDialog(
                        onDislikeRestaurant: () {
                          // TODO: 处理不喜欢餐厅
                          print('Dislike restaurant');
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