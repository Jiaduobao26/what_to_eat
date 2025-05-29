import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../blocs/wheel_bloc.dart';
import '../widgets/dialogs/result_dialog.dart';
import '../widgets/buttons/custom_button_widget.dart';
import '../widgets/dialogs/edit_wheel_option_dialog.dart';
import '../widgets/restaurant_detail_card.dart';
import 'dart:math';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<int>();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  void _onWheelStop() {
    if (_isSpinning && _selectedIndex != null) {
      setState(() {
        _isSpinning = false;
        // get the options from the context
        final options = context.read<WheelBloc>().state.options;
        final selectedOption = options[_selectedIndex!];
        context.read<WheelBloc>().add(
          FetchRestaurantEvent(selectedOption.keyword),
        );
      });
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
                SizedBox(
                  height: 300,
                  child:
                      state.options.length > 1
                          ? FortuneWheel(
                            selected: _streamController.stream,
                            animateFirst: false,
                            onAnimationEnd: _onWheelStop,
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
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.food_bank,
                                                      size: 40,
                                                      color: Colors.grey,
                                                    ),
                                          ),
                                      const SizedBox(height: 4),
                                      Text(
                                        option.name,
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
                          )
                          : Center(
                            child: Text(
                              'Please add at least 2 options to spin the wheel',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                ),
                BlocBuilder<WheelBloc, WheelState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        if (!state.showResult) ...[
                          const SizedBox(height: 40),
                          CustomButtonWidget(
                            color: 'white',
                            text: 'GO!',
                            onPressed:() async {
                              final randomIndex = Random().nextInt(
                                context
                                    .read<WheelBloc>()
                                    .state
                                    .options
                                    .length,
                              );
                              _streamController.add(randomIndex);
                              setState(() {
                                _isSpinning = true;
                                _selectedIndex = randomIndex;
                              });
                            },
                          ),
                        ] else ...[
                          const SizedBox.shrink(),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                BlocBuilder<WheelBloc, WheelState>(
                  builder:
                      (context, state) => TextButton(
                        onPressed:
                            () => context.read<WheelBloc>().add(
                              ShowModifyEvent(),
                            ),
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
                          builder:
                              (dialogContext) => BlocProvider.value(
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
                      final randomIndex = Random().nextInt(
                        context.read<WheelBloc>().state.options.length,
                      );
                      _streamController.add(randomIndex);
                      setState(() {
                        _isSpinning = true;
                        _selectedIndex = randomIndex;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  // display the result restaurant, data is fetched from the bloc
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
}