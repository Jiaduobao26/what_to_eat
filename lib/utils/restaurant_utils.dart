// untils/restaurant_utils.dart
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