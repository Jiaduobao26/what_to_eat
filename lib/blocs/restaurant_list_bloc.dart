import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class RestaurantInfo extends Equatable {
  final String name;
  final double rating;
  final int reviews;
  final String description;
  const RestaurantInfo({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.description,
  });
  @override
  List<Object?> get props => [name, rating, reviews, description];
}

// Events
abstract class RestaurantListEvent extends Equatable {
  const RestaurantListEvent();
  @override
  List<Object?> get props => [];
}
class LoadRestaurantsEvent extends RestaurantListEvent {}
class AddRestaurantEvent extends RestaurantListEvent {
  final RestaurantInfo info;
  const AddRestaurantEvent(this.info);
  @override
  List<Object?> get props => [info];
}
class RemoveRestaurantEvent extends RestaurantListEvent {
  final int index;
  const RemoveRestaurantEvent(this.index);
  @override
  List<Object?> get props => [index];
}

// State
class RestaurantListState extends Equatable {
  final List<RestaurantInfo> restaurants;
  const RestaurantListState({
    this.restaurants = const [
      RestaurantInfo(
        name: 'Golden Dragon',
        rating: 4.3,
        reviews: 305,
        description: 'Locally owned restaurant serving up a variety of traditional Chinese ...',
      ),
      RestaurantInfo(
        name: 'Spicy House',
        rating: 4.7,
        reviews: 210,
        description: 'Authentic Sichuan cuisine with a modern twist ...',
      ),
      RestaurantInfo(
        name: 'Veggie Delight',
        rating: 4.5,
        reviews: 180,
        description: 'Vegetarian and vegan friendly, fresh and healthy ...',
      ),
      RestaurantInfo(
        name: 'Noodle Bar',
        rating: 4.2,
        reviews: 150,
        description: 'Hand-pulled noodles and delicious broths ...',
      ),
      RestaurantInfo(
        name: 'BBQ Corner',
        rating: 4.6,
        reviews: 220,
        description: 'Barbecue specialties and local favorites ...',
      ),
      RestaurantInfo(
        name: 'Seafood Palace',
        rating: 4.4,
        reviews: 175,
        description: 'Fresh seafood and ocean-inspired dishes ...',
      ),
    ],
  });
  @override
  List<Object?> get props => [restaurants];
}

// Bloc
class RestaurantListBloc extends Bloc<RestaurantListEvent, RestaurantListState> {
  RestaurantListBloc() : super(const RestaurantListState()) {
    on<LoadRestaurantsEvent>((event, emit) {
      emit(const RestaurantListState());
    });
    on<AddRestaurantEvent>((event, emit) {
      final updated = List<RestaurantInfo>.from(state.restaurants)..add(event.info);
      emit(RestaurantListState(restaurants: updated));
    });
    on<RemoveRestaurantEvent>((event, emit) {
      final updated = List<RestaurantInfo>.from(state.restaurants)..removeAt(event.index);
      emit(RestaurantListState(restaurants: updated));
    });
  }
}
