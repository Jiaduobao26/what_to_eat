import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/restaurant_list_bloc.dart';
import '../widgets/dialogs/map_popup.dart';
import '../widgets/dialogs/list_dialog.dart';

class Lists extends StatelessWidget {
  const Lists({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RestaurantListBloc(),
      child: const ListsView(),
    );
  }
}

class ListsView extends StatelessWidget {
  const ListsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE95322),
        elevation: 0,
        title: const Text(
          'Recommendation',
          style: TextStyle(
            color: Color(0xFF391713),
            fontSize: 22,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.map, color: Color(0xFF391713)), 
              onPressed: () {
                GoRouter.of(context).go('/map');
              },
            ),
          ),
        ],
      ),
      body: BlocBuilder<RestaurantListBloc, RestaurantListState>(
        builder: (context, state) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          itemCount: state.restaurants.length,
          itemBuilder: (context, index) => _RestaurantCard(info: state.restaurants[index]),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFFA500),
        unselectedItemColor: const Color(0xFF391713),
        currentIndex: 0,
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
            icon: Icon(Icons.home, color: Color(0xFFE95322)),
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

class _RestaurantCard extends StatelessWidget {
  final RestaurantInfo info;
  const _RestaurantCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const SizedBox(
                width: 93,
                height: 93,
                child: Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        info.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFF79747E),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.star, color: Color(0xFFFFA500), size: 16),
                      const SizedBox(width: 5),
                      Text(
                        '(${info.reviews})',
                        style: const TextStyle(
                          color: Color(0xFF79747E),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    info.description,
                    style: const TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 12,
                      fontFamily: 'Roboto',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Transform.rotate(
                    angle: 1.5708, // 90 degrees in radians
                    child: const Icon(Icons.navigation, color: Color(0xFFE95322)),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => MapPopup(
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
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF391713)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ListDialog(
                        onDislikeRestaurant: () {
                          // TODO: 处理不喜欢餐厅
                          print('Dislike restaurant');
                        },
                        onDislikeCuisine: () {
                          // TODO: 处理不喜欢菜系
                          print('Dislike cuisine');
                        },
                        onCancel: () {
                          print('Cancel');
                        },
                        onConfirm: () {
                          print('Confirm');
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}