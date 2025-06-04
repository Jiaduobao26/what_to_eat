import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant_detail.dart';
import 'local_properties_service.dart';

class RestaurantDetailService {
  static final RestaurantDetailService _instance = RestaurantDetailService._internal();
  factory RestaurantDetailService() => _instance;
  RestaurantDetailService._internal();

  String? _apiKey;

  /// 获取餐厅详细信息
  Future<RestaurantDetail> getRestaurantDetail(String placeId) async {
    try {
      // 确保API密钥已加载
      _apiKey ??= await LocalPropertiesService.getGoogleMapsApiKey();
      
      if (_apiKey == null) {
        throw Exception('Google Maps API key not available');
      }

      print('🔍 Fetching restaurant details for place_id: $placeId');

      // 构建Place Details API请求
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        {
          'place_id': placeId,
          'fields': [
            // 基本信息
            'place_id',
            'name',
            'formatted_address',
            'formatted_phone_number',
            'website',
            
            // 评分和评论
            'rating',
            'user_ratings_total',
            'reviews',
            
            // 营业信息
            'opening_hours',
            'current_opening_hours',
            
            // 价格和类型
            'price_level',
            'types',
            
            // 照片和位置
            'photos',
            'geometry',
            
            // 附加信息
            'editorial_summary',
          ].join(','),
          'key': _apiKey!,
          'language': 'en', // 可以改为 'zh' 获取中文信息
        },
      );

      print('🌐 API Request: ${uri.toString()}');

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final data = json.decode(response.body);
      
      // 检查API响应状态
      final status = data['status'];
      if (status != 'OK') {
        throw Exception('Google Places API Error: $status - ${data['error_message'] ?? 'Unknown error'}');
      }

      final result = data['result'];
      if (result == null) {
        throw Exception('No restaurant details found for place_id: $placeId');
      }

      print('✅ Restaurant details fetched successfully: ${result['name']}');

      return RestaurantDetail.fromJson(result);
      
    } catch (e) {
      print('❌ Error fetching restaurant details: $e');
      rethrow;
    }
  }

  /// 获取餐厅照片URL列表
  List<String> getPhotoUrls(RestaurantDetail restaurant, {int maxWidth = 400, int? limit}) {
    if (_apiKey == null) return [];
    
    var photos = restaurant.photos;
    if (limit != null && photos.length > limit) {
      photos = photos.take(limit).toList();
    }
    
    return photos.map((photo) => photo.getPhotoUrl(_apiKey!, maxWidth: maxWidth)).toList();
  }

  /// 格式化营业时间为更友好的显示
  List<String> getFormattedOpeningHours(RestaurantDetail restaurant) {
    final openingHours = restaurant.openingHours;
    if (openingHours == null) return ['Opening hours not available'];
    
    if (openingHours.weekdayText.isNotEmpty) {
      return openingHours.weekdayText;
    }
    
    // 如果weekdayText为空，从periods生成
    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final formattedHours = <String>[];
    
    for (int day = 0; day < 7; day++) {
      final periodsForDay = openingHours.periods.where((period) => period.open?.day == day).toList();
      
      if (periodsForDay.isEmpty) {
        formattedHours.add('${weekdays[day]}: Closed');
      } else {
        final times = periodsForDay.map((period) {
          final openTime = period.open?.formattedTime ?? '';
          final closeTime = period.close?.formattedTime ?? '';
          return '$openTime - $closeTime';
        }).join(', ');
        formattedHours.add('${weekdays[day]}: $times');
      }
    }
    
    return formattedHours;
  }

  /// 获取当前营业状态的友好描述
  String getOpenStatusText(RestaurantDetail restaurant) {
    final isOpen = restaurant.currentlyOpen;
    final openingHours = restaurant.openingHours;
    
    if (isOpen == null) {
      return 'Opening status unknown';
    }
    
    if (isOpen) {
      return 'Open now';
    } else {
      return 'Closed now';
    }
  }

  /// 格式化评论为更好的显示
  String getFormattedReviewText(Review review, {int maxLength = 200}) {
    if (review.text.length <= maxLength) {
      return review.text;
    }
    
    return '${review.text.substring(0, maxLength)}...';
  }

  /// 生成星级评分显示
  String getStarRating(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;
    
    String stars = '★' * fullStars;
    if (hasHalfStar) {
      stars += '☆';
    }
    
    final remainingStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    stars += '☆' * remainingStars;
    
    return stars;
  }

  /// 获取菜系类型的友好显示名称
  List<String> getFormattedCuisineTypes(RestaurantDetail restaurant) {
    return restaurant.types
        .where((type) => !['establishment', 'point_of_interest', 'food'].contains(type))
        .map((type) => _formatCuisineType(type))
        .toList();
  }

  String _formatCuisineType(String type) {
    final typeMap = {
      'restaurant': 'Restaurant',
      'meal_takeaway': 'Takeaway',
      'meal_delivery': 'Delivery',
      'bakery': 'Bakery',
      'bar': 'Bar',
      'cafe': 'Cafe',
      'chinese_restaurant': 'Chinese',
      'japanese_restaurant': 'Japanese',
      'korean_restaurant': 'Korean',
      'italian_restaurant': 'Italian',
      'french_restaurant': 'French',
      'mexican_restaurant': 'Mexican',
      'indian_restaurant': 'Indian',
      'thai_restaurant': 'Thai',
      'vietnamese_restaurant': 'Vietnamese',
      'american_restaurant': 'American',
      'mediterranean_restaurant': 'Mediterranean',
      'pizza_restaurant': 'Pizza',
      'seafood_restaurant': 'Seafood',
      'steakhouse': 'Steakhouse',
      'sushi_restaurant': 'Sushi',
      'fast_food_restaurant': 'Fast Food',
      'sandwich_shop': 'Sandwich',
      'ice_cream_shop': 'Ice Cream',
    };

    return typeMap[type] ?? type.replaceAll('_', ' ').split(' ').map((word) => 
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word).join(' ');
  }
} 