import 'package:flutter/material.dart';

class ResultDialog extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final VoidCallback onClose;

  const ResultDialog({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF391713),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF79747E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              price,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE95322),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
                foregroundColor: const Color(0xFF391713),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              onPressed: onClose,
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 17,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.09,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 