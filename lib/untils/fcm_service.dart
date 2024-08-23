import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully.');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
}

Future<void> initializeFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print('Notification permissions are denied');
  } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
    // Retrieve APNs token
    String? apnsToken = await messaging.getAPNSToken();
    if (apnsToken != null) {
      print('APNs Token: $apnsToken');
    } else {
      print('Failed to retrieve APNs token.');
    }

    // Get FCM token directly
    String? fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      print("FCM Token: $fcmToken");
    } else {
      print("Failed to retrieve FCM token.");
    }
  } else {
    print('User has not yet responded to the permission request');
  }
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

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  await initializeFCM();
  await initializeSharedPreferences();
}