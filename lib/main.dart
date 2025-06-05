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
import 'widgets/splash_screen.dart'; // import SplashScreen
import 'services/notification_permission_helper.dart'; // import NotificationPermissionHelper

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

class _MyRouterAppState extends State<MyRouterApp> {
  late final AppRouter _appRouter;
  bool _showSplash = true; // Controls whether to show splash screen
  bool _dataLoadingComplete = false; // Track when data loading is complete
  double _currentOverlayOpacity = 1.0; // Current overlay opacity for fade-out

  @override
  void initState() {
    super.initState();
    print('🚀 MyRouterApp initState - Starting splash animation initialization');
    final authBloc = context.read<AuthenticationBloc>();
    _appRouter = AppRouter(authBloc: authBloc);

    // Listen to restaurant provider for data loading completion
    final restaurantProvider = context.read<NearbyRestaurantProvider>();

    // Add listener to monitor loading state
    void checkLoadingState() {
      if (restaurantProvider.hasLoaded && !_dataLoadingComplete) {
        print('✅ Restaurant data loading completed, stopping animation');
        _dataLoadingComplete = true;
        _finishSplashAnimation();
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
        if (!_dataLoadingComplete) {
          _dataLoadingComplete = true;
          _finishSplashAnimation();
        }
      }).catchError((e) {
        print('❌ Restaurant data preload failed: $e');
        // Even if loading fails, end the splash after a timeout
        if (!_dataLoadingComplete) {
          _dataLoadingComplete = true;
          _finishSplashAnimation();
        }
      });
      
      // Fallback timeout in case data loading takes too long
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && !_dataLoadingComplete) {
          print('⏰ Timeout reached, ending splash animation');
          _dataLoadingComplete = true;
          _finishSplashAnimation();
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

  // New method to handle the final animation and hide splash
  void _finishSplashAnimation() {
    if (!mounted) return;

    // Very fast fade-out animation
    const fadeDuration = Duration(milliseconds: 200); // Much faster
    const fadeSteps = 10; // Much fewer steps
    final stepDuration = Duration(milliseconds: fadeDuration.inMilliseconds ~/ fadeSteps);

    int currentStep = 0;

    void fadeStep() {
      if (!mounted) return;

      currentStep++;
      final progress = currentStep / fadeSteps;

      // Use easing curve for smoother appearance
      final easedProgress = progress * progress; // Quadratic easing
      _currentOverlayOpacity = 1.0 - easedProgress;

      setState(() {});

      if (progress >= 1.0) {
        // Fade complete, hide splash immediately
        setState(() => _showSplash = false);
      } else {
        // Continue fading with minimal delay
        Future.delayed(stepDuration, fadeStep);
      }
    }

    // Start the fade-out animation immediately
    fadeStep();
  }

  @override
  void dispose() {
    super.dispose();
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
              SplashScreen(
                overlayOpacity: _currentOverlayOpacity,
                visible: _showSplash,
              ),
            ],
          );
        },
      ),
    );
  }
}