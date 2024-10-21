import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:books_app/pages/book_details.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;

  const CustomSearchBar({super.key, required this.controller});

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  List<Map<String, String>> suggestions = []; //lista sugerowanych tytułow książek i id

  //szukanie ksiazek w bazie
  Future<void> searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        suggestions = [];
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();

    // pobranie wszystkich ksiazek
    final results = await FirebaseFirestore.instance.collection('book').get();

    // filtrowanie wyników ktore zaczynają się lub zawierają wpisywaną frazę
    final startsWithQuery = results.docs
        .map((doc) => {'title': doc['title'] as String, 'id': doc.id})
        .where((book) => book['title']!.toLowerCase().startsWith(lowerCaseQuery))
        .toList();

    final containsQuery = results.docs
        .map((doc) => {'title': doc['title'] as String, 'id': doc.id})
        .where((book) => book['title']!.toLowerCase().contains(lowerCaseQuery) &&
        !book['title']!.toLowerCase().startsWith(lowerCaseQuery))
        .toList();

    // najpierw wyswietlamy tytuły które się zaczynają od danej frazy, później te, które ją zawierają
    setState(() {
      suggestions = [...startsWithQuery, ...containsQuery].take(5).toList(); // Maksymalnie 5 sugestii
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            child: TextField(
              controller: widget.controller,
              onChanged: searchBooks, // Wyszukiwanie ksiazek na biezaco, gdy uzytkownik wpisuje coś w search bar
              textInputAction: TextInputAction.search, // Zmiana klawiatury (enter na search)
              onSubmitted: (value) {
                searchBooks(value);
              },
              decoration: InputDecoration(
                hintText: 'Wyszukaj książkę lub autora',
                hintStyle: TextStyle(color: Colors.grey[500]),
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
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(FontAwesomeIcons.book, color: Colors.grey),
                          title: Text(
                            suggestions[index]['title']!, // Wyswietlanie tytułu
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            // Po kliknieciu otwarcie szczegołów książki
                            final bookId = suggestions[index]['id']; // Pobranie ID ksiazki
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetails(bookId: bookId!),
                              ),
                            );
                            widget.controller.text = suggestions[index]['title']!; // w inpucie wpisuje sie pełny tytuł
                            setState(() {
                              suggestions = []; //Ukrycie sugestii po kliknieciu
                            });
                          },
                        ),
                        if (index < suggestions.length - 1) // Linia w sugestiach (kosmetyka)
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7, //dlugosc tej linii
                            child: const Divider(height: 1),
                          ),
                      ],
                    );
                  },
                ),
                ListTile(
                  title: const Center(
                    child: Text(
                      'Pokaż wszystkie wyniki',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3C729E),
                      ),
                    ),
                  ),
                  onTap: () {
                    // TODO: Handle "Show all results" tap
                    print('Show all results tapped');
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
