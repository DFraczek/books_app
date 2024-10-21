import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'follow_list.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

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
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'user_id');
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _fetchUsername() async {
    const storage = FlutterSecureStorage();
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
    const storage = FlutterSecureStorage();
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
    const storage = FlutterSecureStorage();
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
    const storage = FlutterSecureStorage();
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9F1E5),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edytuj opis',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "Napisz coś o sobie...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      maxLength: 100,
                      keyboardType: TextInputType.text, // Restrict keyboard to text input
                      textInputAction: TextInputAction.done, // Change Enter key to done
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp('\n')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(controller.text);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF3C729E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Zapisz'),
                      ),
                      const SizedBox(width: 10), // Space between buttons
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

    if (newAboutMe != null) {
      const storage = FlutterSecureStorage();
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
    ValueNotifier<String?> errorMessageNotifier = ValueNotifier<String?>(null);

    String? newEmail = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            backgroundColor: Colors.transparent,
            child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F1E5),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Zmień adres e-mail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: oldEmailController,
                          decoration: InputDecoration(
                            hintText: "Stary adres e-mail",
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(FontAwesomeIcons.envelope, color: Colors.grey),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Input field for new email
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: newEmailController,
                          decoration: InputDecoration(
                            hintText: "Nowy adres e-mail",
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(FontAwesomeIcons.envelope, color: Colors.grey),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<String?>(
                        valueListenable: errorMessageNotifier,
                        builder: (context, errorMessage, child) {
                          return Visibility(
                            visible: errorMessage != null,
                            child: Text(
                              errorMessage ?? '',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: TextButton(
                              onPressed: () async {
                                errorMessageNotifier.value = null;

                                const storage = FlutterSecureStorage();
                                String? userId = await storage.read(key: 'user_id');

                                // Regex for validating email
                                final RegExp emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                );

                                if (!emailRegex.hasMatch(newEmailController.text)) {
                                  errorMessageNotifier.value = 'Proszę wprowadzić prawidłowy adres e-mail.';
                                  return;
                                }

                                QuerySnapshot existingUsers = await FirebaseFirestore.instance
                                    .collection('user')
                                    .where('email', isEqualTo: newEmailController.text)
                                    .get();

                                if (existingUsers.docs.isNotEmpty) {
                                  errorMessageNotifier.value = 'Adres e-mail jest już zajęty.';
                                  return;
                                }

                                if (userId != null) {
                                  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('user').doc(userId).get();
                                  String? oldEmail = userDoc['email'];

                                  if (oldEmailController.text != oldEmail) {
                                    errorMessageNotifier.value = 'Wprowadzony stary adres e-mail jest nieprawidłowy.';
                                    return;
                                  }

                                  await FirebaseFirestore.instance.collection('user').doc(userId).update({'email': newEmailController.text});
                                  await _fetchUsername();
                                  Navigator.of(context).pop(newEmailController.text);
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFF3C729E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Zapisz'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: TextButton(
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
                          ),
                        ],
                      ),

                    ],
                  ),
                )
            )
        );
      },
    );
  }

  Future<void> _changePassword() async {
    TextEditingController oldPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();
    ValueNotifier<String?> errorMessageNotifier = ValueNotifier<String?>(null);
    bool isPasswordVisible = false;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom, // Przesunięcie przy wywołaniu klawiatury
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F1E5),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Zmień hasło',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      _buildPasswordInputField(
                        context,
                        controller: oldPasswordController,
                        hintText: "Stare hasło",
                        isPasswordVisible: isPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      // Input field for new password
                      _buildPasswordInputField(
                        context,
                        controller: newPasswordController,
                        hintText: "Nowe hasło",
                        isPasswordVisible: isPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildPasswordInputField(
                        context,
                        controller: confirmPasswordController,
                        hintText: "Potwierdź nowe hasło",
                        isPasswordVisible: isPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<String?>(
                        valueListenable: errorMessageNotifier,
                        builder: (context, errorMessage, child) {
                          return Visibility(
                            visible: errorMessage != null,
                            child: Text(
                              errorMessage ?? '',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: TextButton(
                              onPressed: () async {
                                errorMessageNotifier.value = null;

                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  errorMessageNotifier.value =
                                  'Nie jesteś zalogowany.';
                                  return;
                                }

                                try {
                                  AuthCredential credential =
                                  EmailAuthProvider.credential(
                                    email: user.email!,
                                    password: oldPasswordController.text,
                                  );

                                  await user.reauthenticateWithCredential(
                                      credential);

                                  if (newPasswordController.text !=
                                      confirmPasswordController.text) {
                                    errorMessageNotifier.value =
                                    'Nowe hasła nie pasują do siebie.';
                                    return;
                                  }

                                  await user.updatePassword(
                                      newPasswordController.text);
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Hasło zostało zmienione.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  if (e is FirebaseAuthException) {
                                    if (e.code == 'invalid-credential') {
                                      errorMessageNotifier.value =
                                      'Stare hasło jest nieprawidłowe.';
                                    } else {
                                      errorMessageNotifier.value =
                                      'Błąd zmiany hasła. Spróbuj ponownie';
                                    }
                                  } else {
                                    errorMessageNotifier.value =
                                    'Błąd zmiany hasła. Spróbuj ponownie';
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFF3C729E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Zapisz'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: TextButton(
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

  Widget _buildPasswordInputField(BuildContext context,
      {required TextEditingController controller,
        required String hintText,
        required bool isPasswordVisible,
        required VoidCallback onVisibilityToggle}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: !isPasswordVisible,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(FontAwesomeIcons.lock, color: Colors.grey),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible
                  ? FontAwesomeIcons.eyeSlash
                  : FontAwesomeIcons.eye,
              color: Colors.grey,
            ),
            onPressed: onVisibilityToggle,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.88;
    final userId = FirebaseAuth.instance.currentUser!.uid; 

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
                  offset: const Offset(0, 4),
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
                      color: const Color(0xFFD9D9D9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
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
                          : const Center(child: CircularProgressIndicator()),
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
                      child: const Center(child: CircularProgressIndicator()),
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
                        color: const Color(0xFFC4C2C2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
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
                      fontSize: (username?.length ?? 0) > 12 ? 18 : 22,
                      fontFamily: 'Inter',
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
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
                      TextButton(onPressed: 
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowList(
                              title: 'Obserwujący',
                              userId: userId,
                              isFollowers: true,
                            ),
                          ),
                        );
                      }, 
                      child: Column(
                        children: [
                          Text(
                        followersCount != null ? followersCount.toString() : '',
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Obserwujący',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                        ),
                      ),
                        ],
                      )),
                    ],
                  ),
                ),
                Positioned(
                  top: 250,
                  right: 40,
                  child: Column(
                    children: [
                      TextButton(onPressed: 
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowList(
                              title: 'Obserwowani',
                              userId: userId,
                              isFollowers: false,
                            ),
                          ),
                        );
                      }, 
                      child: Column(
                        children: [
                          Text(
                        followingCount != null ? followingCount.toString() : '',
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Obserwowani',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                        ),
                      ),
                        ],
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: _changeEmail,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20.0),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 20.0),
                    child: Icon(
                      FontAwesomeIcons.pen,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
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
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => _changePassword(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 20.0, right: 30.0),
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
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          //logout
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C729E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
            ),
            child: Container(
              width: containerWidth,
              height: 50,
              alignment: Alignment.center,
              child: const Text(
                'Wyloguj',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }


}
