import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/authentication_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/main_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
        if (state.isLoggedIn || state.isGuest) {
          MainScaffold.globalKey.currentState?.switchTab(1);
        }
      },
      child:Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE95322),
                  fontSize: 32,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Email',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Password',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA500),
                  foregroundColor: const Color(0xFF391713),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF2C2C2C)),
                  ),
                ),
                onPressed: () {
                  context.read<AuthenticationBloc>().add(
                  AuthenticationLoginRequested(
                    email: _emailController.text,
                    password: _passwordController.text,
                  ), 
                  );
                },
                child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const CircularProgressIndicator(color: Colors.white);
                  }
                  return const Text('Sign In');
                },
              ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.go('/forgot-password');
                },
                child: const Text(
                  'Forget Password',
                  style: TextStyle(
                    color: Color(0xFF391713),
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA500),
                  foregroundColor: const Color(0xFF391713),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF2C2C2C)),
                  ),
                ),
                onPressed: () {
                  context.go('/register');
                },
                child: const Text('Create New Account'),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                   context.read<AuthenticationBloc>().add(AuthenticationGuestRequested());
                },
                child: const Text(
                  'Continue without sign in',
                  style: TextStyle(
                    color: Color(0xFF386BF6),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }
}