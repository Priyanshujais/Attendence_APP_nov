import 'dart:async'; // Added missing import for Timer
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../Login_pages/LoginScreen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Set background color to transparent
        body: Stack(
          children: [
            // Background image
            Image.asset(
              'assets/images/background.jpeg',
              // Replace with your background image path
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
            // Overlay image
            Positioned.fill(
              child: Center(
                child: Image.asset(
                  'assets/images/zarvis.png',
                  // Replace with your overlay image path
                  width: 200.w, // Adjust the width as needed
                  height: 200.h, // Adjust the height as needed
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
