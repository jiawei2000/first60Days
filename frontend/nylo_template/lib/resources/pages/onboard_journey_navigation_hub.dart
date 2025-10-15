import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

import 'package:flutter_app/resources/widgets/onboard_journey/first_widget.dart';
import 'package:flutter_app/resources/widgets/onboard_journey/second_widget.dart';
import 'package:flutter_app/resources/widgets/onboard_journey/third_widget.dart';
import 'package:flutter_app/resources/widgets/onboard_journey/fourth_widget.dart';

class OnboardJourneyNavigationHub extends NyStatefulWidget
    with BottomNavPageControls {
  static RouteView path =
      ("/onboard-journey", (_) => OnboardJourneyNavigationHub());

  OnboardJourneyNavigationHub()
      : super(
            child: () => _OnboardJourneyNavigationHubState(),
            stateName: path.stateName());

  /// State actions
  static NavigationHubStateActions stateActions =
      NavigationHubStateActions(path.stateName());
}

class _OnboardJourneyNavigationHubState
    extends NavigationHub<OnboardJourneyNavigationHub> {
  /// Layouts:
  /// - [NavigationHubLayout.bottomNav] Bottom navigation
  /// - [NavigationHubLayout.topNav] Top navigation
  /// - [NavigationHubLayout.journey] Journey navigation
  NavigationHubLayout? layout = NavigationHubLayout.journey(
      // backgroundColor: Colors.white,
      );

  /// Should the state be maintained
  @override
  bool get maintainState => true;

  /// Navigation pages
  _OnboardJourneyNavigationHubState()
      : super(() async {
          /// * Creating Navigation Tabs
          /// [Navigation Tabs] 'dart run nylo_framework:main make:stateful_widget home_tab,settings_tab'
          /// [Journey States] 'dart run nylo_framework:main make:journey_widget welcome_tab,users_dob,users_info --parent=OnboardJourney'
          return {
            0: NavigationTab.journey(
              page: const FirstWidget(),
            ),
            1: NavigationTab.journey(
              page: const SecondWidget(),
            ),
            2: NavigationTab.journey(
              page: const ThirdWidget(),
            ),
            3: NavigationTab.journey(
              page: const FourthWidget(),
            ),
          };
        });

  /// Handle the tap event
  @override
  onTap(int index) {
    super.onTap(index);
  }
}
