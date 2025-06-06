import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/nearby_restaurant_provider.dart';
import '../services/restaurant_detail_service.dart';
import '../repositories/user_preference_repository.dart';
import '../models/preference.dart' as pref_models;
import '../models/restaurant.dart';
import '../blocs/wheel_bloc.dart';
import '../utils/restaurant_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RestaurantSelectorService {
  final BuildContext context;
  final Random _random = Random();

  RestaurantSelectorService(this.context);

  // 完全随机选择（Surprise me!）
  Future<Map<String, dynamic>?> performSurpriseSelection(
    List<Map<String, dynamic>> nearbyList,
    Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>) filterDislikedRestaurants) async {
      final filteredRestaurants = await filterDislikedRestaurants(nearbyList);
      if (filteredRestaurants.isEmpty) return null;
      final randomIndex = _random.nextInt(filteredRestaurants.length);
      return filteredRestaurants[randomIndex];
    }

  // 基于偏好选择
  Future<void> performPreferenceBasedSelection({
    required Future<pref_models.Preference?> Function() getPreference,
    required Future<void> Function(Map<String, dynamic>) displaySelectedRestaurant,
    required Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>) filterDislikedRestaurants,
    required Future<void> Function() fallbackSurpriseSelection,
  }) async {
    try {
      final preference = await getPreference();

      if (preference == null) {
        _showSnackBar('No preferences found. Please set your preferences first.');
        return;
      }

      final mixedPreferences = <dynamic>[];
      mixedPreferences.addAll(preference.likedRestaurants);
      mixedPreferences.addAll(preference.likedCuisines);

      if (mixedPreferences.isEmpty) {
        _showSnackBar('No liked restaurants or cuisines found. Please add some preferences first.');
        return;
      }

      int maxRetries = 3;
      bool selectionMade = false;

      for (int attempt = 1; attempt <= maxRetries && !selectionMade; attempt++) {
        final randomIndex = _random.nextInt(mixedPreferences.length);
        final selectedPreference = mixedPreferences[randomIndex];

        try {
          if (selectedPreference is pref_models.RestaurantInfo) {
            await selectSpecificRestaurant(selectedPreference, displaySelectedRestaurant);
            selectionMade = true;
          } else if (selectedPreference is String) {
            await selectFromSpecificCuisine(selectedPreference, displaySelectedRestaurant, filterDislikedRestaurants);
            selectionMade = true;
          }
        } catch (_) {
          if (attempt == maxRetries) {
            await fallbackSurpriseSelection();
            selectionMade = true;
          }
        }
      }
    } catch (e) {
      _showSnackBar('Error loading preferences. Falling back to random selection.');
      await fallbackSurpriseSelection();
    }
  }

  /// 选择特定餐厅
  Future<void> selectSpecificRestaurant(
    pref_models.RestaurantInfo restaurantInfo,
    Future<void> Function(Map<String, dynamic>) displaySelectedRestaurant,
  ) async {
    try {
      final detailService = RestaurantDetailService();
      final restaurantDetail = await detailService.getRestaurantDetail(restaurantInfo.id);

      // 检查不喜欢的菜系
      final dislikedCuisines = await _getDislikedCuisines();

      for (final type in restaurantDetail.types) {
        final typeStr = type.toLowerCase();
        for (final dislikedCuisine in dislikedCuisines) {
          final dislikedLower = dislikedCuisine.toLowerCase();
          if (typeStr.contains(dislikedLower) || dislikedLower.contains(typeStr)) {
            throw Exception('Restaurant contains disliked cuisine');
          }
        }
      }

      final restaurantData = {
        'place_id': restaurantDetail.placeId,
        'name': restaurantDetail.name,
        'vicinity': restaurantDetail.formattedAddress,
        'rating': restaurantDetail.rating ?? 0.0,
        'geometry': {
          'location': {
            'lat': restaurantDetail.geometry.location.lat,
            'lng': restaurantDetail.geometry.location.lng,
          }
        },
        'types': restaurantDetail.types,
        'photos': restaurantDetail.photos.isNotEmpty
            ? [
                {'photo_reference': restaurantDetail.photos.first.photoReference}
              ]
            : null,
      };

      await displaySelectedRestaurant(restaurantData);
    } catch (e) {
      rethrow;
    }
  }

  // 从特定菜系中随机选择餐厅
  Future<void> selectFromSpecificCuisine(
    String cuisine,
    Future<void> Function(Map<String, dynamic>) displaySelectedRestaurant,
    Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>) filterDislikedRestaurants,
  ) async {
    final originalList = Provider.of<NearbyRestaurantProvider>(context, listen: false).restaurants;
    final nearbyList = List<Map<String, dynamic>>.from(originalList);

    final matchingRestaurants = <Map<String, dynamic>>[];

    for (final restaurant in nearbyList) {
      final types = restaurant['types'] as List<dynamic>? ?? [];
      if (types.any((type) =>
          type.toString().toLowerCase().contains(cuisine.toLowerCase()) ||
          cuisine.toLowerCase().contains(type.toString().toLowerCase()))) {
        matchingRestaurants.add(restaurant);
      }
    }

    if (matchingRestaurants.isNotEmpty) {
      final filteredRestaurants = await filterDislikedRestaurants(matchingRestaurants);
      if (filteredRestaurants.isNotEmpty) {
        final randomIndex = _random.nextInt(filteredRestaurants.length);
        final selectedRestaurant = filteredRestaurants[randomIndex];
        await displaySelectedRestaurant(selectedRestaurant);
        return;
      }
    }

    // 如果附近没有，调用API
    try {
      final wheelBloc = context.read<WheelBloc>();
      final restaurant = await wheelBloc.fetchRestaurantByCuisine(cuisine);
      context.read<WheelBloc>().add(SetSelectedRestaurantEvent(restaurant));
    } catch (e) {
      throw Exception('No restaurants found for $cuisine cuisine');
    }
  }

  // get disliked cuisines
  Future<List<String>> _getDislikedCuisines() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final repo = UserPreferenceRepository();
      final pref = await repo.fetchPreference(user.uid);
      return pref?.dislikedCuisines ?? [];
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('guest_disliked_cuisines') ?? [];
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}