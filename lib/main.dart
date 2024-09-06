import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';
import 'main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase

  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => const Login(),
      '/login': (context) => const Login(),
      '/register': (context) => const Register(),
      '/main_page': (context) => const MainPage(),

    },
  ));
}

