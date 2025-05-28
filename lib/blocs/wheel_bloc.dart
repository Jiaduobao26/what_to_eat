import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:math';
import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/restaurant.dart';

import '../services/local_properties_service.dart';



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
class FetchRestaurantEvent extends WheelEvent {
  final String keyword;
  const FetchRestaurantEvent(this.keyword);

  @override
  List<Object?> get props => [keyword];
}

class WheelBloc extends Bloc<WheelEvent, WheelState> {
  final _random = Random();
  StreamController<int>? _spinController;
  List<Cuisine> cuisines = [];
  String? _apiKey;

  WheelBloc() : super(WheelState(
    selectedIndex: 0,
    options: []
  )){
     _loadCuisines(); // 加载菜系数据
    on<ShowResultEvent>((event, emit) {
      emit(state.copyWith(showResult: true));
    });
    on<ShowModifyEvent>((event, emit) {
      emit(state.copyWith(showModify: true));
    });
    on<CloseModifyEvent>((event, emit) {
      emit(state.copyWith(showModify: false));
    });
    on<UpdateOptionEvent>((event, emit) {
      final newOptions = List<Option>.from(state.options);
      newOptions[event.index] = Option(name: event.name, keyword: event.keyword);
      emit(state.copyWith(options: newOptions));
    });
    on<RemoveOptionEvent>((event, emit) {
      final newOptions = List<Option>.from(state.options)..removeAt(event.index);
      emit(state.copyWith(options: newOptions));
    });
    on<AddOptionEvent>((event, emit) {
      final newOptions = List<Option>.from(state.options)..add(Option(name: '', keyword: ''));
      emit(state.copyWith(options: newOptions));
    });
    on<SpinWheelEvent>((event, emit) {
      final randomIndex = _random.nextInt(state.options.length);
      _spinController?.add(randomIndex);
      emit(state.copyWith(selectedIndex: randomIndex));
    });
    on<FetchRestaurantEvent>(_onFetchRestaurant);
  }

  Future<void> _loadCuisines() async {
    final jsonStr = await rootBundle.loadString('assets/cuisines.json');
    final data = json.decode(jsonStr);
    cuisines = (data['cuisines'] as List)
        .map((e) => Cuisine.fromJson(e))
        .toList();
    
    print('Loaded cuisines: ${cuisines.map((c) => c.name).toList()}');
    if (cuisines.length >= 3) {
      final firstThree = cuisines.take(3).map((c) => Option(name: c.name, keyword: c.keyword)).toList();
      emit(state.copyWith(options: firstThree));
    }
  }
  Future<void> _onFetchRestaurant(
      FetchRestaurantEvent event, Emitter<WheelState> emit) async {
    emit(state.copyWith(loadingRestaurant: true));
    try {
      final restaurant = await fetchRestaurantByCuisine(event.keyword);
      emit(state.copyWith(
        selectedRestaurant: restaurant,
        loadingRestaurant: false,
        showResult: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        selectedRestaurant: null,
        loadingRestaurant: false,
      ));
    }
  }
  Future<Restaurant> fetchRestaurantByCuisine(String keyword) async {
    print('Fetching restaurant for cuisine: $keyword');
    final key = await _getApiKey();
    print('key: $key');
    
    final uri = Uri.https("maps.googleapis.com", "/maps/api/place/nearbysearch/json", {
      // "location": "${lat},${lng}",
      "location": "37.7749,-122.4194", // 示例坐标，实际请替换为用户当前位置
      "radius": "1500",
      "type": "restaurant",
      "keyword": keyword, // 替换为用户选择的菜系
      "key": key,
      "open_now": "true",
      "rankby": "prominence",
    });

    final response = await http.get(uri);
    print('status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('Request failed: ${response.body}');
    }

    final data = json.decode(response.body);
    
    final results = data['results'] as List<dynamic>;
    final restaurants = parseRestaurants(results, 'japanese'); 
    print(restaurants);
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
      );
    }).toList();
  }

  String getPhotoUrl(Map<String, dynamic> json) {
    final photos = json['photos'] as List<dynamic>?;
    if (photos != null && photos.isNotEmpty) {
      final ref = photos.first['photo_reference'];
      return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$ref&key=$_apiKey';
    } else {
      // 使用默认图片或空字符串
      return 'https://via.placeholder.com/400x300.png?text=No+Image';
    }
  }

  @override
  Future<void> close() {
    _spinController?.close();
    return super.close();
  }
}
