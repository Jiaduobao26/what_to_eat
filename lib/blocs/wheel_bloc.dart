import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/restaurant.dart';
import '../services/local_properties_service.dart';
import '../repositories/user_preference_repository.dart';

class Cuisine {
  final String name;
  final String keyword;
  Cuisine({required this.name, required this.keyword});

  factory Cuisine.fromJson(Map<String, dynamic> json) {
    return Cuisine(
      name: json['name'],
      keyword: json['keyword'],
    );
  }
}

class Option extends Equatable {
  final String name;
  final String keyword;
  const Option({required this.name, required this.keyword});

  @override
  List<Object?> get props => [name, keyword];
}

class WheelState extends Equatable {
  final int? selectedIndex;
  final List<Option> options;
  final bool showModify;
  final bool showResult;
  final bool shouldSpin;
  final Restaurant? selectedRestaurant;
  final bool loadingRestaurant;

  WheelState({
    this.selectedIndex,
    List<Option>? options,
    this.showModify = false,
    this.showResult = false,
    this.shouldSpin = false,
    this.selectedRestaurant,
    this.loadingRestaurant = false,
  }) : options = options ?? [];

  WheelState copyWith({
    int? selectedIndex,
    List<Option>? options,
    bool? showModify,
    bool? showResult,
    bool? shouldSpin,
    Restaurant? selectedRestaurant,
    bool? loadingRestaurant,
  }) {
    return WheelState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      options: options ?? this.options,
      showModify: showModify ?? this.showModify,
      showResult: showResult ?? this.showResult,
      shouldSpin: shouldSpin ?? this.shouldSpin,
      selectedRestaurant: selectedRestaurant ?? this.selectedRestaurant,
      loadingRestaurant: loadingRestaurant ?? this.loadingRestaurant,
    );
  }

  @override
  List<Object?> get props => [selectedIndex, options, showModify, showResult, shouldSpin, selectedRestaurant, loadingRestaurant,];
}

abstract class WheelEvent extends Equatable {
  const WheelEvent();

  @override
  List<Object?> get props => [];
}

class ShowResultEvent extends WheelEvent {}
class ShowModifyEvent extends WheelEvent {}
class CloseModifyEvent extends WheelEvent {}
class UpdateOptionEvent extends WheelEvent {
  final int index;
  final String name;
  final String keyword;
  const UpdateOptionEvent(this.index, this.name, this.keyword);

  @override
  List<Object?> get props => [index, name, keyword];
}
class RemoveOptionEvent extends WheelEvent {
  final int index;
  const RemoveOptionEvent(this.index);

  @override
  List<Object?> get props => [index];
}
class AddOptionEvent extends WheelEvent {}
class SpinWheelEvent extends WheelEvent {}
class InitializeWithPreferencesEvent extends WheelEvent {}
class InitializeDefaultEvent extends WheelEvent {}
class FetchRestaurantEvent extends WheelEvent {
  final String keyword;
  final List<Map<String, dynamic>>? nearbyList;
  const FetchRestaurantEvent(this.keyword, {this.nearbyList});

  @override
  List<Object?> get props => [keyword, nearbyList];
}
class SetSelectedRestaurantEvent extends WheelEvent {
  final Restaurant restaurant;
  const SetSelectedRestaurantEvent(this.restaurant);

  @override
  List<Object?> get props => [restaurant];
}

class WheelBloc extends Bloc<WheelEvent, WheelState> {
  final _random = Random();
  StreamController<int>? _spinController;
  List<Cuisine> cuisines = [];
  String? _apiKey;
  String? get apiKey => _apiKey;
  WheelBloc() : super(WheelState(
    selectedIndex: 0,
    options: []
  )){
     _loadCuisines(); // 加载菜系数据
     _initializeApiKey(); // 加载API key
    on<ShowResultEvent>((event, emit) {
      emit(state.copyWith(showResult: true));
    });
    on<ShowModifyEvent>((event, emit) {
      emit(state.copyWith(showModify: true));
    });
    on<CloseModifyEvent>((event, emit) {
      emit(state.copyWith(showModify: false));
    });
    on<UpdateOptionEvent>((event, emit) async {
      final newOptions = List<Option>.from(state.options);
      newOptions[event.index] = Option(name: event.name, keyword: event.keyword);
      emit(state.copyWith(options: newOptions));
      await saveOptionsToLocal(newOptions);
    });
    on<RemoveOptionEvent>((event, emit) async {
      final newOptions = List<Option>.from(state.options)..removeAt(event.index);
      emit(state.copyWith(options: newOptions));
      await saveOptionsToLocal(newOptions);
    });
    on<AddOptionEvent>((event, emit) async {
      // 找到一个还没有被使用的菜系作为默认选项
      final usedKeywords = state.options.map((option) => option.keyword).toSet();
      final availableCuisines = cuisines.where((cuisine) => !usedKeywords.contains(cuisine.keyword)).toList();
      
      final defaultOption = availableCuisines.isNotEmpty 
        ? Option(name: availableCuisines.first.name, keyword: availableCuisines.first.keyword)
        : cuisines.isNotEmpty 
          ? Option(name: cuisines.first.name, keyword: cuisines.first.keyword)
          : const Option(name: 'Default Option', keyword: 'default'); // 最后的备用方案
      
      final newOptions = List<Option>.from(state.options)..add(defaultOption);
      emit(state.copyWith(options: newOptions));
      await saveOptionsToLocal(newOptions);
    });
    on<SpinWheelEvent>((event, emit) {
      final randomIndex = _random.nextInt(state.options.length);
      _spinController?.add(randomIndex);
      emit(state.copyWith(selectedIndex: randomIndex));
    });
    on<InitializeWithPreferencesEvent>(_onInitializeWithPreferences);
    on<InitializeDefaultEvent>(_onInitializeDefault);
    on<FetchRestaurantEvent>(_onFetchRestaurant);
    on<SetSelectedRestaurantEvent>(_onSetSelectedRestaurant);
  }  Future<void> _loadCuisines() async {
    final jsonStr = await rootBundle.loadString('assets/cuisines.json');
    final data = json.decode(jsonStr);
    cuisines = (data['cuisines'] as List)
        .map((e) => Cuisine.fromJson(e))
        .toList();

    // Trigger initialization event instead of setting state directly
    add(InitializeDefaultEvent());
  }

  Future<void> _initializeApiKey() async {
    try {
      _apiKey = await LocalPropertiesService.getGoogleMapsApiKey();
      print('🔑 API Key initialized: ${_apiKey?.isNotEmpty == true ? "✅" : "❌"}');
    } catch (e) {
      print('❌ Failed to load API key: $e');
    }
  }

  Future<void> _onInitializeDefault(
      InitializeDefaultEvent event, Emitter<WheelState> emit) async {
    // load initial options from local storage
    final localOptions = await loadOptionsFromLocal();
    if (localOptions.isNotEmpty) {
      emit(state.copyWith(options: localOptions));
    } else if (cuisines.length >= 3) {
      final firstThree = cuisines.take(3).map((c) => Option(name: c.name, keyword: c.keyword)).toList();
      emit(state.copyWith(options: firstThree));
      // save initial options to local storage
      await saveOptionsToLocal(firstThree);
    }
  }
  Future<void> _onInitializeWithPreferences(
      InitializeWithPreferencesEvent event, Emitter<WheelState> emit) async {
    try {
      List<String> preferredCuisines = [];
      
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Authenticated user - load from Firebase
        try {
          final userPreferenceRepository = UserPreferenceRepository();
          final preference = await userPreferenceRepository.fetchPreference(user.uid);
          if (preference != null) {
            preferredCuisines = preference.likedCuisines;
          }
        } catch (e) {
          print('Error loading user preferences from Firebase: $e');
        }
      } else {
        // Guest user - load from SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          preferredCuisines = prefs.getStringList('guest_liked_cuisines') ?? [];
        } catch (e) {
          print('Error loading guest preferences from SharedPreferences: $e');
        }
      }

      if (preferredCuisines.isNotEmpty && cuisines.isNotEmpty) {
        // Filter cuisines based on preferences
        final preferredOptions = <Option>[];
        
        for (final preferredCuisine in preferredCuisines) {
          final matchingCuisine = cuisines.firstWhere(
            (cuisine) => cuisine.name.toLowerCase() == preferredCuisine.toLowerCase(),
            orElse: () => cuisines.firstWhere(
              (cuisine) => cuisine.keyword.toLowerCase() == preferredCuisine.toLowerCase(),
              orElse: () => Cuisine(name: preferredCuisine, keyword: preferredCuisine),
            ),
          );
          preferredOptions.add(Option(name: matchingCuisine.name, keyword: matchingCuisine.keyword));
        }

        if (preferredOptions.isNotEmpty) {
          emit(state.copyWith(options: preferredOptions));
          await saveOptionsToLocal(preferredOptions);
          return;
        }
      }
      
      // Fallback: use default cuisines if no preferences found
      if (cuisines.length >= 3) {
        final firstThree = cuisines.take(3).map((c) => Option(name: c.name, keyword: c.keyword)).toList();
        emit(state.copyWith(options: firstThree));
        await saveOptionsToLocal(firstThree);
      }
    } catch (e) {
      print('Error initializing wheel with preferences: $e');
      // Fallback to default behavior
      if (cuisines.length >= 3) {
        final firstThree = cuisines.take(3).map((c) => Option(name: c.name, keyword: c.keyword)).toList();
        emit(state.copyWith(options: firstThree));
        await saveOptionsToLocal(firstThree);
      }
    }
  }
  Future<void> _onFetchRestaurant(
      FetchRestaurantEvent event, Emitter<WheelState> emit) async {
    emit(state.copyWith(loadingRestaurant: true));
    try {
      final localList = event.nearbyList ?? [];
      print('Nearby list count: \\${localList.length}');
      
      // 改进的菜系匹配逻辑，与DiceWheel保持一致
      final matchingRestaurants = localList.where((restaurant) {
        final types = restaurant['types'] as List<dynamic>? ?? [];
        return types.any((type) => 
          type.toString().toLowerCase().contains(event.keyword.toLowerCase()) ||
          event.keyword.toLowerCase().contains(type.toString().toLowerCase())
        );
      }).toList();
      
      print('Matched restaurants for \\${event.keyword}: \\${matchingRestaurants.length}');
      
      if (matchingRestaurants.isNotEmpty) {
        // 应用用户偏好过滤 - 普通转盘只过滤餐厅ID，不过滤菜系
        final filteredRestaurants = await _filterDislikedRestaurants(
          matchingRestaurants, 
          onlyFilterRestaurantIds: true, // 普通转盘模式：只过滤特定餐厅，不过滤菜系
        );
        print('After preference filtering: \\${filteredRestaurants.length}');
        
        if (filteredRestaurants.isNotEmpty) {
          final random = Random().nextInt(filteredRestaurants.length);
          final selected = filteredRestaurants[random];
          print('Selected from local: \\${selected['name']}');
          final restaurant = Restaurant(
            name: selected['name'] ?? 'Unknown',
            cuisine: _formatCuisineDisplay(selected['types'] as List<dynamic>? ?? []),
            rating: (selected['rating'] as num?)?.toDouble() ?? 0.0,
            address: selected['vicinity'] ?? 'Unknown address',
            imageUrl: getPhotoUrl(selected),
            lat: (selected['geometry']?['location']?['lat'] as num?)?.toDouble() ?? 0.0,
            lng: (selected['geometry']?['location']?['lng'] as num?)?.toDouble() ?? 0.0,
          );
          emit(state.copyWith(
            selectedRestaurant: restaurant,
            loadingRestaurant: false,
            showResult: true,
          ));
          return;
        } else {
          print('All nearby restaurants filtered out by preferences, using Google API...');
        }
      } else {
        print('No nearby match for \\${event.keyword}, using Google API...');
      }
      
      // 回退到Google API搜索
      final restaurant = await fetchRestaurantByCuisine(event.keyword);
      print('Google API result: \\${restaurant.name}');
      emit(state.copyWith(
        selectedRestaurant: restaurant,
        loadingRestaurant: false,
        showResult: true,
      ));
    } catch (e) {
      print('Fetch restaurant error: \\${e.toString()}');
      emit(state.copyWith(
        selectedRestaurant: null,
        loadingRestaurant: false,
      ));
    }
  }
  Future<Restaurant> fetchRestaurantByCuisine(String keyword) async {
    final key = await _getApiKey();
    print('Google API search for \\${keyword}');
    final uri = Uri.https("maps.googleapis.com", "/maps/api/place/nearbysearch/json", {
      "location": "37.7749,-122.4194", // example coordinates (San Francisco)
      "radius": "1500",
      "type": "restaurant",
      "keyword": keyword,
      "key": key,
      "open_now": "true",
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      print('Request failed: \\${response.body}');
    }

    final data = json.decode(response.body);
    final results = data['results'] as List<dynamic>;
    print('Google API results count: \\${results.length}');
    if (results.isEmpty) throw Exception('No results from Google API');
    final restaurants = parseRestaurants(results, keyword); 
    return restaurants[0];
  }
  Future<String> _getApiKey() async {
    if (_apiKey != null) return _apiKey!;
    _apiKey = await LocalPropertiesService.getGoogleMapsApiKey();
    return _apiKey!;
  }

  List<Restaurant> parseRestaurants(List<dynamic> jsonList, String cuisineKeyword) {
    return jsonList.map((item) {
      return Restaurant(
        name: item['name'] ?? 'Unknown',
        cuisine: cuisineKeyword,
        rating: (item['rating'] as num?)?.toDouble() ?? 0.0,
        address: item['vicinity'] ?? 'Unknown address',
        imageUrl: getPhotoUrl(item),
        lat: (item['geometry']?['location']?['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (item['geometry']?['location']?['lng'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  String getPhotoUrl(Map<String, dynamic> json) {
    final photos = json['photos'] as List<dynamic>?;
    if (photos != null && photos.isNotEmpty) {
      final ref = photos.first['photo_reference'];
      return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$ref&key=$_apiKey';
    } else {
      // use a placeholder image if no photo is available
      return 'https://via.placeholder.com/400x300.png?text=No+Image';
    }
  }

  @override
  Future<void> close() {
    _spinController?.close();
    return super.close();
  }

  // Save options to local storage
  Future<void> saveOptionsToLocal(List<Option> options) async {
    final prefs = await SharedPreferences.getInstance();
    final optionsJson = jsonEncode(options.map((e) => {'name': e.name, 'keyword': e.keyword}).toList());
    await prefs.setString('wheel_options', optionsJson);
  }
  // Load options from local storage
  Future<List<Option>> loadOptionsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final optionsJson = prefs.getString('wheel_options');
    if (optionsJson == null) return [];
    final List<dynamic> decoded = jsonDecode(optionsJson);
    return decoded.map((e) => Option(name: e['name'], keyword: e['keyword'])).toList();
  }

  // 直接设置选中的餐厅，用于preference模式
  Future<void> _onSetSelectedRestaurant(
      SetSelectedRestaurantEvent event, Emitter<WheelState> emit) async {
    print('🎯 Setting selected restaurant directly: ${event.restaurant.name}');
    emit(state.copyWith(
      selectedRestaurant: event.restaurant,
      loadingRestaurant: false,
      showResult: true,
    ));
  }
  
  // 过滤不喜欢的餐厅和菜系
  Future<List<Map<String, dynamic>>> _filterDislikedRestaurants(
    List<Map<String, dynamic>> restaurants, {
    bool onlyFilterRestaurantIds = false, // 新参数：是否只过滤餐厅ID
  }) async {
    try {
      List<String> dislikedRestaurantIds = [];
      List<String> dislikedCuisines = [];
      
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // 登录用户
        final repo = UserPreferenceRepository();
        final pref = await repo.fetchPreference(user.uid);
        if (pref != null) {
          dislikedRestaurantIds = pref.dislikedRestaurantIds;
          if (!onlyFilterRestaurantIds) {
            dislikedCuisines = pref.dislikedCuisines;
          }
        }
      } else {
        // 游客用户
        final prefs = await SharedPreferences.getInstance();
        if (!onlyFilterRestaurantIds) {
          dislikedCuisines = prefs.getStringList('guest_disliked_cuisines') ?? [];
        }
        final dislikedRestaurantsStr = prefs.getStringList('guest_disliked_restaurants') ?? [];
        dislikedRestaurantIds = dislikedRestaurantsStr.map((str) {
          try {
            final map = json.decode(str) as Map<String, dynamic>;
            return map['id'] as String;
          } catch (e) {
            return str; // 回退到旧格式
          }
        }).toList();
      }

      print('🚫 Disliked restaurant IDs: $dislikedRestaurantIds');
      if (!onlyFilterRestaurantIds) {
        print('🚫 Disliked cuisines: $dislikedCuisines');
      } else {
        print('ℹ️ Only filtering restaurant IDs (wheel mode)');
      }
      
      final filteredRestaurants = restaurants.where((restaurant) {
        final placeId = restaurant['place_id'] as String? ?? '';
        final types = restaurant['types'] as List<dynamic>? ?? [];
        final restaurantName = restaurant['name'] ?? '';
        
        // 总是检查是否是不喜欢的餐厅ID
        if (dislikedRestaurantIds.contains(placeId)) {
          print('🚫 Filtered out restaurant by ID: $restaurantName');
          return false;
        }
        
        // 只在非wheel模式下检查菜系类型
        if (!onlyFilterRestaurantIds) {
          for (final type in types) {
            final typeStr = type.toString().toLowerCase();
            for (final dislikedCuisine in dislikedCuisines) {
              final dislikedLower = dislikedCuisine.toLowerCase();
              if (typeStr.contains(dislikedLower) || dislikedLower.contains(typeStr)) {
                print('🚫 Filtered out restaurant by cuisine: $restaurantName (type: $typeStr, disliked: $dislikedCuisine)');
                return false;
              }
            }
          }
        }
        
        return true;
      }).toList();
      
      print('📊 Filter results: ${restaurants.length} → ${filteredRestaurants.length}');
      return filteredRestaurants;
    } catch (e) {
      print('❌ Error filtering restaurants: $e');
      return restaurants;
    }
  }
  
  // 格式化菜系类型显示
  String _formatCuisineDisplay(List<dynamic> types) {
    if (types.isEmpty) return 'Restaurant';
    
    // 尝试找到最有意义的类型
    for (final type in types) {
      final typeStr = type.toString();
      switch (typeStr) {
        case 'chinese_restaurant':
          return 'Chinese';
        case 'japanese_restaurant':
          return 'Japanese';
        case 'korean_restaurant':
          return 'Korean';
        case 'italian_restaurant':
          return 'Italian';
        case 'mexican_restaurant':
          return 'Mexican';
        case 'indian_restaurant':
          return 'Indian';
        case 'thai_restaurant':
          return 'Thai';
        case 'vietnamese_restaurant':
          return 'Vietnamese';
        case 'french_restaurant':
          return 'French';
        case 'american_restaurant':
          return 'American';
        case 'pizza_restaurant':
          return 'Pizza';
        case 'seafood_restaurant':
          return 'Seafood';
        case 'bakery':
          return 'Bakery';
        case 'cafe':
          return 'Cafe';
        case 'bar':
          return 'Bar';
        default:
          if (typeStr != 'restaurant' && typeStr != 'establishment' && 
              typeStr != 'food' && typeStr != 'point_of_interest') {
            return typeStr.replaceAll('_', ' ').split(' ').map((word) => 
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
            ).join(' ');
          }
      }
    }
    
    return 'Restaurant';
  }
}
