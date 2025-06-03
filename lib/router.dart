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
import 'screens/fcm_test_screen.dart';

class AppRouter {
  final AuthenticationBloc authBloc;

  AppRouter({required this.authBloc});

  // 公共页面动画包装函数（左右滑动）
  Page<dynamic> buildSlidePage(Widget child, GoRouterState state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // 从右滑入
        const end = Offset.zero;
        const curve = Curves.ease;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

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
        pageBuilder: (context, state) => buildSlidePage(const LoginScreen(), state),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => buildSlidePage(const RegisterScreen(), state),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => buildSlidePage(const ForgotPasswordScreen(), state),
      ),
      GoRoute(
        path: '/preferenceChoose',
        pageBuilder: (context, state) => buildSlidePage(const PreferenceChooseScreen(), state),
      ),
      GoRoute(
        path: '/preference-manage',
        pageBuilder: (context, state) => buildSlidePage(const PreferenceManageScreen(), state),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => buildSlidePage(MainScaffold(key: MainScaffold.globalKey), state),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) {
          final restaurants = state.extra as List<Map<String, dynamic>>?;
          return buildSlidePage(MapScreen(restaurants: restaurants), state);
        },
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => buildSlidePage(const ProfileScreen(), state),
      ),
      GoRoute(
        path: '/fcm-test',
        pageBuilder: (context, state) => buildSlidePage(const FCMTestScreen(), state),
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
