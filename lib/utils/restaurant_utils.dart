// untils/restaurant_utils.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/user_preference_repository.dart';
import '../models/preference.dart' as pref_models;

// This file contains utility functions for handling restaurant data
String formatCuisineType(List<dynamic> types) {
  if (types.isEmpty) return 'Restaurant';

  for (final type in types) {
    final typeStr = type.toString();
    switch (typeStr) {
      case 'chinese_restaurant':
        return 'Chinese';
      case 'japanese_restaurant':
        return 'Japanese';
      case 'korean_restaurant':
        return 'Korean';
      case 'italian_restaurant':
        return 'Italian';
      case 'mexican_restaurant':
        return 'Mexican';
      case 'indian_restaurant':
        return 'Indian';
      case 'thai_restaurant':
        return 'Thai';
      case 'vietnamese_restaurant':
        return 'Vietnamese';
      case 'french_restaurant':
        return 'French';
      case 'american_restaurant':
        return 'American';
      case 'pizza_restaurant':
        return 'Pizza';
      case 'seafood_restaurant':
        return 'Seafood';
      case 'bakery':
        return 'Bakery';
      case 'cafe':
        return 'Cafe';
      case 'bar':
        return 'Bar';
      default:
        if (typeStr != 'restaurant' && typeStr != 'establishment' &&
            typeStr != 'food' && typeStr != 'point_of_interest') {
          return typeStr
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) =>
                  word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
              .join(' ');
        }
    }
  }

  return 'Restaurant';
}

String getPhotoUrl(Map<String, dynamic> restaurant) {
  final photos = restaurant['photos'] as List<dynamic>?;
  if (photos != null && photos.isNotEmpty) {
    final ref = photos.first['photo_reference'];
    // 这里需要API key，暂时使用占位图
    return 'https://via.placeholder.com/400x300.png?text=Restaurant+Photo';
  } else {
    return 'https://via.placeholder.com/400x300.png?text=No+Image';
  }
}

// 过滤不喜欢的餐厅
Future<List<Map<String, dynamic>>> filterDislikedRestaurants(
    List<Map<String, dynamic>> restaurants) async {
  final restaurantsCopy = List<Map<String, dynamic>>.from(restaurants);
  final user = FirebaseAuth.instance.currentUser;

  try {
    List<String> dislikedRestaurantIds = [];
    List<String> dislikedCuisines = [];

    if (user != null) {
      final repo = UserPreferenceRepository();
      final pref = await repo.fetchPreference(user.uid);
      if (pref != null) {
        dislikedRestaurantIds = pref.dislikedRestaurantIds;
        dislikedCuisines = pref.dislikedCuisines;
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      dislikedCuisines = prefs.getStringList('guest_disliked_cuisines') ?? [];
      final dislikedRestaurantsStr = prefs.getStringList('guest_disliked_restaurants') ?? [];
      dislikedRestaurantIds = dislikedRestaurantsStr.map((str) {
        try {
          final map = json.decode(str) as Map<String, dynamic>;
          return map['id'] as String;
        } catch (e) {
          return str;
        }
      }).toList();
    }

    return restaurantsCopy.where((restaurant) {
      final placeId = restaurant['place_id'] as String? ?? '';
      final types = restaurant['types'] as List<dynamic>? ?? [];
      if (dislikedRestaurantIds.contains(placeId)) return false;
      for (final type in types) {
        final typeStr = type.toString().toLowerCase();
        if (dislikedCuisines.map((c) => c.toLowerCase()).contains(typeStr)) return false;
        for (final dislikedCuisine in dislikedCuisines) {
          final dislikedLower = dislikedCuisine.toLowerCase();
          if (typeStr.contains(dislikedLower) || dislikedLower.contains(typeStr)) return false;
        }
      }
      return true;
    }).toList();
  } catch (e) {
    return restaurantsCopy;
  }
}

// 获取游客用户偏好
Future<pref_models.Preference?> getGuestPreferences() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final likedCuisines = prefs.getStringList('guest_liked_cuisines') ?? [];
    final likedRestaurantsStr = prefs.getStringList('guest_liked_restaurants') ?? [];
    if (likedCuisines.isEmpty && likedRestaurantsStr.isEmpty) return null;
    final likedRestaurants = likedRestaurantsStr.map((str) {
      try {
        final map = json.decode(str) as Map<String, dynamic>;
        return pref_models.RestaurantInfo.fromMap(map);
      } catch (e) {
        return pref_models.RestaurantInfo(id: str, name: str);
      }
    }).toList();
    return pref_models.Preference(
      userId: 'guest',
      likedCuisines: likedCuisines,
      likedRestaurants: likedRestaurants,
    );
  } catch (e) {
    return null;
  }
}