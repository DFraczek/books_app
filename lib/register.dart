import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _isErrorVisible = false;
  bool _isSuccessVisible = false;
  bool _isLoading = false; // New state variable
  String _errorMessage = '';

  // Kontrolery tekstowe dla pól tekstowych
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repetPasswordController = TextEditingController();

  // Validate email
  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
        r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$'); // email regex
    return emailRegex.hasMatch(email);
  }

  // Validate username
  bool _isValidUsername(String username) {
    final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9]{3,20}$');
    return usernameRegex.hasMatch(username);
  }

  // Validate data
  bool _isValidData() {
    String email = _emailController.text;
    String username = _usernameController.text;
    String password = _passwordController.text;
    String password2 = _repetPasswordController.text;

    if (username.isEmpty || password.isEmpty || email.isEmpty || password2.isEmpty) {
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
      _errorMessage = "Nazwa użytkownika musi mieć od 3 do 20 znaków i składać się tylko z liter oraz cyfr";
      return false;
    } else {
      return true;
    }
  }

  Future<void> _handleRegisterButtonPress() async {
    setState(() {
      _isErrorVisible = false;
      _isSuccessVisible = false;
      _isLoading = true; // Set loading state to true
    });

    if (_isValidData()) {
      String email = _emailController.text;
      String username = _usernameController.text;
      String password = _passwordController.text;

      try {
        final db = FirebaseFirestore.instance;

        final emailQuery = await db.collection('user').where('email', isEqualTo: email).get();
        if (emailQuery.docs.isNotEmpty) {
          // Email already exists
          setState(() {
            _errorMessage = "Adres e-mail jest już zarejestrowany";
            _isErrorVisible = true;
          });
          return;
        }

        final usernameQuery = await db.collection('user').where('username', isEqualTo: username).get();
        if (usernameQuery.docs.isNotEmpty) {
          // Username already exists
          setState(() {
            _errorMessage = "Nazwa użytkownika jest już zajęta";
            _isErrorVisible = true;
          });
          return;
        }

        // Create new user document
        await db.collection('user').add({
          'email': email,
          'followed': 0,
          'password': password, // Todo: hashowanie hasła
          'registrationDate': Timestamp.now(),
          'role': 'user',
          'username': username,
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
          _isLoading = false; // Set loading state to false
        });
      }
    } else {
      setState(() {
        _isErrorVisible = true;
        _isLoading = false; // Set loading state to false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1E5),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          //------------------------------------------------- ovals in bg
          Positioned(
            left: 145,
            top: -107,
            child: Container(
              width: 459,
              height: 457,
              decoration: const ShapeDecoration(
                color: Color(0xFF528BB9),
                shape: OvalBorder(),
              ),
            ),
          ),
          Positioned(
            left: -345,
            top: -282,
            child: Container(
              width: 712,
              height: 566,
              decoration: const ShapeDecoration(
                color: Color(0xFF3C729E),
                shape: OvalBorder(),
              ),
            ),
          ),
          //-------------------------------------------------"Zarejestruj się" text
          const Positioned(
            left: 0,
            right: 0,
            top: 152,
            child: Center(
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
          ),
          //------------------------------------------------- inputs
          Positioned( // email input
            left: 0,
            right: 0,
            top: 306,
            child: FractionallySizedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Material(
                  elevation: 4, // shadow
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Adres email',
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
          ),
          Positioned( // username input
            left: 0,
            right: 0,
            top: 377,
            child: FractionallySizedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Material(
                  elevation: 4, // shadow
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  child: TextField(
                    controller: _usernameController,
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
          ),
          Positioned( // password input
            left: 0,
            right: 0,
            top: 448,
            child: FractionallySizedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Material(
                  elevation: 4, // shadow
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  child: TextField(
                    controller: _passwordController,
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
          ),
          Positioned( // repeat password input
            left: 0,
            right: 0,
            top: 519,
            child: FractionallySizedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Material(
                  elevation: 4, // shadow
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  child: TextField(
                    controller: _repetPasswordController,
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
          ),
          //------------------------------------------------- register button
          Positioned(
            left: 0,
            right: 0,
            top: 598,
            child: Center(
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
          ),
          //------------------------------------------------- register errors||success
          if (_isErrorVisible || _isSuccessVisible)
            Positioned(
              left: 0,
              right: 0,
              top: 672,
              child: Center(
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: _isSuccessVisible ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
          //------------------------------------------------- registration prompt
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Masz już konto?',
                    style: TextStyle(
                      color: Color(0xFF949494),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w300,
                      height: 0,
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
                        height: 0,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          //------------------------------------------------- loading indicator
          if (_isLoading)
            const Positioned(
              left: 0,
              right: 0,
              top: 672,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3C729E)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
