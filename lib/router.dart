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

class AppRouter {
  final AuthenticationBloc authBloc;

  AppRouter({required this.authBloc}); // Constructor to inject the AuthenticationBloc

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = context.read<AuthenticationBloc>().state;
      final isLoggedIn = authState.isLoggedIn;
      final isGuest = authState.isGuest;
      final loggingIn = state.uri.toString() == '/login' || 
                         state.uri.toString() == '/register' ||
                         state.uri.toString() == '/forgot-password';
      print('redirect: $isLoggedIn, $isGuest, $loggingIn');
      if (!isLoggedIn && !isGuest && !loggingIn) {
        return '/login';
      }
      if ((isLoggedIn || isGuest) && loggingIn) {
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
      ShellRoute(
        builder: (context, state, child) => MainScaffold(key: MainScaffold.globalKey),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/preferenceChoose',
            builder: (context, state) => const PreferenceChooseScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
        ]
      )
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