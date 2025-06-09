import 'package:flutter/material.dart';
import 'random_mode.dart';

class DiceModeSelector extends StatelessWidget {
  final RandomMode selectedMode;
  final ValueChanged<RandomMode> onModeChanged;

  const DiceModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: () => onModeChanged(RandomMode.surprise),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedMode == RandomMode.surprise 
                    ? const Color(0xFFE95322) 
                    : Colors.white,
                foregroundColor: selectedMode == RandomMode.surprise 
                    ? Colors.white 
                    : const Color(0xFFE95322),
                side: const BorderSide(color: Color(0xFFE95322), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                elevation: selectedMode == RandomMode.surprise ? 4 : 1,
              ),
              icon: Icon(
                Icons.casino,
                size: 18,
                color: selectedMode == RandomMode.surprise 
                    ? Colors.white 
                    : const Color(0xFFE95322),
              ),
              label: const Text(
                'Surprise me!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: () => onModeChanged(RandomMode.preference),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedMode == RandomMode.preference 
                    ? const Color(0xFF4CAF50) 
                    : Colors.white,
                foregroundColor: selectedMode == RandomMode.preference 
                    ? Colors.white 
                    : const Color(0xFF4CAF50),
                side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                elevation: selectedMode == RandomMode.preference ? 4 : 1,
              ),
              icon: Icon(
                Icons.favorite,
                size: 18,
                color: selectedMode == RandomMode.preference 
                    ? Colors.white 
                    : const Color(0xFF4CAF50),
              ),
              label: const Text(
                'Based on my preference',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}