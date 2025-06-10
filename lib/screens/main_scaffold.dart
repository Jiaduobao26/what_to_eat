import 'package:flutter/material.dart';
import '../services/nearby_restaurant_provider.dart';
import 'lists.dart';
import 'wheel.dart';
import 'profile.dart';
import '../widgets/dialogs/edit_wheel_option_dialog.dart';
import '../widgets/app_bar_actions_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/wheel_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatefulWidget {
  static final GlobalKey<_MainScaffoldState> globalKey = GlobalKey<_MainScaffoldState>();
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 1; // 默认转盘页
  List<Map<String, dynamic>>? _restaurants;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      Lists(onRestaurantsChanged: (restaurants) {
        setState(() {
          _restaurants = restaurants;
        });
      }),
      const WheelOne(),
      const ProfileScreen(),
    ]);
    _checkIfNeedsPreferenceSetup();
  }

  // 检查当前用户是否需要设置偏好
  Future<void> _checkIfNeedsPreferenceSetup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final prefs = await SharedPreferences.getInstance();
      final needsPreferenceEmails = prefs.getStringList('needsPreferenceSetup') ?? [];
      
      if (needsPreferenceEmails.contains(user.email)) {
        // 当前用户需要设置偏好，跳转到偏好选择页面
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/preferenceChoose');
        });
      }
    }
  }

  void switchTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Recommendation';
      case 1:
        return 'Wheel';
      case 2:
        return 'What to eat today?';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    void showEditWheelDialog() {
      showDialog(
        context: context,
        builder: (dialogContext) => BlocProvider(
          create: (_) => WheelBloc(),
          child: const EditWheelOptionsDialog(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE95322),
        elevation: 0,
        title: Text(
          _getTitle(_selectedIndex),
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 22,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          AppBarActionsWidget(
            location: _selectedIndex == 0 ? '/lists' : _selectedIndex == 1 ? '/wheel' : '/profile',
            onEditWheel: _selectedIndex == 1 ? showEditWheelDialog : null,
            restaurants: _selectedIndex == 0 ? _restaurants : null,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE95322),
        unselectedItemColor: const Color(0xFF391713),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
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
      ),
    );
  }
}