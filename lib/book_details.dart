import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/background_ovals.dart';

class BookDetails extends StatelessWidget {
  final Map<String, dynamic> book;

  const BookDetails({super.key, required this.book});
  final storage = const FlutterSecureStorage();

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2C5473),
      iconTheme: const IconThemeData(
        color: Color(0xFFF9F1E5),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchReviews(String bookId) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('review')
        .where('book', isEqualTo: bookId)
        .get();

    double totalRating = 0.0;
    int count = snapshot.docs.length;

    for (var doc in snapshot.docs) {
      totalRating += (doc['rate'] as int).toDouble();
    }

    double averageRating = count > 0 ? totalRating / count : 0.0;

    return {
      'averageRating': averageRating,
      'count': count,
    };
  }

  Future<List<String>> _fetchShelfNamesWithBook(String bookId) async {
    String? userId = await storage.read(key: 'user_id');
    if (userId == null) {
      return [];
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('user').doc(userId).get();

    List<dynamic> bookshelves = userDoc['bookshelves'] ?? [];
    //szukanie półek na których jest dana książka
    List<String> shelfNames = [];
    for (String shelfId in bookshelves) {
      DocumentSnapshot shelfDoc = await FirebaseFirestore.instance.collection('shelf').doc(shelfId).get();
      List<dynamic> books = shelfDoc['books'] ?? [];
      if (books.contains(bookId)) {
        shelfNames.add(shelfDoc['name']);
      }
    }
    return shelfNames;
  }

  Future<List<Map<String, dynamic>>> _fetchBookReviews(String bookId) async {
    String? userId = await storage.read(key: 'user_id');
    if (userId == null) {
      return [];
    }
    QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
        .collection('review')
        .where('user', isEqualTo: userId)
        .where('book', isEqualTo: bookId)
        .get();

    List<Map<String, dynamic>> reviews = reviewSnapshot.docs.map((doc) {
      return {
        'rate': doc['rate'],
        'text': doc['text'],
      };
    }).toList();

    return reviews;
  }


  @override
  Widget build(BuildContext context) {
    final String title = book['title'] ?? 'Brak tytułu';
    final String author = (book['author'] as List<dynamic>).join(', ');
    final String? coverImage = book['coverImage'];
    final String bookId = book['id'];
    final String description = book['description'];
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.88;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F1E5),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          const BackgroundOvals(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: containerWidth,
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        coverImage != null && coverImage.isNotEmpty
                            ? Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.network(
                            coverImage,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 180,
                          ),
                        )
                            : Icon(
                          FontAwesomeIcons.book,
                          size: 50,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          author,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _fetchReviews(bookId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Błąd: ${snapshot.error}');
                            } else if (!snapshot.hasData || snapshot.data!['count'] == 0) {
                              return const Text('Brak ocen książki');
                            } else {
                              final double averageRating = snapshot.data!['averageRating'];
                              final int count = snapshot.data!['count'];

                              // Count full and half stars
                              int fullStars = 0;
                              bool halfStar = false;

                              if (averageRating < 0.25) {
                                fullStars = 0;
                                halfStar = false;
                              } else if (averageRating < 0.75) {
                                fullStars = 0;
                                halfStar = true;
                              } else if (averageRating < 1.25) {
                                fullStars = 1;
                                halfStar = false;
                              } else if (averageRating < 1.75) {
                                fullStars = 1;
                                halfStar = true;
                              } else if (averageRating < 2.25) {
                                fullStars = 2;
                                halfStar = false;
                              } else if (averageRating < 2.75) {
                                fullStars = 2;
                                halfStar = true;
                              } else if (averageRating < 3.25) {
                                fullStars = 3;
                                halfStar = false;
                              } else if (averageRating < 3.75) {
                                fullStars = 3;
                                halfStar = true;
                              } else if (averageRating < 4.25) {
                                fullStars = 4;
                                halfStar = false;
                              } else if (averageRating < 4.75) {
                                fullStars = 4;
                                halfStar = true;
                              } else {
                                fullStars = 5;
                                halfStar = false;
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ...List.generate(5, (index) {
                                    if (index < fullStars) {
                                      return const Icon(
                                        FontAwesomeIcons.solidStar,
                                        size: 20,
                                        color: Color(0xFFFFD700),
                                      );
                                    } else if (index == fullStars && halfStar) {
                                      return const Icon(
                                        FontAwesomeIcons.starHalf,
                                        size: 20,
                                        color: Color(0xFFFFD700),
                                      );
                                    } else {
                                      return const Icon(
                                        FontAwesomeIcons.star,
                                        size: 20,
                                        color: Color(0xFFFFD700),
                                      );
                                    }
                                  }),
                                  const SizedBox(width: 10), // Space between stars and rating text
                                  Text(
                                    '${averageRating.toStringAsFixed(1)}, Ilość ocen: $count',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center( //---------------------------------------------------------------------------------------------- description section
                  child: Container(
                    width: containerWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Opis książki',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3C729E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center( //--------------------------------------------------------------------------------------shelves section
                  child:  FutureBuilder<List<String>>(
                    future: _fetchShelfNamesWithBook(bookId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Błąd: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) { //jeżeli książka nie jest dodana na żadną półkę użytkownika
                        return Center( // Center the container within its parent
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Add book to shelf implementation
                            },
                            child: Container(
                              width: containerWidth,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Dodaj książkę na półkę',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Icon(
                                      FontAwesomeIcons.chevronRight,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                      } else { // gdy książka jest dodana na jakąś półkę użytkownika
                        return GestureDetector(
                          onTap: () {
                            // TODO: Remove book from shelf/change shelf implementation
                          },
                          child: Container(
                            width: containerWidth,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min, // Allow height to adjust based on content
                                children: [
                                  const Center(
                                    child: Text(
                                      'Na półce:',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3C729E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: snapshot.data!.map<Widget>((shelfName) {
                                            return Text(
                                              shelfName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      const SizedBox(width: 10), // Spacing between text and icon
                                      const Icon(
                                        FontAwesomeIcons.pen,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  // -----------------------------------------------------------------------rate section
                  child: Container(
                    width: containerWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _fetchBookReviews(bookId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Błąd: ${snapshot.error}');
                                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      // If the user has not rated the book
                                      return GestureDetector(
                                        onTap: () {
                                          // TODO: Add rate implementation
                                        },
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Oceń książkę',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Icon(
                                              FontAwesomeIcons.chevronRight,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      // If the user has rated the book
                                      Map<String, dynamic> review = snapshot.data!.first;
                                      int rate = review['rate'];
                                      List<Widget> stars = List.generate(5, (index) {
                                        return Icon(
                                          index < rate ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
                                          color: Colors.yellow,
                                        );
                                      });

                                      return GestureDetector(
                                        onTap: () {
                                          // TODO: Add change/delete rate function
                                        },
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Moja ocena: ',
                                                        style: TextStyle(
                                                          color: Color(0xFF3C729E),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Row(
                                                        children: stars,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10), // Spacing between text/stars and icon
                                            const Icon(
                                              FontAwesomeIcons.pen,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      );
                                    }},),],
                            ),
                          ),],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center( //---------------------------------------------------------------------------------------------- review section
                  child: Container(
                    width: containerWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _fetchBookReviews(bookId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Błąd: ${snapshot.error}'));
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) { // If there are no reviews
                                  return GestureDetector(
                                    onTap: () {
                                      // TODO: Add rate implementation
                                    },
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Napisz recenzję',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Icon(
                                          FontAwesomeIcons.chevronRight,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  String reviewText = snapshot.data!.first['text'];
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Center(
                                        child: Text(
                                          'Moja recenzja',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3C729E),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                        child: Text(
                                          reviewText,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              // TODO: Add edit review functionality
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3C729E),
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    FontAwesomeIcons.pen,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 7),
                                                  Text(
                                                    'Edytuj',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          GestureDetector(
                                            onTap: () {
                                              // TODO: Add delete review functionality
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3C729E),
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    FontAwesomeIcons.trash,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 7),
                                                  Text(
                                                    'Usuń',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center( //---------------------------------------------------------------------------------------------- show all reviews
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Add functionality to show all reviews
                    },
                    child: Container(
                      width: containerWidth,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3C729E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Zobacz wszystkie recenzje',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Icon(
                              FontAwesomeIcons.chevronRight,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

