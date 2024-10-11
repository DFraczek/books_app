import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';

//zakładka z profilem użytkownika i settingsami

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? username;
  String? aboutMe;
  String? profilePictureUrl;
  int? followersCount;
  int? followingCount;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchFollowers();
    _fetchFollowing();
  }


//pobranie username z firestore
  Future<void> _fetchUsername() async {
    final storage = FlutterSecureStorage();
    String? userId = await storage.read(key: 'user_id');

    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('user').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'];
          profilePictureUrl = userDoc['profilePicture'];
          aboutMe = userDoc['aboutMe'] ?? '';
        });
      }
    }
  }

  Future<void> _fetchFollowers() async {
    final storage = FlutterSecureStorage();
    String? userId = await storage.read(key: 'user_id');

    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('user').doc(userId).get();
      if (userDoc.exists) {
        List<dynamic> followers = userDoc['followers'];
        setState(() {
          followersCount = followers.length;
        });
      }
    }
  }

  Future<void> _fetchFollowing() async {
    final storage = FlutterSecureStorage();
    String? userId = await storage.read(key: 'user_id');

    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('user').doc(userId).get();
      if (userDoc.exists) {
        List<dynamic> following = userDoc['following'];
        setState(() {
          followingCount = following.length;
        });
      }
    }
  }

  //image picker do zmiany zdjecia profilowego

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
        ],
        cropStyle: CropStyle.circle,
        compressQuality: 100,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (croppedFile != null) {
        setState(() {
          _isLoading = true;
        });
        await _uploadImageToFirebase(croppedFile.path);
      }
    }
  }


//dodawanie zdjecia do bazy danych. tam jest coś takiego jak Firebase Storage gdzie przechowywane sa zdjecia

  Future<void> _uploadImageToFirebase(String filePath) async {
    final storage = FlutterSecureStorage();
    String? userId = await storage.read(key: 'user_id');
    if (userId != null) {
      try {
        Reference ref = FirebaseStorage.instance.ref().child('profile_pictures/$userId.jpg');
        await ref.putFile(File(filePath));
        //kazde zdjecie w firebase storage ma swoj url
        // Pobierz URL
        String downloadUrl = await ref.getDownloadURL();
        await FirebaseFirestore.instance.collection('user').doc(userId).update({'profilePicture': downloadUrl});
        setState(() {
          profilePictureUrl = downloadUrl;
        });
      } catch (e) {
        print('Error uploading image: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

//edycja opisu uzytkownika
  Future<void> _editAboutMe() async {
    String? newAboutMe = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController(text: aboutMe);
        return AlertDialog(
          backgroundColor: const Color(0xFFF9F1E5),
          title: Text('Edytuj opis'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Napisz coś o sobie..."),
            maxLength: 100,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: Text('Zapisz'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Anuluj'),
            ),
          ],
        );
      },
    );

    if (newAboutMe != null) {
      final storage = FlutterSecureStorage();
      String? userId = await storage.read(key: 'user_id');
      if (userId != null) {
        await FirebaseFirestore.instance.collection('user').doc(userId).update({'aboutMe': newAboutMe});
        setState(() {
          aboutMe = newAboutMe;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: profilePictureUrl != null
                          ? (profilePictureUrl == 'assets/images/default_avatar.jpg' //defaultowy avatar przechowywany w assetsach
                          ? Image.asset(
                        profilePictureUrl!,
                        fit: BoxFit.cover,
                      )
                          : Image.network(
                        profilePictureUrl!,
                        fit: BoxFit.cover,
                      ))
                          : Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
                if (_isLoading)
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                Positioned(
                  top: 80,
                  left: 90,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFFC4C2C2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        FontAwesomeIcons.pen,
                        color: Colors.black,
                        size: 15,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 160,
                  child: Text(
                    username ?? 'Ładowanie...',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  top: 140,
                  left: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: _editAboutMe,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded( // Umożliwia dynamiczne dopasowanie do dostępnej przestrzeni
                            child: Text(
                              aboutMe != null && aboutMe!.isNotEmpty
                                  ? aboutMe!
                                  : 'Dodaj kilka słów o sobie',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            FontAwesomeIcons.pen,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 250,
                  left: 40,
                  child: Column(
                    children: [
                      Text(
                        followersCount != null ? followersCount.toString() : 'Ładowanie...',
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'obserwujących',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 250,
                  right: 40,
                  child: Column(
                    children: [
                      Text(
                        followingCount != null ? followingCount.toString() : 'Ładowanie...',
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'obserwatorów',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Zmień e-mail, do poprawy
          Container(
            width: 350,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 30.0),
                  child: Icon(
                    FontAwesomeIcons.at,
                    color: Color(0xFF3C729E),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Zmień adres e-mail',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Zmień hasło, do zrobienia
          Container(
            width: 350,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 30.0),
                  child: Icon(
                    FontAwesomeIcons.lock,
                    color: Color(0xFF3C729E),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Zmień hasło',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
