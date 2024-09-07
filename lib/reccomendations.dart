
import 'package:flutter/material.dart';

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