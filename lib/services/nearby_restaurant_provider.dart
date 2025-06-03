import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../services/local_properties_service.dart';

class NearbyRestaurantProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  String? _apiKey;
  
  double _lat = 37.3467; // Santa Clara, CA 95051 默认位置
  double _lng = -121.9842;

  List<Map<String, dynamic>> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  double get lat => _lat;
  double get lng => _lng;

  void updateRestaurants(List<Map<String, dynamic>> newList) {
    _restaurants = newList;
    _hasLoaded = true;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
  
  // 应用启动时调用此方法预加载数据
  Future<void> preloadRestaurants() async {
    if (_hasLoaded || _isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // 先尝试获取用户位置
      await _getCurrentLocation();
      
      // 加载附近餐厅
      await _fetchNearbyRestaurants();
      
    } catch (e) {
      _error = e.toString();
      print('Preload restaurants error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      _lat = position.latitude;
      _lng = position.longitude;
    } catch (e) {
      print('Get location error: $e');
      // 继续使用默认位置
    }
  }
  
  Future<void> _fetchNearbyRestaurants() async {
    try {
      if (_apiKey == null) {
        _apiKey = await LocalPropertiesService.getGoogleMapsApiKey();
      }
      if (_apiKey == null) {
        throw Exception('API key not available');
      }
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$_lat,$_lng&radius=2000&type=restaurant&key=$_apiKey&language=en';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        _restaurants = results.map((e) => e as Map<String, dynamic>).toList();
        _hasLoaded = true;
        _error = null;
      } else {
        throw Exception('Network error: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }
  
  // 重置状态，用于刷新
  void reset() {
    _restaurants.clear();
    _hasLoaded = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}