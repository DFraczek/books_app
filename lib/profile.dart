import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? username;
  String? aboutMe;
  String? email;
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

  // Logout function
  Future<void> _logout() async {
    final storage = FlutterSecureStorage();
    await storage.delete(key: 'user_id');
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

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
          email = userDoc['email'] ?? '';
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


  Future<void> _uploadImageToFirebase(String filePath) async {
    final storage = FlutterSecureStorage();
    String? userId = await storage.read(key: 'user_id');
    if (userId != null) {
      try {
        Reference ref = FirebaseStorage.instance.ref().child('profile_pictures/$userId.jpg');
        await ref.putFile(File(filePath));
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

  Future<void> _changeEmail() async {
    TextEditingController oldEmailController = TextEditingController();
    TextEditingController newEmailController = TextEditingController();

    // Show dialog to enter old and new email
    String? newEmail = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF9F1E5),
          title: Text('Zmień adres e-mail'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldEmailController,
                decoration: InputDecoration(hintText: "Wprowadź stary adres e-mail..."),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: newEmailController,
                decoration: InputDecoration(hintText: "Wprowadź nowy adres e-mail..."),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(newEmailController.text);
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

    if (newEmail != null && newEmail.isNotEmpty) {
      final storage = FlutterSecureStorage();
      String? userId = await storage.read(key: 'user_id');

      // Regex for validating email
      final RegExp emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      if (!emailRegex.hasMatch(newEmail)) {
        _showErrorDialog('Proszę wprowadzić prawidłowy adres e-mail.');
        return;
      }

      // Check if the new email is unique
      QuerySnapshot existingUsers = await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: newEmail)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        _showErrorDialog('Adres e-mail jest już zajęty.');
        return;
      }

      // Check if the old email matches the one in Firestore
      if (userId != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('user').doc(userId).get();
        String? oldEmail = userDoc['email'];

        if (oldEmailController.text != oldEmail) {
          _showErrorDialog('Wprowadzony stary adres e-mail jest nieprawidłowy.');
          return;
        }

        // If everything is valid, update the email in Firestore
        await FirebaseFirestore.instance.collection('user').doc(userId).update({'email': newEmail});

      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF9F1E5),
          title: Text('Błąd'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.88;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: containerWidth,
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
                          ? (profilePictureUrl == 'assets/images/default_avatar.jpg'
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
                // Overlay the loading indicator
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
                        followersCount != null ? followersCount.toString() : '',
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
                        followingCount != null ? followingCount.toString() : '',
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
          // Zmień e-mail
          Container(
            width: containerWidth,
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
            child: GestureDetector(
              onTap: _changeEmail,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Change to spaceBetween
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Icon(
                      FontAwesomeIcons.at,
                      color: Color(0xFF3C729E),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Text(
                        email ?? 'Błąd przy pobieraniu adresu email',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Icon(
                      FontAwesomeIcons.pen,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),
          // Zmień hasło
          Container(
            width: containerWidth,
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
          SizedBox(height: 16),
          //logout
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3C729E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
            ),
            child: Container(
              width: containerWidth,
              height: 50,
              alignment: Alignment.center,
              child: Text(
                'Wyloguj',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }


}
