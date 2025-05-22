import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_bar_actions_widget.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final String location;

  const MainScaffold({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {

    final bool hideBottomNavigationBar = location.contains('/preferenceChoose');
    final bool hideAppBar = location.contains('/preferenceChoose');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:hideAppBar ? null : AppBar(
        backgroundColor: const Color(0xFFE95322),
        elevation: 0,
        title: Text(
          _getTitle(context, location),
          style: const TextStyle(
            color: Color(0xFF391713),
            fontSize: 22,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          AppBarActionsWidget(location: location),
        ],
      ),
      body: child,
      bottomNavigationBar: !hideBottomNavigationBar
          ? BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFFFFA500),
              unselectedItemColor: const Color(0xFF391713),
              currentIndex: _getSelectedIndex(context, location),
              onTap: (index) => _onItemTapped(context, index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'List',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }

  String _getTitle(BuildContext context, String location) {
    if (location.startsWith('/lists')) {
      return 'Recommendation';
    } else if (location.startsWith('/wheel')) {
      return 'Wheel';
    } else {
      return 'What to eat today?';
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/lists');
        break;
      case 1:
        context.go('/wheel');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  int _getSelectedIndex(BuildContext context, String location) {
    if (location.startsWith('/lists')) {
      return 0;
    } else if (location.startsWith('/wheel')) {
      return 1;
    } else if (location.startsWith('/profile')) {
      return 2;
    }
    return 1; // default index
  }
}