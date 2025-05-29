import 'package:flutter/material.dart';
import '../screens/lists.dart';
import '../screens/wheel.dart';
import '../screens/profile.dart';
import '../widgets/app_bar_actions_widget.dart';
import '../widgets/dialogs/edit_wheel_option_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/wheel_bloc.dart';

class MainScaffold extends StatefulWidget {
  static final GlobalKey<_MainScaffoldState> globalKey = GlobalKey<_MainScaffoldState>();
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 1; // 默认转盘页

  final List<Widget> _pages = const [
    Lists(),
    WheelOne(),
    ProfileScreen(),
  ];

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
            color: Color(0xFF391713),
            fontSize: 22,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          AppBarActionsWidget(
            location: _selectedIndex == 0 ? '/lists' : _selectedIndex == 1 ? '/wheel' : '/profile',
            onEditWheel: _selectedIndex == 1 ? showEditWheelDialog : null,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFFA500),
        unselectedItemColor: const Color(0xFF391713),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
      ),
    );
  }
}