import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'shelf.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'icon_map.dart';

class Library extends StatefulWidget {
  const Library({super.key});

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
      final storage = const FlutterSecureStorage();
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
              .contains((shelf.data())['name']))
          .toList()
        ..addAll(shelvesQuery.docs.where((shelf) => !predefinedShelves
            .contains((shelf.data())['name'])));

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
        String selectedIconId = 'BNY3UlRkOfWOKvjLgunJ'; // Default icon ID
        Color selectedColor = const Color(0xFF3C729E); // Default color

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF9F1E5),
              title: const Text(
                'Dodaj nową półkę',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Wpisz nazwę półki',
                          errorText:
                          errorMessage.isNotEmpty ? errorMessage : null,
                        ),
                        onChanged: (value) {
                          newShelfName = value;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Icon selection
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('shelfIcon')
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final icons = snapshot.data!.docs;
                          return DropdownButton<String>(
                            value: selectedIconId,
                            items: icons.map((icon) {
                              final iconName = icon['name'];
                              final iconData =
                                  iconMap[iconName] ?? FontAwesomeIcons.book;
                              return DropdownMenuItem<String>(
                                value: icon.id,
                                child: Row(
                                  children: [
                                    FaIcon(iconData),
                                    const SizedBox(width: 10),
                                    Text(iconName),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedIconId = value!;
                              });
                            },
                            hint: const Text('Wybierz ikonę'),
                            dropdownColor: const Color(0xFFF9F1E5),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Color picker
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFFF9F1E5),
                                title: const Text('Wybierz kolor'),
                                content: SingleChildScrollView(
                                  child: ColorPicker(
                                    pickerColor: selectedColor,
                                    onColorChanged: (color) {
                                      setState(() {
                                        selectedColor = color;
                                      });
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text(
                                      'Gotowe',
                                      style:
                                      TextStyle(color: Color(0xFF3C729E)),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          color: selectedColor,
                          child: const Center(
                            child: Text(
                              'Wybierz kolor półki',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
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
                                  errorMessage =
                                  'Nazwa może składać się tylko z liter.';
                                });
                                return;
                              }

                              const storage = FlutterSecureStorage();
                              final userId = await storage.read(key: 'user_id');

                              if (userId == null) {
                                Navigator.of(context).pop();
                                return;
                              }

                              // Fetch all shelves first
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('user')
                                  .doc(userId)
                                  .get();
                              final bookshelvesIds = List<String>.from(
                                  userDoc['bookshelves'] ?? []);

                              final shelvesQuery = await FirebaseFirestore
                                  .instance
                                  .collection('shelf')
                                  .where(FieldPath.documentId,
                                  whereIn: bookshelvesIds)
                                  .get();
                              final existingShelves = shelvesQuery.docs;

                              bool isDuplicate = existingShelves.any((shelf) {
                                return (shelf.data())['name'] ==
                                    newShelfName;
                              });

                              if (isDuplicate) {
                                setState(() {
                                  errorMessage =
                                  'Półka o tej nazwie już istnieje.';
                                });
                                return;
                              }

                              final newShelfRef = FirebaseFirestore.instance
                                  .collection('shelf')
                                  .doc();
                              await newShelfRef.set({
                                'name': newShelfName,
                                'books': [],
                                'visibility': 'public',
                                'icon': [
                                  {
                                    'name': selectedIconId,
                                    'color':
                                    '0x${selectedColor.value.toRadixString(16).toUpperCase()}'
                                  },
                                ],
                              });

                              await FirebaseFirestore.instance
                                  .collection('user')
                                  .doc(userId)
                                  .update({
                                'bookshelves':
                                FieldValue.arrayUnion([newShelfRef.id]),
                              });

                              Navigator.of(context).pop();
                              _loadShelves(); // reload shelves
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF3C729E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Dodaj'),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF3C729E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Anuluj'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  Future<String> _getIconNameFromId(String iconId) async {
    final iconDoc = await FirebaseFirestore.instance
        .collection('shelfIcon')
        .doc(iconId)
        .get();
    if (iconDoc.exists) {
      return iconDoc.data()?['name'] ?? 'book';
    } else {
      throw Exception('Icon not found');
    }
  }

  //map to faicon
  Future<IconData> _getIconData(String iconId) async {
    try {
      final iconName = await _getIconNameFromId(iconId);
      return iconMap[iconName] ?? FontAwesomeIcons.book;
    } catch (e) {
      print('Error getting icon data: $e');
      return FontAwesomeIcons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.88;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ..._shelves.map((shelf) {
                      final shelfData = shelf.data() as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Shelf(shelfId: shelf.id),
                            ),
                          );
                          _loadShelves();

                        },
                        child: Container(
                          width: containerWidth,
                          height: 85,
                          margin: const EdgeInsets.symmetric(vertical: 10),
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
                                    shadows: const [
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
                                child: SizedBox(
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
                                            style: const TextStyle(
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
                                            '${(shelfData['books'] as List<dynamic>).length} książek',
                                            style: const TextStyle(
                                              color: Color(0xFF949494),
                                              fontSize: 10,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                              height: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      //-----------------------------------------------
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: FutureBuilder<IconData>(
                                          future: _getIconData(
                                              shelfData['icon'][0]['name']),
                                          builder: (context, snapshot) {
                                            final iconData = snapshot.data ??
                                                FontAwesomeIcons.book;
                                            return SizedBox(
                                              width: 46,
                                              height: 64,
                                              child: Center(
                                                child: FaIcon(
                                                  iconData,
                                                  size: 50,
                                                  color: Color(
                                                    int.parse(
                                                      (shelfData['icon'][0]
                                                                  ['color']
                                                              as String)
                                                          .replaceFirst(
                                                              '0x', ''),
                                                      radix: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _showAddShelfDialog,
                      child: SizedBox(
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
                                  shadows: const [
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
                              child: SizedBox(
                                width: 46,
                                height: 64,
                                child: const Center(
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
                                child: const Text(
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
