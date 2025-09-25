import 'dart:ui';
import 'package:nylo_framework/nylo_framework.dart';
import 'bootstrap/boot.dart';

/// Nylo - Framework for Flutter Developers
/// Docs: https://nylo.dev/docs/6.x

/// Main entry point for the application.
void main() async {
  await Nylo.init(
    setup: Boot.nylo,
    setupFinished: Boot.finished,

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
