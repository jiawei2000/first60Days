import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

/* Login Form
|--------------------------------------------------------------------------
| Usage: https://nylo.dev/docs/6.x/forms#how-it-works
| Casts: https://nylo.dev/docs/6.x/forms#form-casts
| Validation Rules: https://nylo.dev/docs/6.x/validation#validation-rules
|-------------------------------------------------------------------------- */

class LoginForm extends NyFormData {
  LoginForm({String? name}) : super(name ?? "login");

  @override
  fields() => [
        Field.text(
          "Username",
          autofocus: true,
          prefixIcon: const Icon(Icons.person_outline),
          validate: FormValidator.rule("not_empty"),
          style: "compact",
          value: "jiawei11",
        ),
        Field.password(
          "Password",
          validate: FormValidator.rule("not_empty"),
          style: "compact",
          value: "password123",
        ),
      ];
}
