import 'package:flutter/material.dart';

class CustomButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final String color; // 'orange', 'white', or 'disabled'
  const CustomButtonWidget({
    super.key, 
    this.onPressed,
    required this.text,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    final isOrange = color == 'orange';
    final isDisabled = color == 'disabled' || onPressed == null;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled 
            ? Colors.grey[300] 
            : isOrange 
                ? const Color(0xFFFFA500) 
                : Colors.white,
        foregroundColor: isDisabled 
            ? Colors.grey[600] 
            : const Color(0xFF391713),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: isDisabled
              ? BorderSide(color: Colors.grey[400]!)
              : isOrange
                  ? BorderSide.none
                  : const BorderSide(color: Color(0xFFFFA500)),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontFamily: 'League Spartan',
          fontWeight: FontWeight.w700,
          letterSpacing: -0.09,
          color: isDisabled ? Colors.grey[600] : null,
        ),
      ),
    );
  }
}