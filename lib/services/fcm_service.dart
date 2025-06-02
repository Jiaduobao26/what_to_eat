import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:io';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  late FirebaseMessaging _messaging;
  Future<void> initialize() async {
    _messaging = FirebaseMessaging.instance;
    
    // Check and request notification permissions for Android
    await _checkAndRequestNotificationPermissions();
    
    // Request FCM permissions
    await _requestPermissions();
    
    // Get FCM token
    await _getToken();
    
    // Configure message handlers
    _configureMessageHandlers();
  }

  Future<void> _checkAndRequestNotificationPermissions() async {
    if (Platform.isAndroid) {
      // 检查通知权限
      PermissionStatus status = await Permission.notification.status;
      if (kDebugMode) {
        print('🔔 Notification permission status: $status');
      }
      
      if (status.isDenied) {
        // 请求通知权限
        if (kDebugMode) {
          print('🔔 Requesting notification permission...');
        }
        
        PermissionStatus result = await Permission.notification.request();
        if (kDebugMode) {
          print('🔔 Notification permission result: $result');
        }
        
        if (result.isPermanentlyDenied) {
          // 如果用户永久拒绝，引导到设置页面
          if (kDebugMode) {
            print('🔔 Permission permanently denied, opening app settings');
          }
          await _showPermissionDialog();
        }
      }
    }
  }

  Future<void> _showPermissionDialog() async {
    // 这里需要在有context的地方调用，暂时只打印日志
    if (kDebugMode) {
      print('🔔 Should show permission dialog to user');
      print('🔔 Opening app settings...');
    }
    
    // 直接打开应用设置
    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        print('🔔 Error opening app settings: $e');
      }
    }
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('FCM Permission granted: ${settings.authorizationStatus}');
    }
  }

  Future<void> _getToken() async {
    try {
      String? token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      
      // Save token to your backend/Firestore here
      await _saveTokenToDatabase(token);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  Future<void> _saveTokenToDatabase(String? token) async {
    if (token != null) {
      // Here you would save the token to your Firestore/backend
      // For now, we'll just print it
      if (kDebugMode) {
        print('Saving FCM token to database: $token');
      }
      
      // Example: Save to Firestore
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(currentUserId)
      //     .update({'fcmToken': token});
    }
  }

  void _configureMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📱 Foreground message received!');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
      }
    });

    // Handle background messages when app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('🔔 App opened from notification!');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
      }
      
      // Handle navigation based on message data
      _handleNotificationTap(message);
    });

    // Handle initial message if app was opened from notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('🚀 App launched from notification!');
          print('Title: ${message.notification?.title}');
          print('Body: ${message.notification?.body}');
          print('Data: ${message.data}');
        }
        
        _handleNotificationTap(message);
      }
    });

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((String token) {
      if (kDebugMode) {
        print('🔄 FCM Token refreshed: $token');
      }
      _saveTokenToDatabase(token);
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Handle navigation based on notification data
    if (kDebugMode) {
      print('🎯 Handling notification tap: ${message.data}');
    }
    
    // Example: Navigate to specific screen based on message data
    // if (message.data.containsKey('screen')) {
    //   String screen = message.data['screen'];
    //   // Navigate to the specified screen
    // }
  }

  // Method to subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('✅ Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to topic $topic: $e');
      }
    }
  }

  // Method to unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('✅ Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error unsubscribing from topic $topic: $e');
      }
    }
  }
  // Method to get current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
      return null;
    }
  }

  // Method to check notification permission status
  Future<bool> isNotificationPermissionGranted() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.notification.status;
      return status.isGranted;
    }
    return true; // iOS permissions are handled by FCM itself
  }

  // Method to request notification permissions with user dialog
  Future<bool> requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.notification.status;
      
      if (status.isDenied) {
        PermissionStatus result = await Permission.notification.request();
        if (kDebugMode) {
          print('🔔 Notification permission request result: $result');
        }
        return result.isGranted;
      } else if (status.isPermanentlyDenied) {
        // 用户之前永久拒绝了权限，引导到设置
        if (kDebugMode) {
          print('🔔 Notification permission permanently denied');
        }
        return false;
      }
      
      return status.isGranted;
    }
    return true;
  }

  // Method to open app settings for notification permissions
  Future<void> openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening app settings: $e');
      }
    }
  }
}
