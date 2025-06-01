import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../blocs/wheel_bloc.dart';
import '../../repositories/user_preference_repository.dart';
import '../../models/preference.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class EditWheelOptionsDialog extends StatelessWidget {
  const EditWheelOptionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WheelBloc>().state;
    return AlertDialog(
      backgroundColor: const Color(0xFFF5F5F5),
      contentPadding: EdgeInsets.zero,
      content: SingleChildScrollView(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Wheel Options',
                    style: TextStyle(
                      color: Color(0xFF391713),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF79747E)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(state.options.length, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE95322), width: 1.2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: DropdownButtonFormField<Option>(
                          value: state.options[i].keyword.isEmpty ? null : state.options[i],
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                          hint: const Text('choose a cuisine'),
                          items: context.read<WheelBloc>().cuisines.map((cuisine) {
                            final isSelected = state.options
                                .where((opt) => opt != state.options[i])
                                .any((opt) => opt.keyword == cuisine.keyword);
                            final option = Option(name: cuisine.name, keyword: cuisine.keyword);
                            return DropdownMenuItem<Option>(
                              value: option,
                              enabled: !isSelected,
                              child: Text(
                                cuisine.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.grey : const Color(0xFF391713),
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (option) {
                            if (option != null) {
                              context.read<WheelBloc>().add(UpdateOptionEvent(i, option.name, option.keyword));
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFE95322)),
                      onPressed: () {
                        if (state.options.length > 2) {
                          context.read<WheelBloc>().add(RemoveOptionEvent(i));
                        } else {
                          Fluttertoast.showToast(
                            msg: "At least 2 options are required.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: Colors.black87,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      },
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE95322),
                        side: const BorderSide(color: Color(0xFFE95322)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.read<WheelBloc>().add(AddOptionEvent()),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Option'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _fillWithPreferences(context),
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Random preferences'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE95322),
                        side: const BorderSide(color: Color(0xFFE95322)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fillWithPreferences(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Fluttertoast.showToast(
          msg: "Please log in to use your preferences.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      final repo = UserPreferenceRepository();
      final preference = await repo.fetchPreference(user.uid);
      
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

      final wheelBloc = context.read<WheelBloc>();
      final allCuisines = wheelBloc.cuisines;
      final currentOptions = wheelBloc.state.options;
      
      // 找到与用户喜欢的菜系匹配的可用菜系
      final matchedOptions = <Option>[];
      
      for (final likedCuisine in preference.likedCuisines) {
        // 在所有可用菜系中寻找匹配的
        for (final cuisine in allCuisines) {
          if (cuisine.keyword == likedCuisine || cuisine.name.toLowerCase() == likedCuisine.toLowerCase()) {
            // 避免重复添加
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
      
      // 随机打乱匹配的选项
      final random = Random();
      matchedOptions.shuffle(random);
      
      // 确保至少有2个选项，如果偏好不够，保留一些现有选项
      final newOptions = <Option>[];
      final maxOptions = currentOptions.length;
      
      // 先添加随机排序的匹配偏好
      newOptions.addAll(matchedOptions.take(maxOptions));
      
      // 如果偏好选项少于当前选项数量，用现有选项补足
      if (newOptions.length < maxOptions) {
        final remainingCount = maxOptions - newOptions.length;
        final existingOptionsToKeep = currentOptions.where((option) => 
          option.keyword.isNotEmpty && 
          !newOptions.any((newOption) => newOption.keyword == option.keyword)
        ).toList();
        
        // 也随机选择现有选项
        existingOptionsToKeep.shuffle(random);
        newOptions.addAll(existingOptionsToKeep.take(remainingCount));
      }
      
      // 确保至少有2个选项
      if (newOptions.length < 2) {
        // 如果还是不够，从所有菜系中随机选择一些
        final additionalNeeded = 2 - newOptions.length;
        final usedKeywords = newOptions.map((opt) => opt.keyword).toSet();
        final availableOptions = allCuisines
          .where((cuisine) => !usedKeywords.contains(cuisine.keyword))
          .toList();
        
        // 随机选择可用选项
        availableOptions.shuffle(random);
        final selectedOptions = availableOptions
          .take(additionalNeeded)
          .map((cuisine) => Option(name: cuisine.name, keyword: cuisine.keyword));
        
        newOptions.addAll(selectedOptions);
      }

      // 逐个更新选项
      for (int i = 0; i < newOptions.length && i < currentOptions.length; i++) {
        wheelBloc.add(UpdateOptionEvent(i, newOptions[i].name, newOptions[i].keyword));
      }
      
      Fluttertoast.showToast(
        msg: "Wheel randomly filled with your preferences! (${newOptions.length} options)",
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