import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/wheel_bloc.dart';
import '../models/restaurant.dart';
import '../widgets/dialogs/map_popup.dart';
import '../widgets/buttons/custom_button_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailCard extends StatelessWidget {
  const RestaurantDetailCard({super.key});

  // 将API类型转换为友好的显示名称
  String _formatCuisineType(String cuisine) {
    const typeMap = {
      'meal_takeaway': '外卖',
      'meal_delivery': '配送',
      'restaurant': '餐厅',
      'bakery': '烘焙店',
      'bar': '酒吧',
      'cafe': '咖啡店',
      'night_club': '夜店',
      'chinese_restaurant': '中餐',
      'japanese_restaurant': '日料',
      'korean_restaurant': '韩餐',
      'italian_restaurant': '意大利菜',
      'french_restaurant': '法餐',
      'mexican_restaurant': '墨西哥菜',
      'indian_restaurant': '印度菜',
      'thai_restaurant': '泰餐',
      'vietnamese_restaurant': '越南菜',
      'american_restaurant': '美式',
      'mediterranean_restaurant': '地中海菜',
      'pizza_restaurant': '披萨',
      'seafood_restaurant': '海鲜',
      'steakhouse': '牛排店',
      'sushi_restaurant': '寿司',
      'fast_food_restaurant': '快餐',
      'sandwich_shop': '三明治',
      'ice_cream_shop': '冰淇淋',
      'chinese': '中餐',
      'japanese': '日料',
      'korean': '韩餐',
      'italian': '意大利菜',
      'mexican': '墨西哥菜',
      'thai': '泰餐',
      'vietnamese': '越南菜',
      'indian': '印度菜',
      'american': '美式',
      'french': '法餐',
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
              child: Image.network(
                'https://maps.googleapis.com/maps/api/staticmap'
                '?center=${restaurant.lat},${restaurant.lng}'
                '&zoom=15'
                '&size=550x200'
                '&maptype=roadmap'
                '&markers=color:red%7C${restaurant.lat},${restaurant.lng}'
                '&key=$apiKey',
                fit: BoxFit.cover,
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
