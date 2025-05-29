import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/wheel_bloc.dart';
import '../models/restaurant.dart';
import '../widgets/dialogs/map_popup.dart';

class RestaurantDetailCard extends StatelessWidget {
  const RestaurantDetailCard({super.key});

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
                      'Cuisine: ${restaurant.cuisine}',
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
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
                foregroundColor: const Color(0xFF391713),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder:
                      (dialogContext) => MapPopup(
                        onAppleMapSelected: () {
                          // 处理 Apple Map 选择
                          print('Apple Map selected');
                        },
                        onGoogleMapSelected: () {
                          // 处理 Google Map 选择
                          print('Google Map selected');
                        },
                      ),
                );
              },
              child: const Text(
                "Let's Go!",
                style: TextStyle(
                  fontSize: 17,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.09,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
