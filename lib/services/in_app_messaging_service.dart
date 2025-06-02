import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class InAppMessagingService {
  static final InAppMessagingService _instance = InAppMessagingService._internal();
  factory InAppMessagingService() => _instance;
  InAppMessagingService._internal();

  final FirebaseInAppMessaging _iam = FirebaseInAppMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> initialize({bool enableDebug = true}) async {
    // Enable automatic message display
    await _iam.setAutomaticDataCollectionEnabled(true);

    // Optionally enable debug mode (messages can be triggered every minute)
    if (enableDebug) {
      await _iam.triggerEvent('test_debug_event'); // trigger dummy event
      if (kDebugMode) {
        print('[IAM] Debug event triggered');
      }
    }
  }

  Future<void> triggerEvent(String name) async {
    await _analytics.logEvent(name: name);
    await _iam.triggerEvent(name);
    if (kDebugMode) {
      print('[IAM] Event triggered: $name');
    }
  }
} 