import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../blocs/wheel_bloc.dart';
import '../widgets/dialogs/result_dialog.dart';
import '../widgets/buttons/custom_button_widget.dart';
import '../widgets/dialogs/edit_wheel_option_dialog.dart';
import '../widgets/restaurant_detail_card.dart';
import '../widgets/dice_wheel.dart';
import 'dart:math';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/nearby_restaurant_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_preference_repository.dart';
import '../models/preference.dart' as pref_models;

class WheelOne extends StatelessWidget {
  const WheelOne({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WheelBloc(),
      child: const WheelOneView(),
    );
  }
}

class WheelOneView extends StatefulWidget {
  const WheelOneView({super.key});

  @override
  State<WheelOneView> createState() => _WheelOneViewState();
}

class _WheelOneViewState extends State<WheelOneView> {
  late StreamController<int> _streamController;
  bool _isSpinning = false;
  int? _selectedIndex;
  
  // model change to toggle between custom wheel and random mode
  bool _isRandomMode = false;
  
  // trigger callback for dice wheel
  VoidCallback? _rollDiceCallback;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<int>.broadcast();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  void _onWheelStop() {
    print('Wheel stopped. _isSpinning: $_isSpinning, _selectedIndex: $_selectedIndex');
    if (_isSpinning && _selectedIndex != null) {
      setState(() {
        _isSpinning = false;
      });
      
      final options = context.read<WheelBloc>().state.options;
      final selectedOption = options[_selectedIndex!];
      final nearbyList = Provider.of<NearbyRestaurantProvider>(context, listen: false).restaurants;
    
      print('Selected option: ${selectedOption.name}, keyword: ${selectedOption.keyword}');
      print('Nearby restaurants count: ${nearbyList.length}');
      
      context.read<WheelBloc>().add(
        FetchRestaurantEvent(selectedOption.keyword, nearbyList: nearbyList),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<WheelBloc, WheelState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // 模式切换器
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            print('Switching to Custom Wheel mode...');
                            setState(() {
                              _isRandomMode = false;
                              _isSpinning = false;
                              _selectedIndex = null;
                            });
                            print('Switched to Custom Wheel mode');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isRandomMode ? const Color(0xFFE95322) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Custom Wheel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !_isRandomMode ? Colors.white : const Color(0xFF79747E),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            print('Switching to Random mode...');
                            setState(() {
                              _isRandomMode = true;
                              _isSpinning = false;
                              _selectedIndex = null;
                            });
                            print('Switched to Random Mode');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isRandomMode ? const Color(0xFFE95322) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Random Mode',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isRandomMode ? Colors.white : const Color(0xFF79747E),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // dice wheel or custom wheel section
                SizedBox(
                  height: 300,
                  child: _isRandomMode ? DiceWheel(
                    onRegisterCallback: (callback) {
                      _rollDiceCallback = callback;
                    },
                  ) : _buildWheelSection(state),
                ),
                BlocBuilder<WheelBloc, WheelState>(
                  builder: (context, state) {
                    final hasEmptyOptions = state.options.any((option) => option.keyword.isEmpty);
                    final canSpin = state.options.length >= 2 && !hasEmptyOptions;
                    
                    return Column(
                      children: [
                        if (!state.showResult) ...[
                          const SizedBox(height: 40),
                          CustomButtonWidget(
                            color: _isRandomMode || canSpin ? 'white' : 'disabled',
                            text: 'GO!',
                            onPressed: _isRandomMode ? () {
                              print('Starting dice roll...');
                              _rollDiceCallback?.call();
                            } : (canSpin ? () {
                              print('Starting wheel spin...');
                              final randomIndex = Random().nextInt(
                                context
                                    .read<WheelBloc>()
                                    .state
                                    .options
                                    .length,
                              );
                              print('Selected index: $randomIndex');
                              _streamController.add(randomIndex);
                              setState(() {
                                _isSpinning = true;
                                _selectedIndex = randomIndex;
                              });
                            } : null),
                          ),
                        ] else ...[
                          const SizedBox.shrink(),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (!_isRandomMode) // only show modify button for custom wheel
                  BlocBuilder<WheelBloc, WheelState>(
                    builder: (context, state) => TextButton(
                      onPressed: () => context.read<WheelBloc>().add(ShowModifyEvent()),
                      child: const Text(
                        'Modify my wheel',
                        style: TextStyle(
                          color: Color(0xFF386BF6),
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                BlocBuilder<WheelBloc, WheelState>(
                  builder: (context, state) {
                    if (state.showModify) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => BlocProvider.value(
                            value: context.read<WheelBloc>(),
                            child: const EditWheelOptionsDialog(),
                          ),
                        );
                        context.read<WheelBloc>().add(CloseModifyEvent());
                      });
                      return const SizedBox.shrink();
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 15),
                if (state.selectedRestaurant != null) ...[
                  CustomButtonWidget(
                    color: 'white',
                    text: 'Try Again',
                    onPressed: () async {
                      if (_isRandomMode) {
                        _rollDiceCallback?.call();
                      } else {
                        final randomIndex = Random().nextInt(
                          context.read<WheelBloc>().state.options.length,
                        );
                        _streamController.add(randomIndex);
                        setState(() {
                          _isSpinning = true;
                          _selectedIndex = randomIndex;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  RestaurantDetailCard(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWheelSection(WheelState state) {
    final hasEmptyOptions = state.options.any((option) => option.keyword.isEmpty);
    
    if (state.options.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Please add at least 2 options to spin the wheel',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    if (hasEmptyOptions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note,
              size: 48,
              color: Colors.red[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Some options are incomplete.\nPlease select cuisines for all options.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    return FortuneWheel(
      selected: _streamController.stream,
      animateFirst: false,
      onAnimationEnd: _onWheelStop,
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOutCubic,
      indicators: <FortuneIndicator>[
        FortuneIndicator(
          alignment: Alignment.topCenter,
          child: Icon(
            Icons.arrow_drop_down,
            size: 48,
            color: Color(0xFFE95322),
          ),
        ),
      ],
      items: [
        for (var option in state.options)
          FortuneItem(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                option.keyword.isEmpty
                    ? const Icon(
                      Icons.image,
                      size: 40,
                      color: Colors.grey,
                    )
                    : Image.asset(
                      'assets/cuisines_images/${option.keyword}.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                            Icons.food_bank,
                            size: 40,
                            color: Colors.grey,
                          ),
                    ),
                const SizedBox(height: 4),
                Text(
                  option.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF391713),
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            style: FortuneItemStyle(
              color: const Color(0xFFFFF3E0),
              borderColor: const Color(0xFFE95322),
              borderWidth: 3,
            ),
          ),
      ],
    );
  }
}