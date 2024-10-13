import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'icon_map.dart';
import 'book_details.dart';
import 'widgets/background_ovals.dart';

class Shelf extends StatefulWidget {
  final String shelfId;

  const Shelf({Key? key, required this.shelfId}) : super(key: key);

  @override
  _ShelfState createState() => _ShelfState();
}

class _ShelfState extends State<Shelf> {
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;
  String _shelfName = "";
  int _numberOfBooks = 0;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final shelfDoc = await _getShelfDocument(widget.shelfId);

      if (shelfDoc.exists) {
        final books = List<String>.from(shelfDoc['books'] ?? []);
        List<Map<String, dynamic>> bookDetails = [];
        setState(() {
          _numberOfBooks = books.length;
          _shelfName = shelfDoc['name'];
        });

        for (var bookId in books) {
          final bookData = await _getBookData(bookId);
          if (bookData != null) {
            bookDetails.add(bookData);
          }
        }

        setState(() {
          _books = bookDetails;
          _isLoading = false;
        });
      } else {
        print("Shelf does not exist");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading books: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<DocumentSnapshot> _getShelfDocument(String shelfId) async {
    return await FirebaseFirestore.instance
        .collection('shelf')
        .doc(shelfId)
        .get();
  }

  Future<Map<String, dynamic>?> _getBookData(String bookId) async {
    final bookDoc =
        await FirebaseFirestore.instance.collection('book').doc(bookId).get();

    if (bookDoc.exists) {
      final bookTitle = bookDoc['title'];
      final coverImage = bookDoc['coverImage'];
      final description = bookDoc['description'];
      final bookAuthorIds = List<String>.from(bookDoc['author']);
      List<String> authorNames = await _getAuthorNames(bookAuthorIds);

      int rate = await _getUserRatingForBook(bookId);

      return {
        'id': bookId,
        'title': bookTitle,
        'author': authorNames,
        'rate': rate,
        'coverImage': coverImage,
        'description': description,
      };
    }
    return null;
  }

  Future<List<String>> _getAuthorNames(List<String> authorIds) async {
    List<String> authorNames = [];

    for (var authorId in authorIds) {
      final authorDoc = await FirebaseFirestore.instance
          .collection('author')
          .doc(authorId)
          .get();

      if (authorDoc.exists) {
        final authorName = authorDoc['name'];
        final authorSurname = authorDoc['surname'];
        authorNames.add('$authorName $authorSurname');
      }
    }

    return authorNames;
  }

  Future<int> _getUserRatingForBook(String bookId) async {
    final storage = FlutterSecureStorage();
    String? userId = await storage.read(key: 'user_id');

    final reviewQuery = await FirebaseFirestore.instance
        .collection('review')
        .where('book', isEqualTo: bookId)
        .where('user', isEqualTo: userId)
        .get();

    if (reviewQuery.docs.isNotEmpty) {
      final reviewDoc = reviewQuery.docs.first;
      return reviewDoc['rate'] ?? 0;
    }

    return 0;
  }

  Future<void> _updateShelfName(String shelfId, String newName) async {
    try {
      final shelfRef =
          FirebaseFirestore.instance.collection('shelf').doc(shelfId);

      await shelfRef.update({
        'name': newName,
      });

      print("Shelf name updated successfully");
    } catch (e) {
      print("Error updating shelf name: $e");
    }
  }

  Future<void> _updateShelfIcon(String shelfId, String icon, Color color) async {
    try {
      final shelfRef =
      FirebaseFirestore.instance.collection('shelf').doc(shelfId);

      await shelfRef.update({
        'icon': [{'color': '0x${color.value.toRadixString(16).toUpperCase()}', 'name': icon}],
      });

      print("Shelf icon updated successfully");
    } catch (e) {
      print("Error updating shelf icon: $e");
    }
  }

  void _showRenameShelfDialog() {
    TextEditingController _controller = TextEditingController(text: _shelfName);
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                // Calculate available height minus padding for keyboard
                double availableHeight = constraints.maxHeight;
                double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
                double dialogHeight = availableHeight - keyboardHeight;

                return AlertDialog(
                  backgroundColor: const Color(0xFFF9F1E5),
                  title: Text('Zmień nazwę półki'),
                  contentPadding: EdgeInsets.all(16),
                  content: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: dialogHeight * 0.6, // Adjust height ratio as needed
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            autofocus: true,
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Wpisz nazwę półki',
                              errorText: errorMessage.isNotEmpty ? errorMessage : null,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final newShelfName = _controller.text;

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
                                  final userDoc = await FirebaseFirestore.instance
                                      .collection('user')
                                      .doc(userId)
                                      .get();
                                  final bookshelvesIds =
                                  List<String>.from(userDoc['bookshelves'] ?? []);

                                  final shelvesQuery = await FirebaseFirestore.instance
                                      .collection('shelf')
                                      .where(FieldPath.documentId, whereIn: bookshelvesIds)
                                      .get();
                                  final existingShelves = shelvesQuery.docs;

                                  bool isDuplicate = existingShelves.any((shelf) {
                                    return (shelf.data() as Map<String, dynamic>)['name'] ==
                                        newShelfName;
                                  });

                                  if (isDuplicate) {
                                    setState(() {
                                      errorMessage = 'Półka o tej nazwie już istnieje.';
                                    });
                                    return;
                                  }

                                  _updateShelfName(widget.shelfId, newShelfName);

                                  Navigator.of(context).pop();
                                  _loadBooks();
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Color(0xFF3C729E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text('Zmień nazwę'),
                              ),
                              SizedBox(width: 8),
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
      },
    );
  }

  Future<void> _deleteShelf(String shelfId) async {
    try {
      final storage = FlutterSecureStorage();
      String? userId = await storage.read(key: 'user_id');
      final userRef = FirebaseFirestore.instance.collection('user').doc(userId);

      await userRef.update({
        'bookshelves': FieldValue.arrayRemove([widget.shelfId]),
      });
    } catch (e) {
      print("Error removing shelf from user bookshelves: $e");
    }

    try {
      final shelfRef =
          FirebaseFirestore.instance.collection('shelf').doc(shelfId);
      await shelfRef.delete();
    } catch (e) {
      print("Error removing shelf: $e");
    }
  }

  void _showRemoveShelfDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF9F1E5),
              title: Text('Na pewno chcesz usunąć półkę?'),
              actions: [
                TextButton(
                  onPressed: () async {
                    _deleteShelf(widget.shelfId);

                    Navigator.of(context).pop();
                    Navigator.pop(context, true);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFF3C729E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Usuń'),
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

  void _showChangeShelfVisibilityDialog() async {
    final shelfDoc = await FirebaseFirestore.instance
        .collection('shelf')
        .doc(widget.shelfId)
        .get();
    final shelfData = shelfDoc.data();
    final String? currentVisibility = shelfData?['visibility'] ??
        'public'; // Default to 'public' if no value is found

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF9F1E5),
          title: Text('Ustawienia widoczności'),
          content: ChangeVisibilityDialog(
            currentVisibility: currentVisibility,
            onSave: (String newVisibility) async {
              try {
                final shelfRef = FirebaseFirestore.instance
                    .collection('shelf')
                    .doc(widget.shelfId);
                await shelfRef.update({
                  'visibility': newVisibility,
                });
                Navigator.of(context).pop();
              } catch (e) {
                print("Error updating visibility: $e");
              }
            },
          ),
        );
      },
    );
  }

  void _showChangeShelfIconDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        String selectedIconId = 'BNY3UlRkOfWOKvjLgunJ'; // Default icon ID
        Color selectedColor = Color(0xFF3C729E); // Default color

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF9F1E5),
              title: Text(
                'Zmień ikonę półki',
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
                      // Icon selection
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('shelfIcon')
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
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
                                    SizedBox(width: 10),
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
                            hint: Text('Wybierz ikonę'),
                            dropdownColor: Color(0xFFF9F1E5),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      // Color picker
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: Color(0xFFF9F1E5),
                                title: Text('Wybierz kolor'),
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
                                    child: Text(
                                      'Gotowe',
                                      style:
                                      TextStyle(color: Color(0xFF3C729E)),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context, true);
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
                          child: Center(
                            child: Text(
                              'Wybierz kolor półki',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              _updateShelfIcon(widget.shelfId, selectedIconId, selectedColor);
                              Navigator.pop(context, true);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Color(0xFF3C729E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('Zapisz'),
                          ),
                          SizedBox(width: 10),
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2C5473),
      iconTheme: IconThemeData(
        color: Color(0xFFF9F1E5),
      ),
      actions: <Widget>[
        //--------------------------------------------search menu
        PopupMenuButton<int>(
          icon: const FaIcon(FontAwesomeIcons.magnifyingGlass),
          color: Color(0xFFF9F1E5),
          tooltip: 'Szukaj',
          onSelected: (value) {
            switch (value) {
              case 0:
              // Implement search action
                break;
              case 1:
              // 2nd implementation
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<int>(
              value: 0,
              child: Text('Option 1'),
            ),
            PopupMenuItem<int>(
              value: 1,
              child: Text('Option 2'),
            ),
          ],
        ),
        //----------------------------------------------settings menu
        FutureBuilder<DocumentSnapshot>(
          future: _getShelfDocument(widget.shelfId),

          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return SizedBox(); // If there's an error or no data, display nothing
            }

            final shelfName = snapshot.data!['name'];

            final isDefaultShelf = shelfName == "Chcę przeczytać" ||
                shelfName == "Właśnie czytam" ||
                shelfName == "Przeczytane";

            return PopupMenuButton<int>(
              icon: const FaIcon(FontAwesomeIcons.sliders),
              tooltip: 'Ustawienia',
              color: Color(0xFFF9F1E5),
              onSelected: (value) {
                switch (value) {
                  case 0:
                    _showChangeShelfIconDialog();
                    break;
                  case 1:
                    _showChangeShelfVisibilityDialog();
                    break;
                  case 2:
                    _showRenameShelfDialog();
                    break;
                  case 3:
                    _showRemoveShelfDialog();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                List<PopupMenuEntry<int>> items = [
                  PopupMenuItem<int>(
                    value: 0,
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.icons, color: Color(0xFF3C729E)),
                        const SizedBox(width: 10),
                        Text('Zmień ikonę'),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem<int>(
                    value: 1,
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.solidEye, color: Color(0xFF3C729E)),
                        const SizedBox(width: 10),
                        Text('Ustawienia widoczności'),
                      ],
                    ),
                  ),
                ];

                //defaultowe polki mają NIE mieć opcji zmiany nazwy i usunięcia
                if (!isDefaultShelf) {
                  items.addAll([
                    PopupMenuDivider(),
                    PopupMenuItem<int>(
                      value: 2,
                      child: Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.pen, color: Color(0xFF3C729E)),
                          const SizedBox(width: 10),
                          Text('Zmień nazwę'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem<int>(
                      value: 3,
                      child: Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.trash, color: Color(0xFF3C729E)),
                          const SizedBox(width: 10),
                          Text('Usuń półkę'),
                        ],
                      ),
                    ),
                  ]);
                }
                return items;
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1E5),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          BackgroundOvals(),
          Positioned(
            top: 10,
            left: 20,
            right: 20,
            child: Text(
              _shelfName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: 20,
            child: Text(
              'Ilość książek: $_numberOfBooks',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 20,
                shadows: [
                  Shadow(
                    offset: Offset(0.5, 0.5),
                    blurRadius: 2.0,
                    color: Colors.black.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            bottom: 0,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  ..._books.map((book) => BookItem(book: book)).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class BookItem extends StatelessWidget {
  final Map<String, dynamic> book;

  const BookItem({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.88;

    final authorsList = List<String>.from(book['author'] ?? []);
    final containerHeight = 100.0 + ((authorsList.length - 1) * 20.0);

    return GestureDetector(
      onTap: () {
        // Przejście do nowego ekranu po kliknięciu
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetails(book: book),
          ),
        );
      },
      child: Container(
        width: containerWidth,
        height: containerHeight,
        margin: EdgeInsets.symmetric(vertical: 10),
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 75,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: book['coverImage'] != null && book['coverImage'].isNotEmpty
                        ? Image.network(
                      book['coverImage'],
                      fit: BoxFit.cover,
                    )
                        : Icon(
                      FontAwesomeIcons.book,
                      size: 30,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          book['title'] ?? 'N/A',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: (book['title'] != null && book['title'].length > 20) ? 14 : 20,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: authorsList.map((author) {
                            return Text(
                              author,
                              style: TextStyle(
                                color: Color(0xFF949494),
                                fontSize: 16,
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (book['rate'] != 0)
              Positioned(
                right: 8,
                bottom: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    if (index < book['rate']) {
                      return Icon(
                        FontAwesomeIcons.solidStar,
                        size: 20,
                        color: Color(0xFFFFD700),
                      );
                    } else {
                      return Icon(
                        FontAwesomeIcons.star,
                        size: 20,
                        color: Color(0xFFFFD700),
                      );
                    }
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChangeVisibilityDialog extends StatefulWidget {
  final String? currentVisibility;
  final void Function(String) onSave;

  const ChangeVisibilityDialog({
    Key? key,
    required this.currentVisibility,
    required this.onSave,
  }) : super(key: key);

  @override
  _ChangeVisibilityDialogState createState() => _ChangeVisibilityDialogState();
}

class _ChangeVisibilityDialogState extends State<ChangeVisibilityDialog> {
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.currentVisibility;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          contentPadding: EdgeInsets.zero, // Usunięcie domyślnych odstępów
          title: Row(
            children: [
              const FaIcon(
                  FontAwesomeIcons.earthAmericas, color: Color(0xFF3C729E)),
              const SizedBox(width: 10),
              Text('Wszyscy'),
            ],
          ),
          leading: RadioTheme(
            data: RadioThemeData(
              fillColor: MaterialStateProperty.all(
                  Color(0xFF3C729E)), // Kolor zaznaczonego przycisku
            ),
            child: Radio<String>(
              value: 'public',
              groupValue: _selectedOption,
              onChanged: (String? value) {
                setState(() {
                  _selectedOption = value;
                });
              },
            ),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero, // Usunięcie domyślnych odstępów
          title: Row(
            children: [
              const FaIcon(FontAwesomeIcons.lock, color: Color(0xFF3C729E)),
              const SizedBox(width: 10),
              Text('Tylko ja'),
            ],
          ),
          leading: RadioTheme(
            data: RadioThemeData(
              fillColor: MaterialStateProperty.all(
                  Color(0xFF3C729E)), // Kolor zaznaczonego przycisku
            ),
            child: Radio<String>(
              value: 'private',
              groupValue: _selectedOption,
              onChanged: (String? value) {
                setState(() {
                  _selectedOption = value;
                });
              },
            ),
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
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
            SizedBox(width: 8),
            TextButton(
              onPressed: () {
                if (_selectedOption != null) {
                  widget.onSave(_selectedOption!);
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF3C729E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Zapisz'),
            ),
          ],
        ),
      ],
    );
  }

}
