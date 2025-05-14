import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PreferenceChooseScreen extends StatefulWidget {
  const PreferenceChooseScreen({Key? key}) : super(key: key);

  @override
  State<PreferenceChooseScreen> createState() => _PreferenceChooseScreenState();
}

class _PreferenceChooseScreenState extends State<PreferenceChooseScreen> {
  String flag = 'like';

  void _onContinue() {
    if (flag == 'like') {
      setState(() {
        flag = 'dislike';
      });
    } else {
      // dislike设置完成，进入wheel
      GoRouter.of(context).go('/wheel');
    }
  }

  void _onSkip() {
    GoRouter.of(context).go('/wheel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _onSkip,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Color(0xFF386BF6),
                fontSize: 15,
                fontStyle: FontStyle.italic,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text(
                flag == 'like' ? 'What do you like?' : 'What do you dislike?',
                style: const TextStyle(
                  color: Color(0xFFE95322),
                  fontSize: 24,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
                children: [
                  _FoodCard(
                    imageUrl: 'https://placehold.co/217x144',
                    title: 'Fried chicken m.',
                    price: 'N1,900',
                  ),
                  _FoodCard(
                    imageUrl: 'https://placehold.co/217x144',
                    title: 'Veggie tomato mix',
                    price: 'N1,900',
                  ),
                  _FoodCard(
                    imageUrl: 'https://placehold.co/217x144',
                    title: 'Moi-moi and ekpa.',
                    price: 'N1,900',
                  ),
                  _FoodCard(
                    imageUrl: 'https://placehold.co/217x144',
                    title: 'Egg and cucumber...',
                    price: 'N1,900',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  foregroundColor: const Color(0xFFF5F5F5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF2C2C2C)),
                  ),
                ),
                onPressed: _onContinue,
                child: Text(flag == 'like' ? 'Continue' : 'Finish'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;

  const _FoodCard({
    required this.imageUrl,
    required this.title,
    required this.price,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const SizedBox(
                width: 100,
                height: 80,
                child: Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'SF Pro Rounded',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(
                color: Color(0xFFFA4A0C),
                fontSize: 16,
                fontFamily: 'SF Pro Rounded',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}