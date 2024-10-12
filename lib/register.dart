import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/background_ovals.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _isErrorVisible = false;
  bool _isSuccessVisible = false;
  bool _isLoading = false;
  String _errorMessage = '';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repetPasswordController = TextEditingController();

  bool _isValidEmail(String email) {
    final RegExp emailRegex =
    RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidUsername(String username) {
    final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9]{3,20}$');
    return usernameRegex.hasMatch(username);
  }

  bool _isValidData() {
    String email = _emailController.text;
    String username = _usernameController.text;
    String password = _passwordController.text;
    String password2 = _repetPasswordController.text;

    if (username.isEmpty ||
        password.isEmpty ||
        email.isEmpty ||
        password2.isEmpty) {
      _errorMessage = "Pola nie mogą być puste";
      return false;
    } else if (!_isValidEmail(email)) {
      _errorMessage = "Niepoprawny adres e-mail";
      return false;
    } else if (password != password2) {
      _errorMessage = "Hasła muszą być takie same";
      return false;
    } else if (password.length < 6) {
      _errorMessage = "Hasło jest za krótkie";
      return false;
    } else if (!_isValidUsername(username)) {
      _errorMessage =
      "Nazwa użytkownika musi mieć od 3 do 20 znaków i składać się tylko z liter oraz cyfr";
      return false;
    } else {
      return true;
    }
  }

  Future<void> _handleRegisterButtonPress() async {
    setState(() {
      _isErrorVisible = false;
      _isSuccessVisible = false;
      _isLoading = true;
    });

    if (_isValidData()) {
      String email = _emailController.text;
      String username = _usernameController.text;
      String password = _passwordController.text;

      try {
        final db = FirebaseFirestore.instance;
        final auth = FirebaseAuth.instance;

        // Check if email or username already exists in Firestore
        final emailQuery = await db.collection('user').where('email', isEqualTo: email).get();
        if (emailQuery.docs.isNotEmpty) {
          setState(() {
            _errorMessage = "Adres e-mail jest już zarejestrowany";
            _isErrorVisible = true;
          });
          return;
        }

        final usernameQuery = await db.collection('user').where('username', isEqualTo: username).get();
        if (usernameQuery.docs.isNotEmpty) {
          setState(() {
            _errorMessage = "Nazwa użytkownika jest już zajęta";
            _isErrorVisible = true;
          });
          return;
        }

        // Register user with Firebase Authentication
        UserCredential userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Create default shelves
        List<String> shelfIds = [];
        final shelves = [
          {'name': 'Przeczytane', 'books': [], 'visibility': 'public', 'icon': [{'name': 'BNY3UlRkOfWOKvjLgunJ', 'color': '0xFF3C729E'}]},
          {'name': 'Właśnie czytam', 'books': [], 'visibility': 'public', 'icon': [{'name': 'booBNY3UlRkOfWOKvjLgunJ', 'color': '0xFF3C729E'}]},
          {'name': 'Chcę przeczytać', 'books': [], 'visibility': 'public', 'icon': [{'name': 'BNY3UlRkOfWOKvjLgunJ', 'color': '0xFF3C729E'}]}
        ];

        for (var shelf in shelves) {
          DocumentReference shelfRef = await db.collection('shelf').add(shelf);
          shelfIds.add(shelfRef.id);
        }

        // Add additional user data to Firestore
        await db.collection('user').doc(userCredential.user!.uid).set({
          'email': email,
          'followers': [],
          'following': [],
          'registrationDate': Timestamp.now(),
          'role': 'user',
          'username': username,
          'bookshelves': shelfIds,
          'profilePicture': 'assets/images/default_avatar.jpg',
          'aboutMe': "",
        });

        setState(() {
          _errorMessage = "Konto zostało utworzone";
          _isSuccessVisible = true;
        });
      } catch (e) {
        setState(() {
          _errorMessage = "Wystąpił błąd: $e";
          _isErrorVisible = true;
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isErrorVisible = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1E5),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const BackgroundOvals(),
          GestureDetector(
            onTap: () {
              // Schowaj klawiaturę po kliknięciu poza pole tekstowe
              FocusScope.of(context).unfocus();
            },
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 150),
                const Center(
                  child: Text(
                    'Zarejestruj się',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                RegisterForm(
                  emailController: _emailController,
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  password2Controller: _repetPasswordController,
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 186,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: _handleRegisterButtonPress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C729E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Zarejestruj się',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isErrorVisible || _isSuccessVisible) const SizedBox(height: 20),
                if (_isErrorVisible || _isSuccessVisible)
                  Center(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: _isSuccessVisible ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                if (_isLoading) const SizedBox(height: 20),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3C729E)),
                    ),
                  ),
                const SizedBox(height: 100),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Masz już konto?',
                      style: TextStyle(
                        color: Color(0xFF949494),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        'Zaloguj się',
                        style: TextStyle(
                          color: Color(0xFF3C729E),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w300,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ),
      ]),
    );
  }
}


class RegisterForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController password2Controller;

  const RegisterForm({
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
    required this.password2Controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FractionallySizedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Adres e-mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  prefixIcon: const Icon(FontAwesomeIcons.envelope, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FractionallySizedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  hintText: 'Nazwa użytkownika',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  prefixIcon: const Icon(FontAwesomeIcons.solidUser, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),// Space between inputs
        FractionallySizedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Hasło',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  prefixIcon: const Icon(FontAwesomeIcons.lock, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),// Space between inputs
        FractionallySizedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: TextField(
                controller: password2Controller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Powtórz hasło',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  prefixIcon: const Icon(FontAwesomeIcons.lock, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
