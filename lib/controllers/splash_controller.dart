import 'package:flutter/material.dart';

class SplashController extends ChangeNotifier {
  bool showSplash = true;
  bool dataLoadingComplete = false;
  double overlayOpacity = 1.0;

  void finishSplashAnimation(VoidCallback onFinish) {
    const fadeDuration = Duration(milliseconds: 200);
    const fadeSteps = 10;
    final stepDuration = Duration(milliseconds: fadeDuration.inMilliseconds ~/ fadeSteps);

    int currentStep = 0;

    void fadeStep() {
      currentStep++;
      final progress = currentStep / fadeSteps;
      final easedProgress = progress * progress;
      overlayOpacity = 1.0 - easedProgress;
      notifyListeners();

      if (progress >= 1.0) {
        showSplash = false;
        notifyListeners();
        onFinish();
      } else {
        Future.delayed(stepDuration, fadeStep);
      }
    }

    fadeStep();
  }
}