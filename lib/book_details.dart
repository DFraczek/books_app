import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/background_ovals.dart';
import 'package:intl/intl.dart';
import 'add_book_to_shelf_page.dart';

class BookDetails extends StatelessWidget {
  final String bookId;
  const BookDetails({super.key, required this.bookId});
  final storage = const FlutterSecureStorage();

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2C5473),
      iconTheme: const IconThemeData(
        color: Color(0xFFF9F1E5),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getBookData(String bookId) async {
    final bookDoc =
        await FirebaseFirestore.instance.collection('book').doc(bookId).get();

    if (bookDoc.exists) {
      final bookTitle = bookDoc['title'];
      final coverImage = bookDoc['coverImage'];
      final description = bookDoc['description'];

      final Timestamp publicationTimestamp = bookDoc['publicationDate'];
      // Format the date as dd.MM.yyyy
      final String publicationDate =
          DateFormat('dd.MM.yyyy').format(publicationTimestamp.toDate());

      final bookAuthorIds = List<String>.from(bookDoc['author']);
      List<String> authorNames = await _getAuthorNames(bookAuthorIds);
      final bookGenreIds = List<String>.from(bookDoc['genre']);
      List<String> genreNames = await _getGenres(bookGenreIds);
      final bookPublisherId = bookDoc['publisher'];
      String publisherName = await _getPublisherName(bookPublisherId);

      int rate = await _getUserRatingForBook(bookId);

      return {
        'id': bookId,
        'title': bookTitle,
        'author': authorNames,
        'genre': genreNames,
        'rate': rate,
        'coverImage': coverImage,
        'description': description,
        'publisher': publisherName,
        'publicationDate': publicationDate,
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

    if (authorNames.isEmpty) authorNames.add("Nieznany");

    return authorNames;
  }

  Future<List<String>> _getGenres(List<String> genreIds) async {
    List<String> genreNames = [];

    for (var genreId in genreIds) {
      final genreDoc = await FirebaseFirestore.instance
          .collection('genre')
          .doc(genreId)
          .get();

      if (genreDoc.exists) {
        final genreName = genreDoc['name'];
        genreNames.add(genreName);
      }
    }

    if (genreNames.isEmpty) genreNames.add("Brak danych");

    return genreNames;
  }

  Future<String> _getPublisherName(String publisherId) async {
    String publisherName = "Brak danych";

    final publisherDoc = await FirebaseFirestore.instance
        .collection('publisher')
        .doc(publisherId)
        .get();

    if (publisherDoc.exists && publisherDoc['name'] != null) {
      publisherName = publisherDoc['name'];
    }

    return publisherName;
  }

  Future<int> _getUserRatingForBook(String bookId) async {
    const storage = FlutterSecureStorage();
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

  Future<Map<String, dynamic>> _fetchReviews(String bookId) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('review')
        .where('book', isEqualTo: bookId)
        .get();

    double totalRating = 0.0;
    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('rate') && data['rate'] != null) {
        totalRating += (data['rate'] as int).toDouble();
        count++;
      }
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

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();

    List<dynamic> bookshelves = userDoc['bookshelves'] ?? [];
    //szukanie półek na których jest dana książka
    List<String> shelfNames = [];
    for (String shelfId in bookshelves) {
      DocumentSnapshot shelfDoc = await FirebaseFirestore.instance
          .collection('shelf')
          .doc(shelfId)
          .get();
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
      // Initialize a map to hold the review data
      Map<String, dynamic> reviewData = {};

      final data = doc.data() as Map<String, dynamic>?;

      // Check if data is not null and then check for 'rate'
      if (data != null && data.containsKey('rate')) {
        reviewData['rate'] = data['rate'];
      }

      // Check if data is not null and then check for 'text'
      if (data != null && data.containsKey('text')) {
        reviewData['text'] = data['text'];
      }

      return reviewData;
    }).toList();

    return reviews;
  }

  Widget _addRate(BuildContext context) {
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
  }

  Widget _addReview(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Add review implementation
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
  }

  //funkcja do obliczania ilosci gwiazdek w avg rate ksiazki
  List<Widget> _buildStarRating(double averageRating) {
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

    //wyswietlanie gwiazdek
    return List.generate(5, (index) {
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
    });
  }

  //do dodawania ksiazki na polke (w trakcie roboty)
  Future<List<Map<String, dynamic>>> _fetchUserShelves() async {
    String? userId = await storage.read(key: 'user_id');
    if (userId == null) {
      return [];
    }

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();

    List<dynamic> bookshelves = userDoc['bookshelves'] ?? [];
    List<Map<String, dynamic>> shelves = [];

    for (var shelfId in bookshelves) {
      final shelfDoc = await FirebaseFirestore.instance
          .collection('shelf')
          .doc(shelfId)
          .get();
      if (shelfDoc.exists) {
        shelves.add({
          'id': shelfId,
          'name': shelfDoc['name'],
          'containsBook': (shelfDoc['books'] as List<dynamic>).contains(bookId),
        });
      }
    }

    return shelves;
  }

  Future<List<String>> _fetchUserShelfIds() async {
    String? userId = await storage.read(key: 'user_id');
    if (userId == null) {
      return [];
    }

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();

    List<dynamic> bookshelves = userDoc['bookshelves'] ?? [];
    return bookshelves.cast<String>();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.88;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F1E5),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          const BackgroundOvals(),
          FutureBuilder<Map<String, dynamic>?>(
              future:
                  _getBookData(bookId), // Fetch the book data using the bookId
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading book data'));
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('Book not found'));
                }

                final bookData = snapshot.data!;
                final String title = bookData['title'] ?? 'Brak tytułu';
                final String author =
                    (bookData['author'] as List<dynamic>).join(', ');
                final String genre =
                    (bookData['genre'] as List<dynamic>).join(', ');
                final String? coverImage = bookData['coverImage'];
                final String publisherName = bookData['publisher'];
                final String? publicationDate = bookData['publicationDate'];
                final String description =
                    bookData['description'] ?? 'Brak opisu';

                return SingleChildScrollView(
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
                          //--------------------------------------------------- cover image, title, authors and avgRate section
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(height: 30),
                              coverImage != null && coverImage.isNotEmpty
                                  ? Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
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
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Błąd: ${snapshot.error}');
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!['count'] == 0) {
                                    return const Text('Brak ocen książki');
                                  } else {
                                    final double averageRating =
                                        snapshot.data!['averageRating'];
                                    final int count = snapshot.data!['count'];

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ..._buildStarRating(averageRating),
                                        const SizedBox(width: 10),
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
                      Center(
                        //---------------------------------------------------------------------------------------------- description section
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Text(
                                  description,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      //---------------------------------------------------------------------------------------------- genres section
                      Center(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Gatunek:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3C729E),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(genre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      fontSize: 16,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      //---------------------------------------------------------------------------------------------- publisher section
                      Center(
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
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Aligns text to the start
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Wydawca:',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3C729E),
                                      ),
                                    ),
                                    const SizedBox(
                                        width:
                                            10), // Use width for horizontal spacing
                                    Text(
                                      publisherName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        fontSize:
                                            publisherName.length > 20 ? 10 : 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                    height: 20), // Add some space between rows
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Data wydania:',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3C729E),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      publicationDate ?? "brak danych",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        //--------------------------------------------------------------------------------------shelves section
                        child: FutureBuilder<List<String>>(
                          future: _fetchShelfNamesWithBook(bookId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Błąd: ${snapshot.error}');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              //jeżeli książka nie jest dodana na żadną półkę użytkownika
                              return Center(
                                // Center the container within its parent
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
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton(
                                            onPressed: () async {
                                              List<String> shelfIds =
                                                  await _fetchUserShelfIds();
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AddBookToShelfPage(
                                                    shelfIds: shelfIds,
                                                    bookId: bookId,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Dodaj na półkę',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                //Do poprawy aby ikona była na końcu przycisku
                                                Icon(
                                                  FontAwesomeIcons.chevronRight,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              // gdy książka jest dodana na jakąś półkę użytkownika
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
                                      mainAxisSize: MainAxisSize.min,
                                      // Allow height to adjust based on content
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: snapshot.data!
                                                    .map<Widget>((shelfName) {
                                                  return Text(
                                                    shelfName,
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            // Spacing between text and icon
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                        future: _fetchBookReviews(bookId),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          } else if (snapshot.hasError) {
                                            return Text(
                                                'Błąd: ${snapshot.error}');
                                          } else if (!snapshot.hasData ||
                                              snapshot.data!.isEmpty) {
                                            // If the user has not rated the book
                                            return _addRate(context);
                                          } else {
                                            // If the user has rated the book
                                            Map<String, dynamic> review =
                                                snapshot.data!.first;
                                            // Check if 'rate' is null
                                            if (review['rate'] == null) {
                                              return _addRate(context);
                                            }

                                            // If rate is not null
                                            int rate = review['rate'] ??
                                                0; // Default to 0 if null
                                            List<Widget> stars =
                                                List.generate(5, (index) {
                                              return Icon(
                                                index < rate
                                                    ? FontAwesomeIcons.solidStar
                                                    : FontAwesomeIcons.star,
                                                color: Colors.yellow,
                                              );
                                            });

                                            return GestureDetector(
                                              onTap: () {
                                                // TODO: Add change/delete rate function
                                              },
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const Text(
                                                              'Moja ocena: ',
                                                              style: TextStyle(
                                                                color: Color(
                                                                    0xFF3C729E),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 20,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 10),
                                                            Row(
                                                              children: stars,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // Spacing between text/stars and icon
                                                  const Icon(
                                                    FontAwesomeIcons.pen,
                                                    color: Colors.grey,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Center(
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
                                  child:
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                    future: _fetchBookReviews(bookId),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      } else if (snapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                'Błąd: ${snapshot.error}'));
                                      } else if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        // Return the widget that prompts the user to add a review if there are no reviews
                                        return _addReview(context);
                                      } else {
                                        String? reviewText =
                                            snapshot.data!.first['text'];
                                        if (reviewText == null ||
                                            reviewText.isEmpty) {
                                          // Return the widget that prompts the user to add a review if reviewText is null or empty
                                          return _addReview(context);
                                        }

                                        // If review text is available, return the review content widget
                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20.0),
                                              child: Text(
                                                reviewText,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    // TODO: Add edit review functionality
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF3C729E),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
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
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF3C729E),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                    ),
                                                    child: const Row(
                                                      children: [
                                                        Icon(
                                                          FontAwesomeIcons
                                                              .trash,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(width: 7),
                                                        Text(
                                                          'Usuń',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
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

                      Center(
                        //---------------------------------------------------------------------------------------------- show all reviews
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
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              child: Row(
                                children: [
                                  Expanded(
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
                                  Icon(
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
                );
              })
        ],
      ),
    );
  }
}
