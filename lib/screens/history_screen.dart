import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/history_service.dart';
import '../models/restaurant_history.dart';
import '../widgets/dialogs/map_popup.dart';
import '../repositories/user_preference_repository.dart';
import '../models/preference.dart' as pref_models;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<RestaurantHistory> _historyList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final history = await _historyService.getHistory();
      
      setState(() {
        _historyList = history;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteHistoryItem(String historyId) async {
    try {
      await _historyService.deleteHistory(historyId);
      await _loadHistory(); // 重新加载列表
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History item deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleRestaurantPreference(RestaurantHistory history, bool isLike) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final restaurantInfo = pref_models.RestaurantInfo(
        id: history.restaurantId,
        name: history.name,
        address: history.address,
        lat: history.lat,
        lng: history.lng,
      );

      if (user != null) {
        // 登录用户 - 更新Firebase偏好
        final repo = UserPreferenceRepository();
        final pref = await repo.fetchPreference(user.uid) ?? 
            pref_models.Preference(userId: user.uid);
        
        final updatedLiked = List<pref_models.RestaurantInfo>.from(pref.likedRestaurants);
        final updatedDisliked = List<pref_models.RestaurantInfo>.from(pref.dislikedRestaurants);
        
        // 从两个列表中移除（避免重复）
        updatedLiked.removeWhere((r) => r.id == history.restaurantId);
        updatedDisliked.removeWhere((r) => r.id == history.restaurantId);
        
        // 添加到对应列表
        if (isLike) {
          updatedLiked.add(restaurantInfo);
        } else {
          updatedDisliked.add(restaurantInfo);
        }
        
        final updatedPref = pref_models.Preference(
          userId: user.uid,
          likedRestaurants: updatedLiked,
          dislikedRestaurants: updatedDisliked,
          likedCuisines: pref.likedCuisines,
          dislikedCuisines: pref.dislikedCuisines,
        );
        
        await repo.setPreference(updatedPref);
      } else {
        // 游客用户 - 更新本地偏好
        final prefs = await SharedPreferences.getInstance();
        
        // 获取当前偏好
        final likedRestaurantsStr = prefs.getStringList('guest_liked_restaurants') ?? [];
        final dislikedRestaurantsStr = prefs.getStringList('guest_disliked_restaurants') ?? [];
        
        final likedRestaurants = <pref_models.RestaurantInfo>[];
        final dislikedRestaurants = <pref_models.RestaurantInfo>[];
        
        // 解析现有数据
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
        
        // 从两个列表中移除（避免重复）
        likedRestaurants.removeWhere((r) => r.id == history.restaurantId);
        dislikedRestaurants.removeWhere((r) => r.id == history.restaurantId);
        
        // 添加到对应列表
        if (isLike) {
          likedRestaurants.add(restaurantInfo);
        } else {
          dislikedRestaurants.add(restaurantInfo);
        }
        
        // 保存回本地
        await prefs.setStringList('guest_liked_restaurants', 
            likedRestaurants.map((r) => jsonEncode(r.toMap())).toList());
        await prefs.setStringList('guest_disliked_restaurants', 
            dislikedRestaurants.map((r) => jsonEncode(r.toMap())).toList());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLike ? 'Added to liked restaurants' : 'Added to disliked restaurants'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update preference: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE95322),
        title: const Text(
          'History',
          style: TextStyle(color: Color(0xFF391713)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF391713)),
          onPressed: () => context.pop(),
        ),

      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No history yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyList.length,
                  itemBuilder: (context, index) {
                    final history = _historyList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.restaurant),
                        title: Text(history.name),
                        subtitle: Text(history.cuisine),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.thumb_up_outlined),
                              color: const Color(0xFF4CAF50),
                              onPressed: () => _toggleRestaurantPreference(history, true),
                              tooltip: 'Like',
                            ),
                            IconButton(
                              icon: const Icon(Icons.thumb_down_outlined),
                              color: const Color(0xFFFF5722),
                              onPressed: () => _toggleRestaurantPreference(history, false),
                              tooltip: 'Dislike',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 