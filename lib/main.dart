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

/// Combine splash animation and routing in the same StatefulWidget
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
  late final Animation<double> _overlayOpacity;
  bool _showSplash = true; // Controls whether to show splash screen

  @override
  void initState() {
    super.initState();
    print('🚀 MyRouterApp initState - Starting splash animation initialization');
    final authBloc = context.read<AuthenticationBloc>();
    _appRouter = AppRouter(authBloc: authBloc);

    // 2. Create animation controller: Increase duration for loading time
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // Increased to 4 seconds
    );
    
    // Scale animation: from 0 to 1.2 then back to 1.0
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
      end: 4 * 3.14159, // Increase rotation for more visibility
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    // Opacity animation - Extended display time
    _logoOpacity = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 30.0, // Reduce fade-in time
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 70.0, // Increase display time
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20.0, // Reduce fade-out time
      ),
    ]).animate(_animController);

    // Overlay opacity animation - Longer display time
    _overlayOpacity = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 90.0, // Increase overlay display time
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20.0, // Quick fade-out
      ),
    ]).animate(_animController);

    _animController.addStatusListener((status) {
      print('🎬 Animation status changed: $status');
      if (status == AnimationStatus.completed) {
        print('✅ Splash animation completed, hiding splash screen');
        setState(() => _showSplash = false);
      }
    });

    // 4. Start animation
    print('🎬 Starting splash animation...');
    _animController.forward();

    // 5. Remaining initialization logic: register BLoC observer, preload data, check notification permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📱 Starting background initialization...');
      
      // Authentication check
      print('🔐 Checking user authentication status...');
      authBloc.add(AuthenticationCheckGuestStatusRequested());
      
      // Preload restaurant data
      print('🍽️ Starting restaurant data preload...');
      final restaurantProvider = context.read<NearbyRestaurantProvider>();
      restaurantProvider.preloadRestaurants().then((_) {
        print('✅ Restaurant data preload completed');
      }).catchError((e) {
        print('❌ Restaurant data preload failed: $e');
      });
      
      // Delay notification permission check to give other initialization more time
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          print('🔔 Checking notification permissions...');
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

  /// Show notification permission dialog
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
    // Non-blocking approach: always render main app, use overlay to show splash animation
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listenWhen: (previous, current) => previous.isLoggedIn != current.isLoggedIn,
      listener: (context, state) {
      },
      child: MaterialApp.router(
        routerConfig: _appRouter.router,
        title: 'What to Eat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        builder: (context, child) {
          // Show splash animation overlay if needed
          return Stack(
            children: [
              // Main app content (always exists, not blocked)
              child ?? const SizedBox(),
              // Splash animation overlay (can disappear)
              if (_showSplash)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      return Opacity(
                        opacity: _overlayOpacity.value,
                        child: Container(
                          color: Colors.white,
                          width: double.infinity,
                          height: double.infinity,
                          child: Center(
                            child: Transform.rotate(
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
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/icon/app_icon.png',
                                      width: 150, // Increase icon size
                                      height: 150,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}