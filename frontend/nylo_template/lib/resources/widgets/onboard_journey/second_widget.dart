import 'package:flutter/material.dart';
import 'package:flutter_app/resources/pages/onboard_journey_navigation_hub.dart';
import '/resources/widgets/buttons/buttons.dart';
import 'package:nylo_framework/nylo_framework.dart';

class SecondWidget extends StatefulWidget {
  const SecondWidget({super.key});

  @override
  createState() => _SecondWidgetState();
}

class _SecondWidgetState extends JourneyState<SecondWidget> {
  _SecondWidgetState()
      : super(navigationHubState: OnboardJourneyNavigationHub.path.stateName());

  @override
  get init => () {
        // Your initialization logic here
      };

  @override
  Widget view(BuildContext context) {
    return buildJourneyContent(
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Digital Nanny', style: Theme.of(context).textTheme.headlineMedium),
          Image.asset(
            getImageAsset("secondwidget.jpg")
          ),
          const SizedBox(height: 20),
          Text('Update the baby journal online'),
        ],
      ),
      nextButton: Button.primary(
        text: isLastStep ? "Get Started" : "Continue",
        onPressed: onNextPressed,
      ),
      backButton: isFirstStep
          ? null
          : Button.textOnly(
              text: "Back",
              textColor: Colors.black87,
              onPressed: onBackPressed,
            ),
    );
  }

  /// Check if the journey can continue to the next step
  /// Override this method to add validation logic
  @override
  Future<bool> canContinue() async {
    // Perform your validation logic here
    // Return true if the journey can continue, false otherwise
    return true;
  }

  /// Called when unable to continue (canContinue returns false)
  /// Override this method to handle validation failures
  @override
  Future<void> onCannotContinue() async {
    showToastSorry(description: "You cannot continue");
  }

  /// Called before navigating to the next step
  /// Override this method to perform actions before continuing
  @override
  Future<void> onBeforeNext() async {
    // E.g. save data to session
    // session('onboarding', {
    //   'name': 'Anthony Gordon',
    //   'occupation': 'Software Engineer',
    // });
    //
    // final sessionData = session('onboarding').data(); // {'name': 'Anthony Gordon', 'occupation': 'Software Engineer'}
    // printInfo(sessionData);

    // access the session data from other NavigationTabs
  }

  /// Called after navigating to the next step
  /// Override this method to perform actions after continuing
  @override
  Future<void> onAfterNext() async {
    print('Navigated to the next step');
  }

  /// Called when the journey is complete (at the last step)
  /// Override this method to perform completion actions
  @override
  Future<void> onComplete() async {}
}
