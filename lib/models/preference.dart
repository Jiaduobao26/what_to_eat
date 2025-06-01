class RestaurantInfo {
  final String id;
  final String name;

  RestaurantInfo({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory RestaurantInfo.fromMap(Map<String, dynamic> map) {
    return RestaurantInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }
}

class Preference {
  final String userId;
  final List<RestaurantInfo> likedRestaurants;
  final List<RestaurantInfo> dislikedRestaurants;
  final List<String> likedCuisines;
  final List<String> dislikedCuisines;

  Preference({
    required this.userId,
    this.likedRestaurants = const [],
    this.dislikedRestaurants = const [],
    this.likedCuisines = const [],
    this.dislikedCuisines = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'likedRestaurants': likedRestaurants.map((r) => r.toMap()).toList(),
      'dislikedRestaurants': dislikedRestaurants.map((r) => r.toMap()).toList(),
      'likedCuisines': likedCuisines,
      'dislikedCuisines': dislikedCuisines,
    };
  }

  factory Preference.fromMap(Map<String, dynamic> map) {
    return Preference(
      userId: map['userId'] ?? '',
      likedRestaurants: (map['likedRestaurants'] as List<dynamic>? ?? [])
          .map((item) {
            // 兼容旧格式：如果是字符串，转换为RestaurantInfo
            if (item is String) {
              return RestaurantInfo(id: item, name: item);
            }
            // 新格式：直接从Map创建
            return RestaurantInfo.fromMap(item as Map<String, dynamic>);
          })
          .toList(),
      dislikedRestaurants: (map['dislikedRestaurants'] as List<dynamic>? ?? [])
          .map((item) {
            // 兼容旧格式：如果是字符串，转换为RestaurantInfo
            if (item is String) {
              return RestaurantInfo(id: item, name: item);
            }
            // 新格式：直接从Map创建
            return RestaurantInfo.fromMap(item as Map<String, dynamic>);
          })
          .toList(),
      likedCuisines: List<String>.from(map['likedCuisines'] ?? []),
      dislikedCuisines: List<String>.from(map['dislikedCuisines'] ?? []),
    );
  }
  
  // 辅助方法：获取餐厅ID列表（用于兼容现有代码）
  List<String> get likedRestaurantIds => likedRestaurants.map((r) => r.id).toList();
  List<String> get dislikedRestaurantIds => dislikedRestaurants.map((r) => r.id).toList();
} 