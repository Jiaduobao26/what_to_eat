class RestaurantDetail {
  final String placeId;
  final String name;
  final String formattedAddress;
  final String? formattedPhoneNumber;
  final String? website;
  final double? rating;
  final int? userRatingsTotal;
  final int? priceLevel; // 0-4, where 0=Free, 1=Inexpensive, 2=Moderate, 3=Expensive, 4=Very Expensive
  final List<String> types;
  final List<Photo> photos;
  final OpeningHours? openingHours;
  final bool? currentlyOpen;
  final List<Review> reviews;
  final Geometry geometry;
  final String? editorialSummary;
  final List<PopularTime>? popularTimes;
  
  RestaurantDetail({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    this.formattedPhoneNumber,
    this.website,
    this.rating,
    this.userRatingsTotal,
    this.priceLevel,
    this.types = const [],
    this.photos = const [],
    this.openingHours,
    this.currentlyOpen,
    this.reviews = const [],
    required this.geometry,
    this.editorialSummary,
    this.popularTimes,
  });

  factory RestaurantDetail.fromJson(Map<String, dynamic> json) {
    return RestaurantDetail(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      formattedPhoneNumber: json['formatted_phone_number'],
      website: json['website'],
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      priceLevel: json['price_level'],
      types: (json['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      photos: (json['photos'] as List<dynamic>?)
          ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      openingHours: json['opening_hours'] != null 
          ? OpeningHours.fromJson(json['opening_hours'] as Map<String, dynamic>)
          : null,
      currentlyOpen: json['opening_hours']?['open_now'],
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      geometry: Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
      editorialSummary: json['editorial_summary']?['overview'],
    );
  }

  String get priceRange {
    switch (priceLevel) {
      case 0: return 'Free';
      case 1: return '\$';
      case 2: return '\$\$';
      case 3: return '\$\$\$';
      case 4: return '\$\$\$\$';
      default: return 'Price not available';
    }
  }
}

class Photo {
  final String photoReference;
  final int height;
  final int width;
  final List<String> htmlAttributions;

  Photo({
    required this.photoReference,
    required this.height,
    required this.width,
    required this.htmlAttributions,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      photoReference: json['photo_reference'] ?? '',
      height: json['height'] ?? 0,
      width: json['width'] ?? 0,
      htmlAttributions: (json['html_attributions'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
    );
  }

  String getPhotoUrl(String apiKey, {int maxWidth = 400}) {
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=$apiKey';
  }
}

class OpeningHours {
  final bool openNow;
  final List<String> weekdayText;
  final List<Period> periods;

  OpeningHours({
    required this.openNow,
    required this.weekdayText,
    required this.periods,
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openNow: json['open_now'] ?? false,
      weekdayText: (json['weekday_text'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      periods: (json['periods'] as List<dynamic>?)
          ?.map((e) => Period.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class Period {
  final DayTime? open;
  final DayTime? close;

  Period({this.open, this.close});

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      open: json['open'] != null ? DayTime.fromJson(json['open']) : null,
      close: json['close'] != null ? DayTime.fromJson(json['close']) : null,
    );
  }
}

class DayTime {
  final int day; // 0=Sunday, 1=Monday, etc.
  final String time; // HHMM format

  DayTime({required this.day, required this.time});

  factory DayTime.fromJson(Map<String, dynamic> json) {
    return DayTime(
      day: json['day'] ?? 0,
      time: json['time'] ?? '',
    );
  }

  String get formattedTime {
    if (time.length != 4) return time;
    final hour = int.parse(time.substring(0, 2));
    final minute = time.substring(2);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return '$displayHour:$minute $period';
  }
}

class Review {
  final String authorName;
  final String? authorUrl;
  final String language;
  final String? profilePhotoUrl;
  final int rating;
  final String relativeTimeDescription;
  final String text;
  final int time;

  Review({
    required this.authorName,
    this.authorUrl,
    required this.language,
    this.profilePhotoUrl,
    required this.rating,
    required this.relativeTimeDescription,
    required this.text,
    required this.time,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      authorName: json['author_name'] ?? '',
      authorUrl: json['author_url'],
      language: json['language'] ?? '',
      profilePhotoUrl: json['profile_photo_url'],
      rating: json['rating'] ?? 0,
      relativeTimeDescription: json['relative_time_description'] ?? '',
      text: json['text'] ?? '',
      time: json['time'] ?? 0,
    );
  }
}

class Geometry {
  final Location location;
  final Viewport? viewport;

  Geometry({required this.location, this.viewport});

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      viewport: json['viewport'] != null 
          ? Viewport.fromJson(json['viewport'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['lat']?.toDouble() ?? 0.0,
      lng: json['lng']?.toDouble() ?? 0.0,
    );
  }
}

class Viewport {
  final Location northeast;
  final Location southwest;

  Viewport({required this.northeast, required this.southwest});

  factory Viewport.fromJson(Map<String, dynamic> json) {
    return Viewport(
      northeast: Location.fromJson(json['northeast'] as Map<String, dynamic>),
      southwest: Location.fromJson(json['southwest'] as Map<String, dynamic>),
    );
  }
}

class PopularTime {
  final String name; // e.g., "Monday", "Tuesday"
  final List<int> data; // Hour-by-hour popularity (0-100)

  PopularTime({required this.name, required this.data});

  factory PopularTime.fromJson(Map<String, dynamic> json) {
    return PopularTime(
      name: json['name'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt()).toList() ?? [],
    );
  }
} 