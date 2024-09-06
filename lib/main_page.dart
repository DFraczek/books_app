import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _searchBarController = TextEditingController();
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Recommendations(),
    Center(child: Text('Library Page')),
    Center(child: Text('Stats Page')),
    Center(child: Text('Profile Page')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1E5),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          BackgroundOvals(),
          Positioned(
            left: 0,
            right: 0,
            top: 60,
            child: SearchBar(controller: _searchBarController),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 140,
            bottom: 80,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: _pages,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -10,
            child: CustomBottomNavigationBar(
              selectedIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}

class BackgroundOvals extends StatelessWidget {
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
            decoration: const ShapeDecoration(
              color: Color(0xFF528BB9),
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
            decoration: const ShapeDecoration(
              color: Color(0xFF3C729E),
              shape: OvalBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Material(
          elevation: 4, // Shadow
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Wyszukaj książkę lub autora',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass,
                  color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}

class Recommendations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: screenWidth,
            height: 60,
            child: Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: (screenWidth - 230) / 2,
                    height: 1,
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Polecamy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 0,
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: (screenWidth - 230) / 2,
                    height: 1,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          // Book List
          Container(
            width: screenWidth,
            height: 160,
            child: Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Left book
                  Container(
                    width: 90,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  // Middle book
                  Container(
                    width: 130,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  // Right book
                  Container(
                    width: 90,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            height: 10,
            child: Center(
              child: Text(
                'Autor',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w300,
                  height: 0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 5),
          SizedBox(
            height: 15,
            child: Center(
              child: Text(
                'Tytuł książki',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w300,
                  height: 0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      )
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      height: 70,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: FontAwesomeIcons.house,
            index: 0,
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _buildNavItem(
            icon: FontAwesomeIcons.bookOpen,
            index: 1,
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          _buildNavItem(
            icon: FontAwesomeIcons.chartSimple,
            index: 2,
            isSelected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          _buildNavItem(
            icon: FontAwesomeIcons.solidUser,
            index: 3,
            isSelected: selectedIndex == 3,
            onTap: () => onTap(3),
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
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF3C729E),
        )
            : null,
        padding: const EdgeInsets.all(12.0),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}
