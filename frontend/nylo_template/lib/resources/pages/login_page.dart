import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/controllers/login_controller.dart';
import '/app/forms/login_form.dart';
import '/resources/widgets/logo_widget.dart';
import '/resources/widgets/buttons/buttons.dart';
import '/app/networking/user_api_service.dart';
import '/config/keys.dart';
import '/resources/pages/choose_baby_page.dart';

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

  void onLogin(String username, String password) async {
    var response =
        await userApiService.login(username: username, password: password);

    // Handle response
    if (response != null) {
      // showToastSuccess(title: "Login success", description: "Login Successful");
      await Auth.authenticate(data: {"token": response['token']});
      await Keys.bearerToken.save(response['token']);
      // Navigate to navigation hub
      routeTo(ChooseBabyPage.path, navigationType: NavigationType.pushAndForgetAll);
    } else {
      // Show error message
      showToastWarning(title: "Login failed", description: "Please try again");
    }
  }
}
