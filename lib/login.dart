import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _isErrorVisible = false;
  bool _isLoading = false;
  String _errorMessage = '';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLoginButtonPress() async {
    setState(() {
      _isErrorVisible = false;
      _isLoading = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Pola nie mogą być puste";
        _isErrorVisible = true;
        _isLoading = false;
      });
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Get the user's unique ID from FirebaseAuth
      final user = userCredential.user;
      if (user != null) {
        final storage = FlutterSecureStorage();
        await storage.write(key: 'user_id',
            value: user.uid); // Store the user ID in secure storage

        Navigator.pushNamed(context, '/main_page');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = "Użytkownik o podanym adresie e-mail nie istnieje";
        } else if (e.code == 'wrong-password') {
          _errorMessage = "Niepoprawne hasło";
        } else {
          _errorMessage = "Wystąpił błąd. Spróbuj ponownie";
        }
        _isErrorVisible = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Wystąpił błąd: $e";
        _isErrorVisible = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery
        .of(context)
        .orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F1E5),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          BackgroundOvals(),
          GestureDetector(
            onTap: () {
              // Schowaj klawiaturę po kliknięciu poza pole tekstowe
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 150),
                  Center(
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
                  SizedBox(height: 100),
                  LoginForm(
                    emailController: _emailController,
                    passwordController: _passwordController,
                  ),
                  SizedBox(height: 40),
                  LoginButton(onPressed: _handleLoginButtonPress),
                  if (_isErrorVisible)
                    SizedBox(height: 20),
                  if (_isErrorVisible)
                    Center(
                      child: ErrorMessage(message: _errorMessage),
                    ),
                  if (_isLoading)
                    SizedBox(height: 20),
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF3C729E)),
                      ),
                    ),
                  SizedBox(height: isPortrait ? 170 : 100),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: RegistrationPrompt(),
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

class BackgroundOvals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
      ],
    );
  }
}

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginForm({
    required this.emailController,
    required this.passwordController,
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
                  prefixIcon: const Icon(FontAwesomeIcons.solidUser, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40), // Space between inputs
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
      ],
    );
  }
}

class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 186,
        height: 36,
        child: ElevatedButton(
          onPressed: onPressed,
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
    );
  }
}

class ErrorMessage extends StatelessWidget {
  final String message;

  const ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: message == "Konto zostało utworzone" ? Colors.green : Colors.red,
      ),
    );
  }
}

class RegistrationPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}