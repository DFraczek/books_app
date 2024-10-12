import 'package:flutter/cupertino.dart';

class BackgroundOvals extends StatelessWidget {
  const BackgroundOvals({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 145,
          top: -107,
          child: Container(
            width: 459,
            height: 457,
            decoration: ShapeDecoration(
              color: const Color(0xFF528BB9),
              shape: OvalBorder(),
            ),
          ),
        ),
        Positioned(
          left: -345,
          top: -282,
          child: Container(
            width: 712,
            height: 566,
            decoration: ShapeDecoration(
              color: const Color(0xFF3C729E),
              shape: OvalBorder(),
            ),
          ),
        ),
      ],
    );
  }
}