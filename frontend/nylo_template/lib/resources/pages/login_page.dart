import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/controllers/login_controller.dart';
import '/app/forms/login_form.dart';
import '/resources/widgets/logo_widget.dart';
import '/resources/widgets/buttons/buttons.dart';
import '/app/networking/user_api_service.dart';
import '/config/keys.dart';
import '/resources/pages/choose_baby_page.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends NyStatefulWidget<LoginController> {
  static RouteView path = ("/login", (_) => LoginPage());

  LoginPage({super.key}) : super(child: () => _LoginPageState());
}

class _LoginPageState extends NyPage<LoginPage> {
  /// [LoginController] controller
  LoginController get controller => widget.controller;
  LoginForm form = LoginForm();

  late UserApiService userApiService;

  @override
  get init => () {
        userApiService = UserApiService();
      };

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In"), centerTitle: true),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Logo(),
            Text(
              "Baby Journal",
            ).displayMedium(),
            const SizedBox(height: 36),
            NyForm(
              form: form,
              footer: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Button.primary(
                  text: "Login",
                  submitForm: (
                    form,
                    (data) async {
                      onLogin(data['username'], data['password']);
                    }
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _getFcmTokenWithPermission() async {
    final messaging = FirebaseMessaging.instance;

    // Request notification permission (iOS + Android 13+)
    final settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      showToastWarning(
        title: "Notifications disabled",
        description: "Enable them in Settings to receive alerts.",
      );
      return null;
    }

    final token = await messaging.getToken();
    if (token == null) {
      showToastWarning(title: "No FCM token", description: "Could not register this device for notifications.");
    }
    return token;
  }

  void onLogin(String username, String password) async {
    final fcmToken = await _getFcmTokenWithPermission();

    var response =
        await userApiService.login(username: username, password: password, fcmToken: fcmToken,);

    // Handle response
    if (response != null) {
      // showToastSuccess(title: "Login success", description: "Login Successful");
      await Auth.authenticate(data: {"token": response['token']});
      await Keys.bearerToken.save(response['token']);
      final dynamic userId = response['user']?["id"];
      if (userId != null) {
        await Keys.userId.save(userId.toString());
      }
      // Persist caregiver/account name for Profile display
      await Keys.caregiverName.save(username);
      // Navigate to navigation hub

      // Test subscribe to daily topic
      //    so the cron job can reach this device
      if (fcmToken != null) {
        await FirebaseMessaging.instance.subscribeToTopic('daily_baby_journal');
      }


      routeTo(ChooseBabyPage.path, navigationType: NavigationType.pushAndForgetAll);
    } else {
      // Show error message
      showToastWarning(title: "Login failed", description: "Please try again");
    }
  }
}
