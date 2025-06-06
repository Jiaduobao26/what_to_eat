import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/nearby_restaurant_provider.dart';
import '../services/restaurant_detail_service.dart';
import '../repositories/user_preference_repository.dart';
import '../models/preference.dart' as pref_models;
import '../models/restaurant.dart';
import '../blocs/wheel_bloc.dart';
import '../widgets/dice/dice_face.dart';
import '../utils/restaurant_utils.dart';

enum RandomMode { surprise, preference }

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
  
  // 新增：随机模式选择
  RandomMode _selectedMode = RandomMode.surprise;

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
    print('Performing random selection in ${_selectedMode.name} mode...');
    try {
      if (_selectedMode == RandomMode.surprise) {
        await _performSurpriseSelection();
      } else {
        await _performPreferenceBasedSelection();
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

  // Surprise me! 模式 - 完全随机选择
  Future<void> _performSurpriseSelection() async {
    // 创建列表副本以避免并发修改异常
    final originalList = Provider.of<NearbyRestaurantProvider>(context, listen: false).restaurants;
    final nearbyList = List<Map<String, dynamic>>.from(originalList);
    print('Total restaurants from provider: ${nearbyList.length}');
    
    final filteredRestaurants = await filterDislikedRestaurants(nearbyList);
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
    
    await _displaySelectedRestaurant(selectedRestaurant);
  }

  // Based on my preference 模式 - 基于用户偏好选择
  Future<void> _performPreferenceBasedSelection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      pref_models.Preference? preference;
      
      if (user != null) {
        // 登录用户 - 从Firebase获取偏好
        final repo = UserPreferenceRepository();
        preference = await repo.fetchPreference(user.uid);
      } else {
        // 游客用户 - 从SharedPreferences获取偏好
        preference = await getGuestPreferences();
      }
      
      if (preference == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No preferences found. Please set your preferences first.')),
          );
        }
        return;
      }
      
      print('🎯 User preferences:');
      print('   Liked cuisines: ${preference.likedCuisines}');
      print('   Disliked cuisines: ${preference.dislikedCuisines}');
      print('   Liked restaurants: ${preference.likedRestaurants.map((r) => r.name).toList()}');
      
      // 创建混合的偏好选择池
      final mixedPreferences = <dynamic>[];
      
      // 添加所有喜欢的餐厅
      mixedPreferences.addAll(preference.likedRestaurants);
      
      // 添加所有喜欢的菜系
      mixedPreferences.addAll(preference.likedCuisines);
      
      if (mixedPreferences.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No liked restaurants or cuisines found. Please add some preferences first.')),
          );
        }
        return;
      }
      
      print('Mixed preferences pool size: ${mixedPreferences.length} (${preference.likedRestaurants.length} restaurants + ${preference.likedCuisines.length} cuisines)');
      
      // 尝试选择，如果失败则重试（最多3次）
      int maxRetries = 3;
      bool selectionMade = false;
      
      for (int attempt = 1; attempt <= maxRetries && !selectionMade; attempt++) {
        print('🎲 Selection attempt $attempt/$maxRetries');
        
        // 随机选择一个偏好项目
        final randomIndex = _random.nextInt(mixedPreferences.length);
        final selectedPreference = mixedPreferences[randomIndex];
        
        try {
          // 根据选中的类型进行相应处理
          if (selectedPreference is pref_models.RestaurantInfo) {
            // 选中的是餐厅，检查菜系偏好后选择
            print('🍽️ Selected liked restaurant: ${selectedPreference.name} (ID: ${selectedPreference.id})');
            await _selectSpecificRestaurant(selectedPreference);
            selectionMade = true;
          } else if (selectedPreference is String) {
            // 选中的是菜系，从该菜系中随机选择餐厅
            print('🍜 Selected liked cuisine: $selectedPreference');
            await _selectFromSpecificCuisine(selectedPreference);
            selectionMade = true;
          }
        } catch (e) {
          print('❌ Attempt $attempt failed: $e');
          if (attempt == maxRetries) {
            print('⚠️ All attempts failed, falling back to surprise mode');
            await _performSurpriseSelection();
            selectionMade = true;
          }
        }
      }
      
    } catch (e) {
      print('❌ Error in preference-based selection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences. Falling back to random selection.')),
        );
      }
      // 回退到surprise模式
      await _performSurpriseSelection();
    }
  }

  // 选择特定的餐厅（通过API获取详情）
  Future<void> _selectSpecificRestaurant(pref_models.RestaurantInfo restaurantInfo) async {
    try {
      // 使用Google Places API获取餐厅详细信息
      final detailService = RestaurantDetailService();
      final restaurantDetail = await detailService.getRestaurantDetail(restaurantInfo.id);
      
      // 🚨 关键修复：在选择喜欢的餐厅之前，先检查菜系偏好
      final user = FirebaseAuth.instance.currentUser;
      List<String> dislikedCuisines = [];
      
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
      
      // 检查这个餐厅是否包含不喜欢的菜系
      for (final type in restaurantDetail.types) {
        final typeStr = type.toLowerCase();
        for (final dislikedCuisine in dislikedCuisines) {
          final dislikedLower = dislikedCuisine.toLowerCase();
          if (typeStr.contains(dislikedLower) || dislikedLower.contains(typeStr)) {
            print('🚨 Skipping liked restaurant ${restaurantInfo.name} because it contains disliked cuisine $dislikedCuisine (type: $typeStr)');
            throw Exception('Restaurant contains disliked cuisine');
          }
        }
      }
      
      print('✅ Liked restaurant ${restaurantInfo.name} passed cuisine filter check');
      
      // 转换为适合的格式并显示
      final restaurantData = {
        'place_id': restaurantDetail.placeId,
        'name': restaurantDetail.name,
        'vicinity': restaurantDetail.formattedAddress,
        'rating': restaurantDetail.rating ?? 0.0,
        'geometry': {
          'location': {
            'lat': restaurantDetail.geometry.location.lat,
            'lng': restaurantDetail.geometry.location.lng,
          }
        },
        'types': restaurantDetail.types,
        'photos': restaurantDetail.photos.isNotEmpty ? [
          {'photo_reference': restaurantDetail.photos.first.photoReference}
        ] : null,
      };
      
      await _displaySelectedRestaurant(restaurantData);
      
    } catch (e) {
      print('❌ Error with specific restaurant ${restaurantInfo.name}: $e');
      // 不显示错误消息给用户，让调用者处理fallback
      rethrow;
    }
  }

  // 从特定菜系中随机选择餐厅
  Future<void> _selectFromSpecificCuisine(String cuisine) async {
    // 创建列表副本以避免并发修改异常
    final originalList = Provider.of<NearbyRestaurantProvider>(context, listen: false).restaurants;
    final nearbyList = List<Map<String, dynamic>>.from(originalList);
    
    print('🔍 Searching for cuisine: $cuisine in ${nearbyList.length} nearby restaurants');
    
    // 找到匹配该菜系的附近餐厅
    final matchingRestaurants = <Map<String, dynamic>>[];
    
    for (final restaurant in nearbyList) {
      final types = restaurant['types'] as List<dynamic>? ?? [];
      final restaurantName = restaurant['name'] ?? 'Unknown';
      
      if (types.any((type) => type.toString().toLowerCase().contains(cuisine.toLowerCase()) ||
                              cuisine.toLowerCase().contains(type.toString().toLowerCase()))) {
        print('   ✅ Match found: $restaurantName (types: $types)');
        matchingRestaurants.add(restaurant);
      }
    }
    
    print('📊 Found ${matchingRestaurants.length} restaurants matching cuisine: $cuisine');
    
    if (matchingRestaurants.isNotEmpty) {
      // 在nearby list中找到了匹配的餐厅
      print('🚫 Applying dislike filters to nearby restaurants...');
      final filteredRestaurants = await filterDislikedRestaurants(matchingRestaurants);
      
      print('📊 After filtering: ${filteredRestaurants.length} restaurants remain');
      
      if (filteredRestaurants.isNotEmpty) {
        // 随机选择一个匹配的餐厅
        final randomIndex = _random.nextInt(filteredRestaurants.length);
        final selectedRestaurant = filteredRestaurants[randomIndex];
        
        print('🎲 Selected restaurant from nearby list: ${selectedRestaurant['name']} (index: $randomIndex)');
        
        await _displaySelectedRestaurant(selectedRestaurant);
        return;
      } else {
        print('⚠️ All nearby restaurants were filtered out due to dislikes, using Google API...');
      }
    } else {
      print('⚠️ No restaurants found in nearby list, using Google API...');
    }
    
    // 如果nearby list中没有找到合适的餐厅，使用Google API搜索
    try {
      print('🌐 Searching for $cuisine cuisine using Google API...');
      final detailService = RestaurantDetailService();
      final wheelBloc = context.read<WheelBloc>();
      final restaurant = await wheelBloc.fetchRestaurantByCuisine(cuisine);
      
      print('🎯 Found restaurant via API: ${restaurant.name}');
      
      // 直接显示API结果（API结果已经是Restaurant对象）
      context.read<WheelBloc>().add(SetSelectedRestaurantEvent(restaurant));
      
    } catch (e) {
      print('❌ Error searching via Google API: $e');
      throw Exception('No restaurants found for $cuisine cuisine');
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
              // 重新执行偏好选择
              await _performPreferenceBasedSelection();
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