import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/nearby_restaurant_provider.dart';

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
  final List<Map<String, dynamic>>? nearbyList;
  const FetchRestaurantEvent(this.keyword, {this.nearbyList});

  @override
  List<Object?> get props => [keyword, nearbyList];
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
      final newOptions = List<Option>.from(state.options)..add(Option(name: '', keyword: ''));
      emit(state.copyWith(options: newOptions));
      await saveOptionsToLocal(newOptions);
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
  Future<void> _onFetchRestaurant(
      FetchRestaurantEvent event, Emitter<WheelState> emit) async {
    emit(state.copyWith(loadingRestaurant: true));
    try {
      final localList = event.nearbyList ?? [];
      print('Nearby list count: \\${localList.length}');
      final filtered = localList.where((r) => (r['types'] as List?)?.contains(event.keyword) ?? false).toList();
      print('Filtered count for \\${event.keyword}: \\${filtered.length}');
      if (filtered.isNotEmpty) {
        final random = Random().nextInt(filtered.length);
        final selected = filtered[random];
        print('Selected from local: \\${selected['name']}');
        final restaurant = Restaurant(
          name: selected['name'] ?? 'Unknown',
          cuisine: event.keyword,
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
      }
      print('No local match, using Google API...');
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
}
