import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // Ensure you're using the correct options
    );
    print('Firebase initialized successfully.');
  } catch (e) {
    print('Error initializing Firebase: $e');
    throw e; // Rethrow the error for further handling
  }
}
Future<void> initializeFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
    try {
      String? apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null) {
        print('APNs Token: $apnsToken');
      } else {
        print('Failed to retrieve APNs token.');
      }
    } catch (e) {
      print('Error retrieving APNs token: $e');
    }
  } else {
    print('User declined or has not accepted permission');
  }
}

Future<void> initializeApp() async {
  await initializeFirebase();
  await initializeFCM();
  await initializeSharedPreferences();
}


Future<void> initializeSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? storedFcmToken = prefs.getString('fcm_token');
  if (storedFcmToken != null) {
    print("Stored FCM Token: $storedFcmToken");
  } else {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await prefs.setString('fcm_token', fcmToken);
      print("New FCM Token stored: $fcmToken");
    } else {
      print("Failed to retrieve FCM token.");
    }
  }
}

