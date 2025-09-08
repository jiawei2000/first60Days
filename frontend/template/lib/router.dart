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
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.journal:
        return MaterialPageRoute(builder: (_) => const JournalEntryPage());

      case Routes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case Routes.chooseBaby:
        final token = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ChooseBabyScreen(token: token),
        );

      case Routes.chat:
        return MaterialPageRoute(builder: (_) => const ChatPage());

      case Routes.calendar:
        return MaterialPageRoute(builder: (_) => const CalendarScreen());

      case Routes.landing:
        final baby = settings.arguments as Baby;
        return MaterialPageRoute(
          builder: (_) => LandingPage(
            babyName: baby.name,
            avatarUrl: baby.avatarUrl,
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
    }
  }
}
