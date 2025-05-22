import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBarActionsWidget extends StatelessWidget {
  final String location;
  const AppBarActionsWidget({super.key, required this.location});

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
        GoRouter.of(context).go('/map');
      };
    } else if (location.startsWith('/wheel')) {
      icon = Icons.add;
      onPressed = () {
        GoRouter.of(context).go('/add');
      };
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