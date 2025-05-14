import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WheelOne extends StatelessWidget {
  const WheelOne({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE95322),
        elevation: 0,
        title: const Text(
          'What to eat today?',
          style: TextStyle(
            color: Color(0xFF391713),
            fontSize: 22,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          const Text(
            'Make a turn!',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Container(
              width: 279,
              height: 279,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://placehold.co/279x279'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA500),
              foregroundColor: const Color(0xFF391713),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            onPressed: () {},
            child: const Text(
              'GO!',
              style: TextStyle(
                fontSize: 17,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w700,
                letterSpacing: -0.09,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Modify my wheel',
              style: TextStyle(
                color: Color(0xFF386BF6),
                fontSize: 15,
                fontStyle: FontStyle.italic,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE95322),
        unselectedItemColor: const Color(0xFF391713),
        currentIndex: 1,
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
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}