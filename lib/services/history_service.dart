import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant_history.dart';
import '../models/restaurant.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();  /// 检查当前用户是否为guest用户
  Future<bool> _isGuestUser() async {
    try {
      // 检查SharedPreferences中的guest状态
      final prefs = await SharedPreferences.getInstance();
      final isGuestLoggedIn = prefs.getBool('guestLoggedIn') ?? false;
      
      // 如果明确标记为guest用户，返回true
      if (isGuestLoggedIn) {
        print('✅ User is guest (guestLoggedIn=true)');
        return true;
      }
      
      // 检查Firebase Auth用户
      final user = FirebaseAuth.instance.currentUser;
      print('🔍 Firebase Auth current user: ${user?.uid}');
      
      // 如果有Firebase用户，视为登录用户（登录时已验证过邮箱）
      if (user != null) {
        print('✅ User is authenticated Firebase user: ${user.uid}');
        return false;
      }
      
      // 没有Firebase用户，也没有明确的guest标志，视为未认证
      print('✅ User is unauthenticated (no Firebase user, no guest flag)');
      return true; // 默认为guest，使用本地存储
    } catch (e) {
      print('⚠️ Error checking user status, defaulting to guest: $e');
      return true; // 出错时默认为guest，使用本地存储
    }
  }

  /// 保存餐厅历史记录
  Future<void> saveRestaurantHistory(Restaurant restaurant, String source) async {
    final isGuest = await _isGuestUser();
    
    final history = RestaurantHistory.fromRestaurant(
      restaurantId: _extractRestaurantId(restaurant),
      name: restaurant.name,
      address: restaurant.address,
      cuisine: restaurant.cuisine,
      rating: restaurant.rating,
      lat: restaurant.lat,
      lng: restaurant.lng,
      imageUrl: restaurant.imageUrl,
      source: source,
    );

    if (!isGuest) {
      // 登录用户 - 保存到Firebase
      final user = FirebaseAuth.instance.currentUser!;
      await _saveToFirebase(user.uid, history);
    } else {
      // 游客用户 - 保存到本地
      await _saveToLocal(history);
    }

    print('📚 Saved restaurant history: ${restaurant.name} (source: $source, isGuest: $isGuest)');
  }

  /// 获取历史记录列表
  Future<List<RestaurantHistory>> getHistory() async {
    print('📖 Getting history records...');
    final isGuest = await _isGuestUser();
    
    if (!isGuest) {
      // 登录用户 - 从Firebase获取
      final user = FirebaseAuth.instance.currentUser!;
      print('📖 Getting history from Firebase for user: ${user.uid}');
      final result = await _getFromFirebase(user.uid);
      print('📖 Retrieved ${result.length} records from Firebase');
      return result;
    } else {
      // 游客用户 - 从本地获取
      print('📖 Getting history from local storage');
      final result = await _getFromLocal();
      print('📖 Retrieved ${result.length} records from local storage');
      return result;
    }
  }

  /// 删除历史记录
  Future<void> deleteHistory(String historyId) async {
    final isGuest = await _isGuestUser();
    
    if (!isGuest) {
      // 登录用户 - 从Firebase删除
      final user = FirebaseAuth.instance.currentUser!;
      await _deleteFromFirebase(user.uid, historyId);
    } else {
      // 游客用户 - 从本地删除
      await _deleteFromLocal(historyId);
    }

    print('🗑️ Deleted history record: $historyId');
  }

  /// 清空所有历史记录
  Future<void> clearAllHistory() async {
    final isGuest = await _isGuestUser();
    
    if (!isGuest) {
      // 登录用户 - 清空Firebase记录
      final user = FirebaseAuth.instance.currentUser!;
      await _clearFirebaseHistory(user.uid);
    } else {
      // 游客用户 - 清空本地记录
      await _clearLocalHistory();
    }

    print('🗑️ Cleared all history records');
  }

  // === Firebase相关方法 ===
  
  Future<void> _saveToFirebase(String userId, RestaurantHistory history) async {
    try {
      print('💾 Attempting to save to Firebase for user: $userId');
      print('💾 History data: ${history.toMap()}');
      
      await FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: 'userinfo',
      ).collection('userinfo').doc(userId).collection('history').doc(history.id).set(history.toMap());
      
      print('✅ Successfully saved to Firebase');
    } catch (e) {
      print('❌ Error saving history to Firebase: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<RestaurantHistory>> _getFromFirebase(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: 'userinfo',
      ).collection('userinfo').doc(userId).collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RestaurantHistory.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting history from Firebase: $e');
      return [];
    }
  }

  Future<void> _deleteFromFirebase(String userId, String historyId) async {
    try {
      await FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: 'userinfo',
      ).collection('userinfo').doc(userId).collection('history').doc(historyId).delete();
    } catch (e) {
      print('❌ Error deleting history from Firebase: $e');
      rethrow;
    }
  }

  Future<void> _clearFirebaseHistory(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: 'userinfo',
      ).collection('userinfo').doc(userId).collection('history').get();

      final batch = FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: 'userinfo',
      ).batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error clearing history from Firebase: $e');
      rethrow;
    }
  }

  // === SharedPreferences相关方法 ===

  Future<void> _saveToLocal(RestaurantHistory history) async {
    try {
      print('💾 Attempting to save to local storage');
      print('💾 History data: ${history.toMap()}');
      
      final prefs = await SharedPreferences.getInstance();
      final historyList = await _getFromLocal();
      
      print('📝 Current local history count: ${historyList.length}');
      
      // 添加新记录
      historyList.add(history);
      
      // 限制历史记录数量（最多100条）
      if (historyList.length > 100) {
        historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        historyList.removeRange(100, historyList.length);
      }
      
      // 保存到本地
      final historyStrings = historyList.map((h) => jsonEncode(h.toMap())).toList();
      await prefs.setStringList('restaurant_history', historyStrings);
      
      print('✅ Successfully saved to local storage, new count: ${historyList.length}');
    } catch (e) {
      print('❌ Error saving history to local: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<RestaurantHistory>> _getFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStrings = prefs.getStringList('restaurant_history') ?? [];
      
      final historyList = historyStrings.map((str) {
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          return RestaurantHistory.fromMap(map);
        } catch (e) {
          print('⚠️ Error parsing history record: $e');
          return null;
        }
      }).where((h) => h != null).cast<RestaurantHistory>().toList();
      
      // 按时间倒序排列
      historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return historyList;
    } catch (e) {
      print('❌ Error getting history from local: $e');
      return [];
    }
  }

  Future<void> _deleteFromLocal(String historyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await _getFromLocal();
      
      historyList.removeWhere((h) => h.id == historyId);
      
      final historyStrings = historyList.map((h) => jsonEncode(h.toMap())).toList();
      await prefs.setStringList('restaurant_history', historyStrings);
    } catch (e) {
      print('❌ Error deleting history from local: $e');
      rethrow;
    }
  }

  Future<void> _clearLocalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('restaurant_history');
    } catch (e) {
      print('❌ Error clearing local history: $e');
      rethrow;
    }
  }

  // === 工具方法 ===

  /// 从Restaurant对象中提取餐厅ID
  String _extractRestaurantId(Restaurant restaurant) {
    // 暂时使用餐厅名称和地址的组合作为唯一标识
    return '${restaurant.name}_${restaurant.address}'.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
  }

  /// 检查历史记录中是否已存在某个餐厅
  Future<bool> isRestaurantInHistory(Restaurant restaurant) async {
    final historyList = await getHistory();
    final restaurantId = _extractRestaurantId(restaurant);
    
    return historyList.any((h) => h.restaurantId == restaurantId);
  }

  /// 获取历史记录统计信息
  Future<Map<String, int>> getHistoryStats() async {
    final historyList = await getHistory();
    
    final stats = <String, int>{
      'total': historyList.length,
      'wheel': historyList.where((h) => h.source == 'wheel').length,
      'random': historyList.where((h) => h.source == 'random').length,
      'thisWeek': historyList.where((h) => 
        h.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7)))
      ).length,
    };
    
    return stats;
  }

  /// 调试方法：获取当前用户信息
  Future<void> debugCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    print('🔍 Debug - Current User Info:');
    print('🔍 UID: ${user?.uid}');
    print('🔍 Email: ${user?.email}');
    print('🔍 Email Verified: ${user?.emailVerified}');
    print('🔍 Display Name: ${user?.displayName}');
    
    final prefs = await SharedPreferences.getInstance();
    final isGuestLoggedIn = prefs.getBool('guestLoggedIn') ?? false;
    print('🔍 Guest Logged In: $isGuestLoggedIn');
    
    final isGuest = await _isGuestUser();
    print('🔍 Is Guest User: $isGuest');
  }
}