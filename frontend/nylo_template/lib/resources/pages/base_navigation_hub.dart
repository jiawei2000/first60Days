import 'package:flutter/material.dart';
import 'package:flutter_app/resources/pages/create_journal_entry_page.dart';
import 'package:flutter_app/resources/pages/profile_page.dart';
import 'package:flutter_app/resources/widgets/splash_screen.dart';
import 'package:nylo_framework/nylo_framework.dart';

class BaseNavigationHub extends NyStatefulWidget with BottomNavPageControls {
  static RouteView path = ("/base", (_) => BaseNavigationHub());

  BaseNavigationHub()
      : super(
            child: () => _BaseNavigationHubState(),
            stateName: path.stateName());

  /// State actions
  static NavigationHubStateActions stateActions =
      NavigationHubStateActions(path.stateName());
}

class _BaseNavigationHubState extends NavigationHub<BaseNavigationHub> {
  /// Layouts:
  // / - [NavigationHubLayout.bottomNav] Bottom navigation
  /// - [NavigationHubLayout.topNav] Top navigation
  /// - [NavigationHubLayout.journey] Journey navigation
  NavigationHubLayout? layout = NavigationHubLayout.bottomNav(
    backgroundColor: Colors.white,
  );

  /// Should the state be maintained
  @override
  bool get maintainState => true;

  /// Navigation pages
  _BaseNavigationHubState()
      : super(() async {
          /// * Creating Navigation Tabs
          /// [Navigation Tabs] 'dart run nylo_framework:main make:stateful_widget home_tab,settings_tab'
          /// [Journey States] 'dart run nylo_framework:main make:journey_widget welcome_tab,users_dob,users_info --parent=Base'
          return {
            0: NavigationTab(
              title: "Home",
              page: CreateJournalEntryPage(),
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home),
            ),
            1: NavigationTab(
              title: "Baby Journal",
              page: SplashScreen(),
              icon: Icon(Icons.book),
              activeIcon: Icon(Icons.book),
            ),
            2: NavigationTab(
              title: "Feed Plan",
              page: SplashScreen(),
              icon: Icon(Icons.calendar_today_rounded),
              activeIcon: Icon(Icons.calendar_today_rounded),
            ),
            3: NavigationTab(
              title: "Profile",
              page: ProfilePage(),
              icon: Icon(Icons.person),
              activeIcon: Icon(Icons.person),
            ),
          };
        });

  /// Handle the tap event
  @override
  onTap(int index) {
    super.onTap(index);
  }
}
