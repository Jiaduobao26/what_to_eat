import 'package:flutter/material.dart';
import 'dart:math';

class DiceAnimationController {
  final TickerProvider vsync;
  late final AnimationController controller;
  late final Animation<double> rotationAnimation;
  late final Animation<double> scaleAnimation;

  DiceAnimationController({required this.vsync}) {
    controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: vsync,
    );

    rotationAnimation = Tween<double>(
      begin: 0,
      end: 8 * pi,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));

    scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));
  }

  void dispose() {
    controller.dispose();
  }
}