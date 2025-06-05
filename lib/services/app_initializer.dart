import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'fcm_service.dart';
import 'in_app_messaging_service.dart';
import 'installation_id_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> initializeApp(Future<void> Function(RemoteMessage) backgroundHandler) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Set the background message handler early on
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  // Initialize FCM Service (outputs FCM token)
  await FCMService().initialize();
  // Initialize Firebase Analytics & IAM
  await FirebaseAnalytics.instance.logAppOpen();
  await InAppMessagingService().initialize();
  // Output Installation ID for debugging
  try {
    final installationId = await InstallationIdService().getFirebaseInstallationId();
    if (kDebugMode) {
      print('🔑 Installation ID: $installationId');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error getting Installation ID: $e');
    }
  }
}