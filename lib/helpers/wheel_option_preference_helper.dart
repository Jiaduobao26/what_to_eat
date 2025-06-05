import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../blocs/wheel_bloc.dart';
import '../repositories/user_preference_repository.dart';
import '../models/preference.dart';

class WheelOptionPreferenceHelper {
  static Future<void> fillWithPreferences(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      Preference? preference;

      if (user == null) {
        final prefs = await SharedPreferences.getInstance();
        final likedCuisines = prefs.getStringList('guest_liked_cuisines') ?? [];
        final dislikedCuisines = prefs.getStringList('guest_disliked_cuisines') ?? [];

        if (likedCuisines.isEmpty) {
          Fluttertoast.showToast(
            msg: "No liked cuisines found. Please add some preferences first.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return;
        }

        preference = Preference(
          userId: 'guest',
          likedCuisines: likedCuisines,
          dislikedCuisines: dislikedCuisines,
        );
      } else {
        final repo = UserPreferenceRepository();
        preference = await repo.fetchPreference(user.uid);

        if (preference == null || preference.likedCuisines.isEmpty) {
          Fluttertoast.showToast(
            msg: "No liked cuisines found. Please add some preferences first.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return;
        }
      }
      final wheelBloc = Provider.of<WheelBloc>(context, listen: false);
      final allCuisines = wheelBloc.cuisines;
      final currentOptions = wheelBloc.state.options;

      final matchedOptions = <Option>[];

      for (final likedCuisine in preference.likedCuisines) {
        for (final cuisine in allCuisines) {
          if (cuisine.keyword == likedCuisine || cuisine.name.toLowerCase() == likedCuisine.toLowerCase()) {
            if (!matchedOptions.any((option) => option.keyword == cuisine.keyword)) {
              matchedOptions.add(Option(name: cuisine.name, keyword: cuisine.keyword));
            }
            break;
          }
        }
      }

      if (matchedOptions.isEmpty) {
        Fluttertoast.showToast(
          msg: "No matching cuisines found in available options.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      final random = Random();
      matchedOptions.shuffle(random);

      final newOptions = <Option>[];
      final maxOptions = currentOptions.length;

      newOptions.addAll(matchedOptions.take(maxOptions));

      if (newOptions.length < maxOptions) {
        final remainingCount = maxOptions - newOptions.length;
        final existingOptionsToKeep = currentOptions.where((option) =>
          option.keyword.isNotEmpty &&
          !newOptions.any((newOption) => newOption.keyword == option.keyword)
        ).toList();

        existingOptionsToKeep.shuffle(random);
        newOptions.addAll(existingOptionsToKeep.take(remainingCount));
      }

      if (newOptions.length < 2) {
        final additionalNeeded = 2 - newOptions.length;
        final usedKeywords = newOptions.map((opt) => opt.keyword).toSet();
        final availableOptions = allCuisines
          .where((cuisine) => !usedKeywords.contains(cuisine.keyword))
          .toList();

        availableOptions.shuffle(random);
        final selectedOptions = availableOptions
          .take(additionalNeeded)
          .map((cuisine) => Option(name: cuisine.name, keyword: cuisine.keyword));

        newOptions.addAll(selectedOptions);
      }

      for (int i = 0; i < newOptions.length && i < currentOptions.length; i++) {
        wheelBloc.add(UpdateOptionEvent(i, newOptions[i].name, newOptions[i].keyword));
      }

      final userType = user == null ? "guest" : "logged-in";
      Fluttertoast.showToast(
        msg: "Wheel filled with your $userType preferences! (${newOptions.length} options)",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.green[700],
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      print('Error filling with preferences: $e');
      Fluttertoast.showToast(
        msg: "Error loading preferences: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red[700],
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}