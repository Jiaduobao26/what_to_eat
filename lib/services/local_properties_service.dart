import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

class LocalPropertiesService {
  static Future<String?> getGoogleMapsApiKey() async {
    try {
      final content = await rootBundle.loadString('assets/local.properties');
      final lines = content.split('\n');
      for (var line in lines) {
        if (line.startsWith('GOOGLE_MAPS_API_KEY=')) {
          return line.split('=')[1].trim();
        }
      }
    } catch (e) {
      print("Error reading local.properties: $e");
    }
    return null;
  }
}
