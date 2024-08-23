import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zarvis_app/pages/home_page/HomeScreen.dart';
import '../Login_pages/LoginScreen.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Delay for splash screen and then navigate based on authentication status
    Timer(const Duration(seconds: 4), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token=prefs.getString("token");
      String? locationId =prefs.getString("locationId");
      String? userId =prefs.getString("userId");
      String? projectCode =prefs.getString("projectCode");
      String? deviceId =prefs.getString("deviceId");
      String? companyId =prefs.getString("companyId");
      String? empCode =prefs.getString("empCode");
      String? clientId =prefs.getString("clientId");

      bool? isLoggedIn = prefs.getBool('isLoggedIn');

      if (isLoggedIn != null) {
        // Navigate to HomeScreen if user is logged in
        if (isLoggedIn) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) =>
                  Homescreen(token: token ?? "",
                    locationId: locationId??"",
                    userId: userId??"",
                    projectCode: projectCode??"",
                    deviceId: deviceId??"",
                    clientId:clientId??"",
                    companyId: companyId??"",
                    empCode: empCode??"",
                        ),
              ));
        }
        else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()
              ));
        }
      }
      else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()
            ));
      }
    }
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Image.asset(
            'assets/images/background.jpeg',
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/images/zarvis.png',
                width: 200.w,
                height: 200.h,
              ),
            ),
          ),
        ],
      ),
    );
  }
  }



