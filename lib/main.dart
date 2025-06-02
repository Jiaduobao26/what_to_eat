import 'package:flutter/material.dart';
import 'router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth/authentication_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/nearby_restaurant_provider.dart';
import 'services/fcm_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Top-level function to handle background messages
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
  );
  
  // Set the background message handler early on
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize FCM Service
  await FCMService().initialize();
  
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


class MyRouterApp extends StatefulWidget {
  const MyRouterApp({super.key});

  @override
  State<MyRouterApp> createState() => _MyRouterAppState();
}

class _MyRouterAppState extends State<MyRouterApp> {
  late final AppRouter _appRouter; // singleton router

  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthenticationBloc>();
    _appRouter = AppRouter(authBloc: authBloc); // pass the AuthenticationBloc to AppRouter
    
    // Check guest status on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authBloc.add(AuthenticationCheckGuestStatusRequested());
      
      // preload restaurant data
      final restaurantProvider = context.read<NearbyRestaurantProvider>();
      restaurantProvider.preloadRestaurants();
    });
  }

  @override
  Widget build(BuildContext context) {
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