import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/nearby_restaurant_provider.dart';
import '../repositories/user_preference_repository.dart';
import '../blocs/wheel_bloc.dart';

class DiceWheel extends StatefulWidget {
  final Function(VoidCallback)? onRegisterCallback;
  
  const DiceWheel({super.key, this.onRegisterCallback});

  @override
  State<DiceWheel> createState() => _DiceWheelState();
}

class _DiceWheelState extends State<DiceWheel> with SingleTickerProviderStateMixin {
  late AnimationController _diceAnimationController;
  late Animation<double> _diceRotationAnimation;
  late Animation<double> _diceScaleAnimation;
  bool _isDiceRolling = false;
  
  int _currentDiceNumber = 1;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // 注册回调函数
    widget.onRegisterCallback?.call(rollDice);
    
    // 初始化骰子动画
    _diceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _diceRotationAnimation = Tween<double>(
      begin: 0,
      end: 8 * pi,
    ).animate(CurvedAnimation(
      parent: _diceAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _diceScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _diceAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _diceAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isDiceRolling = false;
        });
        _performRandomSelection();
      }
    });
    
    // 初始化时随机设置一个骰子数字
    _currentDiceNumber = _random.nextInt(6) + 1;
  }

  @override
  void dispose() {
    _diceAnimationController.dispose();
    super.dispose();
  }

  // 公共方法供外部调用
  void rollDice() {
    _rollDice();
  }

  void resetAnimation() {
    if (_diceAnimationController.isAnimating) {
      _diceAnimationController.stop();
    }
    _diceAnimationController.reset();
    setState(() {
      _isDiceRolling = false;
    });
  }

  // 骰子投掷动画 - 改为私有方法
  void _rollDice() {
    if (_isDiceRolling) {
      print('Dice is already rolling, ignoring...');
      return;
    }
    
    print('Starting dice animation...');
    setState(() {
      _isDiceRolling = true;
    });
    
    // 重置动画控制器
    _diceAnimationController.reset();
    
    // 动画过程中随机改变骰子数字
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_diceAnimationController.isAnimating) {
        setState(() {
          _currentDiceNumber = _random.nextInt(6) + 1;
        });
      } else {
        timer.cancel();
        print('Dice animation timer cancelled');
      }
    });
    
    _diceAnimationController.forward();
  }

  // 执行随机餐厅选择
  Future<void> _performRandomSelection() async {
    print('Performing random selection...');
    try {
      final nearbyList = Provider.of<NearbyRestaurantProvider>(context, listen: false).restaurants;
      print('Total restaurants from provider: ${nearbyList.length}');
      
      final filteredRestaurants = await _filterDislikedRestaurants(nearbyList);
      print('Filtered restaurants count: ${filteredRestaurants.length}');
      
      if (filteredRestaurants.isEmpty) {
        print('No restaurants available for random selection');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No restaurants available for random selection')),
          );
        }
        return;
      }
      
      // 随机选择一个餐厅
      final randomIndex = _random.nextInt(filteredRestaurants.length);
      final selectedRestaurant = filteredRestaurants[randomIndex];
      
      print('Random selection: index $randomIndex, restaurant: ${selectedRestaurant['name']}');
      
      // 使用现有的bloc逻辑显示随机选择的餐厅
      if (mounted) {
        final types = selectedRestaurant['types'] as List<dynamic>? ?? [];
        final cuisineType = types.isNotEmpty ? types.first.toString() : 'restaurant';
        
        print('Using cuisine type: $cuisineType');
        
        context.read<WheelBloc>().add(
          FetchRestaurantEvent(cuisineType, nearbyList: [selectedRestaurant]),
        );
      }
    } catch (e) {
      print('Error in random selection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error selecting random restaurant')),
        );
      }
    }
  }

  // 过滤不喜欢的餐厅
  Future<List<Map<String, dynamic>>> _filterDislikedRestaurants(List<Map<String, dynamic>> restaurants) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return restaurants;

    try {
      final repo = UserPreferenceRepository();
      final pref = await repo.fetchPreference(user.uid);
      if (pref == null) return restaurants;

      final dislikedRestaurantIds = pref.dislikedRestaurantIds;
      final dislikedCuisines = pref.dislikedCuisines;

      return restaurants.where((restaurant) {
        final placeId = restaurant['place_id'] as String? ?? '';
        final types = restaurant['types'] as List<dynamic>? ?? [];
        
        if (dislikedRestaurantIds.contains(placeId)) {
          return false;
        }
        
        for (final type in types) {
          if (dislikedCuisines.contains(type.toString())) {
            return false;
          }
        }
        
        return true;
      }).toList();
    } catch (e) {
      print('Error filtering restaurants: $e');
      return restaurants;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _diceAnimationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _diceRotationAnimation.value,
                child: Transform.scale(
                  scale: _diceScaleAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE95322), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _buildDiceface(_currentDiceNumber),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            _isDiceRolling ? 'Rolling...' : 'Roll for a random restaurant!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF391713),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceface(int number) {
    final dots = <Widget>[];
    
    switch (number) {
      case 1:
        dots.add(const Positioned(
          top: 45, left: 45,
          child: DiceDot(),
        ));
        break;
      case 2:
        dots.addAll([
          const Positioned(top: 20, left: 20, child: DiceDot()),
          const Positioned(bottom: 20, right: 20, child: DiceDot()),
        ]);
        break;
      case 3:
        dots.addAll([
          const Positioned(top: 15, left: 15, child: DiceDot()),
          const Positioned(top: 45, left: 45, child: DiceDot()),
          const Positioned(bottom: 15, right: 15, child: DiceDot()),
        ]);
        break;
      case 4:
        dots.addAll([
          const Positioned(top: 20, left: 20, child: DiceDot()),
          const Positioned(top: 20, right: 20, child: DiceDot()),
          const Positioned(bottom: 20, left: 20, child: DiceDot()),
          const Positioned(bottom: 20, right: 20, child: DiceDot()),
        ]);
        break;
      case 5:
        dots.addAll([
          const Positioned(top: 15, left: 15, child: DiceDot()),
          const Positioned(top: 15, right: 15, child: DiceDot()),
          const Positioned(top: 45, left: 45, child: DiceDot()),
          const Positioned(bottom: 15, left: 15, child: DiceDot()),
          const Positioned(bottom: 15, right: 15, child: DiceDot()),
        ]);
        break;
      case 6:
        dots.addAll([
          const Positioned(top: 15, left: 20, child: DiceDot()),
          const Positioned(top: 15, right: 20, child: DiceDot()),
          const Positioned(top: 45, left: 20, child: DiceDot()),
          const Positioned(top: 45, right: 20, child: DiceDot()),
          const Positioned(bottom: 15, left: 20, child: DiceDot()),
          const Positioned(bottom: 15, right: 20, child: DiceDot()),
        ]);
        break;
    }
    
    return Stack(children: dots);
  }
}

class DiceDot extends StatelessWidget {
  const DiceDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Color(0xFFE95322),
        shape: BoxShape.circle,
      ),
    );
  }
} 