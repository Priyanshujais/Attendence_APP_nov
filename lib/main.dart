import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      // Use builder only if you need to use library outside ScreenUtilInit context
      builder: (_, child) {
        return KeyboardVisibilityProvider(
          child: MaterialApp(
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
      child: const SplashScreen(),
    );
  }
}
