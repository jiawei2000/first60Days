import 'dart:io';
import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'routes.dart';
import 'screens/onboarding_screen.dart'; 
import 'screens/landing_page.dart';
import 'screens/create_journal_entry.dart';
import 'screens/profile_page.dart';
import 'screens/choose_baby_screen.dart';
import 'model/baby.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness:
            !kIsWeb && Platform.isAndroid ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return MaterialApp(
      title: 'Digital Nanny',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: AppTheme.textTheme,
        platform: TargetPlatform.iOS,
        dividerTheme: const DividerThemeData(color: Color(0xFFE0E0E0)),
      ),
      home: const OnboardingScreen(),
      routes: {
            Routes.journal: (_) => const JournalEntryPage(),
            Routes.profile: (_) => const ProfilePage(),
            Routes.chooseBaby: (_) => const ChooseBabyScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == Routes.landing && settings.arguments is Baby) {
          final b = settings.arguments as Baby;
          return MaterialPageRoute(
            builder: (_) => LandingPage(
              babyName: b.name,
              avatarUrl: b.avatarUrl,
            ),
          );
        }
        return null;
      },
    );
  }
}

// 👇 Keep HexColor class here
class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }
}
