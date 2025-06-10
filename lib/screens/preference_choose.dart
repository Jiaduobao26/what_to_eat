import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/user_preference_repository.dart';
import '../models/preference.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/authentication_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceChooseScreen extends StatefulWidget {
  const PreferenceChooseScreen({super.key});

  @override
  State<PreferenceChooseScreen> createState() => _PreferenceChooseScreenState();
}

class _PreferenceChooseScreenState extends State<PreferenceChooseScreen> {
  String flag = 'like';
  final Set<String> _likedCuisines = {};
  final Set<String> _dislikedCuisines = {};
  List<Map<String, String>> _allCuisines = [];
  bool _loading = true;
  bool _saving = false;
  final _repo = UserPreferenceRepository();

  @override
  void initState() {
    super.initState();
    _loadCuisines();
  }

  Future<void> _loadCuisines() async {
    try {
      final data = await DefaultAssetBundle.of(context).loadString('assets/cuisines.json');
      final json = jsonDecode(data);
      setState(() {
        _allCuisines = List<Map<String, String>>.from(
          json['cuisines'].map((c) => {
            'name': c['name'] as String,
            'keyword': c['keyword'] as String,
          })
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _onCuisineTap(String keyword) {
    setState(() {
      if (flag == 'like') {
        if (_likedCuisines.contains(keyword)) {
          _likedCuisines.remove(keyword);
        } else {
          _likedCuisines.add(keyword);
        }
      } else {
        if (_dislikedCuisines.contains(keyword)) {
          _dislikedCuisines.remove(keyword);
        } else {
          _dislikedCuisines.add(keyword);
        }
      }
    });
  }

  void _onContinue() {
    if (flag == 'like') {
      setState(() {
        flag = 'dislike';
      });
    } else {
      _savePreferences();
    }
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    
    setState(() {
      _saving = true;
    });

    try {
      // 检查是否为游客
      if (user == null) {
        // 游客用户 - 保存到SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        
        // 保存偏好到本地
        await prefs.setStringList('guest_liked_cuisines', _likedCuisines.toList());
        await prefs.setStringList('guest_disliked_cuisines', _dislikedCuisines.toList());
        await prefs.setStringList('guest_liked_restaurants', []);
        await prefs.setStringList('guest_disliked_restaurants', []);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences saved locally!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 游客用户完成偏好选择后标记为已登录
          context.read<AuthenticationBloc>().add(AuthenticationGuestLoginButtonPressed());
          GoRouter.of(context).go('/');
        }
        return;
      }

      // 检查用户是否存在于 userinfo 数据库
      final userInfo = await FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: 'userinfo',
      ).collection('userinfo').doc(user.uid).get();
      
      if (!userInfo.exists) {
        // 如果用户信息不存在，说明是游客，保存到本地
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setStringList('guest_liked_cuisines', _likedCuisines.toList());
        await prefs.setStringList('guest_disliked_cuisines', _dislikedCuisines.toList());
        await prefs.setStringList('guest_liked_restaurants', []);
        await prefs.setStringList('guest_disliked_restaurants', []);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences saved locally!'),
              backgroundColor: Colors.green,
            ),
          );
          
          context.read<AuthenticationBloc>().add(AuthenticationGuestLoginButtonPressed());
          GoRouter.of(context).go('/');
        }
        return;
      }

      // 正常用户 - 保存到Firebase
      // 获取现有偏好或创建新的
      final existingPref = await _repo.fetchPreference(user.uid);
      
      // 创建新的偏好对象，合并现有的餐厅偏好
      final preference = Preference(
        userId: user.uid,
        likedCuisines: _likedCuisines.toList(),
        dislikedCuisines: _dislikedCuisines.toList(),
        likedRestaurants: existingPref?.likedRestaurants ?? [],
        dislikedRestaurants: existingPref?.dislikedRestaurants ?? [],
      );

      // 保存到数据库
      await _repo.setPreference(preference);

      // 偏好设置完成，从需要设置偏好的邮箱列表中移除当前用户
      final prefs = await SharedPreferences.getInstance();
      final needsPreferenceEmails = prefs.getStringList('needsPreferenceSetup') ?? [];
      if (needsPreferenceEmails.contains(user.email)) {
        needsPreferenceEmails.remove(user.email);
        await prefs.setStringList('needsPreferenceSetup', needsPreferenceEmails);
      }

      if (mounted) {
        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 跳转到主页
        GoRouter.of(context).go('/');
      }
    } catch (e) {
      if (mounted) {
        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _onSkip() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // 如果是访客，标记为已登录
      context.read<AuthenticationBloc>().add(AuthenticationGuestLoginButtonPressed());
    } else {
      // 如果是正式用户跳过偏好设置，也要从列表中移除邮箱
      final prefs = await SharedPreferences.getInstance();
      final needsPreferenceEmails = prefs.getStringList('needsPreferenceSetup') ?? [];
      if (needsPreferenceEmails.contains(user.email)) {
        needsPreferenceEmails.remove(user.email);
        await prefs.setStringList('needsPreferenceSetup', needsPreferenceEmails);
      }
    }
    
    GoRouter.of(context).go('/');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: flag == 'dislike' 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFA4A0C)),
              onPressed: () {
                setState(() {
                  flag = 'like';
                });
              },
            )
          : null,
        actions: [
          TextButton(
            onPressed: _onSkip,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Color(0xFF386BF6),
                fontSize: 15,
                fontStyle: FontStyle.italic,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text(
                flag == 'like' ? 'What cuisines do you like?' : 'What cuisines do you dislike?',
                style: const TextStyle(
                  color: Color(0xFFE95322),
                  fontSize: 24,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                flag == 'like' 
                  ? 'Select your favorite cuisines to get better recommendations'
                  : 'Select cuisines you want to avoid',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _allCuisines.length,
                itemBuilder: (context, index) {
                  final cuisine = _allCuisines[index];
                  final keyword = cuisine['keyword']!;
                  final name = cuisine['name']!;
                  
                  bool isSelected = false;
                  bool isDisabled = false;
                  
                  if (flag == 'like') {
                    isSelected = _likedCuisines.contains(keyword);
                  } else {
                    isSelected = _dislikedCuisines.contains(keyword);
                    // 在不喜欢界面，如果菜系已经被标记为喜欢，则禁用
                    isDisabled = _likedCuisines.contains(keyword);
                  }

                  return GestureDetector(
                    onTap: isDisabled ? null : () => _onCuisineTap(keyword),
                    child: _CuisineCard(
                      name: name,
                      keyword: keyword,
                      selected: isSelected,
                      disabled: isDisabled,
                      flag: flag,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: flag == 'like' ? const Color(0xFFE95322) : Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: flag == 'dislike' ? const Color(0xFFE95322) : Colors.grey[300],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE95322),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saving ? null : _onContinue,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        flag == 'like' ? 'Continue' : 'Finish',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CuisineCard extends StatelessWidget {
  final String name;
  final String keyword;
  final bool selected;
  final bool disabled;
  final String flag;

  const _CuisineCard({
    required this.name,
    required this.keyword,
    required this.selected,
    this.disabled = false,
    required this.flag,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    Color textColor = Colors.black87;
    
    if (disabled) {
      // 禁用状态：灰色背景和边框
      backgroundColor = Colors.grey[100]!;
      borderColor = Colors.grey[200]!;
      textColor = Colors.grey[400]!;
    } else if (selected) {
      if (flag == 'like') {
        backgroundColor = Colors.green[50]!;
        borderColor = Colors.green[400]!;
        textColor = Colors.green[700]!;
      } else {
        backgroundColor = Colors.red[50]!;
        borderColor = Colors.red[400]!;
        textColor = Colors.red[700]!;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: selected ? 2 : 1,
        ),
        boxShadow: disabled ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cuisine image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ColorFiltered(
                  colorFilter: disabled 
                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                    : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                  child: Image.asset(
                    'assets/cuisines_images/$keyword.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.restaurant,
                      size: 40,
                      color: disabled ? Colors.grey[300] : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Cuisine name
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            // Selection indicator or disabled indicator
            if (disabled) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.green[400],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Liked',
                    style: TextStyle(
                      color: Colors.green[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ] else if (selected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                color: flag == 'like' ? Colors.green[600] : Colors.red[600],
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}