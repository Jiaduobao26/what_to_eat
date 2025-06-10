import 'package:flutter/material.dart';
import 'router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth/authentication_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/nearby_restaurant_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'widgets/splash_screen.dart'; // import SplashScreen
import 'controllers/splash_controller.dart'; // import SplashController
import 'services/notification_permission_helper.dart'; // import NotificationPermissionHelper
import 'services/app_initializer.dart'; // import app initializer

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
  await initializeApp(_firebaseMessagingBackgroundHandler);
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

class _MyRouterAppState extends State<MyRouterApp> {
  late final AppRouter _appRouter;
  late final SplashController _splashController; // Controller for splash screen state

  @override
  void initState() {
    _splashController = SplashController();
    super.initState();
    print('🚀 MyRouterApp initState - Starting splash animation initialization');
    final authBloc = context.read<AuthenticationBloc>();
    _appRouter = AppRouter(authBloc: authBloc);

    // 监听启动屏幕状态变化
    _splashController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Listen to restaurant provider for data loading completion
    final restaurantProvider = context.read<NearbyRestaurantProvider>();

    // Add listener to monitor loading state
    void checkLoadingState() {
      if (restaurantProvider.hasLoaded && !_splashController.dataLoadingComplete) {
        print('✅ Restaurant data loading completed, stopping animation');
        _splashController.dataLoadingComplete = true;
        _splashController.finishSplashAnimation(() {});
      }
    }

    restaurantProvider.addListener(checkLoadingState);
    
    // Start background initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📱 Starting background initialization...');
      
      // Authentication check
      print('🔐 Checking user authentication status...');
      authBloc.add(AuthenticationCheckGuestStatusRequested());
         
      // Preload restaurant data
      print('🍽️ Starting restaurant data preload...');
      restaurantProvider.preloadRestaurants().then((_) {
        print('✅ Restaurant data preload completed');
        // Double check in case listener didn't catch it
        if (!_splashController.dataLoadingComplete) {
          _splashController.dataLoadingComplete = true;
          _splashController.finishSplashAnimation(() {});
        }
      }).catchError((e) {
        print('❌ Restaurant data preload failed: $e');
        // Even if loading fails, end the splash after a timeout
        if (!_splashController.dataLoadingComplete) {
          _splashController.dataLoadingComplete = true;
          _splashController.finishSplashAnimation(() {});
        }
      });
      
      // Fallback timeout in case data loading takes too long
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && !_splashController.dataLoadingComplete) {
          print('⏰ Timeout reached, ending splash animation');
          _splashController.dataLoadingComplete = true;
          _splashController.finishSplashAnimation(() {});
        }
      });
            
      // Delay notification permission check
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {          
          print('🔔 Checking notification permissions...');          
          NotificationPermissionHelper.checkAndRequest(context); // Check and request notification permissions
        }
      });
    });
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          // 只在需要时显示启动屏幕，不包裹AnimatedBuilder
          return Stack(
            children: [
              // 主应用内容
              child ?? const SizedBox(),
              // 启动屏幕覆盖层 - 让SplashScreen自己处理动画
              if (_splashController.showSplash)
                SplashScreen(
                  overlayOpacity: _splashController.overlayOpacity,
                  visible: _splashController.showSplash,
                ),
            ],
          );
        },
      ),
    );
  }
}