import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/installation_id_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class InstallationIdDemoScreen extends StatefulWidget {
  const InstallationIdDemoScreen({super.key});

  @override
  State<InstallationIdDemoScreen> createState() => _InstallationIdDemoScreenState();
}

class _InstallationIdDemoScreenState extends State<InstallationIdDemoScreen> {
  final InstallationIdService _installationIdService = InstallationIdService();
  Map<String, String?> _identifiers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadIdentifiers();
  }

  Future<void> _loadIdentifiers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final identifiers = await _installationIdService.getAllIdentifiers();
      setState(() {
        _identifiers = identifiers;
      });
    } catch (e) {
      _showToast('加载标识符时出错: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _copyToClipboard(String text, String name) {
    Clipboard.setData(ClipboardData(text: text));
    _showToast('$name 已复制到剪贴板');
  }

  Widget _buildIdentifierCard(String title, String? value, String description) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (value != null && !value.startsWith('Error:'))
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyToClipboard(value, title),
                    tooltip: '复制',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: value?.startsWith('Error:') == true 
                    ? Colors.red[50] 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value?.startsWith('Error:') == true 
                      ? Colors.red[200]! 
                      : Colors.grey[300]!,
                ),
              ),
              child: Text(
                value ?? '加载中...',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: value?.startsWith('Error:') == true 
                      ? Colors.red[700] 
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('安装ID示例'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadIdentifiers,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '以下是不同类型的安装标识符。每种都有不同的用途和特性：',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _buildIdentifierCard(
                    'Firebase Installation ID',
                    _identifiers['firebaseInstallationId'],
                    '推荐使用：Firebase为每个应用安装生成的唯一标识符，安全且稳定。卸载重装后会改变。',
                  ),
                  _buildIdentifierCard(
                    'FCM Token',
                    _identifiers['fcmToken'],
                    '推送通知令牌，也可用作设备标识符。可能会定期更新，适合推送通知场景。',
                  ),
                  _buildIdentifierCard(
                    '自定义安装ID',
                    _identifiers['customInstallationId'],
                    '本地生成的简单标识符，保存在SharedPreferences中。卸载应用后会丢失。',
                  ),
                  _buildIdentifierCard(
                    'Firebase Installation Token',
                    _identifiers['firebaseInstallationToken'],
                    'Firebase Installation的身份验证令牌，用于服务器端验证。',
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            try {
                              await _installationIdService.deleteFirebaseInstallation();
                              _showToast('Firebase Installation 已删除，正在重新加载...');
                              await Future.delayed(const Duration(seconds: 1));
                              _loadIdentifiers();
                            } catch (e) {
                              _showToast('删除失败: $e');
                            }
                          },
                          child: const Text('删除Firebase Installation'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            try {
                              await _installationIdService.clearCustomInstallationId();
                              _showToast('自定义安装ID已清除，正在重新加载...');
                              _loadIdentifiers();
                            } catch (e) {
                              _showToast('清除失败: $e');
                            }
                          },
                          child: const Text('清除自定义安装ID'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
