import 'dart:ui';
import 'package:nylo_framework/nylo_framework.dart';
import 'bootstrap/boot.dart';

import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

/// Nylo - Framework for Flutter Developers
/// Docs: https://nylo.dev/docs/6.x

void _logNotificationId(RemoteMessage message, {String context = 'onMessage'}) {
  final nid = message.data['notificationId']?.toString();
  if (nid != null && nid.isNotEmpty) {
    debugPrint('[FCM][$context] notificationId=$nid');
  } else {
    debugPrint('[FCM][$context] no notificationId on message.data');
  }
}

// Background handler (separate isolate)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _logNotificationId(message, context: 'background');
}

Future<void> _attachFcmToNyloPush() async {
  // Allow banners while app is in foreground
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, badge: true, sound: true,
  );

  // Foreground: mirror incoming FCM to a Nylo local notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    _logNotificationId(message, context: 'onMessage');
    final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body  = message.notification?.body  ?? message.data['body']  ?? '';
    await PushNotification.sendNotification(title: title, body: body);
  });

  // App opened from a notification 
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    _logNotificationId(message, context: 'onMessageOpenedApp');
    final title = message.notification?.title ?? 'Opened from notification';
    final body  = message.notification?.body  ?? '';
    await PushNotification.sendNotification(title: title, body: body);
  });
}

/// Main entry point for the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Nylo.init(
    setup: Boot.nylo,
    // setupFinished: Boot.finished,
    setupFinished: (nylo) async {
      await Boot.finished(nylo);
      await _attachFcmToNyloPush();
    },

    // appLifecycle: {
    //   // Uncomment the code below to enable app lifecycle events
    //   AppLifecycleState.resumed: () {
    //     print("App resumed");
    //   },
    //   AppLifecycleState.paused: () {
    //     print("App paused");
    //   },
    // }

    // showSplashScreen: true,
    // Uncomment showSplashScreen to show the splash screen
    // File: lib/resources/widgets/splash_screen.dart
  );
}
