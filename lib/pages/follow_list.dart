import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/background_ovals.dart';

class FollowList extends StatefulWidget {
  final String title;
  final String userId;
  final bool isFollowers;

  const FollowList({super.key, 
    required this.title,
    required this.userId,
    required this.isFollowers,
  });

  @override
  State<FollowList> createState() => _FollowListState(userId: userId, isFollowers: isFollowers);
}

class _FollowListState extends State<FollowList> {
  List<String> users = [];
  bool isLoading = true;

  final String userId;
  final bool isFollowers;

  _FollowListState({
    required this.userId,
    required this.isFollowers,
  });

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });
  }

  Future<void> _fetchFollowList() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();

    if (userDoc.exists) {
      List<dynamic> followers =
          isFollowers ? userDoc['followers'] : userDoc['following'];
      for (var follower in followers) {
        DocumentSnapshot followerDoc = await FirebaseFirestore.instance
            .collection('user')
            .doc(follower)
            .get();
        if (followerDoc.exists) {
          users.add(followerDoc['username']);
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) _fetchFollowList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          const BackgroundOvals(),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : users.isNotEmpty
                  ? ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                            child: Text(users[index])),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                      'Brak użytkowników do wyświetlenia',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    )),
        ],
      ),
    );
  }
}
