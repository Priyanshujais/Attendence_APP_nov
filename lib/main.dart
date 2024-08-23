import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:zarvis_app/pages/home_page/splash_screen.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'connectivitiplus.dart';
import 'firebase_initialization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();
  await Future.delayed(const Duration(seconds: 3));
  //String ? token = await FirebaseMessaging.instance.getToken();
  runApp(MyApp());
  Get.put(Connectivitiplus(),permanent: true);
}
  //await Future.delayed(const Duration(seconds: 3));
  // String? token = await FirebaseMessaging.instance.getToken();



class MyApp extends StatelessWidget {
  const MyApp({super.key});

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