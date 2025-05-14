import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                onPressed: () {},
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
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
                onPressed: () {},
                child: const Text('Create New Account'),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  GoRouter.of(context).go('/preferenceChoose');
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
    );
  }
}