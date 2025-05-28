import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../blocs/wheel_bloc.dart';
import '../widgets/dialogs/result_dialog.dart';
import '../widgets/dialogs/map_popup.dart';
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
  int? _selectedIndex;
  late StreamController<int> _streamController;
  bool _isSpinning = false;

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
        // 获取 Bloc 最新 options
        final options = context.read<WheelBloc>().state.options;
        final selectedOption = options[_selectedIndex!];
        context.read<WheelBloc>().add(FetchRestaurantEvent(selectedOption.keyword));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // final wheelBloc = context.read<WheelBloc>();
    // 打印菜系数据
    // print('Cuisines: ${wheelBloc.cuisines.map((c) => c.name).toList()}');
  
    final bloc = context.read<WheelBloc>();
    final apiKey = bloc.apiKey;

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
                  child: state.options.length > 1
                      ? FortuneWheel(
                          selected: _streamController.stream,
                          animateFirst: false,
                          onAnimationEnd: _onWheelStop,
                          indicators: <FortuneIndicator>[
                            FortuneIndicator(
                              alignment: Alignment.topCenter,
                              child: Icon(Icons.arrow_drop_down, size: 48, color: Color(0xFFE95322)), // 你可以换成任意 Widget
                            ),
                          ],
                          items: [
                            for (var option in state.options)
                              FortuneItem(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    option.keyword.isEmpty
                                      ? const Icon(Icons.image, size: 40, color: Colors.grey)
                                      : Image.asset(
                                          'assets/cuisines_images/${option.keyword}.png',
                                          width: 40,
                                          height: 40,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.food_bank, size: 40, color: Colors.grey),
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
                const SizedBox(height: 40),
                BlocBuilder<WheelBloc, WheelState>(
                  builder: (context, state) {
                    final bool hasEnoughOptions = state.options.length >= 2;
                    return Column(
                      children: [
                        if (!hasEnoughOptions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Please add at least 2 options to spin the wheel',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        if (!state.showResult)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasEnoughOptions ? const Color(0xFFFFA500) : Colors.grey,
                              foregroundColor: const Color(0xFF391713),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            onPressed: hasEnoughOptions ? () async {
                              final randomIndex = Random().nextInt(context.read<WheelBloc>().state.options.length);
                              _streamController.add(randomIndex);
                              setState(() {
                                _isSpinning = true;
                                _selectedIndex = randomIndex;
                              });
                            } : null,
                            child: const Text(
                              'GO!',
                              style: TextStyle(
                                fontSize: 17,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.09,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [],
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
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
                      return Column(
                        children: [
                          const SizedBox(height: 24),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
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
                                      onPressed: () => context.read<WheelBloc>().add(CloseModifyEvent()),
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
                                        onPressed: state.options.length > 2 
                                          ? () => context.read<WheelBloc>().add(RemoveOptionEvent(i))
                                          : null,
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFE95322),
                                        side: const BorderSide(color: Color(0xFFE95322)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        context.read<WheelBloc>().add(CloseModifyEvent());
                                      },
                                      child: const Text('Close'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 40),
                if (state.selectedRestaurant != null) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500),
                      foregroundColor: const Color(0xFF391713),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (dialogContext) => MapPopup(
                          onAppleMapSelected: () {
                            // 处理 Apple Map 选择
                            print('Apple Map selected');
                          },
                          onGoogleMapSelected: () {
                            // 处理 Google Map 选择
                            print('Google Map selected');
                          },
                        ),
                      );
                    },
                    child: const Text(
                      "Let's Go!",
                      style: TextStyle(
                        fontSize: 17,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.09,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF391713),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: const BorderSide(color: Color(0xFFFFA500)),
                      ),
                    ),
                    onPressed: () async {
                      final randomIndex = Random().nextInt(context.read<WheelBloc>().state.options.length);
                      _streamController.add(randomIndex);
                      setState(() {
                        _isSpinning = true;
                        _selectedIndex = randomIndex;
                      });
                    },
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 17,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.09,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 120,
                          width: 400,
                          child: Center(
                            child: Image.network(
                              'https://maps.googleapis.com/maps/api/staticmap'
                              '?center=${state.selectedRestaurant!.lat},${state.selectedRestaurant!.lng}'
                              '&zoom=15'
                              '&size=400x200'
                              '&maptype=roadmap'
                              '&markers=color:red%7C${state.selectedRestaurant!.lat},${state.selectedRestaurant!.lng}'
                              '&key=$apiKey',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                state.selectedRestaurant!.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.selectedRestaurant!.name,
                                    style: const TextStyle(
                                      color: Color(0xFF391713),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Cuisine: ${state.selectedRestaurant!.cuisine}',
                                    style: const TextStyle(
                                      color: Color(0xFF391713),
                                      fontSize: 16,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  Text(
                                    'Rating: ${state.selectedRestaurant!.rating}',
                                    style: const TextStyle(
                                      color: Color(0xFF391713),
                                      fontSize: 16,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Address: ${state.selectedRestaurant!.address}',
                          style: const TextStyle(
                            color: Color(0xFF79747E),
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
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