import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../blocs/wheel_bloc.dart';
import '../../helpers/wheel_option_preference_helper.dart';

class EditWheelOptionsDialog extends StatelessWidget {
  const EditWheelOptionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WheelBloc>().state;
    return AlertDialog(
      elevation: 8,
      backgroundColor: const Color(0xFFF5F5F5),
      contentPadding: EdgeInsets.zero,
      content: SingleChildScrollView(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
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
                          dropdownColor: Color(0xFFF5F5F5),
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
                        foregroundColor: Colors.orange,
                        side: BorderSide(color: Colors.orange),
                        // foregroundColor: const Color(0xFF4CAF50),
                        // side: const BorderSide(color: Color(0xFF4CAF50)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => WheelOptionPreferenceHelper.fillWithPreferences(context),
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Randomize'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
 }