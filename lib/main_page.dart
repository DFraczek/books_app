import 'package:flutter/material.dart';
import 'reccomendations.dart';
import 'widgets/bottomNavBar.dart';
import 'widgets/background_ovals.dart';
import 'widgets/search_bar.dart';
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
      body: GestureDetector( // Wrap the Stack with GestureDetector
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard
        },
        child: Stack(
          children: [
            BackgroundOvals(),
            Positioned(
              left: 0,
              right: 0,
              top: 60,
              child: CustomSearchBar(controller: _searchBarController),
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
      ),
    );
  }
}
