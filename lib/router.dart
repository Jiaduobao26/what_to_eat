import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/preference_choose.dart';
import 'screens/lists.dart';
import 'screens/wheel.dart';
import 'screens/map.dart';
import 'screens/profile.dart';
import 'screens/register_screen.dart';
import 'screens/forgetpassword_screen.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/preferenceChoose',
      builder: (context, state) => const PreferenceChooseScreen(),
    ),
    GoRoute(
      path: '/lists',
      builder: (context, state) => const Lists(),
    ),
    GoRoute(
      path: '/wheel',
      builder: (context, state) => WheelOne(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);