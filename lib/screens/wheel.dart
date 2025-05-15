import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/wheel_bloc.dart';

class WheelOne extends StatelessWidget {
  const WheelOne({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WheelBloc(),
      child: const WheelOneView(),
    );
  }
}

class WheelOneView extends StatelessWidget {
  const WheelOneView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE95322),
        elevation: 0,
        title: const Text(
          'What to eat today?',
          style: TextStyle(
            color: Color(0xFF391713),
            fontSize: 22,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text(
              'Make a turn!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 279,
                height: 279,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(140),
                  border: Border.all(color: const Color(0xFFE95322), width: 4),
                ),
                child: const Center(
                  child: Icon(Icons.casino, size: 120, color: Color(0xFFE95322)),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
                foregroundColor: const Color(0xFF391713),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              onPressed: () => context.read<WheelBloc>().add(ShowResultEvent()),
              child: const Text(
                'GO!',
                style: TextStyle(
                  fontSize: 17,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.09,
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
                                      child: TextFormField(
                                        initialValue: state.options[i].name,
                                        style: const TextStyle(
                                          color: Color(0xFF391713),
                                          fontSize: 16,
                                          fontFamily: 'Roboto',
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        onChanged: (val) {
                                          context.read<WheelBloc>().add(UpdateOptionEvent(i, val));
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFE95322)),
                                    onPressed: () => context.read<WheelBloc>().add(RemoveOptionEvent(i)),
                                  ),
                                ],
                              ),
                            )),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE95322),
                                side: const BorderSide(color: Color(0xFFE95322)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => context.read<WheelBloc>().add(AddOptionEvent()),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Option'),
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
                if (state.showResult) {
                  return Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF3E0),
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
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Color(0xFFE0E0E0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(Icons.map, size: 60, color: Color(0xFF79747E)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: const SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Icon(Icons.image, size: 40, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Golden Dragon',
                                        style: const TextStyle(
                                          color: Color(0xFF391713),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '¥88',
                                        style: const TextStyle(
                                          color: Color(0xFFFA4A0C),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Locally owned restaurant serving up a variety of traditional Chinese ...',
                              style: TextStyle(
                                color: Color(0xFF79747E),
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE95322),
        unselectedItemColor: const Color(0xFF391713),
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) {
            GoRouter.of(context).go('/lists');
          } else if (i == 1) {
            GoRouter.of(context).go('/wheel');
          } else if (i == 2) {
            GoRouter.of(context).go('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}