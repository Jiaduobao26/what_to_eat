import 'package:equatable/equatable.dart';

class Restaurant extends Equatable {
  final String name;
  final String cuisine;
  final double rating;
  final String address;
  final String imageUrl;

  const Restaurant({
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.address,
    required this.imageUrl,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      name: json['name'],
      cuisine: json['cuisine'],
      rating: (json['rating'] as num).toDouble(),
      address: json['address'],
      imageUrl: json['imageUrl'],
    );
  }

  @override
  List<Object?> get props => [name, cuisine, rating, address, imageUrl];
}