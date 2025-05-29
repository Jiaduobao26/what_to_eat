import 'package:equatable/equatable.dart';

class Restaurant extends Equatable {
  final String name;
  final String cuisine;
  final double rating;
  final String address;
  final String imageUrl;
  final double lat;
  final double lng;


  const Restaurant({
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.address,
    required this.imageUrl,
    required this.lat,
    required this.lng,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      name: json['name'],
      cuisine: json['cuisine'],
      rating: (json['rating'] as num).toDouble(),
      address: json['address'],
      imageUrl: json['imageUrl'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [name, cuisine, rating, address, imageUrl];
}