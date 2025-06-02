import 'package:flutter/material.dart';
import '../../services/fcm_service.dart';

class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            'To receive push notifications about new restaurants and recommendations, please enable notifications for this app.',
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
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
            // 请求权限
            bool granted = await FCMService().requestNotificationPermissions();
            if (!granted) {
              // 如果权限被拒绝，可以再次显示对话框引导到设置
              if (context.mounted) {
                _showSettingsDialog(context);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Enable'),
        ),
      ],
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

  // Static method to show the permission dialog
  static Future<void> showPermissionDialog(BuildContext context) async {
    // 先检查权限状态
    bool isGranted = await FCMService().isNotificationPermissionGranted();
    
    if (!isGranted) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const NotificationPermissionDialog(),
        );
      }
    }
  }
}
