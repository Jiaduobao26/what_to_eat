import 'package:flutter/material.dart';

class CustomButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final String color; // 'orange' or 'white'
  const CustomButtonWidget({
    super.key, 
    required this.onPressed,
    required this.text,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    final isOrange = color == 'orange';
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isOrange ? const Color(0xFFFFA500) : Colors.white,
        foregroundColor: const Color(0xFF391713),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: isOrange
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFFFA500)),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontFamily: 'League Spartan',
          fontWeight: FontWeight.w700,
          letterSpacing: -0.09,
        ),
      ),
    );
  }
}