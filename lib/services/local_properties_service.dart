import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

class LocalPropertiesService {
  static Future<String?> getGoogleMapsApiKey() async {
    try {
      // 从根目录读取 local.properties 文件
      final content = await rootBundle.loadString('local.properties');
      final lines = content.split('\n');
      for (var line in lines) {
        line = line.trim(); // 去除空白字符
        if (line.startsWith('GOOGLE_MAPS_API_KEY=')) {
          final apiKey = line.split('=')[1].trim();
          print('🔑 API Key loaded from root local.properties');
          return apiKey;
        }
      }
      print('❌ GOOGLE_MAPS_API_KEY not found in local.properties');
    } catch (e) {
      print("❌ Error reading local.properties from root: $e");
      
      // 备用方案：尝试从 assets 目录读取
      try {
        print('🔄 Trying fallback: assets/local.properties');
        final content = await rootBundle.loadString('assets/local.properties');
        final lines = content.split('\n');
        for (var line in lines) {
          line = line.trim();
          if (line.startsWith('GOOGLE_MAPS_API_KEY=')) {
            final apiKey = line.split('=')[1].trim();
            print('🔑 API Key loaded from assets/local.properties (fallback)');
            return apiKey;
          }
        }
      } catch (fallbackError) {
        print("❌ Fallback also failed: $fallbackError");
      }
    }
    return null;
  }
}
