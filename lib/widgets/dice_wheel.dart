import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/nearby_restaurant_provider.dart';
import '../repositories/user_preference_repository.dart';
import '../models/restaurant.dart';
import '../blocs/wheel_bloc.dart';
import '../widgets/dice/dice_face.dart';
import '../utils/restaurant_utils.dart';
import '../services/restaurant_selector_service.dart';
import './dice/dice_animation_controller.dart';

enum RandomMode { surprise, preference }

class DiceWheel extends StatefulWidget {
  final Function(VoidCallback)? onRegisterCallback;
  
  const DiceWheel({super.key, this.onRegisterCallback});

  @override
  State<DiceWheel> createState() => _DiceWheelState();
}

class _DiceWheelState extends State<DiceWheel> with SingleTickerProviderStateMixin {
  late DiceAnimationController _diceAnim;
  bool _isDiceRolling = false;
  
  int _currentDiceNumber = 1;
  final Random _random = Random();

  // 新增：随机模式选择  
  RandomMode _selectedMode = RandomMode.surprise;

  late RestaurantSelectorService _restaurantSelectorService;

  @override
  void initState() {
    super.initState();
    
    // 先初始化骰子动画控制器
    _diceAnim = DiceAnimationController(vsync: this);
    
    // 注册回调函数
    widget.onRegisterCallback?.call(rollDice);


    _diceAnim.controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isDiceRolling = false;
        });
        _performRandomSelection();
      }
    });

    _restaurantSelectorService = RestaurantSelectorService(context);
    // 初始化时随机设置一个骰子数字
    _currentDiceNumber = _random.nextInt(6) + 1;
  }

  @override
  void dispose() {
    _diceAnim.dispose();
    super.dispose();
  }

  // 公共方法供外部调用
  void rollDice() {
    _rollDice();
  }

  void resetAnimation() {
    if (_diceAnim.controller.isAnimating) {
      _diceAnim.controller.stop();
    }
    _diceAnim.controller.reset();
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
    _diceAnim.controller.reset();

    // 动画过程中随机改变骰子数字
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_diceAnim.controller.isAnimating) {
        setState(() {
          _currentDiceNumber = _random.nextInt(6) + 1;
        });
      } else {
        timer.cancel();
        print('Dice animation timer cancelled');
      }
    });

    _diceAnim.controller.forward();
  }

  // 执行随机餐厅选择
  Future<void> _performRandomSelection() async {
    print('Performing random selection in ${_selectedMode.name} mode...');
    try {
      if (_selectedMode == RandomMode.surprise) {
        final originalList = Provider.of<NearbyRestaurantProvider>(context, listen: false).restaurants;
        final nearbyList = List<Map<String, dynamic>>.from(originalList);
        final selected = await _restaurantSelectorService.performSurpriseSelection(
          nearbyList,
          filterDislikedRestaurants,
        );
        if (selected != null) {
          await _displaySelectedRestaurant(selected);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No restaurants available for random selection')),
          );
        }
      } else {
        await _restaurantSelectorService.performPreferenceBasedSelection(
          getPreference: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final repo = UserPreferenceRepository();
              return await repo.fetchPreference(user.uid);
            } else {
              return await getGuestPreferences();
            }
          },
          displaySelectedRestaurant: _displaySelectedRestaurant,
          filterDislikedRestaurants: filterDislikedRestaurants,
          fallbackSurpriseSelection: () async {
            final originalList = Provider.of<NearbyRestaurantProvider>(context, listen: false).restaurants;
            final nearbyList = List<Map<String, dynamic>>.from(originalList);
            final selected = await _restaurantSelectorService.performSurpriseSelection(
              nearbyList,
              filterDislikedRestaurants,
            );
            if (selected != null) {
              await _displaySelectedRestaurant(selected);
            }
          },
        );
      }
    } catch (e) {
      print('Error in random selection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting random restaurant: $e')),
        );
      }
    }
  }

  // 显示选中的餐厅
  Future<void> _displaySelectedRestaurant(Map<String, dynamic> selectedRestaurant) async {
    if (mounted) {
      final types = selectedRestaurant['types'] as List<dynamic>? ?? [];
      final restaurantName = selectedRestaurant['name'] ?? 'Unknown';

      print('Displaying selected restaurant: $restaurantName (types: $types)');

      // 🚨 最终验证：确保这个餐厅不包含不喜欢的菜系
      final user = FirebaseAuth.instance.currentUser;
      List<String> dislikedCuisines = [];

      try {
        if (user != null) {
          final repo = UserPreferenceRepository();
          final pref = await repo.fetchPreference(user.uid);
          if (pref != null) {
            dislikedCuisines = pref.dislikedCuisines;
          }
        } else {
          final prefs = await SharedPreferences.getInstance();
          dislikedCuisines = prefs.getStringList('guest_disliked_cuisines') ?? [];
        }

        // 检查是否包含不喜欢的菜系
        for (final type in types) {
          final typeStr = type.toString().toLowerCase();
          for (final dislikedCuisine in dislikedCuisines) {
            final dislikedLower = dislikedCuisine.toLowerCase();
            if (typeStr.contains(dislikedLower) || dislikedLower.contains(typeStr)) {
              print('🚨 Final validation failed: $restaurantName contains disliked cuisine $dislikedCuisine (type: $typeStr)');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('发现不喜欢的菜系，重新选择...')),
                );
              }
              await _performRandomSelection();
              return;
            }
          }
        }

        print('✅ Final validation passed for: $restaurantName');
      } catch (e) {
        print('⚠️ Error in final validation: $e, proceeding anyway...');
      }

      // 创建Restaurant对象
      final restaurant = Restaurant(
        name: restaurantName,
        cuisine: formatCuisineType(types),
        rating: (selectedRestaurant['rating'] as num?)?.toDouble() ?? 0.0,
        address: selectedRestaurant['vicinity'] ?? selectedRestaurant['formatted_address'] ?? 'Unknown address',
        imageUrl: getPhotoUrl(selectedRestaurant),
        lat: (selectedRestaurant['geometry']?['location']?['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (selectedRestaurant['geometry']?['location']?['lng'] as num?)?.toDouble() ?? 0.0,
      );

      print('✅ Created restaurant object: ${restaurant.name}, cuisine: ${restaurant.cuisine}');

      // 🔧 修复：直接设置选中的餐厅状态，而不是触发新的搜索
      // 使用SetSelectedRestaurantEvent直接设置结果
      context.read<WheelBloc>().add(SetSelectedRestaurantEvent(restaurant));
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 骰子动画
          AnimatedBuilder(
            animation: _diceAnim.controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _diceAnim.rotationAnimation.value,
                child: Transform.scale(
                  scale: _diceAnim.scaleAnimation.value,
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
                      child: DiceFace(_currentDiceNumber),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 30),
          
          // 模式选择按钮 - 新的样式，放在骰子下方
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Surprise me! 按钮
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedMode = RandomMode.surprise;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMode == RandomMode.surprise 
                          ? const Color(0xFFE95322) 
                          : Colors.white,
                      foregroundColor: _selectedMode == RandomMode.surprise 
                          ? Colors.white 
                          : const Color(0xFFE95322),
                      side: const BorderSide(color: Color(0xFFE95322), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      elevation: _selectedMode == RandomMode.surprise ? 4 : 1,
                    ),
                    icon: Icon(
                      Icons.casino,
                      size: 18,
                      color: _selectedMode == RandomMode.surprise 
                          ? Colors.white 
                          : const Color(0xFFE95322),
                    ),
                    label: const Text(
                      'Surprise me!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Based on my preference 按钮
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedMode = RandomMode.preference;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMode == RandomMode.preference 
                          ? const Color(0xFF4CAF50) 
                          : Colors.white,
                      foregroundColor: _selectedMode == RandomMode.preference 
                          ? Colors.white 
                          : const Color(0xFF4CAF50),
                      side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      elevation: _selectedMode == RandomMode.preference ? 4 : 1,
                    ),
                    icon: Icon(
                      Icons.favorite,
                      size: 18,
                      color: _selectedMode == RandomMode.preference 
                          ? Colors.white 
                          : const Color(0xFF4CAF50),
                    ),
                    label: const Text(
                      'Based on my preference',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Text(
            _isDiceRolling 
                ? 'Rolling...' 
                : _selectedMode == RandomMode.surprise 
                    ? 'Roll for a surprise restaurant!'
                    : 'Roll for a restaurant you\'ll love!',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF391713),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}