import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(HedieatyApp());
}

class HedieatyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedieaty - Gift List Manager',
      theme: ThemeData(
        primaryColor: Color(0xFF6200EE),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF6200EE)),
        scaffoldBackgroundColor: Color(0xFFF2F2F2),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF6200EE),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6200EE),
        ),
      ),
      home: LoginPage(), // The LoginPage you already created
    );
  }
}
