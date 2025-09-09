// lib/router.dart
import 'package:flutter/material.dart';
import 'routes.dart';
import 'screens/onboarding_screen.dart';
import 'screens/landing_page.dart';
import 'screens/create_journal_entry.dart';
import 'screens/profile_page.dart';
import 'screens/choose_baby_screen.dart';
import 'screens/chat_page.dart';
import 'screens/calendar/calendar_screen.dart';
import 'model/baby.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.journal: {
        // expects: { 'babyId': String }
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || args['babyId'] == null) {
          return _badArgs('Routes.journal expects { babyId }');
        }
        final String babyId = args['babyId'] as String;
        return MaterialPageRoute(
          builder: (_) => JournalEntryPage(babyId: babyId),
        );
      }

      case Routes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case Routes.chooseBaby:
        // no arguments; token comes from AuthProvider globally
        return MaterialPageRoute(builder: (_) => const ChooseBabyScreen());

      case Routes.chat:
        return MaterialPageRoute(builder: (_) => const ChatPage());

      case Routes.calendar:
        return MaterialPageRoute(builder: (_) => const CalendarScreen());

      case Routes.landing: {
        // expects: { 'baby': Baby }
        final args = settings.arguments as Map<String, dynamic>?;
        final baby = args?['baby'] as Baby?;
        if (baby == null) return _badArgs('Routes.landing expects { baby }');
        return MaterialPageRoute(
          builder: (_) => LandingPage(baby: baby),
        );
      }

      default:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
    }
  }

  static Route<dynamic> _badArgs(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Routing error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
