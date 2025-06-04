import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth/authentication_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/nearby_restaurant_provider.dart';
import 'services/fcm_service.dart';
import 'services/installation_id_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'services/in_app_messaging_service.dart';

/// Top-level function to handle background FCM messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
  print('Background message data: ${message.data}');
  if (message.notification != null) {
    print('Background notification title: ${message.notification!.title}');
    print('Background notification body: ${message.notification!.body}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );  // Set the background message handler early on
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NearbyRestaurantProvider(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthenticationBloc()),
        ],
        child: const MyRouterApp(),
      ),
    );
  }
}

/// 我们把启动动画和路由放到同一个 StatefulWidget 里
class MyRouterApp extends StatefulWidget {
  const MyRouterApp({super.key});

  @override
  State<MyRouterApp> createState() => _MyRouterAppState();
}

class _MyRouterAppState extends State<MyRouterApp>
    with SingleTickerProviderStateMixin {
  late final AppRouter _appRouter;
  late final AnimationController _animController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;
  late final Animation<double> _logoOpacity;
  bool _showSplash = true; // 用来控制是否展示启动页

  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthenticationBloc>();
    _appRouter = AppRouter(authBloc: authBloc);

    // 2. 创建动画控制器：持续 2 秒的缩放
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    // 缩放动画：从0到1.2再回到1.0
    _logoScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40.0,
      ),
    ]).animate(_animController);

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 4 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    // 透明度动画
    _logoOpacity = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 70.0,
      ),
    ]).animate(_animController);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() => _showSplash = false);
        });
      }
    });

    // 4. 动画开始
    _animController.forward();

    // 5. 剩余初始化逻辑：注册 BLoC 观察，预加载数据，检查通知权限
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authBloc.add(AuthenticationCheckGuestStatusRequested());
      
      // preload restaurant data
      final restaurantProvider = context.read<NearbyRestaurantProvider>();
      restaurantProvider.preloadRestaurants();
      
      // Check notification permissions after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _checkNotificationPermissions();
        }
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// 弹出通知权限的对话框
  Future<void> _checkNotificationPermissions() async {
    try {
      bool isGranted = await FCMService().isNotificationPermissionGranted();
      if (!isGranted && mounted) {
        // Show permission request dialog
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
                  if (!granted && mounted) {
                    _showSettingsDialog();
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
    } catch (e) {
      print('Error checking notification permissions: $e');
    }
  }

  void _showSettingsDialog() {
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

  @override
  Widget build(BuildContext context) {
    // 如果仍然要显示启动动画，就返回一个单独的 MaterialApp 包裹缩放动画
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _logoRotation.value,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 150,
                          height: 150,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // 动画结束后，渲染你原本的路由结构
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listenWhen: (previous, current) => previous.isLoggedIn != current.isLoggedIn,
      listener: (context, state) {
      },
      child: MaterialApp.router(
        routerConfig: _appRouter.router,
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
      ),
    );
  }
}