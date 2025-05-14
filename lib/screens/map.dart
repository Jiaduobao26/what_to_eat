import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 300,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://placehold.co/400x393'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: const [
                _RestaurantCard(
                  name: 'Roxie Food Center',
                  imageUrl: 'https://placehold.co/93x93',
                ),
                _RestaurantCard(
                  name: 'Excelsior Coffee',
                  imageUrl: 'https://placehold.co/93x93',
                ),
                _RestaurantCard(
                  name: 'Taqueria Guadalajara',
                  imageUrl: 'https://placehold.co/93x93',
                ),
                _RestaurantCard(
                  name: 'Restaurant Name',
                  imageUrl: 'https://placehold.co/93x93',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final String name;
  final String imageUrl;

  const _RestaurantCard({
    required this.name,
    required this.imageUrl,
    Key? key,
  }) : super(key: key);

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
                imageUrl,
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
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: const [
                      Text(
                        '4.3',
                        style: TextStyle(
                          color: Color(0xFF79747E),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.star, color: Color(0xFFFFA500), size: 16),
                      SizedBox(width: 5),
                      Text(
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