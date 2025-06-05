import 'package:flutter/material.dart';
import 'package:what_to_eat/services/fcm_service.dart';

class NotificationPermissionHelper {
  static Future<void> checkAndRequest(BuildContext context) async {
    try {
      bool isGranted = await FCMService().isNotificationPermissionGranted();
      if (!isGranted && context.mounted) {
        _showPermissionDialog(context);
      }
    } catch (e) {
      print('Error checking notification permissions: $e');
    }
  }

  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications, color: Colors.orange),
            SizedBox(width: 8),
            Text('Enable Notifications'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To receive notifications about restaurants and recommendations, please enable notifications for this app.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'You can change this setting anytime in your device settings.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              bool granted = await FCMService().requestNotificationPermissions();
              if (!granted && context.mounted) {
                _showSettingsDialog(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Notifications are disabled. To enable them, please go to Settings > Apps > What to Eat > Notifications and turn on notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await FCMService().openNotificationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}