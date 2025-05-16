import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../blocs/wheel_bloc.dart';
import '../widgets/dialogs/result_dialog.dart';
import '../widgets/dialogs/map_popup.dart';
import 'dart:math';
import 'dart:async';
import '../models/restaurant.dart';

class WheelOne extends StatelessWidget {
  const WheelOne({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WheelBloc(),
      child: const WheelOneView(),
    );
  }
}

class WheelOneView extends StatefulWidget {
  const WheelOneView({super.key});

  @override
  State<WheelOneView> createState() => _WheelOneViewState();
}

class _WheelOneViewState extends State<WheelOneView> {
  late StreamController<int> _streamController;
  late Random _random;
  bool _isSpinning = false;
  List<Restaurant> _restaurants = [];
  Restaurant? _selectedRestaurant;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<int>();
    _random = Random();
    // 初始化餐厅列表
    _restaurants = [
      Restaurant(
        name: 'Restaurant 1',
        cuisine: 'Chinese',
        rating: 4.5,
        address: '123 Main St',
        imageUrl: 'https://picsum.photos/200',
      ),
      Restaurant(
        name: 'Restaurant 2',
        cuisine: 'Japanese',
        rating: 4.8,
        address: '456 Oak Ave',
        imageUrl: 'https://picsum.photos/201',
      ),
      Restaurant(
        name: 'Restaurant 3',
        cuisine: 'Western',
        rating: 4.2,
        address: '789 Pine Rd',
        imageUrl: 'https://picsum.photos/202',
      ),
      Restaurant(
        name: 'Restaurant 4',
        cuisine: 'Korean',
        rating: 4.6,
        address: '321 Elm St',
        imageUrl: 'https://picsum.photos/203',
      ),
    ];
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  void _onWheelStop() {
    if (_isSpinning) {
      setState(() {
        _isSpinning = false;
      });
      // 移除弹窗，直接更新餐厅信息
      final selectedIndex = _random.nextInt(_restaurants.length);
      _selectedRestaurant = _restaurants[selectedIndex];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE95322),
        elevation: 0,
        title: const Text(
          'Wheel',
          style: TextStyle(
            color: Color(0xFF391713),
            fontSize: 22,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF391713)),
              onPressed: () {
                GoRouter.of(context).go('/add');
              },
            ),
          ),
        ],
      ),
      body: BlocBuilder<WheelBloc, WheelState>(
        builder: (context, state) {
          // 同步选项到转盘
          _restaurants = state.options.map((option) => Restaurant(
            name: option.name,
            cuisine: 'Cuisine',  // 默认值
            rating: 4.5,        // 默认值
            address: 'Address',  // 默认值
            imageUrl: 'https://picsum.photos/200',
          )).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                SizedBox(
                  height: 300,
                  child: FortuneWheel(
                    selected: _streamController.stream,
                    animateFirst: false,
                    onAnimationEnd: _onWheelStop,
                    items: [
                      for (var restaurant in _restaurants)
                        FortuneItem(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(
                              color: Color(0xFF391713),
                              fontSize: 16,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: FortuneItemStyle(
                            color: const Color(0xFFFFF3E0),
                            borderColor: const Color(0xFFE95322),
                            borderWidth: 3,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                BlocBuilder<WheelBloc, WheelState>(
                  builder: (context, state) {
                    final bool hasEnoughOptions = state.options.length >= 2;
                    return Column(
                      children: [
                        if (!hasEnoughOptions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Please add at least 2 options to spin the wheel',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        if (!state.showResult)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasEnoughOptions ? const Color(0xFFFFA500) : Colors.grey,
                              foregroundColor: const Color(0xFF391713),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            onPressed: hasEnoughOptions ? () async {
                              final randomIndex = Random().nextInt(context.read<WheelBloc>().state.options.length);
                              _streamController.add(randomIndex);
                              setState(() {
                                _isSpinning = true;
                              });
                            } : null,
                            child: const Text(
                              'GO!',
                              style: TextStyle(
                                fontSize: 17,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.09,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFA500),
                                  foregroundColor: const Color(0xFF391713),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder: (dialogContext) => MapPopup(
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
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF391713),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                    side: const BorderSide(color: Color(0xFFFFA500)),
                                  ),
                                ),
                                onPressed: () async {
                                  final randomIndex = Random().nextInt(context.read<WheelBloc>().state.options.length);
                                  _streamController.add(randomIndex);
                                  await Future.delayed(const Duration(seconds: 3));
                                  if (context.mounted) {
                                    final selectedOption = context.read<WheelBloc>().state.options[randomIndex];
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) => ResultDialog(
                                        title: selectedOption.name,
                                        description: 'Locally owned restaurant serving up a variety of traditional Chinese ...',
                                        price: '¥88',
                                        onClose: () {
                                          Navigator.of(dialogContext).pop();
                                          context.read<WheelBloc>().add(ShowResultEvent());
                                        },
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Try Again',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.09,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                BlocBuilder<WheelBloc, WheelState>(
                  builder: (context, state) => TextButton(
                    onPressed: () => context.read<WheelBloc>().add(ShowModifyEvent()),
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
                ),
                BlocBuilder<WheelBloc, WheelState>(
                  builder: (context, state) {
                    if (state.showModify) {
                      return Column(
                        children: [
                          const SizedBox(height: 24),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Edit Wheel Options',
                                      style: TextStyle(
                                        color: Color(0xFF391713),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Color(0xFF79747E)),
                                      onPressed: () => context.read<WheelBloc>().add(CloseModifyEvent()),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(state.options.length, (i) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE95322), width: 1.2),
                                          ),
                                          child: TextFormField(
                                            initialValue: state.options[i].name,
                                            style: const TextStyle(
                                              color: Color(0xFF391713),
                                              fontSize: 16,
                                              fontFamily: 'Roboto',
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            ),
                                            onChanged: (val) {
                                              context.read<WheelBloc>().add(UpdateOptionEvent(i, val));
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFE95322)),
                                        onPressed: state.options.length > 2 
                                          ? () => context.read<WheelBloc>().add(RemoveOptionEvent(i))
                                          : null,
                                      ),
                                    ],
                                  ),
                                )),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE95322),
                                    side: const BorderSide(color: Color(0xFFE95322)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => context.read<WheelBloc>().add(AddOptionEvent()),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Option'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 40),
                if (_selectedRestaurant != null) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500),
                      foregroundColor: const Color(0xFF391713),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (dialogContext) => MapPopup(
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
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF391713),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: const BorderSide(color: Color(0xFFFFA500)),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedRestaurant = null;
                      });
                    },
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 17,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.09,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
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
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(Icons.map, size: 60, color: Color(0xFF79747E)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: const SizedBox(
                                width: 60,
                                height: 60,
                                child: Icon(Icons.image, size: 40, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedRestaurant!.name,
                                    style: const TextStyle(
                                      color: Color(0xFF391713),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Cuisine: ${_selectedRestaurant!.cuisine}',
                                    style: const TextStyle(
                                      color: Color(0xFF391713),
                                      fontSize: 16,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  Text(
                                    'Rating: ${_selectedRestaurant!.rating}',
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
                          'Address: ${_selectedRestaurant!.address}',
                          style: const TextStyle(
                            color: Color(0xFF79747E),
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFFA500),
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
            icon: Icon(Icons.home, color: Color(0xFFE95322)),
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