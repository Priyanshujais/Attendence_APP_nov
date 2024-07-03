import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import 'package:zarvis_app/pages/home_page/splash_screen.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';



void main() {
  runApp(const pages());
}

class pages extends StatelessWidget {
  const pages({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return KeyboardVisibilityProvider(
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Zarvis',
            // You can use the library anywhere in the app even in theme
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: child,
          ),
        );
      },
      child:   SplashScreen(),
    );
  }
}
