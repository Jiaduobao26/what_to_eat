import 'package:flutter/material.dart';

class DiceFace extends StatelessWidget {
  final int number;
  const DiceFace(this.number, {super.key});

  @override
  Widget build(BuildContext context) {
    final dots = <Widget>[];

    switch (number) {
      case 1:
        dots.add(const Positioned(
          top: 45, left: 45,
          child: DiceDot(),
        ));
        break;
      case 2:
        dots.addAll([
          const Positioned(top: 20, left: 20, child: DiceDot()),
          const Positioned(bottom: 20, right: 20, child: DiceDot()),
        ]);
        break;
      case 3:
        dots.addAll([
          const Positioned(top: 15, left: 15, child: DiceDot()),
          const Positioned(top: 45, left: 45, child: DiceDot()),
          const Positioned(bottom: 15, right: 15, child: DiceDot()),
        ]);
        break;
      case 4:
        dots.addAll([
          const Positioned(top: 20, left: 20, child: DiceDot()),
          const Positioned(top: 20, right: 20, child: DiceDot()),
          const Positioned(bottom: 20, left: 20, child: DiceDot()),
          const Positioned(bottom: 20, right: 20, child: DiceDot()),
        ]);
        break;
      case 5:
        dots.addAll([
          const Positioned(top: 15, left: 15, child: DiceDot()),
          const Positioned(top: 15, right: 15, child: DiceDot()),
          const Positioned(top: 45, left: 45, child: DiceDot()),
          const Positioned(bottom: 15, left: 15, child: DiceDot()),
          const Positioned(bottom: 15, right: 15, child: DiceDot()),
        ]);
        break;
      case 6:
        dots.addAll([
          const Positioned(top: 15, left: 20, child: DiceDot()),
          const Positioned(top: 15, right: 20, child: DiceDot()),
          const Positioned(top: 45, left: 20, child: DiceDot()),
          const Positioned(top: 45, right: 20, child: DiceDot()),
          const Positioned(bottom: 15, left: 20, child: DiceDot()),
          const Positioned(bottom: 15, right: 20, child: DiceDot()),
        ]);
        break;
    }

    return Stack(children: dots);
  }
}

class DiceDot extends StatelessWidget {
  const DiceDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Color(0xFFE95322),
        shape: BoxShape.circle,
      ),
    );
  }
}