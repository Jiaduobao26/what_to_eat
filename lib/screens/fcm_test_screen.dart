import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/fcm_service.dart';

class FCMTestScreen extends StatefulWidget {
  const FCMTestScreen({super.key});

  @override
  State<FCMTestScreen> createState() => _FCMTestScreenState();
}

class _FCMTestScreenState extends State<FCMTestScreen> {
  String? _fcmToken;
  bool _isLoading = false;
  final List<String> _receivedMessages = [];
  bool _isSubscribedToTopic = false;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
    _setupMessageListeners();
  }

  void _setupMessageListeners() {
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Received foreground message in test screen!');
      setState(() {
        _receivedMessages.insert(0, 
          '[${DateTime.now().toString().substring(11, 19)}] 前台消息: ${message.notification?.title ?? 'No title'} - ${message.notification?.body ?? 'No body'}');
      });
      
      // Show dialog
      _showMessageDialog(message, '前台消息');
    });

    // Listen for background app opened messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 App opened from notification in test screen!');
      setState(() {
        _receivedMessages.insert(0, 
          '[${DateTime.now().toString().substring(11, 19)}] 后台点击: ${message.notification?.title ?? 'No title'} - ${message.notification?.body ?? 'No body'}');
      });
    });
  }

  void _showMessageDialog(RemoteMessage message, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📱 收到 $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('标题: ${message.notification?.title ?? 'No title'}'),
            const SizedBox(height: 8),
            Text('内容: ${message.notification?.body ?? 'No body'}'),
            if (message.data.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('数据: ${message.data}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFCMToken() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? token = await FCMService().getToken();
      setState(() {
        _fcmToken = token;
      });
    } catch (e) {
      print('Error loading FCM token: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyTokenToClipboard() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FCM Token 已复制到剪贴板'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _subscribeToTopic() async {
    try {
      await FCMService().subscribeToTopic('test_notifications');
      setState(() {
        _isSubscribedToTopic = true;
        _receivedMessages.insert(0, 
          '[${DateTime.now().toString().substring(11, 19)}] ✅ 已订阅主题: test_notifications');
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已订阅测试主题')),
        );
      }
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  Future<void> _unsubscribeFromTopic() async {
    try {
      await FCMService().unsubscribeFromTopic('test_notifications');
      setState(() {
        _isSubscribedToTopic = false;
        _receivedMessages.insert(0, 
          '[${DateTime.now().toString().substring(11, 19)}] ❌ 已取消订阅主题: test_notifications');
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消订阅测试主题')),
        );
      }
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM 测试'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FCM Token Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_fcmToken != null)
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _fcmToken!,
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _copyTokenToClipboard,
                            icon: const Icon(Icons.copy),
                            label: const Text('复制 Token'),
                          ),
                        ],
                      )
                    else
                      const Text('无法获取 FCM Token', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
            
            // Topic Subscription Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '主题订阅',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: !_isSubscribedToTopic ? _subscribeToTopic : null,
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('订阅测试主题'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isSubscribedToTopic ? _unsubscribeFromTopic : null,
                          icon: const Icon(Icons.notifications_off),
                          label: const Text('取消订阅'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Testing Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 测试说明',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. 复制上面的 FCM Token\n'
                      '2. 访问 Firebase Console > Cloud Messaging\n'
                      '3. 点击 "Send your first message"\n'
                      '4. 选择 "Single device" 并粘贴 Token\n'
                      '5. 发送测试消息\n'
                      '6. 在下方查看接收到的消息\n\n'
                      '💡 提示：模拟器可能不显示系统通知，但消息会在应用内显示',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // Message History
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📨 接收到的消息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _receivedMessages.clear();
                    });
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
            
            Expanded(
              child: _receivedMessages.isEmpty
                  ? const Center(
                      child: Text(
                        '还没有接收到消息\n\n发送一条测试消息试试！',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _receivedMessages.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.message, color: Colors.blue),
                            title: Text(
                              _receivedMessages[index],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
