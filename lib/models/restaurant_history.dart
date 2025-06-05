class RestaurantHistory {
  final String id; // 用于唯一标识这条历史记录
  final String restaurantId; // 餐厅的place_id
  final String name;
  final String address;
  final String cuisine;
  final double rating;
  final double? lat;
  final double? lng;
  final String imageUrl;
  final DateTime timestamp;
  final String source; // 'wheel' or 'random' 记录来源

  RestaurantHistory({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.address,
    required this.cuisine,
    required this.rating,
    this.lat,
    this.lng,
    required this.imageUrl,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'name': name,
      'address': address,
      'cuisine': cuisine,
      'rating': rating,
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'source': source,
    };
  }

  factory RestaurantHistory.fromMap(Map<String, dynamic> map) {
    return RestaurantHistory(
      id: map['id'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      cuisine: map['cuisine'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      source: map['source'] ?? 'wheel',
    );
  }

  // 从Restaurant对象创建历史记录
  factory RestaurantHistory.fromRestaurant({
    required String restaurantId,
    required String name,
    required String address,
    required String cuisine,
    required double rating,
    double? lat,
    double? lng,
    required String imageUrl,
    required String source,
  }) {
    return RestaurantHistory(
      id: '${restaurantId}_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: restaurantId,
      name: name,
      address: address,
      cuisine: cuisine,
      rating: rating,
      lat: lat,
      lng: lng,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      source: source,
    );
  }

  @override
  String toString() {
    return 'RestaurantHistory(id: $id, name: $name, timestamp: $timestamp)';
  }
} 