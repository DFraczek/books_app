import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/background_ovals.dart';

class AddBookToShelfPage extends StatefulWidget {
  final List<String> shelfIds;
  final String bookId;

  const AddBookToShelfPage({super.key, 
    required this.shelfIds,
    required this.bookId,
  });

  @override
  State<AddBookToShelfPage> createState() => _AddBookToShelfPageState();
}

class _AddBookToShelfPageState extends State<AddBookToShelfPage> {
  List<Map<String, dynamic>> shelves = [];

  @override
  void initState() {
    super.initState();
    _fetchShelfList();
  }

  Future<void> _fetchShelfList() async {
    List<Map<String, dynamic>> shelfList = [];
    for (var shelfId in widget.shelfIds) {
      final shelfDoc = await FirebaseFirestore.instance.collection('shelf').doc(shelfId).get();
      if (shelfDoc.exists) {
        shelfList.add({
          'id': shelfId,
          'name': shelfDoc['name'],
          'containsBook': (shelfDoc['books'] as List<dynamic>).contains(widget.bookId),
        });
      }
    }
    setState(() {
      shelves = shelfList;
    });
  }

  Future<void> _addBookToShelf(String shelfId) async {
    await FirebaseFirestore.instance.collection('shelf').doc(shelfId).update({
      'books': FieldValue.arrayUnion([widget.bookId]),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wybierz półkę'),
      ),
      body: Stack(children: [
        const BackgroundOvals(),
        if (shelves.isEmpty)
          const Center(child: CircularProgressIndicator())
        else
          ListView.builder(
            itemCount: shelves.length,
            itemBuilder: (context, index) {
              final shelf = shelves[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(
                    shelf['name'],
                    style: const TextStyle(fontSize: 20),
                  ),
                  trailing: shelf['containsBook']
                      ? const Icon(Icons.check, color: Colors.green)
                      : ElevatedButton(
                          onPressed: () => _addBookToShelf(shelf['id']),
                          child: const Text('Add'),
                        ),
                ),
              );
            },
          ),
      ]),
    );
  }
}