import 'package:nylo_framework/nylo_framework.dart';
import 'package:flutter/material.dart';


class CaregiverForm extends NyFormData {
  CaregiverForm({String? name}) : super(name ?? "caregiver");

  @override
  @override
fields() => [
  Field.text(
    "Username",
    validate: FormValidator.rule("not_empty"),
    style: "compact",
  ),
  Field.text(
    "Email",
    validate: FormValidator.rule("not_empty"),
    style: "compact",
  ),
  Field.text(
    "Phone Number",
    validate: FormValidator.rule("not_empty"),
    style: "compact",
  ),
  Field.password(
    "Password",
    validate: FormValidator.rule("not_empty"),
    style: "compact",
  ),
];

}
