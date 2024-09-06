import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _searchBarController = TextEditingController();

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
            bottom: 0,
            child: SingleChildScrollView( // Allow scrolling
              child: Recommendations(),
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
              prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, color: Colors.grey),
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

    return Column(
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
                // --------------------------------------------------- Left line
                Container(
                  width: (screenWidth - 230) / 2,
                  height: 1,
                  color: Colors.white,
                ),
                SizedBox(width: 10),
                // Space between the line and text
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
                // Space between the line and text
                //--------------------------------------------------- Right line
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

        Container(
          width: screenWidth,
          height: 160,
          child: Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --------------------------------------------------- Left book
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
                // Space between books
                // --------------------------------------------------- Middle book
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
                // Space between books
                //--------------------------------------------------- Right book
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

        SizedBox(height: 30), // Space between books and text

        // ------------------------------------------------- Author text
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
        SizedBox(height: 5), // Space between author and title
        // -------------------------------------------------- Title text
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
    );
  }
}
