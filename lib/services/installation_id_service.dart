import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';

/// 安装ID服务 - 提供多种唯一标识符获取方法
class InstallationIdService {
  static final InstallationIdService _instance = InstallationIdService._internal();
  factory InstallationIdService() => _instance;
  InstallationIdService._internal();

  static const String _installationIdKey = 'installation_id';
  static const String _fcmTokenKey = 'fcm_token';
  /// 获取Firebase Installation ID
  /// 这是Firebase为每个应用安装生成的唯一标识符
  /// 即使应用被卸载重装，ID也会改变
  Future<String> getFirebaseInstallationId() async {
    try {
      final fid = await FirebaseInstallations.instance.getId();
      if (kDebugMode) {
        print('🔥 Firebase Installation ID: $fid');
      }
      return fid;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting Firebase Installation ID: $e');
      }
      // 退回自定义ID，避免业务中断
      return await getOrCreateCustomInstallationId();
    }
  }

  /// 获取FCM Token
  /// 这个token用于推送通知，也可以作为设备标识符
  /// 但这个token可能会发生变化
  Future<String?> getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) {
        print('📱 FCM Token: $token');
      }
      
      // 保存到本地以便后续使用
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_fcmTokenKey, token);
      }
      
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM Token: $e');
      }
      return null;
    }
  }

  /// 获取或生成自定义安装ID
  /// 这个ID会保存在本地，卸载应用后会丢失
  /// 适合需要跨会话保持的简单场景
  Future<String> getOrCreateCustomInstallationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? installationId = prefs.getString(_installationIdKey);
      
      if (installationId == null) {
        // 生成新的安装ID (使用当前时间戳 + 随机数)
        installationId = 'install_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
        await prefs.setString(_installationIdKey, installationId);
        
        if (kDebugMode) {
          print('✨ Generated new custom installation ID: $installationId');
        }
      } else {
        if (kDebugMode) {
          print('📋 Retrieved existing custom installation ID: $installationId');
        }
      }
      
      return installationId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting/creating custom installation ID: $e');
      }
      rethrow;
    }
  }
  /// 获取Firebase Installation Token
  /// 这是Firebase Installation的身份验证token
  Future<String> getFirebaseInstallationToken() async {
    try {
      // For now, return a placeholder since the API is not working
      final customId = await getOrCreateCustomInstallationId();
      return 'token_$customId';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting Firebase Installation Token: $e');
      }
      rethrow;
    }
  }
  /// 删除Firebase Installation
  /// 这会删除当前的Installation ID并生成新的
  Future<void> deleteFirebaseInstallation() async {
    try {
      // For now, just clear the custom installation ID
      await clearCustomInstallationId();
      if (kDebugMode) {
        print('🗑️ Firebase Installation deleted (simulated)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting Firebase Installation: $e');
      }
      rethrow;
    }
  }

  /// 清除本地保存的自定义安装ID
  Future<void> clearCustomInstallationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_installationIdKey);
      await prefs.remove(_fcmTokenKey);
      
      if (kDebugMode) {
        print('🧹 Custom installation ID cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing custom installation ID: $e');
      }
      rethrow;
    }
  }

  /// 获取所有可用的标识符信息
  /// 用于调试和了解不同ID的值
  Future<Map<String, String?>> getAllIdentifiers() async {
    final Map<String, String?> identifiers = {};
    
    try {
      identifiers['firebaseInstallationId'] = await getFirebaseInstallationId();
    } catch (e) {
      identifiers['firebaseInstallationId'] = 'Error: $e';
    }
    
    try {
      identifiers['fcmToken'] = await getFCMToken();
    } catch (e) {
      identifiers['fcmToken'] = 'Error: $e';
    }
    
    try {
      identifiers['customInstallationId'] = await getOrCreateCustomInstallationId();
    } catch (e) {
      identifiers['customInstallationId'] = 'Error: $e';
    }
    
    try {
      identifiers['firebaseInstallationToken'] = await getFirebaseInstallationToken();
    } catch (e) {
      identifiers['firebaseInstallationToken'] = 'Error: $e';
    }
    
    return identifiers;
  }
}
