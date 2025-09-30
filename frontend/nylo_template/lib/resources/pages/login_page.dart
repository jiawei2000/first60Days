import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/controllers/login_controller.dart';
import '/app/forms/login_form.dart';
import '/resources/widgets/logo_widget.dart';
import '/resources/widgets/buttons/buttons.dart';

class LoginPage extends NyStatefulWidget<LoginController> {
  static RouteView path = ("/login", (_) => LoginPage());

  LoginPage({super.key}) : super(child: () => _LoginPageState());
}

class _LoginPageState extends NyPage<LoginPage> {
  /// [LoginController] controller
  LoginController get controller => widget.controller;
  LoginForm form = LoginForm();

  @override
  get init => () {};

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
              "first60Days",
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
                    (data) {
                      debugPrint("Data: $data");
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
}
