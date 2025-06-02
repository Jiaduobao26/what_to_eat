import 'package:flutter/material.dart';
import 'router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth/authentication_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/nearby_restaurant_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

class _MyRouterAppState extends State<MyRouterApp>
    with SingleTickerProviderStateMixin {
  late final AppRouter _appRouter; // singleton router
  late final AnimationController _animController;
  late final Animation<double> _logoScale;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    // 1. 把 AuthenticationBloc 传给 router
    final authBloc = context.read<AuthenticationBloc>();
    _appRouter = AppRouter(authBloc: authBloc);

    // 2. 初始化动画控制器（2 秒缩放效果）
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    // 3. 动画结束后再多停留 500ms，之后隐藏 splash
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() => _showSplash = false);
        });
      }
    });

    // 4. 开始动画
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果 _showSplash == true，则先显示动画启动页
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: ScaleTransition(
              scale: _logoScale,
              // 这里换成你的“开机 image”，可以改为 Image.asset('assets/your_logo.png')
              child: Image.asset('assets/icon/app_icon.png'),
            ),
          ),
        ),
      );
    }

    // 动画结束后，切回到正常的路由结构
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listenWhen: (previous, current) =>
          previous.isLoggedIn != current.isLoggedIn,
      listener: (context, state) {},
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
