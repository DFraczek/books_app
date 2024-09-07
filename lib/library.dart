import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Library extends StatefulWidget {
  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  List<DocumentSnapshot> _shelves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShelves();
  }

  Future<void> _loadShelves() async {
    try {
      final storage = FlutterSecureStorage();
      final userId = await storage.read(key: 'user_id');

      if (userId == null) {
        setState(() {
          _shelves = [];
          _isLoading = false;
        });
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();
      final bookshelvesIds = List<String>.from(userDoc['bookshelves'] ?? []);

      final predefinedShelves = [
        'Przeczytane',
        'Właśnie czytam',
        'Chcę przeczytać'
      ];

      final shelvesQuery = await FirebaseFirestore.instance
          .collection('shelf')
          .where(FieldPath.documentId, whereIn: bookshelvesIds)
          .get();

      final sortedShelves = shelvesQuery.docs
          .where((shelf) => predefinedShelves
              .contains((shelf.data() as Map<String, dynamic>)['name']))
          .toList()
        ..addAll(shelvesQuery.docs.where((shelf) => !predefinedShelves
            .contains((shelf.data() as Map<String, dynamic>)['name'])));

      setState(() {
        _shelves = sortedShelves;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading shelves: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddShelfDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String newShelfName = '';
        String errorMessage = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF9F1E5),
              title: Text('Dodaj nową półkę'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Wpisz nazwę półki',
                      errorText: errorMessage.isNotEmpty ? errorMessage : null,
                    ),
                    onChanged: (value) {
                      newShelfName = value;
                    },
                  ),
                  SizedBox(height: 8),

                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (newShelfName.isEmpty) {
                      setState(() {
                        errorMessage = 'Nazwa nie może być pusta.';
                      });
                      return;
                    }

                    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(newShelfName)) {
                      setState(() {
                        errorMessage = 'Nazwa może składać się tylko z liter.';
                      });
                      return;
                    }

                    final storage = FlutterSecureStorage();
                    final userId = await storage.read(key: 'user_id');

                    if (userId == null) {
                      Navigator.of(context).pop();
                      return;
                    }

                    // Fetch all shelves first
                    final userDoc = await FirebaseFirestore.instance.collection('user').doc(userId).get();
                    final bookshelvesIds = List<String>.from(userDoc['bookshelves'] ?? []);

                    final shelvesQuery = await FirebaseFirestore.instance.collection('shelf').where(FieldPath.documentId, whereIn: bookshelvesIds).get();
                    final existingShelves = shelvesQuery.docs;

                    bool isDuplicate = existingShelves.any((shelf) {
                      return (shelf.data() as Map<String, dynamic>)['name'] == newShelfName;
                    });

                    if (isDuplicate) {
                      setState(() {
                        errorMessage = 'Półka o tej nazwie już istnieje.';
                      });
                      return;
                    }

                    final newShelfRef = FirebaseFirestore.instance.collection('shelf').doc();
                    await newShelfRef.set({
                      'name': newShelfName,
                      'books': [],
                    });

                    await FirebaseFirestore.instance.collection('user').doc(userId).update({
                      'bookshelves': FieldValue.arrayUnion([newShelfRef.id]),
                    });

                    Navigator.of(context).pop();
                    _loadShelves(); //reload shelves
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFF3C729E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Dodaj'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFF3C729E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Anuluj'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.88;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ..._shelves.map((shelf) {
                      final shelfData = shelf.data() as Map<String, dynamic>;
                      return Container(
                        width: containerWidth,
                        height: 85,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: containerWidth,
                                height: 85,
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  shadows: [
                                    BoxShadow(
                                      color: Color(0x3F000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 4),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 32,
                              top: 10,
                              child: Container(
                                width: containerWidth - 64,
                                height: 64,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 74,
                                      top: 12,
                                      child: SizedBox(
                                        width: containerWidth - 148,
                                        height: 33,
                                        child: Text(
                                          shelfData['name'] ?? 'N/A',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            height: 0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 74,
                                      top: 37,
                                      child: SizedBox(
                                        width: 81,
                                        height: 21,
                                        child: Text(
                                          '${(shelfData['books'] as List<dynamic>).length ?? 0} książek',
                                          style: TextStyle(
                                            color: Color(0xFF949494),
                                            fontSize: 10,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            height: 0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: Container(
                                        width: 46,
                                        height: 64,
                                        child: Center(
                                          child: FaIcon(
                                            FontAwesomeIcons.book,
                                            size: 50,
                                            color: Color(0xFF3C729E),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: _showAddShelfDialog,
                      child: Container(
                        width: containerWidth,
                        height: 85,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: containerWidth,
                                height: 85,
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  shadows: [
                                    BoxShadow(
                                      color: Color(0x3F000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 4),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 30,
                              top: 10,
                              child: Container(
                                width: 46,
                                height: 64,
                                child: Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.plus,
                                    size: 50,
                                    color: Color(0xFF3C729E),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 106,
                              top: 31,
                              child: SizedBox(
                                width: containerWidth - 136,
                                height: 33,
                                child: Text(
                                  'Dodaj nową półkę',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    height: 0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
