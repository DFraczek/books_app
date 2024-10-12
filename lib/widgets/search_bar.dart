import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomSearchBar extends StatelessWidget { // Renamed class
  final TextEditingController controller;

  const CustomSearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}
