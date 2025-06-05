import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/wheel_bloc.dart';
import '../models/restaurant.dart';
import '../widgets/dialogs/map_popup.dart';
import '../widgets/buttons/custom_button_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/history_service.dart';

class RestaurantDetailCard extends StatelessWidget {
  const RestaurantDetailCard({super.key});

  // 保存餐厅到历史记录
  Future<void> _saveToHistory(BuildContext context, Restaurant restaurant) async {
    try {
      final historyService = HistoryService();
      // 尝试从路由或widget树判断source类型
      // 这里我们默认使用'wheel'，因为这个卡片主要在wheel结果中使用
      // 如果以后需要更精确的判断，可以通过参数传递
      await historyService.saveRestaurantHistory(restaurant, 'wheel');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${restaurant.name} saved to history'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving to history: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save to history'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Convert API types to friendly English display names
  String _formatCuisineType(String cuisine) {
    const typeMap = {
      'meal_takeaway': 'Takeaway',
      'meal_delivery': 'Delivery',
      'restaurant': 'Restaurant',
      'bakery': 'Bakery',
      'bar': 'Bar',
      'cafe': 'Cafe',
      'night_club': 'Night Club',
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
      'chinese': 'Chinese',
      'japanese': 'Japanese',
      'korean': 'Korean',
      'italian': 'Italian',
      'mexican': 'Mexican',
      'thai': 'Thai',
      'vietnamese': 'Vietnamese',
      'indian': 'Indian',
      'american': 'American',
      'french': 'French',
    };

    return typeMap[cuisine.toLowerCase()] ?? cuisine.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WheelBloc>().state;
    final Restaurant? restaurant = state.selectedRestaurant;
    final bloc = context.read<WheelBloc>();
    final apiKey = bloc.apiKey;

    if (restaurant == null) {
      return const Center(
        child: Text(
          'No restaurant.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            child: Center(
              child: apiKey != null ? Image.network(
                'https://maps.googleapis.com/maps/api/staticmap'
                '?center=${restaurant.lat},${restaurant.lng}'
                '&zoom=15'
                '&size=550x200'
                '&maptype=roadmap'
                '&markers=color:red%7C${restaurant.lat},${restaurant.lng}'
                '&key=$apiKey',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Map not available', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ) : Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Map loading...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  restaurant.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const SizedBox(
                        width: 60,
                        height: 60,
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        color: Color(0xFF391713),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cuisine: ${_formatCuisineType(restaurant.cuisine)}',
                      style: const TextStyle(
                        color: Color(0xFF391713),
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    Text(
                      'Rating: ${restaurant.rating}',
                      style: const TextStyle(
                        color: Color(0xFF391713),
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Address: ${restaurant.address}',
            style: const TextStyle(
              color: Color(0xFF79747E),
              fontSize: 14,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.center,
            child: 
            CustomButtonWidget(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder:
                      (dialogContext) => MapPopup(
                        onAppleMapSelected: () async {
                          // handle Apple Map
                          print('Apple Map selected');
                          final uri = Uri.parse(
                            'http://maps.apple.com/?q=${Uri.encodeComponent(restaurant.address)}',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                            // 📚 保存到历史记录
                            await _saveToHistory(context, restaurant);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Couldn't open Apple Maps")),
                            );
                          }
                        },
                        onGoogleMapSelected: () async {
                          // handle Google Map
                          print('Google Map selected');
                          final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(restaurant.address)}',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                            // 📚 保存到历史记录
                            await _saveToHistory(context, restaurant);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Couldn't open Google Maps")),
                            );
                          }
                        },
                      ),
                );
              },
              text: "Let's Go!", 
              color: 'orange',
            )
          ),
        ],
      ),
    );
  }
}
