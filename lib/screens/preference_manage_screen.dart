import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_preference_repository.dart';
import '../models/preference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';
import 'package:go_router/go_router.dart';

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
  final _restaurantController = TextEditingController();
  List<Map<String, dynamic>> _allCuisines = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadCuisines();
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
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
      setState(() {
        _isGuest = true;
        _loading = false;
      });
      return;
    }
    final pref = await _repo.fetchPreference(user.uid);
    setState(() {
      _preference = pref ?? Preference(userId: user.uid);
      _loading = false;
    });
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
      await _repo.setPreference(_preference!);
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

  void _addRestaurant(bool like) async {
    final name = _restaurantController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      if (like) {
        if (!_preference!.likedRestaurants.contains(name)) {
          _preference!.likedRestaurants.add(name);
        }
      } else {
        if (!_preference!.dislikedRestaurants.contains(name)) {
          _preference!.dislikedRestaurants.add(name);
        }
      }
      _restaurantController.clear();
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

  void _removeRestaurant(String name, bool like) async {
    setState(() {
      if (like) {
        _preference!.likedRestaurants.remove(name);
      } else {
        _preference!.dislikedRestaurants.remove(name);
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
                      } else {
                        context.go('/');
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
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Guest Mode',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to manage your food preferences',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontFamily: 'SF Pro Text',
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFA270C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      child: const Text(
                        'Back to Profile',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
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
                    } else {
                      context.go('/');
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreferenceSection(
                      title: 'Liked',
                      isLiked: true,
                      preference: _preference!,
                      allCuisines: _allCuisines,
                      cuisineController: _cuisineController,
                      restaurantController: _restaurantController,
                      onAddCuisine: _addCuisine,
                      onAddRestaurant: _addRestaurant,
                      onRemoveCuisine: _removeCuisine,
                      onRemoveRestaurant: _removeRestaurant,
                    ),
                    const SizedBox(height: 24),
                    _PreferenceSection(
                      title: 'Disliked',
                      isLiked: false,
                      preference: _preference!,
                      allCuisines: _allCuisines,
                      cuisineController: _cuisineController,
                      restaurantController: _restaurantController,
                      onAddCuisine: _addCuisine,
                      onAddRestaurant: _addRestaurant,
                      onRemoveCuisine: _removeCuisine,
                      onRemoveRestaurant: _removeRestaurant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
  final TextEditingController restaurantController;
  final Function(bool) onAddCuisine;
  final Function(bool) onAddRestaurant;
  final Function(String, bool) onRemoveCuisine;
  final Function(String, bool) onRemoveRestaurant;

  const _PreferenceSection({
    required this.title,
    required this.isLiked,
    required this.preference,
    required this.allCuisines,
    required this.cuisineController,
    required this.restaurantController,
    required this.onAddCuisine,
    required this.onAddRestaurant,
    required this.onRemoveCuisine,
    required this.onRemoveRestaurant,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cuisines = isLiked ? preference.likedCuisines : preference.dislikedCuisines;
    final restaurants = isLiked ? preference.likedRestaurants : preference.dislikedRestaurants;

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
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cuisines.map((c) => Chip(
                    label: Text(c),
                    onDeleted: () => onRemoveCuisine(c, isLiked),
                    backgroundColor: isLiked ? Colors.green[50] : Colors.red[50],
                    deleteIconColor: isLiked ? Colors.green[700] : Colors.red[700],
                    labelStyle: TextStyle(
                      color: isLiked ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  )).toList(),
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
          
          // Restaurant Section
          Text(
            'Restaurant Name',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          restaurants.isEmpty
              ? Container(
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
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: restaurants.map((r) => Chip(
                    label: Text(r),
                    onDeleted: () => onRemoveRestaurant(r, isLiked),
                    backgroundColor: isLiked ? Colors.green[50] : Colors.red[50],
                    deleteIconColor: isLiked ? Colors.green[700] : Colors.red[700],
                    labelStyle: TextStyle(
                      color: isLiked ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  )).toList(),
                ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: restaurantController,
                  decoration: InputDecoration(
                    hintText: 'Enter restaurant name',
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
                  onPressed: () => onAddRestaurant(isLiked),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 