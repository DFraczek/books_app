import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  CustomBottomNavigationBarState createState() => CustomBottomNavigationBarState();
}

class CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Calculate the left offset for the blue circle
    final double itemWidth = screenWidth / 4; // Assuming 4 items
    final double leftOffset = itemWidth * widget.selectedIndex + (itemWidth - 60) / 2;

    return Container(
      width: screenWidth,
      height: 70,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // Animated blue circle
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            left: leftOffset,
            width: 60,
            height: 60,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF3C729E),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: FontAwesomeIcons.house,
                  index: 0,
                  isSelected: widget.selectedIndex == 0,
                  onTap: () => widget.onTap(0),
                ),
                _buildNavItem(
                  icon: FontAwesomeIcons.bookOpen,
                  index: 1,
                  isSelected: widget.selectedIndex == 1,
                  onTap: () => widget.onTap(1),
                ),
                _buildNavItem(
                  icon: FontAwesomeIcons.chartSimple,
                  index: 2,
                  isSelected: widget.selectedIndex == 2,
                  onTap: () => widget.onTap(2),
                ),
                _buildNavItem(
                  icon: FontAwesomeIcons.solidUser,
                  index: 3,
                  isSelected: widget.selectedIndex == 3,
                  onTap: () => widget.onTap(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required bool isSelected,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.grey,
      ),
    );
  }
}
