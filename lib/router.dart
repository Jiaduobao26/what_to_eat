import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../auth/authentication_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// pages
import 'screens/login_screen.dart';
import 'screens/preference_choose.dart';
import 'screens/lists.dart';
import 'screens/wheel.dart';
import 'screens/map.dart';
import 'screens/profile.dart';
import 'screens/register_screen.dart';
import 'screens/forgetpassword_screen.dart';
import '../screens/main_scaffold.dart';
import 'screens/preference_manage_screen.dart';

class AppRouter {
  final AuthenticationBloc authBloc;

  AppRouter({required this.authBloc}); // Constructor to inject the AuthenticationBloc

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = context.read<AuthenticationBloc>().state;
      final isLoggedIn = authState.isLoggedIn;
      final isGuest = authState.isGuest;
      final isGuestLoggedIn = authState.isGuestLoggedIn;
      final loggingIn = state.uri.toString() == '/login' || 
                         state.uri.toString() == '/register' ||
                         state.uri.toString() == '/forgot-password';
      print('redirect: $isLoggedIn, $isGuest, $isGuestLoggedIn, $loggingIn');
      
      if (!isLoggedIn && !isGuest && !isGuestLoggedIn && !loggingIn) {
        return '/login';
      }
      if ((isLoggedIn || isGuest || isGuestLoggedIn) && loggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
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
            path: '/preference-manage',
            builder: (context, state) => const PreferenceManageScreen(), // Preference management route
          ),
      GoRoute(
        path: '/',
        builder: (context, state) => MainScaffold(key: MainScaffold.globalKey),
      ),
        GoRoute(
          path: '/map',
          builder: (context, state) => MapScreen(
            restaurants: state.extra as List<Map<String, dynamic>>?,
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
    ],
  );
}
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    stream.listen((_) {
      notifyListeners();
    });
  }
}