import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_preference_repository.dart';
import '../models/preference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/dialogs/map_popup.dart';

class PreferenceManageScreen extends StatefulWidget {
  const PreferenceManageScreen({super.key});

  @override
  State<PreferenceManageScreen> createState() => _PreferenceManageScreenState();
}

class _PreferenceManageScreenState extends State<PreferenceManageScreen> {
  Preference? _preference;
  bool _loading = true;
  bool _isGuest = false;
  final _repo = UserPreferenceRepository();
  final _cuisineController = TextEditingController();
  List<Map<String, dynamic>> _allCuisines = [];
  bool _showLiked = true; // 新增：切换喜欢/不喜欢

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadCuisines();
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 游客模式 - 从SharedPreferences读取偏好
      await _loadGuestPreferences();
      setState(() {
        _isGuest = true;
        _loading = false;
      });
      return;
    }
    
    // 检查是否为游客
    final userInfo = await FirebaseFirestore.instanceFor(
      app: FirebaseFirestore.instance.app,
      databaseId: 'userinfo',
    ).collection('userinfo').doc(user.uid).get();
    
    if (!userInfo.exists) {
      // 用户信息不存在，也是游客模式
      await _loadGuestPreferences();
      setState(() {
        _isGuest = true;
        _loading = false;
      });
      return;
    }
    
    // 正常用户 - 从Firebase读取偏好
    final pref = await _repo.fetchPreference(user.uid);
    setState(() {
      _preference = pref ?? Preference(userId: user.uid);
      _loading = false;
    });
  }

  Future<void> _loadGuestPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    final likedCuisines = prefs.getStringList('guest_liked_cuisines') ?? [];
    final dislikedCuisines = prefs.getStringList('guest_disliked_cuisines') ?? [];
    
    // 加载餐厅信息 - 兼容旧格式
    final likedRestaurantsStr = prefs.getStringList('guest_liked_restaurants') ?? [];
    final dislikedRestaurantsStr = prefs.getStringList('guest_disliked_restaurants') ?? [];
    
    // 将字符串转换为RestaurantInfo对象
    final likedRestaurants = likedRestaurantsStr.map((str) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return RestaurantInfo.fromMap(map);
      } catch (e) {
        // 兼容旧格式：如果解析失败，认为是直接的名字字符串
        return RestaurantInfo(id: str, name: str);
      }
    }).toList();
    
    final dislikedRestaurants = dislikedRestaurantsStr.map((str) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return RestaurantInfo.fromMap(map);
      } catch (e) {
        // 兼容旧格式：如果解析失败，认为是直接的名字字符串
        return RestaurantInfo(id: str, name: str);
      }
    }).toList();
    
    _preference = Preference(
      userId: 'guest',
      likedCuisines: likedCuisines,
      dislikedCuisines: dislikedCuisines,
      likedRestaurants: likedRestaurants,
      dislikedRestaurants: dislikedRestaurants,
    );
  }

  Future<void> _loadCuisines() async {
    // 读取assets/cuisines.json
    final data = await DefaultAssetBundle.of(context).loadString('assets/cuisines.json');
    final json = jsonDecode(data);
    setState(() {
      _allCuisines = List<Map<String, dynamic>>.from(json['cuisines']);
    });
  }

  Future<void> _updatePreference() async {
    if (_preference != null) {
      if (_isGuest) {
        // 游客模式 - 保存到SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('guest_liked_cuisines', _preference!.likedCuisines);
        await prefs.setStringList('guest_disliked_cuisines', _preference!.dislikedCuisines);
        await prefs.setStringList('guest_liked_restaurants', _preference!.likedRestaurants.map((r) => jsonEncode(r.toMap())).toList());
        await prefs.setStringList('guest_disliked_restaurants', _preference!.dislikedRestaurants.map((r) => jsonEncode(r.toMap())).toList());
      } else {
        // 正常用户 - 保存到Firebase
        await _repo.setPreference(_preference!);
      }
      setState(() {});
    }
  }

  void _addCuisine(bool like) async {
    final keyword = _cuisineController.text.trim();
    if (keyword.isEmpty) return;
    setState(() {
      if (like) {
        if (!_preference!.likedCuisines.contains(keyword)) {
          _preference!.likedCuisines.add(keyword);
        }
      } else {
        if (!_preference!.dislikedCuisines.contains(keyword)) {
          _preference!.dislikedCuisines.add(keyword);
        }
      }
      _cuisineController.clear();
    });
    await _updatePreference();
  }

  void _removeCuisine(String keyword, bool like) async {
    setState(() {
      if (like) {
        _preference!.likedCuisines.remove(keyword);
      } else {
        _preference!.dislikedCuisines.remove(keyword);
      }
    });
    await _updatePreference();
  }

  void _removeRestaurant(String restaurantId, bool like) async {
    setState(() {
      if (like) {
        _preference!.likedRestaurants.removeWhere((r) => r.id == restaurantId);
      } else {
        _preference!.dislikedRestaurants.removeWhere((r) => r.id == restaurantId);
      }
    });
    await _updatePreference();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isGuest) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x07000000),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFFFA4A0C),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontFamily: 'SF Pro Text',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Data saved locally',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontFamily: 'SF Pro Text',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 新增：切换栏
              _buildToggleBar(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildPreferenceManagementContent(),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x07000000),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFFFA4A0C),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Preference Management',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontFamily: 'SF Pro Text',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // 新增：切换栏
            _buildToggleBar(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildPreferenceManagementContent(),
            ),
          ],
        ),
      ),
    );
  }

  // 新增：切换栏Widget
  Widget _buildToggleBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showLiked = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _showLiked ? const Color(0xFFE95322) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                border: Border.all(color: const Color(0xFFE95322)),
              ),
              child: Center(
                child: Text(
                  'Liked',
                  style: TextStyle(
                    color: _showLiked ? Colors.white : const Color(0xFFE95322),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showLiked = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !_showLiked ? const Color(0xFFE95322) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: const Color(0xFFE95322)),
              ),
              child: Center(
                child: Text(
                  'Disliked',
                  style: TextStyle(
                    color: !_showLiked ? Colors.white : const Color(0xFFE95322),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 修改：只显示当前选中的部分
  Widget _buildPreferenceManagementContent() {
    if (_preference == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showLiked)
            _PreferenceSection(
              title: 'Liked',
              isLiked: true,
              preference: _preference!,
              allCuisines: _allCuisines,
              cuisineController: _cuisineController,
              onAddCuisine: _addCuisine,
              onRemoveCuisine: _removeCuisine,
              onRemoveRestaurant: _removeRestaurant,
            ),
          if (!_showLiked)
            _PreferenceSection(
              title: 'Disliked',
              isLiked: false,
              preference: _preference!,
              allCuisines: _allCuisines,
              cuisineController: _cuisineController,
              onAddCuisine: _addCuisine,
              onRemoveCuisine: _removeCuisine,
              onRemoveRestaurant: _removeRestaurant,
            ),
        ],
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  final String title;
  final bool isLiked;
  final Preference preference;
  final List<Map<String, dynamic>> allCuisines;
  final TextEditingController cuisineController;
  final Function(bool) onAddCuisine;
  final Function(String, bool) onRemoveCuisine;
  final Function(String, bool) onRemoveRestaurant;
  const _PreferenceSection({
    required this.title,
    required this.isLiked,
    required this.preference,
    required this.allCuisines,
    required this.cuisineController,
    required this.onAddCuisine,
    required this.onRemoveCuisine,
    required this.onRemoveRestaurant,
  });

  @override
  Widget build(BuildContext context) {
    final cuisines = isLiked ? preference.likedCuisines : preference.dislikedCuisines;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0x07000000),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          // Cuisine Section
          Text(
            'Cuisine',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          cuisines.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    'No cuisines added yet',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )              : Column(
                  children: cuisines.map((c) => _buildCuisineCard(c, isLiked)).toList(),
                ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: null,
                  hint: const Text('Select cuisine'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFA4A0C)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: allCuisines.map((c) => DropdownMenuItem(
                    value: c['keyword'] as String?,
                    child: Text(c['name'] as String? ?? ''),
                  )).toList(),
                  onChanged: (val) {
                    cuisineController.text = val ?? '';
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFA270C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => onAddCuisine(isLiked),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Restaurant Section - 只显示，不能添加
          Text(
            'Restaurants',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildRestaurantsDisplay(isLiked),
        ],
      ),
    );
  }

  Widget _buildRestaurantsDisplay(bool isLiked) {
    final restaurants = isLiked ? preference.likedRestaurants : preference.dislikedRestaurants;

    if (restaurants.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          'No restaurants added yet',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: restaurants.map((r) => _PreferenceRestaurantCard(restaurant: r, isLiked: isLiked, onRemove: onRemoveRestaurant)).toList(),
    );
  }

  Widget _buildCuisineCard(String cuisine, bool isLiked) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/cuisines_images/$cuisine.png',
                width: 93,
                height: 93,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 93,
                  height: 93,
                  child: Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatCuisineName(cuisine),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        size: 14,
                        color: Color(0xFFE95322),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Cuisine',
                        style: TextStyle(
                          color: Color(0xFFE95322),
                          fontSize: 11,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.heart_broken,
                        size: 14,
                        color: isLiked ? const Color(0xFFE95322) : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLiked ? 'Liked' : 'Disliked',
                        style: TextStyle(
                          color: isLiked ? const Color(0xFFE95322) : Colors.grey,
                          fontSize: 11,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFF391713)),
                  onPressed: () => onRemoveCuisine(cuisine, isLiked),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCuisineName(String cuisine) {
    // Convert cuisine keyword to display name
    final displayMap = {
      'chinese': 'Chinese',
      'japanese': 'Japanese',
      'korean': 'Korean',
      'italian': 'Italian',
      'mexican': 'Mexican',
      'thai': 'Thai',
      'vietnamese': 'Vietnamese',
      'indian': 'Indian',
      'french': 'French',
      'american': 'American',
      'mediterranean': 'Mediterranean',
      'greek': 'Greek',
      'spanish': 'Spanish',
      'turkish': 'Turkish',
      'lebanese': 'Lebanese',
      'african': 'African',
      'brazilian': 'Brazilian',
      'cuban': 'Cuban',
      'german': 'German',
      'halal': 'Halal',
    };
    
    return displayMap[cuisine.toLowerCase()] ?? cuisine.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }
}

// 新增：完整卡片组件
class _PreferenceRestaurantCard extends StatelessWidget {
  final RestaurantInfo restaurant;
  final bool isLiked;
  final Function(String, bool) onRemove;
  const _PreferenceRestaurantCard({required this.restaurant, required this.isLiked, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final imageUrl = restaurant.photoRef != null
        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${restaurant.photoRef}&key=你的API_KEY'
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 93,
                      height: 93,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    )
                  : const SizedBox(
                      width: 93,
                      height: 93,
                      child: Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (restaurant.address != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      restaurant.address!,
                      style: const TextStyle(
                        color: Color(0xFF79747E),
                        fontSize: 12,
                        fontFamily: 'Roboto',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (restaurant.types != null && restaurant.types!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          size: 14,
                          color: Color(0xFFE95322),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurant.types!.join('、'),
                            style: const TextStyle(
                              color: Color(0xFFE95322),
                              fontSize: 11,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Transform.rotate(
                    angle: 1.5708,
                    child: const Icon(Icons.navigation, color: Color(0xFFE95322)),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => MapPopup(
                        onAppleMapSelected: () {
                          // 处理 Apple Map 选择
                        },
                        onGoogleMapSelected: () {
                          // 处理 Google Map 选择
                        },
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFF391713)),
                  onPressed: () => onRemove(restaurant.id, isLiked),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}