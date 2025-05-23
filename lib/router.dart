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
      final isLoggedIn = context.read<AuthenticationBloc>().state.isLoggedIn;
      final loggingIn = state.uri.toString() == '/login' || 
                         state.uri.toString() == '/register' ||
                         state.uri.toString() == '/forgot-password';
      print('redirect: $isLoggedIn, $loggingIn');
      if (!isLoggedIn && !loggingIn) {
        return '/login';
      }
      if (isLoggedIn && loggingIn) {
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
        builder: (context, state, child) => MainScaffold(
          location: state.uri.toString(), // pass the location to MainScaffold
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            name: 'home', // add a name to the home route
            // TODO: if login, redirect to the wheel route
            // if not login, redirect to the preferenceChoose or ...
            redirect: (_, __) => '/wheel', // redirect to the wheel route
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