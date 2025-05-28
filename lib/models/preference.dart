class Preference {
  final String userId;
  final List<String> likedRestaurants;
  final List<String> dislikedRestaurants;
  final List<String> likedCuisines;
  final List<String> dislikedCuisines;

  Preference({
    required this.userId,
    this.likedRestaurants = const [],
    this.dislikedRestaurants = const [],
    this.likedCuisines = const [],
    this.dislikedCuisines = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'likedRestaurants': likedRestaurants,
      'dislikedRestaurants': dislikedRestaurants,
      'likedCuisines': likedCuisines,
      'dislikedCuisines': dislikedCuisines,
    };
  }

  factory Preference.fromMap(Map<String, dynamic> map) {
    return Preference(
      userId: map['userId'] ?? '',
      likedRestaurants: List<String>.from(map['likedRestaurants'] ?? []),
      dislikedRestaurants: List<String>.from(map['dislikedRestaurants'] ?? []),
      likedCuisines: List<String>.from(map['likedCuisines'] ?? []),
      dislikedCuisines: List<String>.from(map['dislikedCuisines'] ?? []),
    );
  }
} 