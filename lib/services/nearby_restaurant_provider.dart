import 'package:flutter/material.dart';

class NearbyRestaurantProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _restaurants = [];

  List<Map<String, dynamic>> get restaurants => _restaurants;

  void updateRestaurants(List<Map<String, dynamic>> newList) {
    _restaurants = newList;
    notifyListeners();
  }
} 