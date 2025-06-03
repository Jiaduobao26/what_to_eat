import 'package:geolocator/geolocator.dart';

class DistanceUtils {
  /// Calculate distance between two coordinates and return formatted string
  /// Returns distance in miles (mi) or feet (ft)
  static String calculateDistance(
    double userLat,
    double userLng,
    double restaurantLat,
    double restaurantLng,
  ) {
    try {
      // Use geolocator's distanceBetween method to calculate distance (unit: meters)
      double distanceInMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        restaurantLat,
        restaurantLng,
      );

      // Convert to miles
      double distanceInMiles = distanceInMeters * 0.000621371;

      // Format distance display
      if (distanceInMiles < 0.1) {
        // Less than 0.1 miles, display in feet
        double distanceInFeet = distanceInMeters * 3.28084;
        return '${distanceInFeet.round()} ft';
      } else {
        // 0.1 miles and above, display in miles with one decimal place
        return '${distanceInMiles.toStringAsFixed(1)} mi';
      }
    } catch (e) {
      print('Error calculating distance: $e');
      return '--';
    }
  }

  /// Calculate distance in miles (for filtering purposes)
  static double calculateDistanceInMiles(
    double userLat,
    double userLng,
    double restaurantLat,
    double restaurantLng,
  ) {
    try {
      double distanceInMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        restaurantLat,
        restaurantLng,
      );
      return distanceInMeters * 0.000621371; // Convert meters to miles
    } catch (e) {
      print('Error calculating distance: $e');
      return double.infinity;
    }
  }

  /// Calculate distance in meters (for legacy compatibility)
  static double calculateDistanceInMeters(
    double userLat,
    double userLng,
    double restaurantLat,
    double restaurantLng,
  ) {
    try {
      return Geolocator.distanceBetween(
        userLat,
        userLng,
        restaurantLat,
        restaurantLng,
      );
    } catch (e) {
      print('Error calculating distance: $e');
      return double.infinity;
    }
  }
}
