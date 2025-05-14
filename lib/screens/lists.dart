import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Lists extends StatelessWidget {
  const Lists({Key? key}) : super(key: key);

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
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 24,
              child: Icon(Icons.person, color: Color(0xFFE95322)),
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF391713)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        itemCount: 6,
        itemBuilder: (context, index) => _RestaurantCard(),
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
  const _RestaurantCard({Key? key}) : super(key: key);

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
              child: Image.network(
                'https://placehold.co/93x93',
                width: 93,
                height: 93,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Restaurant Name',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Text(
                        '4.3',
                        style: TextStyle(
                          color: Color(0xFF79747E),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.star, color: Color(0xFFFFA500), size: 16),
                      const SizedBox(width: 5),
                      const Text(
                        '(305)',
                        style: TextStyle(
                          color: Color(0xFF79747E),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Locally owned restaurant serving up a variety of traditional Chinese ...',
                    style: TextStyle(
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
                  icon: const Icon(Icons.favorite_border, color: Color(0xFFE95322)),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF391713)),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}