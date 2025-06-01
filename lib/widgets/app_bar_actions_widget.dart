import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/map.dart';

class AppBarActionsWidget extends StatelessWidget {
  final String location;
  final VoidCallback? onEditWheel;
  final List<Map<String, dynamic>>? restaurants;
  
  const AppBarActionsWidget({
    super.key, 
    required this.location, 
    this.onEditWheel,
    this.restaurants,
  });

  @override
  Widget build(BuildContext context) {
    if (location.startsWith('/profile')) {
      // do not show actions on profile page
      return const SizedBox.shrink();
    }

    IconData icon;
    VoidCallback? onPressed;

    if (location.startsWith('/lists')) {
      icon = Icons.map;
      onPressed = () {
        // 使用push而不是go，这样可以正常返回
        context.push('/map', extra: restaurants);
      };
    } else if (location.startsWith('/wheel')) {
      icon = Icons.add;
      onPressed = onEditWheel;
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF391713)),
        onPressed: onPressed,
      ),
    );
  }
}