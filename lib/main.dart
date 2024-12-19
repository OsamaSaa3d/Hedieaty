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
      home: SplashScreen(), // Show Splash Screen first
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLoginPage();
  }

  // Navigate to LoginPage after a delay
  void _navigateToLoginPage() {
    Future.delayed(Duration(seconds: 3), () {
      // After 3 seconds, navigate to the login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6200EE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.jpg',
                height: 100.0), // Add your logo image here
            SizedBox(height: 20),
            Text(
              'Welcome to Hedieaty!',
              style: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
