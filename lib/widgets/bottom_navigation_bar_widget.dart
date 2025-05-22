import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;

  const BottomNavigationBarWidget({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFFA500),
      unselectedItemColor: const Color(0xFF391713),
      currentIndex: currentIndex,
      onTap: (i) {
        if (i == 0) {
          GoRouter.of(context).go('/lists');
        } else if (i == 1) {
          GoRouter.of(context).go('/wheel');
        } else if (i == 2) {
          GoRouter.of(context).go('/profile');
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'List',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home, color: Color(0xFFE95322)),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}