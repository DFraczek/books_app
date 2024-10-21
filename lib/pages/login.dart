import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/background_ovals.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  bool _isErrorVisible = false;
  bool _isLoading = false;
  String _errorMessage = '';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  Future<void> _handleLoginButtonPress() async {
    setState(() {
      _isErrorVisible = false;
      _isLoading = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    // Email format validation
    final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Pola nie mogą być puste";
        _isErrorVisible = true;
        _isLoading = false;
      });
      return;
    }

    if (!emailRegExp.hasMatch(email)) {
      setState(() {
        _errorMessage = "Niepoprawny adres e-mail";
        _isErrorVisible = true;
        _isLoading = false;
      });
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        const storage = FlutterSecureStorage();
        await storage.write(key: 'user_id', value: user.uid);

        Navigator.pushNamed(context, '/main_page');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = "Użytkownik o podanym adresie e-mail nie istnieje";
        } else if (e.code == 'invalid-credential') {
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
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F1E5),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const BackgroundOvals(),
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 150),
                  const Center(
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
                  const SizedBox(height: 100),
                  LoginForm(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    isPasswordVisible: _isPasswordVisible,
                    onPasswordVisibilityToggle: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  LoginButton(onPressed: _handleLoginButtonPress),
                  if (_isErrorVisible) const SizedBox(height: 20),
                  if (_isErrorVisible)
                    Center(
                      child: ErrorMessage(message: _errorMessage),
                    ),
                  if (_isLoading) const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3C729E)),
                      ),
                    ),
                  SizedBox(height: isPortrait ? 170 : 100),
                  const Positioned(
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

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final VoidCallback onPasswordVisibilityToggle;

  const LoginForm({super.key, 
    required this.emailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.onPasswordVisibilityToggle,
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
        const SizedBox(height: 40),
        FractionallySizedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Hasło',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  prefixIcon: const Icon(FontAwesomeIcons.lock, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                      color: Colors.grey,
                    ),
                    onPressed: onPasswordVisibilityToggle,
                  ),
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

  const LoginButton({super.key, required this.onPressed});

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

  const ErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: Colors.red,
      ),
    );
  }
}

class RegistrationPrompt extends StatelessWidget {
  const RegistrationPrompt({super.key});

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
