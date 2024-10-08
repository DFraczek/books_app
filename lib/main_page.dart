import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'reccomendations.dart';
import 'bottomNavBar.dart';
import 'library.dart';
import 'profile.dart';

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
    Library(),
    Center(child: Text('Stats Page')),
    Profile(),
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
