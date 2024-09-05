import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _isErrorVisible = false;
  String _errorMessage = '';

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLoginButtonPress() async {
    setState(() {
      _isErrorVisible = false;
    });

    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Pola nie mogą być puste";
        _isErrorVisible = true;
      });
      return;
    }

    try {
      final db = FirebaseFirestore.instance;

      final userQuery = await db.collection('user')
          .where('username', isEqualTo: username)
          .get();

      if (userQuery.docs.isEmpty) {
        setState(() {
          _errorMessage = "Użytkownik o podanej nazwie użytkownika nie istnieje";
          _isErrorVisible = true;
        });
        return;
      }

      final userDoc = userQuery.docs.first; //finding user with this username
      final userData = userDoc.data(); //user data

      if (userData['password'] == password) {
        Navigator.pushNamed(context, '/main_page');
      } else {
        setState(() {
          _errorMessage = "Niepoprawne hasło";
          _isErrorVisible = true;
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = "Wystąpił błąd: $e";
        _isErrorVisible = true;
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
          //-------------------------------------------------"zaloguj się" text
          Positioned(
            left: 0,
            right: 0,
            top: 152,
            child: Center(
              child: Text(
                'Zaloguj się',
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
          //------------------------------------------------- username and passwd inputs
          Positioned(
            left: 0,
            right: 0,
            top: 306,
            child: FractionallySizedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Material(
                  elevation: 4, // Cień
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
          Positioned(
            left: 0,
            right: 0,
            top: 397,
            child: FractionallySizedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Material(
                  elevation: 4, // Cień
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
          //------------------------------------------------- login button
          Positioned(
            left: 0,
            right: 0,
            top: 476,
            child: Center(
              child: SizedBox(
                width: 186,
                height: 36,
                child: ElevatedButton(
                  onPressed: _handleLoginButtonPress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C729E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Zaloguj',
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
          //------------------------------------------------- login errors
          if (_isErrorVisible)
            Positioned(
              left: 0,
              right: 0,
              top: 550,
              child: Center(
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          //------------------------------------------------- registration prompt
          Positioned(
            left: 0,
            right: 0,
            bottom: 20, // Odległość od dolnej krawędzi
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nie masz konta?',
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
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      'Zarejestruj się',
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
        ],
      ),
    );
  }
}
